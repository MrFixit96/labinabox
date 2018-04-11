#!/bin/sh
for i in `seq 1 10`;do
  adduser team$i -D -s /sbin/nologin -h /ftpdepot/team$i;
  echo team$i:password|chpasswd
done && \
  sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf && \
  sed -i 's/ftpd_banner=Welcome to VSFTPD service./ftpd_banner=Welcome to WoW VSFTPD service./' /etc/vsftpd/vsftpd.conf && \
  sed -i 's/pasv_address=easypi.info/pasv_address='10.0.241.11'/' /etc/vsftpd/vsftpd.conf
