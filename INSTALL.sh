#!/bin/bash

sudo cp backupscript.sh /usr/local/bin/
sudo chmod a+rx /usr/local/bin/backupscript.sh
sudo cp backup-docker-cronjob /etc/cron.d/
sudo chmod a+rx /etc/cron.d/backup-docker-cronjob

echo "Installed, will run at reboot - edit /etc/crontab.d/backup-docker-cronjob to change file locations"
