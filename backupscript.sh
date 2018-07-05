#!/bin/bash

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

# move to root dir
cd ${ROOT_DIR}

# Cleanly stop all running containers using compose
find -maxdepth ${DEPTH} -name "docker-compose.yml" -exec docker-compose -f {} stop \;

# Stop docker to take down any other non-compose containers
sudo systemctl docker stop

## rsync command - add further switches for src and destination
if ! echo "rsync -axHh --inplace --delete ${SRC_DIR} ${DEST_DIR} > ~/backupscript.log" ; then exit 1; fi

# restart docker (will also bring up any containers set to restart: always)
sudo systemctl docker start

# restart all stopped containers using compose
find -maxdepth ${DEPTH} -name "docker-compose.yml" -exec echo docker-compose -f {} start \;

# move back to original dir
cd ${CUR_DIR}

exit 0
