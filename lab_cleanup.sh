#/bin/bash

echo '**********Removing User Accounts and Home Folders*********'
for id in `seq 1 10`;do 
  docker stop user$id
  docker rm user$id
  userdel -r user$id
  rm -rf /srv/user$id
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
rm -rf /srv/api_server_v2

#Removing Bind image makes it hard to bootstrap system when no
#no internet is present. Only do this when you need to update the image
#docker rm bind
