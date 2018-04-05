#!/bin/bash
export API_REPO='https://github.com/pebcakerror/web-design-contest-api.git'
export API_CONTAINER=janderton/labinabox:api_server
export WWW_CONTAINER=janderton/labinabox:lab_www_server
export FTP_CONTAINER=janderton/labinabox:ftpserver
export LAB_SHELL_CONTAINER=janderton/labinabox:lab_shell
export DNS_CONTAINER=sameersbn/bind:latest
export EXTERNAL_IP=`ifconfig|grep eth0 -A1|grep inet|awk -F: '{print $2}'|awk '{print $1}'`
export BIND_STATUS=`docker ps -a|grep bind`

#Setup DNS Server
echo '*******Copying DNS Zones if not present***********'
if [[ -z /srv/dns ]];then
	cp -r /srv/labinabox/dns /srv/dns
fi
echo '***********STARTING DNS**********'
#check and see if dns is already running and start it if its not
if [[ ! $BIND_STATUS ]];then
    docker run -itd --name=bind --dns=127.0.0.1 -p $EXTERNAL_IP:53:53/udp -p $EXTERNAL_IP:10000:10000  --volume=/srv/dns:/data  --env='ROOT_PASSWORD=SecretPassword'  $DNS_CONTAINER
elif [[ `echo $BIND_STATUS|grep Exited` ]];then
    docker start bind
else
    echo 'DNS is already running' && docker container ls
fi

#Setup Student Shell environment
echo '***********STARTING SHELLS**********'
for id in `seq 1 10`
do
    #sudo useradd -G docker -m -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.' -s /usr/local/bin/lab_shell user$id
    sudo useradd  -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.' -d /srv/user$id -s /usr/local/bin/lab_shell user$id
    docker create -it   --name user$id $LAB_SHELL_CONTAINER /bin/bash
    cd /srv/user$id && tree -H baseHREF >/srv/user$id/index.html && cd -
done


#Setup FTP Server
echo '***********STARTING FTP SERVER**********'
docker run -itd -p 30000-30010:30000-30010 -p 21:21 -p 20:20 -v "/srv:/ftpdepot" --name ftpserver $FTP_CONTAINER
#docker cp ftpsetup.sh $FTP_CONTAINER:/ftpdepot/setup.sh
echo '***********Configuring FTP SERVER**********'
docker exec -itd ftpserver /bin/sh -c '/ftpdepot/ftpsetup.sh'
docker stop ftpserver
docker start ftpserver
docker container ls

#Setup student web servers
echo '***********Setting UP WWW SERVER**********'
docker run -itd -p 80:80  -v "/srv:/usr/share/nginx/html:rw" --name lab_www_server $WWW_CONTAINER
docker cp /usr/bin/tree lab_www_server:/usr/bin/tree
docker exec -it  lab_www_server /bin/sh -c 'tree -H baseHREF >/srv/index.html' #<----Run this from wwwroot dir in main OS

#Setup API Server
echo '***********Cloning API Repo**********'
git clone $API_REPO /srv/api_server

echo '***********Setting UP API SERVER**********'
docker run -itd -P -v "/srv/api_server:/app" --name api_server $API_CONTAINER

