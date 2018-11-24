#!/bin/bash

# deleting update script
if [ -f /Library/Scripts/custom/cert_install_update.sh ];
then
    sudo rm /Library/Scripts/custom/cert_install_update.sh
else
    :
fi

# unloading launchd service
if [[ $(sudo launchctl list | grep cert.install_update) != "" ]];
then
    sudo launchctl unload /Library/LaunchDaemons/com.cert.install_update.plist
else
    :
fi

# deleting launchd service
if [ -f /Library/LaunchDaemons/com.cert.install_update.plist ];
then
    sudo rm /Library/LaunchDaemons/com.cert.install_update.plist
else
    :
fi

# deleting logfile
if [ -f /var/log/cert_update.log ];
then
    sudo rm /var/log/cert_update.log
else
    :
fi

echo "uninstalling done..."

