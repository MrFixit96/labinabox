#!/bin/bash
export API_SERVER='https://github.com/pebcakerror/web-design-contest-api'

echo '*********** Starting DNS Server ***********'
docker run -d --name=bind --dns=127.0.0.1   --publish=53:53/udp --publish=10000:10000   --volume=/srv/dns/bind:/data   --env='ROOT_PASSWORD=SecretPassword' sameersbn/bind:latest

echo '********** Setting up Student Shells ************'
for id in `seq 1 10`
do
    sudo useradd -G docker -d /srv/user$id -m -p '$6$XtP.pKgi$QAykbscs0XTFkpgvPtm/Pm76M4XGkBhGxIS3Th8nN6VX9llOsUn4jyNpyu3Z597eTk8k4wRVYHS4FgkeNMcVr.' -s /usr/local/bin/lab_shell user$id
    docker create -it  --expose 80 --name user$id lab_shell /bin/bash
done

echo '********** Setting up ftp server ************'
docker run -itd -p 30000-30010:30000-30010 -p 21:21 -p 20:20 -v "/srv:/ftpdepot" --name ftpserver janderton/labinabox:ftpserver
docker exec -it ftpserver /bin/sh -c '/ftpdepot/ftpsetup.sh'
docker start ftpserver

echo '********** Setting up WWW Server ***********'
docker run -itd -p 80:80  -v "/srv:/usr/share/nginx/html:rw" --name lab_www_server janderton/labinabox:lab_www_server
docker exec -it  lab_www_server /bin/sh -c '/usr/share/nginx/html/index_setup.sh' #<----Run this from wwwroot dir in main OS

echo '********** Cloning API Repo *************'
git clone $API_REPO /srv/api_server

echo '********** Starting API Server ************'
docker run -itd -P -v "/srv/api_server:/app" --name api_server janderton/labinabox:api_server
