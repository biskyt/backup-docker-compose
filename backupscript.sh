#!/bin/bash

ROOT_DIR='.'
SRC_DIR=''
DEST_DIR=''
DEPTH=2

setroot=0
setsrc=0
setdest=0
setdepth=0

for i in "$@"; do
  case $i in
  --help)
    echo "USAGE: backupscript -r <ROOT_DIR> -s <SRC_DIR> -d <DEST_DIR> [-x <DEPTH>]
      Where:
        ROOT_DIR = the start folder in which to scan for docker-compose.yml files
        SRC_DIR = The source location to copy FROM
        DEST_DIR = The destination to copy TO
        DEPTH = How many levels down from the ROOT_DIR to scan for docker-compose files"
    ;;
  -r | --root)
    setroot=1
    ;;
  -s | -src)
    setsrc=1
    ;;
  -d | -dest)
    setdest=1
    ;;
  -x | -depth)
    setdepth=1
    ;;
  *)
    if [ -n "$i" ]; then
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
      else
        echo "Unknown command line: $i"
        exit 1
      fi
    fi
    ;;
  esac
done

function start-compose-cmd() {
  echo "Starting $1"
  composecmd=$(which docker-compose)
  composecmd="${composecmd:-/usr/local/bin/docker-compose}" # deal with which not returning a value
  currentdir=$(pwd)
  workingdir=$(dirname "$1")
  cd "$workingdir" || return
  $composecmd up -d
  cd "$currentdir" || exit 1
}

export -f start-compose-cmd

function stop-compose-cmd() {
  echo "Stopping $1"
  composecmd=$(which docker-compose)
  composecmd="${composecmd:-/usr/local/bin/docker-compose}" # deal with which not returning a value
  currentdir=$(pwd)
  workingdir=$(dirname "$1")
  cd "$workingdir" || return
  $composecmd stop
  cd "$currentdir" || exit 1
}

export -f stop-compose-cmd

echo "Starting backup at $(date) from DIR $PWD...
ROOT_DIR=$ROOT_DIR
SRC_DIR=$SRC_DIR
DEST_DIR=$DEST_DIR
DEPTH=$DEPTH"

# Verify we are running as root
if [[ $EUID -ne 0 ]]; then
  echo "Failed to start backup at $(date). Must be run as root user..."
  exit 1
fi

# Stop any autoheal monitor containers (as these can cause other containers to restart!
echo looking for autoheal containers
autoheal_id=$(sudo docker ps -aqf "name=autoheal")
if [ -n "$autoheal_id" ]; then
  echo "Found autoheal container id(s): $autoheal_id"
  echo "Stoppping autoheal containers..."
  sudo docker stop "$autoheal_id"
  echo "...Assuming this will be restarted by docker-compose later"
fi

# Cleanly stop all running containers using compose
echo "Running compose stop..."
find "${ROOT_DIR}" -maxdepth "${DEPTH}" -name "docker-compose.yml" -exec echo Stop {} ... \; -exec bash -c 'stop-compose-cmd "$0"' {} \;

# Stop docker to take down any other non-compose containers
# echo "Stopping Docker Service..."
# systemctl stop docker

## rsync command - add further switches for src and destination
echo "Starting rsync..."
if ! rsync -axHhv --exclude 'swapfile' --exclude '*.swp' --exclude '*.tmp' --exclude ';' --exclude 'docker/data/' --inplace --delete "${SRC_DIR}" "${DEST_DIR}";then 
	echo "
*******************************************
*******************************************
************ RSYNC FAILED *****************
*******************************************
*******************************************
"
fi

# restart docker (will also bring up any containers set to restart: always)
# echo "Restarting Docker Service..."
# systemctl start docker

#sudo reboot

# restart all stopped containers using compose
echo "Running compose up..."
find "${ROOT_DIR}" -maxdepth "${DEPTH}" -name "docker-compose.yml" -exec echo up {} ... \; -exec bash -c 'start-compose-cmd "$0"' {} \;

echo ...Backup completed at "$(date)"

exit 0
