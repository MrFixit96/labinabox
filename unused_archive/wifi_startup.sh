#!/bin/bash
#
echo 'This script is to setup the server when using wireless instead of wired connection...Make sure to edit the $WIFI_IP below'
#
export WIFI_IP'=10.0.0.12'
./lab_cleanup.sh
./lab_setup.sh
cp webdesigncontest.org.hosts /srv/dns/bind/lib/webdesigncontest.org.hosts
docker stop bind
sleep 5
docker start bind
echo "nameserver $WIFI_IP">/etc/resolv.conf
dig team1.webdesigncontest.org

curl team1.webdesigncontest.org
