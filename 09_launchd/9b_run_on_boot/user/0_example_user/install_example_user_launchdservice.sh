#!/bin/bash

###
### launchd & applescript to do things on every boot as user after user login
###


### variables
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

SERVICE_NAME=com.example_user.show
SERVICE_INSTALL_PATH=/Users/$USER/Library/LaunchAgents
SCRIPT_NAME=example_user
SCRIPT_INSTALL_PATH=/Users/$USER/Library/Scripts

LOGDIR=/Users/"$USER"/Library/Logs
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log

# UniqueID of loggedInUser
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#UNIQUE_USER_ID="$(dscl . -read /Users/$loggedInUser UniqueID | awk '{print $2;}')"
UNIQUE_USER_ID=$(id -u "$loggedInUser")


### uninstalling possible old files
echo ''
echo "uninstalling possible old files..."
. "$SCRIPT_DIR"/launchd_and_script/uninstall_"$SCRIPT_NAME"_and_launchdservice.sh
wait


### script file
echo "installing script..."
cp "$SCRIPT_DIR"/launchd_and_script/"$SCRIPT_NAME".sh "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh
chown -R "$USER":staff "$SCRIPT_INSTALL_PATH"/
chmod -R 750 "$SCRIPT_INSTALL_PATH"/


### launchd service file
echo "installing launchd service..."
cp "$SCRIPT_DIR"/launchd_and_script/"$SERVICE_NAME".plist "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
chown "$USER":staff "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
chmod 640 "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist


### run script
echo ''
echo "running installed script..."

# be sure to have the correct path to the user logfiles specified for the logfile
# /var/log is only writable as root
#echo ''
bash -c "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh &
wait < <(jobs -p)


### launchd service
echo ''
if [[ $(launchctl list | grep "$SERVICE_NAME") != "" ]];
then
    launchctl unload "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
    launchctl disable user/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
else
    :
fi
launchctl enable user/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
launchctl load "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist

echo "waiting 5s for launchdservice to load before checking installation..."
sleep 5


### checking installation
echo ''
echo "checking installation..."
"$SCRIPT_DIR"/launchd_and_script/checking_installation.sh
wait

#echo ''
#echo "opening logfile..."
#open "$LOGFILE"


#echo ''
echo 'done ;)'
echo ''
