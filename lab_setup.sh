#!/bin/bash
##################################################################################################################################
#
#
#	Name: lab_setup.sh
#	Author: James Anderton @MrFixit96 (james@janderton.com)
#	Date: 4/17/2018
#	Purpose: This script will download and setup a "lab in a box" environment complete with one persistent shell per user,
#		an FTP server, an Nginx WWW Server and a NodeJS API server.
#
#
##################################################################################################################################
OLDIFS="${IFS}"
IFS=$'\n'

######## Global Config Parameters
export API_REPO='https://github.com/pebcakerror/web-design-contest-api.git'
export API_CONTAINER=janderton/labinabox:api_server_v2
export API_CONTAINER_NAME=api_server_v2
export API_VOLUME='/srv/api_server/'
#
export WWW_CONTAINER=janderton/labinabox:lab_www_server
export WWW_CONTAINER_NAME=lab_www_server
export WWW_VOLUME='/srv/'
export WWW_CONFIG_VOLUME='/srv/nginx/etc/'
#
export FTP_CONTAINER=janderton/labinabox:ftpserver
export FTP_CONTAINER_NAME=ftpserver
export FTP_VOLUME='/srv'
#
#export LAB_SHELL_CONTAINER=janderton/labinabox:lab_shell
export LAB_SHELL_CONTAINER=janderton/labinabox:lab_shell 
export LAB_SHELL_CONTAINER_NAME=lab_shell
#
export DNS_CONTAINER=sameersbn/bind:latest
export DNS_CONTAINER_NAME=bind
export DNS_VOLUME='/srv/dns/'
#
export MINIO_COMPOSE_FILE=/srv/labinabox/minio/docker-compose.yml
export MINIO_CONTAINER=minio/minio
export MINIO_CONTAINER_NAME=minio
#
export PWFILE='/srv/labinabox/passwords'
export BIND_STATUS=`docker ps -a|grep bind`
export NUM_TEAMS=`wc -l $PWFILE | awk '{print $1}'`


#IP info
if [[ `ifconfig|grep eno1 -A1|grep inet|awk '{print $2}'|awk '{print $1}'` ]]; then 
	echo 'using wired connection'
	export EXTERNAL_IP=`ifconfig|grep eno1 -A1|grep inet|awk '{print $2}'|awk '{print $1}'`
elif [[ `ifconfig|grep wlp58s0 -A1|grep inet|awk '{print $2}'` ]];then
	echo 'using wireless connection'  `ifconfig|grep wlp58s0 -A1|grep inet|awk '{print $2}'`
        export EXTERNAL_IP=`ifconfig|grep wlp58s0 -A1|grep inet|awk '{print $2}'`
fi
echo "************External IP = $EXTERNAL_IP*************"
export DOCKER_HOST='tcp://:2375'

#################Setup DNS Server ############################################################################################33
echo '*******Copying DNS Zones if not present***********'
#if [[ ! -d /srv/dns ]];then
	rm -rm /srv/dns/bind/lib/webdesigncontest.org.hosts
	cp -r /srv/labinabox/dns $DNS_VOLUME
#fi
echo '***********STARTING DNS**********'
#check and see if dns is already running and start it if its not
if [[ ! $BIND_STATUS ]];then
    docker run -itd --name=$DNS_CONTAINER_NAME --dns=127.0.0.1 -p $EXTERNAL_IP:53:53/udp -p $EXTERNAL_IP:10000:10000  --volume=$DNS_VOLUME:/data  --env='ROOT_PASSWORD=SecretPassword'  $DNS_CONTAINER
elif [[ `echo $BIND_STATUS|grep Exited` ]];then
    docker start bind
else
    echo 'DNS is already running' && docker container ls
fi

#################Setup Student Shell environment #################################################################################
echo '***********STARTING SHELLS**********'
for id in `seq 1 $NUM_TEAMS`
do
    if [[ ! `grep "team$id" /etc/passwd | awk '{print $1}'` == team$id ]];then
        #sudo useradd -G docker -m -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.' -s /usr/local/bin/lab_shell user$id
        sudo useradd  -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.'  -s /usr/local/bin/lab_shell team$id
    fi
    docker create -it -v /srv/team$id:/app   -p 22$id:22 --user team$id --name team$id $LAB_SHELL_CONTAINER /bin/bash
    mkdir -p /srv/team$id/html && cp /srv/labinabox/index.html /srv/team$id/html/
done

###################Setup FTP Server ##############################################################################################
echo '***********STARTING FTP SERVER**********'
docker run -d -p 30000-30010:30000-30010 -p 21:21 -p 20:20 -v "$FTP_VOLUME:/ftpdepot" --name $FTP_CONTAINER_NAME $FTP_CONTAINER
echo '***********Configuring FTP SERVER**********'

if [[ -f $FTP_VOLUME/ftpsetup.sh ]];then
  rm -rf $FTP_VOLUME/ftpsetup.sh
  rm -rf $FTP_VOLUME/ftpsetup2.sh
