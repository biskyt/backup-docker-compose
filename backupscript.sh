#!/bin/bash

ROOT_DIR='.'
SRC_DIR=''
DEST_DIR=''
DEPTH=2
OUTPUTDIR='~'

setroot=0
setsrc=0
setdest=0
setdepth=0
setoutputdir=0

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
    -o|--outputdir) setoutputdir=1
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
            elif [ "$setoutputdir" == "1" ]; then
				OUTPUTDIR=$i
                setoutputdir=0
			else echo "Unknown command line: $i"
				exit 1
			fi
		fi
    ;;
esac
done

echo "Starting backup at $(date) from DIR $PWD...
ROOT_DIR=$ROOT_DIR
SRC_DIR=$SRC_DIR
DEST_DIR=$DEST_DIR
DEPTH=$DEPTH
OUTPUTDIR=$OUTPUTDIR" | tee ${OUTPUTDIR}/backupscript.log

# Verify we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "Failed to start backup at $(date). Must be run as root user..." | tee -a $OUTPUTDIR/backupscript_FAIL.log
   exit 1
fi


CUR_DIR=$PWD

# move to root dir
cd ${ROOT_DIR}

echo Moved to $PWD... | tee -a ${OUTPUTDIR}/backupscript.log

# Stop any autoheal monitor containers (as these can cause other containers to restart!
echo looking for autoheal containers | tee -a ${OUTPUTDIR}/backupscript.log
autoheal_id=$(sudo docker ps -aqf "name=autoheal")
if [ ! -z $autoheal_id ]; then
    echo "Found autoheal container id(s): $autoheal_id" | tee -a ${OUTPUTDIR}/backupscript.log
    echo "Stoppping autoheal containers..." | tee -a ${OUTPUTDIR}/backupscript.log
    sudo docker stop $autoheal_id | tee -a ${OUTPUTDIR}/backupscript.log
    echo "...Assuming this will be restarted by docker-compose later" | tee -a ${OUTPUTDIR}/backupscript.log
fi

# Cleanly stop all running containers using compose
echo "Running compose stop..." | tee -a ${OUTPUTDIR}/backupscript.log
find -maxdepth ${DEPTH} -name "docker-compose.yml" -exec docker-compose -f {} stop \; | tee -a ${OUTPUTDIR}/backupscript.log \;

# Stop docker to take down any other non-compose containers
echo "Stopping Docker Service..." | tee -a ${OUTPUTDIR}/backupscript.log
systemctl stop docker | tee -a ${OUTPUTDIR}/backupscript.log

## rsync command - add further switches for src and destination
if ! rsync -axHhv --inplace --delete ${SRC_DIR} ${DEST_DIR} | tee -a ${OUTPUTDIR}/backupscript.log ; then exit 1; fi

# restart docker (will also bring up any containers set to restart: always)
echo "Restarting Docker Service..." | tee -a ${OUTPUTDIR}/backupscript.log
systemctl start docker | tee -a ${OUTPUTDIR}/backupscript.log

# restart all stopped containers using compose
echo "Running compose up..." | tee -a ${OUTPUTDIR}/backupscript.log
find -maxdepth ${DEPTH} -name "docker-compose.yml" -exec docker-compose -f {} up -d \; | tee -a ${OUTPUTDIR}/backupscript.log \;

# move back to original dir
cd ${CUR_DIR}

echo ...Backup completed at $(date) | tee -a ${OUTPUTDIR}/backupscript.log

exit 0
