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
export DOCKER_HOST=tcp://0.0.0.0:2375

echo '**********Removing User Accounts and Home Folders*********'
for id in `seq 1 $NUM_TEAMS`;do 
  docker stop team$id
  docker rm team$id
  userdel -r team$id
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
docker-compose -f minio/docker-compose.yml down

echo '*********Clearing container configs***********'
rm -rf /srv/api_server
rm -rf /srv/nginx

#Removing Bind image makes it hard to bootstrap system when no
#no internet is present. Only do this when you need to update the image
#docker rm bind
rm -rf /srv/dns/bind/lib/web*
cp -rf /srv/labinabox/dns /srv/
echo '********restarting DNS ************'
docker start bind
