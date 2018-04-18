#!/bin/bash
IFS=$'\n'
export PWFILE='/ftpdepot/passwords'
export NUM_TEAMS=`wc -l $PWFILE|awk '{print $1}'`
for i in `seq 1 $NUM_TEAMS`;do
  logger "adding user team$i"
  adduser team$i -D -s /sbin/nologin -h /ftpdepot/team$i;
done && \
  sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf && \
  sed -i 's/ftpd_banner=Welcome to VSFTPD service./ftpd_banner=Welcome to WoW VSFTPD service./' /etc/vsftpd/vsftpd.conf && \
  sed -i 's/pasv_address=easypi.info/pasv_address='$EXTERNAL_IP'/' /etc/vsftpd/vsftpd.conf

readarray pwarray < $PWFILE
for item in ${pwarray[@]};do
       team=$(echo "$item"|awk '{print $1}')
       passwd=$(echo $item|awk '{print $NF}')
logger "Setting PW for $team"
       echo $team:$passwd|chpasswd
done

