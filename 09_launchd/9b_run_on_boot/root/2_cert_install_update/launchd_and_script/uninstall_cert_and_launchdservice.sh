#!/bin/bash

SERVICE_NAME=com.cert.install_update

# deleting update script
if [ -f /Library/Scripts/custom/cert_install_update.sh ];
then
    sudo rm /Library/Scripts/custom/cert_install_update.sh
else
    :
fi

# unloading launchd service
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]];
then
    sudo launchctl unload /Library/LaunchDaemons/"$SERVICE_NAME".plist
    sudo launchctl disable system/"$SERVICE_NAME"
    sudo launchctl remove "$SERVICE_NAME"
else
    :
fi

# deleting launchd service
if [ -f /Library/LaunchDaemons/"$SERVICE_NAME".plist ];
then
    sudo rm /Library/LaunchDaemons/"$SERVICE_NAME".plist
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

