# Lab In A Box
This project started out as a way to host the contestant environment for the web design contest hosted by WebProfessionals.org and will start up a shell container for each team as well as an nginx and vsftp container all pointing to the user's home directory and htpasswd protected on the web frontend. Finally, there is a NodeJS container hosting an API server as well for the contestants to consume. The docker file for the api server is hosted in the forked repo web-design-contest-api.

##### ToDo: Move configs into containers themselves and convert to docker-compose format

#### File: lab_setup.sh
```
Author: James Anderton @MrFixit96 (james@janderton.com)
Date: 4/17/2018
Purpose: This script will download and setup a "lab in a box" environment complete with one persistent shell per user, an FTP server, an Nginx WWW Server and a NodeJS API server.
```
#### File: lab_cleanup.sh
```
Author: James Anderton @MrFixit96 (james@janderton.com)
Date: 4/17/2018
Purpose: This script will stop all services and clean up the artifacts created by the "lab_setup.sh" script and restart the bind container so that the lab server is ready for another contest.
```
#### File: lab_archive.sh
```
Author: James Anderton @MrFixit96 (james@janderton.com)
Date: 6/20/2018
Purpose: This script will mount a usb drive, create a tar.gz that includes all of the team directories in the "lab in a box" environment and copies it to the usb drive, then unmounts the drive.
```
#### File: test_lab.sh
```
Author: James Anderton @MrFixit96 (james@janderton.com)
Date: 6/20/2018
Purpose: This script is an automated way to test each team's WWW Server and Minio Cloud Storage, and the shared API server.
```
