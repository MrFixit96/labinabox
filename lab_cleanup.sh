#/bin/bash
####################################################################################################################################
#
#	NAME: lab_cleanup.sh
#	Author: James Anderton @MrFixit96 (james@janderton.com)
#	Date: 4/17/2018
#	Purpose: This script reset's the lab in a box environment to a near pristine state saving for maybe a couple dns artifacts
#
###################################################################################################################################
export PWFILE=/srv/labinabox/passwords
export NUM_TEAMS=`wc -l $PWFILE |awk '{print$1}'`
#export DOCKER_HOST=tcp://0.0.0.0:2375

echo '**********Removing User Accounts and Home Folders*********'

for id in `seq 1 $NUM_TEAMS`;do 
  docker stop -t 1 team$id
  docker rm team$id
  userdel -r team$id
  docker stop -t 1 theia_$id
  docker rm theia_$id
  #TODO backup team stuff
  rm -rf /srv/backup/team$id/
  mv /srv/team$id /srv/backup/team$id
  rm -rf /srv/team$id
done

echo '**********Stopping Lab Services*********'
docker stop lab_www_server
docker stop ftpserver
docker stop api_server_v2
docker stop bind


echo '**********Removing Containers*********'
docker rm ftpserver
docker rm lab_www_server
docker rm api_server_v2

echo '********stopping minio service********'
#docker stack rm minio
#docker-compose -f /srv/labinabox/minio/docker-compose.yml down
for id in `seq 1 $NUM_TEAMS`;do 
  echo "********Stopping minio$id************"
  docker stop minio$id
  docker rm minio$id
done
echo > /srv/labinabox/minio/docker-compose.yml
tee /srv/labinabox/minio/docker-compose.yml <<EOF
version: "3"
services:
EOF
echo '*********Clearing container configs***********'
rm -rf /srv/api_server
rm -rf /srv/nginx
rm -rf /srv/html
rm -rf /srv/ftpsetup2.sh

#Removing Bind image makes it hard to bootstrap system when no
#no internet is present. Only do this when you need to update the image
#docker rm bind
rm -rf /srv/dns/bind/lib/web*
cp -rf /srv/labinabox/dns /srv/
echo '********restarting DNS ************'
docker start bind
