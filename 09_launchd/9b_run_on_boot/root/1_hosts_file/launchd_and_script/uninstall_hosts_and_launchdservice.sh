#!/bin/bash

SERVICE_NAME=com.hostsfile.install_update

# moving back original hosts file
if [ -f /etc/hosts.orig ];
then
    sudo cp -a /etc/hosts.orig /etc/hosts
else
    :
fi

# uninstalling hosts file generator
if [ -d /Applications/hosts_file_generator ];
then
    sudo rm -rf /Applications/hosts_file_generator
else
    :
fi

# deleting update script
if [ -f /Library/Scripts/custom/hosts_file_generator.sh ];
then
    sudo rm /Library/Scripts/custom/hosts_file_generator.sh
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
if [ -f /Library/LaunchDaemons/com.hostsfile.install_update.plist ];
then
    sudo rm /Library/LaunchDaemons/com.hostsfile.install_update.plist
else
    :
fi

# deleting logfile
if [ -f /var/log/hosts_file_update.log ];
then
    sudo rm /var/log/hosts_file_update.log
else
    :
fi

# activating changed hosts file
echo "activating changed hosts file..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

