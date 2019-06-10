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
export STUDENT_ZIP_FILE='Materials_for_Contestants.zip'
export BIND_STATUS=`docker ps -a|grep bind`
export NUM_TEAMS=`wc -l $PWFILE | awk '{print $1}'`
#Change this to 1 to start using docker compose services instead of single docker containers
export USE_COMPOSE=0

#Get IP info and deduce API Servers IP Address (webserver plus one)
if [[ `ifconfig|grep -A1 -E '^eno|^eth'|grep inet|awk '{print $2}'|awk '{print $1}'|head -n1` ]]; then 
	echo 'using wired connection'
	export EXTERNAL_IP=`ifconfig|grep -A1  -E '^eno|^eth'|grep inet|awk '{print $2}'|awk '{print $1}'|head -n1`
	export INTERFACE=`ifconfig|grep -A1 -E '^eno|^eth'|head -n1|awk -F: '{print $1}'`
elif [[ `ifconfig|grep wlp -A1|grep inet|awk '{print $2}'|head -n1` ]];then
	echo 'using wireless connection'  `ifconfig|grep wlp -A1|grep inet|awk '{print $2}'|head -n1`
        export EXTERNAL_IP=`ifconfig|grep wlp -A1|grep inet|awk '{print $2}'`
	export INTERFACE=`ifconfig|grep wlp |awk -F: '{print $1}'`
fi

IP_LAST_OCTET=`echo $EXTERNAL_IP|awk -F\. '{print $NF}'`
IP_FIRST_THREE_OCTETS=`echo $EXTERNAL_IP|awk -F\. '{print $1 "." $2 "." $3 "."}'`
IP_NEW_OCTET=`expr $IP_LAST_OCTET + 1`
export WWW_IP_ADDRESS="$EXTERNAL_IP"
export API_IP_ADDRESS="$IP_FIRST_THREE_OCTETS$IP_NEW_OCTET"

######Potential Regression... not sure why this was removed, Leaving it in for Branch Merge #######
#Configuring Docker 
#echo '*******Configuring Docker Port******'
#if [[ ! -f /etc/docker/daemon.json ]];then
#    cp -rf /srv/labinabox/docker/daemon.json /etc/docker/
#fi
#service docker restart
#export DOCKER_HOST='tcp://:2375'

echo "************External IP = $EXTERNAL_IP*************"

#################Setup DNS Server ############################################################################################33
echo '*******Copying DNS Zones if not present***********'
#if [[ ! -f /srv/dns/bind/lib/webdesigncontest.org.hosts ]];then
	rm -rf /srv/dns/
	cp -rf /srv/labinabox/dns $DNS_VOLUME
#fi
#check and see if dns is already running and start it if its not
if [[ ! $BIND_STATUS ]];then
    echo '***********CREATING AND STARTING DNS**********'
    docker run -itd --name=$DNS_CONTAINER_NAME --restart always --dns=127.0.0.1 -p $EXTERNAL_IP:53:53/udp -p $EXTERNAL_IP:10000:10000  --volume=$DNS_VOLUME:/data  --env='ROOT_PASSWORD=SecretPassword'  $DNS_CONTAINER
elif [[ `echo $BIND_STATUS|grep Exited` ]];then
    echo '***********STARTING DNS**********'
    docker start bind
else
    echo 'DNS is already running' && docker container ls
fi

#################Setup Student Shell environment #################################################################################
#Setup Student Shell environment
echo '***********Copying SHELL**********'
if [[ ! -f /usr/local/bin/lab_shell ]];then
    cp /srv/labinabox/lab_shell /usr/local/bin/
