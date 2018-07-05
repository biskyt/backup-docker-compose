#!/bin/bash

# Verify we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# specify root for find as a command option
ROOT_DIR='.'
SRC_DIR=''
DEST_DIR=''
DEPTH=2

setroot=0
setsrc=0
setdest=0
setdepth=0

for i in "$@"
do
case $i in
	--help) echo "USAGE: backupscript -r <ROOT_DIR> -s <SRC_DIR> -d <DEST_DIR> [-x <DEPTH>]
      Where:
        ROOT_DIR = the start folder in which to scan for docker-compose.yml files
        SRC_DIR = The source location to copy FROM
        DEST_DIR = The destination to copy TO
        DEPTH = How many levels down from the ROOT_DIR to scan for docker-compose files"
		;;
    -r|--root) setroot=1
        ;;
    -s|-src) setsrc=1
        ;;
    -d|-dest) setdest=1
        ;;
    -x|-depth) setdepth=1
        ;;
	*)  if [ ! -z "$i" ]; then
			if [ "$setroot" = "1" ]; then
				ROOT_DIR=$i
				setroot=0
			elif [ "$setsrc" = "1" ]; then
                SRC_DIR=$i
                setsrc=0
			elif [ "$setdest" == "1" ]; then
				DEST_DIR=$i
                setdest=0
            elif [ "$setdepth" == "1" ]; then
				DEPTH=$i
                setdest=0
			else echo "Unknown command line: $i"
				exit 1
			fi
		fi
    ;;
esac
done


CUR_DIR=$PWD

echo Starting backup at $(date)... > ~/backupscript.log

# move to root dir
cd ${ROOT_DIR}

echo Moved to $PWD... >> ~/backupscript.log

# Stop any autoheal monitor containers (as these can cause other containers to restart!
echo looking for autoheal containers >> ~/backupscript.log
autoheal_id=$(sudo docker ps -aqf "name=autoheal")
if [ ! -z $autoheal_id ]; then 
    echo "Found autoheal container id(s): $autoheal_id" >> ~/backupscript.log
    echo "Stoppping autoheal containers..." >> ~/backupscript.log
    sudo docker stop $autoheal_id &>> ~/backupscript.log
    echo "...Assuming this will be restarted by docker-compose later" >> ~/backupscript.log
fi

# Cleanly stop all running containers using compose
find -maxdepth ${DEPTH} -name "docker-compose.yml" -exec docker-compose -f {} stop &>> ~/backupscript.log \;

# Stop docker to take down any other non-compose containers
systemctl stop docker &>> ~/backupscript.log

## rsync command - add further switches for src and destination
if ! rsync -axHhv --inplace --delete ${SRC_DIR} ${DEST_DIR} >> ~/backupscript.log ; then exit 1; fi

# restart docker (will also bring up any containers set to restart: always)
systemctl start docker &>> ~/backupscript.log

# restart all stopped containers using compose
find -maxdepth ${DEPTH} -name "docker-compose.yml" -exec docker-compose -f {} start &>> ~/backupscript.log \;

# move back to original dir
cd ${CUR_DIR}

echo ...Backup completed at $(date)

exit 0
