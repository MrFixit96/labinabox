for id in `seq 1 10`;do 
  docker stop user$id
  docker rm user$id
  userdel -r user$id
  rm -rf /srv/user$id
done

docker stop lab_www_server
docker stop ftpserver
docker stop api_server
docker stop bind
docker rm ftpserver
docker rm api_server
docker rm lab_www_server
docker rm bind
