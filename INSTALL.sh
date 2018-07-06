#!/bin/bash

sudo cp backupscript.sh /usr/local/bin/
sudo chmod a+rx /usr/local/bin/backupscript.sh

echo "use 'sudo crontab -e' to set a schedule (recommended 2am every day)

  e.g, '15 2 * * * bash backupscript.sh -r /root/compose/directory -s /source/dicrectory -d /destination/directory'""
