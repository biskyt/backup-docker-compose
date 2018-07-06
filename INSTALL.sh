#!/bin/bash

sudo cp backupscript.sh /usr/local/bin/
sudo chmod a+rx /usr/local/bin/backupscript.sh
sudo cp backup-docker-cronjob /etc/cron.d/
sudo chmod 644 /etc/cron.d/backup-docker-cronjob

echo "Installed, will run at reboot - edit /etc/cron.d/backup-docker-cronjob to change file locations"