fi
echo '***********STARTING SHELLS**********'
for id in `seq 1 $NUM_TEAMS`
do
    if [[ ! `grep "team$id" /etc/passwd | awk '{print $1}'` == team$id ]];then
        sudo useradd  -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.'  -s /usr/local/bin/lab_shell team$id
    fi
    docker create -it -v /srv/team$id:/app   -p 22$id:22 --user team$id --name team$id $LAB_SHELL_CONTAINER /bin/bash
    mkdir /srv/team$id && chown team$id:team$id /srv/team$id && cp -rf /srv/labinabox/html /srv/team$id/html 
    cp -rf /srv/backup/team$id/* /srv/team$id/
    docker run -d -p 420$id:3000 -v "/srv/team$id:/home/project:cached" --name theia_$id theiaide/theia:next --inspect=0.0.0.0:1100$id
done

###################Setup FTP Server ##############################################################################################
echo '***********STARTING FTP SERVER**********'
docker run -d --restart always -p 30000-30010:30000-30010 -p 21:21 -p 20:20 -v "$FTP_VOLUME:/ftpdepot:rw" --restart always --name $FTP_CONTAINER_NAME $FTP_CONTAINER
echo '***********Configuring FTP SERVER**********'

if [[ -f $FTP_VOLUME/ftpsetup2.sh ]];then
  rm -rf $FTP_VOLUME/ftpsetup.sh
  rm -rf $FTP_VOLUME/ftpsetup2.sh
fi
####Setting up basic ftp configs and then coming back to setup users in next section
cp /srv/labinabox/ftpsetup2.sh $FTP_VOLUME/ftpsetup2.sh && chmod u+x /srv/labinabox/ftpsetup2.sh
cp /srv/labinabox/passwords $FTP_VOLUME/passwords
docker exec -it $FTP_CONTAINER_NAME /bin/sh -c "/ftpdepot/ftpsetup2.sh"

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
	cp -rf /srv/labinabox/nginx $WWW_VOLUME
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

  location /editor {
    proxy_pass team$id.webdesigncontest.org:420$id
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

echo "***Restarting dns after registering webservers***"
docker stop bind && docker start bind

echo '##########Starting Contest Instruction Web Server###############'
if [[ ! -d /srv/html ]];then
   mkdir /srv/html 
fi

cp -rf /srv/labinabox/index.html /srv/html/

if [[ -f /srv/labinabox/$STUDENT_ZIP_FILE ]];then
   cp -rf /srv/labinabox/$STUDENT_ZIP_FILE /srv/html/
fi

docker run -itd -p $WWW_IP_ADDRESS:80:80 -v "$WWW_CONFIG_VOLUME:/etc/nginx" --volumes-from ftpserver:rw  --restart always --name $WWW_CONTAINER_NAME $WWW_CONTAINER

######################Setup API Server ################################################################################################
echo '***********Cloning API Repo**********'
rm -rf $API_VOLUME
git clone $API_REPO $API_VOLUME

echo '***********Setting UP API SERVER**********'
if [[ -d /srv/api_server ]];then
  docker build -t $API_CONTAINER $API_VOLUME
fi

#if [[ $INTERFACE =~ 'eno' ]] || [[ $INTERFACE =~ 'eth' ]];then
#  docker run -d -p $API_IP_ADDRESS:80:60606  --restart always --name  $API_CONTAINER_NAME $API_CONTAINER
#else
  docker run -d -p 60606:60606  --restart always --name  $API_CONTAINER_NAME $API_CONTAINER
#fi

###################Setup/start Minio Server ######################################################################################
####Leaving the docker-compose settings in here but not using them at the moment
if [[ $USE_COMPOSE -eq 0 ]];then
for id in `seq 1 $NUM_TEAMS`;
do
   if [[ $id -lt 10 ]];then
	   num=0$id
   else
	   num=$id
   fi

   export item=`grep -w "team$id" passwords`
   team=$(echo "$item"|awk '{print $1}')
   passwd=$(echo $item|awk '{print $NF}')
   docker run -d -p 90$num:9000 --name minio$id -v /srv/team$id:/data -v /srv/minio/config$id --env MINIO_ACCESS_KEY="$team" --env MINIO_SECRET_KEY="$passwd" --restart always minio/minio server /data
done
else
  rm $MINIO_COMPOSE_FILE
  for id in `seq 1 $NUM_TEAMS`;
  do
message=`cat <<-EOF
    $team:
        ports:
            - '90$num:9000'
        container_name: "minio$id"
        volumes:
          - '/srv:/data'
          - '/srv/minio/config$id:/root/.minio'
        image: minio/minio
        environment:
          MINIO_ACCESS_KEY: "$team"
          MINIO_SECRET_KEY: '$passwd'
        command: server /data/$team
        restart: always
EOF
`
  done
  echo "$message" >> $MINIO_COMPOSE_FILE
#docker-compose -f $MINIO_COMPOSE_FILE up -d
docker stack deploy $MINIO_CONTAINER_NAME --compose-file $MINIO_COMPOSE_FILE 
fi
docker container ls

###################### Making Sure not to leave PWs behind #############################################################################
if [[ -f /srv/passwords ]];then
    rm -rf /srv/passwords
fi
IFS="${OLDIFS}"
