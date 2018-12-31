#!/bin/bash

###
### launchd & applescript to do things on every boot after user login
###


### variables
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

SERVICE_NAME=com.screen_resolution.set
SERVICE_INSTALL_PATH=/Users/$USER/Library/LaunchAgents
SCRIPT_NAME=screen_resolution
SCRIPT_INSTALL_PATH=/Users/$USER/Library/Scripts

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


### installing display manager
echo ''
echo "checking internet connection..."
ping -c5 google.com >/dev/null 2>&1
if [[ "$?" = 0 ]]
then

    echo ''
    echo "we are online, installing display manager..."

    # creating installation directory
    mkdir -p /Applications/display_manager
    chown $USER:admin /Applications/display_manager
    chmod 755 /Applications/display_manager

    # downloading display manager from git repository
    # display manager
    # https://github.com/univ-of-utah-marriott-library-apple/display_manager
    echo ''
    echo "downloading display manager..."
    git clone --depth 1 https://github.com/univ-of-utah-marriott-library-apple/display_manager.git /Applications/display_manager/
    
    # checking if python3 is installed
    echo ''
    if [[ $(python --version 2>&1 | awk '{print $NF}' | cut -d'.' -f1) != "3" ]] && [[ $(compgen -c python | grep "^python3$") == "" ]]
    then
        echo "python3 is not installed, using python2..."
        PYTHON_VERSION='python'
        PIP_VERSION='pip'
    else
        echo "python3 is installed, checking modules..."
        PYTHON_VERSION='python3'
        PIP_VERSION='pip3'
        for i in pyobjc-framework-Cocoa pyobjc-framework-Quartz
        do
            if [[ $("$PIP_VERSION" list | grep "$i") == "" ]]
            then
                "$PIP_VERSION" install "$i"
            else
                echo "python3 module "$i" already installed..."
            fi
        done
    fi
    
else

    echo ''
	echo "we are not not online, exiting..."
	exit
	
fi


### run script
echo ''
echo "running installed script..."

# be sure to have the correct path to the user logfiles specified for the logfile
# /var/log is only writable as root
#echo ''
bash -c "$SCRIPT_INSTALL_PATH"/"$SCRIPT_NAME".sh &
wait < <(jobs -p)


### launchd service
echo ""
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
#open /Users/"$USER"/Library/Logs/"$SCRIPT_NAME".log


#echo ''
echo 'done ;)'
echo ''
