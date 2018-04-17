#/bin/bash

echo '**********Removing User Accounts and Home Folders*********'
for id in `seq 1 10`;do 
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
rm -rf /srv/api_server
rm -rf /srv/nginx

#Removing Bind image makes it hard to bootstrap system when no
#no internet is present. Only do this when you need to update the image
#docker rm bind
rm -rf /srv/dns/bind/lib/web*
cp -rf /srv/labinabox/dns /srv/
docker start bind
