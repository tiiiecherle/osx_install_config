#!/bin/bash

### variables
UNINSTALL_SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

SERVICE_NAME=com.hostsfile.install_update
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_NAME=hosts_file_generator
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

# UniqueID of loggedInUser
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#UNIQUE_USER_ID="$(dscl . -read /Users/$loggedInUser UniqueID | awk '{print $2;}')"
UNIQUE_USER_ID=$(id -u "$loggedInUser")

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log


### deleting script
if [[ -f "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh ]]
then
    sudo rm -f "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh
else
    :
fi


### unloading and disabling (-w) launchd service
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]]
then
    sudo launchctl unload "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
    sudo launchctl disable system/"$SERVICE_NAME"
    sudo launchctl remove "$SERVICE_NAME"
else
    :
fi


### deleting launchd service
if [[ -f "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist ]]
then
    sudo rm -f "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
else
    :
fi


### deleting logfile
if [[ -f "$LOGFILE" ]]
then
    sudo rm -f "$LOGFILE"
else
    :
fi


### uninstalling hosts file generator
if [[ -d /Applications/hosts_file_generator ]]
then
    sudo rm -rf /Applications/hosts_file_generator
else
    :
fi


### moving back original hosts file
if [[ -f /etc/hosts.orig ]]
then
    sudo cp -a /etc/hosts.orig /etc/hosts
else
    :
fi


### activating changed hosts file
echo ''
echo "activating changed hosts file..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder


### checking installation
if [[ $(ps aux | grep /install_"$SCRIPT_NAME"_and_launchdservice.sh | grep -v grep) == "" ]]
then
    echo ''
    echo "checking installation..."
    sudo "$UNINSTALL_SCRIPT_DIR"/checking_installation.sh
    wait
else
    :
fi



#echo ''
echo "uninstalling done..."
echo ''

