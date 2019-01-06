#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
    echo "script is not run as root, exiting..."
    exit
else
    :
fi


### variables
SERVICE_NAME=com.hostsfile.install_update
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_NAME=hosts_file_generator
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log

# UniqueID of loggedInUser
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#UNIQUE_USER_ID="$(dscl . -read /Users/$loggedInUser UniqueID | awk '{print $2;}')"
UNIQUE_USER_ID=$(id -u "$loggedInUser")


### checking status of services
for i in "$SERVICE_NAME"
do
    #echo ''
    echo "checking "$i"..."
    if [[ -e "$SERVICE_INSTALL_PATH"/"$i".plist ]]
    then
        echo "$i is installed..."
    
        # checking if running
        if [[ $(sudo launchctl list | grep "$i") != "" ]]
        then
            echo "$i is running..."
        else
            echo "$i is not running..."
        fi
        
        # checking if enabled
        #launchctl print-disabled user/"$UNIQUE_USER_ID" | grep "$i"
        #
        if [[ $(sudo launchctl print-disabled system | grep "$i" | grep false) != "" ]]
        then
            #echo "$i is installed and enabled..."
            echo "$i is enabled..."
        else
           #echo "$i is installed but disabled..."
           echo "$i is disabled..."
        fi
        
        # logfiles
        echo ''
        echo "opening logfiles..."
        logfiles_to_open=(
        "$LOGFILE"
        )
        
        for i in "${logfiles_to_open[@]}"
        do
            if [[ -e "$i" ]]
            then
                open "$i"
            else
                echo "$i does not exist..."
            fi
        done
        #
    else
       echo "$i is not installed..."
    fi
done

echo ''
