#!/bin/bash

sudo cp backupscript.sh /usr/local/bin/
sudo chmod a+rx /usr/local/bin/backupscript.sh
# Use sed to expand variable for home dir
sed "s|\$HOME|$HOME|" backup-docker-cronjob | sudo tee /etc/cron.d/backup-docker-cronjob
sudo chmod 644 /etc/cron.d/backup-docker-cronjob

echo "Installed, will run at above schedule edit /etc/cron.d/backup-docker-cronjob to change file locations"
