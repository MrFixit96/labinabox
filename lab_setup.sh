#!/bin/bash
export API_REPO='https://github.com/pebcakerror/web-design-contest-api.git'
export API_CONTAINER=janderton/labinabox:api_server_v2
export API_CONTAINER_NAME=api_server_v2
export API_VOLUME='/srv/api_server/'
export WWW_CONTAINER=janderton/labinabox:lab_www_server
export WWW_CONTAINER_NAME=lab_www_server
export WWW_VOLUME='/srv/'
export WWW_CONFIG_VOLUME='/srv/nginx/etc/'
export FTP_CONTAINER=janderton/labinabox:ftpserver
export FTP_CONTAINER_NAME=ftpserver
export FTP_VOLUME='/srv/'
export LAB_SHELL_CONTAINER=janderton/labinabox:lab_shell
export LAB_SHELL_CONTAINER_NAME=lab_shell
export DNS_CONTAINER=sameersbn/bind:latest
export DNS_CONTAINER_NAME=bind
export DNS_VOLUME='/srv/dns/'
export EXTERNAL_IP=`ifconfig|grep eth0 -A1|grep inet|awk -F: '{print $2}'|awk '{print $1}'`
export BIND_STATUS=`docker ps -a|grep bind`

#Configuring Docker 
echo '*******Configuring Docker Port******'
if [[ ! -f /etc/docker/daemon.json ]];then
    cp -rf /srv/labinabox/docker/daemon.json /etc/docker/
fi
service docker restart
#Setup DNS Server
echo '*******Copying DNS Zones if not present***********'
if [[ ! -d /srv/dns ]];then
    cp -r /srv/labinabox/dns $DNS_VOLUME
fi
echo '***********STARTING DNS**********'
#check and see if dns is already running and start it if its not
if [[ ! $BIND_STATUS ]];then
    docker run -itd --name=$DNS_CONTAINER_NAME --dns=127.0.0.1 -p $EXTERNAL_IP:53:53/udp -p $EXTERNAL_IP:10000:10000  --volume=$DNS_VOLUME:/data  --env='ROOT_PASSWORD=SecretPassword'  $DNS_CONTAINER
elif [[ `echo $BIND_STATUS|grep Exited` ]];then
    docker start bind
else
    echo 'DNS is already running' && docker container ls
fi

#Setup Student Shell environment
echo '***********Copying SHELL**********'
if [[ ! -f /usr/local/bin/lab_shell ]];then
    cp /srv/labinabox/lab_shell /usr/local/bin/
fi

echo '***********STARTING SHELLS**********'
for id in `seq 1 10`
do
    #sudo useradd -G docker -m -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.' -s /usr/local/bin/lab_shell user$id
    sudo useradd -m -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.' -s /usr/local/bin/lab_shell team$id
    mkdir /srv/team$id && docker create -it  -v /srv/team$id:/root --name team$id $LAB_SHELL_CONTAINER /bin/bash
    cd /srv/team$id && tree -H baseHREF >/srv/team$id/index.html && cd -
#    ln -s /srv/team$id /srv/www/team$id
done


#Setup FTP Server
echo '***********STARTING FTP SERVER**********'
docker run -itd -p 30000-30010:30000-30010 -p 21:21 -p 20:20 -v "$FTP_VOLUME:/ftpdepot:rw" --name $FTP_CONTAINER_NAME $FTP_CONTAINER
echo '***********Configuring FTP SERVER**********'
cp ftpsetup.sh $FTP_VOLUME
docker exec -itd $FTP_CONTAINER_NAME /bin/sh -c '/ftpdepot/ftpsetup.sh'
docker stop $FTP_CONTAINER_NAME > /dev/null 2>&1
docker start $FTP_CONTAINER_NAME > /dev/null 2>&1

#Setup student web servers
echo '*******Copying WWW Config if not present***********'
if [[ ! -d /srv/nginx ]];then
        cp -rf /srv/labinabox/nginx $WWW_VOLUME
fi
echo '***********Setting UP WWW SERVER**********'
docker run -itd -p 80:80  -v "$WWW_CONFIG_VOLUME:/etc/nginx" -v "$WWW_VOLUME:/usr/share/nginx/html:rw" --name $WWW_CONTAINER_NAME $WWW_CONTAINER
docker cp /usr/bin/tree $WWW_CONTAINER_NAME:/usr/bin/tree
docker exec -it $WWW_CONTAINER_NAME /bin/sh -c 'tree -H baseHREF >/srv/index.html' #<----Run this from wwwroot dir in main OS

#Setup API Server
echo '***********Cloning API Repo**********'
git clone $API_REPO $API_VOLUME

echo '***********Setting UP API SERVER**********'
docker build -t $API_CONTAINER_NAME $API_VOLUME
docker run -itd -p 60606:60606  --name  $API_CONTAINER_NAME $API_CONTAINER
docker container ls
