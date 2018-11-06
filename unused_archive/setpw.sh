#!/bin/bash
IFS=$'\n'
readarray pwarray < passwords
for item in ${pwarray[@]};do
       team=$(echo "$item"|awk '{print $1}')
       passwd=$(echo $item|awk '{print $NF}')
       echo $team:$passwd|chpasswd
done
