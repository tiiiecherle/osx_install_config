#!/bin/bash

### variables
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

# logfiles
logfiles_to_open=(
"$LOGFILE"
)


### checking status of services
for i in "$SERVICE_NAME"
do
    #echo ''
    echo "checking "$i"..."
    if [[ -e "$SERVICE_INSTALL_PATH"/"$i".plist ]]
    then
        echo "$i is installed..."
    
        # checking if running
        if [[ $(launchctl list | grep "$i") != "" ]]
        then
            echo "$i is running..."
        else
            echo "$i is not running..."
        fi
        
        # checking if enabled
        #launchctl print-disabled user/"$UNIQUE_USER_ID" | grep "$i"
        #
        if [[ $(launchctl print-disabled user/"$UNIQUE_USER_ID" | grep "$i" | grep false) != "" ]]
        then
            #echo "$i is installed and enabled..."
            echo "$i is enabled..."
        else
           #echo "$i is installed but disabled..."
           echo "$i is disabled..."
        fi

    else
       echo "$i is not installed..."
    fi

    echo ''
            
done


### logfiles
#echo ''
echo "opening logfiles..."
for i in "${logfiles_to_open[@]}"
do
    if [[ -e "$i" ]]
    then
        open "$i"
    else
        echo "$i does not exist..."
    fi
done

echo ''
