#!/bin/bash
#taking input from user, checking each team to see if we can curl their website and display an affirmative result
NUM_TEAMS=$1

for id in `seq 1 $NUM_TEAMS`;do
	if [[ $id -lt 10 ]];then
	  num=0$id
	else
	  num=$id
	fi
       	echo "********* testing team$id **********"
	export passwd=`awk -v pat="team$id" '$1 == pat {print $NF}' passwords`
	curl --user team$id:$passwd http://team$id.webdesigncontest.org && echo "***************** Found team$id ******************"
	curl --ciphers 'AWS4-HMAC-SHA256' --user team$id:$passwd http://team$id.webdesigncontest.org:90$num && echo "************** Found Minio$id ****************"
	unset passwd
done
