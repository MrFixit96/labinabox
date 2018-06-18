grep 'team2' /srv/labinabox/minio/docker-compose.yml
if [[ ! $? == 0 ]];then
for id in `seq 1 $NUM_TEAMS`;
do

message=`cat <<-EOF
    team$id:
        ports:
            - '900$id:9000'
        container_name: minio$id
        volumes:
          - '/srv:/data'
          - '/srv/minio/config$id:/root/.minio'
        image: minio/minio
        environment:
          MINIO_ACCESS_KEY: team$id
          MINIO_SECRET_KEY: 'bird-wheat-govern'
        command: server /data/team$id
EOF`


echo "$message" >> /srv/labinabox/minio/docker-compose.yml

done
fi

