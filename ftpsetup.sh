#!/bin/sh
for i in `seq 1 10`;do
  adduser user$i -D -s /sbin/nologin -h /ftpdepot/user$i;
  echo user$i:password|chpasswd
done && \
  sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf && \
  sed -i 's/ftpd_banner=Welcome to VSFTPD service./ftpd_banner=Welcome to WoW VSFTPD service./' /etc/vsftpd/vsftpd.conf && \
  sed -i 's/pasv_address=easypi.info/pasv_address='$(hostname)'/' /etc/vsftpd/vsftpd.conf
