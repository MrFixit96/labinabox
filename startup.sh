#!/bin/bash
./lab_cleanup.sh
./lab_setup.sh
cp webdesigncontest.org.hosts /srv/dns/bind/lib/webdesigncontest.org.hosts
docker stop bind
sleep 5
docker start bind
curl team1.webdesigncontest.org

