#!/bin/bash

### variables
UNINSTALL_SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

SERVICE_NAME=com.screen_resolution.set
SERVICE_INSTALL_PATH=/Users/$USER/Library/LaunchAgents
SCRIPT_NAME=screen_resolution
SCRIPT_INSTALL_PATH=/Users/$USER/Library/Scripts

# UniqueID of loggedInUser
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#UNIQUE_USER_ID="$(dscl . -read /Users/$loggedInUser UniqueID | awk '{print $2;}')"
UNIQUE_USER_ID=$(id -u "$loggedInUser")

LOGDIR=/Users/"$loggedInUser"/Library/Logs
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log


### deleting display manager
if [[ -e /Applications/display_manager ]]
then
    rm -rf /Applications/display_manager
else
    :
fi


### deleting script
if [[ -f "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh ]]
then
    rm -f "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh
else
    :
fi


### unloading and disabling (-w) launchd service
if [[ $(launchctl list | grep "$SERVICE_NAME") != "" ]]
then
    launchctl unload "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
    launchctl disable user/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
    launchctl remove "$SERVICE_NAME"
else
    :
fi


### enabling launchd service
# checking if installed and disabled, if yes, enable
for i in "$SERVICE_NAME"
do
    if [[ $(launchctl print-disabled user/"$UNIQUE_USER_ID" | grep "$i" | grep true) != "" ]]
    then
        #echo "enabling "$i"..."
        launchctl disable user/"$UNIQUE_USER_ID"/"$i"
    else
        :
    fi
done


### deleting launchd service
if [[ -f "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist ]]
then
    rm -f "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
else
    :
fi


### deleting logfile
if [[ -f "$LOGFILE" ]]
then
    rm -f "$LOGFILE"
else
    :
fi


### checking installation
if [[ $(ps aux | grep /install_"$SCRIPT_NAME"_and_launchdservice.sh | grep -v grep) == "" ]]
then
    echo ''
    echo "checking installation..."
    "$UNINSTALL_SCRIPT_DIR"/checking_installation.sh
    wait
else
    :
fi


#echo ''
echo "uninstalling done..."
echo ''