fi
####Setting up basic ftp configs and then coming back to setup users in next section
cp /srv/labinabox/ftpsetup2.sh $FTP_VOLUME/ftpsetup2.sh
docker exec -itd $FTP_CONTAINER_NAME /bin/sh -c "/ftpdepot/ftpsetup2.sh"

docker stop $FTP_CONTAINER_NAME > /dev/null 2>&1
docker start $FTP_CONTAINER_NAME > /dev/null 2>&1

######################Setting Team Passwords########################################################################################
if [[ ! -f  /srv/nginx/etc/.htpasswd ]];then
    mkdir -p /srv/nginx/etc
    touch  /srv/nginx/etc/.htpasswd
fi

readarray pwarray < $PWFILE
for item in ${pwarray[@]};do
       team=$(echo "$item"|awk '{print $1}')
       passwd=$(echo $item|awk '{print $NF}')
       echo "Setting PW for $team"
       echo $team:$passwd|chpasswd
       echo $passwd|htpasswd -nbi $team >> /srv/$team/.htpasswd
       docker exec -itd -itd $FTP_CONTAINER_NAME /bin/sh -c "echo $team:$passwd|chpasswd"
       chown -R $team:$team /srv/$team
done

#######################Setup student web servers #####################################################################################
echo '*******Copying WWW Config if not present***********'
if [[ ! -f /srv/nginx/etc/nginx/conf.d/default.conf ]];then
	cp -rf /srv/labinabox/nginx /srv/
fi

echo '***********Setting UP WWW SERVER**********'
for id in `seq 1 $NUM_TEAMS`;
do
tee /srv/nginx/etc/conf.d/team$id.conf <<EOF
server {
  listen       80;
  server_name  team$id.webdesigncontest.org;

  location / {
     root   /ftpdepot/team$id/html;
     index  index.html index.htm;
     auth_basic "Admins Area";
     auth_basic_user_file /ftpdepot/team$id/.htpasswd;
  }

}
EOF

##################### Registering WWW Virtual Servers ###############################################################################
echo "Checking team$id dns"
  if [[ ! `grep -i team$id /srv/dns/bind/lib/webdesigncontest.org.hosts` ]];then
    export line="team$id.webdesigncontest.org.     IN      A       $EXTERNAL_IP"
    echo "writing $line"
    echo $line>>/srv/dns/bind/lib/webdesigncontest.org.hosts
fi

done #EndFor

echo '##########Starting Web Server###############'
docker run -itd -p 80:80  -v "$WWW_CONFIG_VOLUME:/etc/nginx" --volumes-from ftpserver:rw --name $WWW_CONTAINER_NAME $WWW_CONTAINER
docker cp /usr/bin/tree $WWW_CONTAINER_NAME:/usr/bin/tree
if [[ ! -d /srv/html ]];then
   mkdir /srv/html 
fi

cd /srv
tree -H baseHREF >/srv/html/index.html  #<----Run this from wwwroot dir in main OS
cd -

######################Setup API Server ################################################################################################
echo '***********Cloning API Repo**********'
git clone $API_REPO $API_VOLUME

echo '***********Setting UP API SERVER**********'
docker build -t $API_CONTAINER_NAME $API_VOLUME
docker run -itd -p 60606:60606  --name  $API_CONTAINER_NAME $API_CONTAINER

###################Setup/start Minio Server ######################################################################################
grep 'team2' $MINIO_COMPOSE_FILE
if [[ ! $? == 0 ]];then
for id in `seq 1 $NUM_TEAMS`;
do
   if [[ $id < 10 ]];then
	   num=0$id
   else
	   num=$id
   fi

export item=`grep -w "team$id" passwords`
   team=$(echo "$item"|awk '{print $1}')
   passwd=$(echo $item|awk '{print $NF}')
docker run -d -p 90$num:9000 --name minio$id -v /srv:/data -v /srv/minio/config$id --env MINIO_ACCESS_KEY="$team" --env MINIO_SECRET_KEY="$passwd" --restart always minio/minio server /data/$team
#message=`cat <<-EOF
#    $team:
#        ports:
#            - '90$num:9000'
#        container_name: "minio$id"
#        volumes:
#          - '/srv:/data'
#          - '/srv/minio/config$id:/root/.minio'
#        image: minio/minio
#        environment:
#          MINIO_ACCESS_KEY: "$team"
#          MINIO_SECRET_KEY: '$passwd'
#        command: server /data/$team
#        restart: always
#EOF
#`

#  echo "$message" >> $MINIO_COMPOSE_FILE

done
fi
#docker-compose -f $MINIO_COMPOSE_FILE up -d
#docker stack deploy $MINIO_CONTAINER_NAME --compose-file $MINIO_COMPOSE_FILE 
docker container ls

###################### Making Sure not to leave PWs behind #############################################################################
if [[ -f /srv/passwords ]];then
    rm -rf /srv/passwords
fi
IFS="${OLDIFS}"
