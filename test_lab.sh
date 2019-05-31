#!/bin/bash
#taking input from user, checking each team to see if we can curl their website and display an affirmative result
NUM_TEAMS=$1
IFACE=$2
CONTESTANT_FILE="Materials_for_Contestants.zip"

for id in `seq 1 $NUM_TEAMS`;do
	if [[ $id -lt 10 ]];then
	  num=0$id
	else
	  num=$id
	fi
       	echo "********* testing team$id **********"
	export passwd=`awk -v pat="team$id" '$1 == pat {print $NF}' passwords`
	curl --user team$id:$passwd http://team$id.webdesigncontest.org && echo "***************** Found team$id ******************"
	curl --user team$id:$passwd http://team$id.webdesigncontest.org/Materials_for_Contestants.zip && echo " ************ Found $CONTESTANT_FILE ************"
	curl --ciphers 'AWS4-HMAC-SHA256' --user team$id:$passwd http://team$id.webdesigncontest.org:90$num && echo "************** Found Minio$id ****************"
	unset passwd
  curl http://api.webdesigncontest.org || curl http://api.webdesigncontest.org:60606
done
if [[ $IFACE == "wired" ]];then
	curl -s http://api.webdesigncontest.org/events
else
	curl -s http://api.webdesigncontest.org:60606/events
fi
