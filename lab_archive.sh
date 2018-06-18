#!/bin/bash
####################################################################################################
#
#	Name: lab_archive.sh
#	Author: James Anderton <james@janderton.org>
#	Date: 6/12/2018
#	Purpose: This script archives the team directories created by labinabox/lab_setup.sh 
#
####################################################################################################
echo '********************* mounting USB Drive ***********************'
mount /dev/sda1 /mnt/usb

echo '********************* creating archive of /srv/team* directories ********************'
tar -czvf webdesigncontest_team_archive_$(date +%m%d%Y).tar.gz /srv/team* && \
	mv webdesigncontest_team_archive_$(date +%m%d%Y).tar.gz /mnt/usb/
ls -aslh /mnt/usb
cd -
