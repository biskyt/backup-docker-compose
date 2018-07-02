#!/bin/bash

# specify root for find as a command option
ROOT_DIR=%1


# Cleanly stop all running containers using compose
for f in `find ${ROOT_DIR} -name "docker-compose.yml"`
do
    sudo docker-compose -f $f stop
done

# Stop docker to take down any other non-compose containers
sudo systemctl docker stop

## rsync command - add further switches for src and destination
rsync -axHh --inplace --delete ${souce} ${destination}

# restart docker (will also bring up any containers set to restart: always)
sudo systemctl docker start

# restart all stopped containers using compose
for f in `find ${ROOT_DIR} -name "docker-compose.yml"`
do
    sudo docker-compose -f $f start
done

exit 0
