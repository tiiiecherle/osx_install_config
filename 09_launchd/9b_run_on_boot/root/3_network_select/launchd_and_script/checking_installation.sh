#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
    echo "script is not run as root, exiting..."
    exit
else
    :
fi


### variables
SERVICE_NAME=com.network.select
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_NAME=network_select
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log

# UniqueID of loggedInUser
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#UNIQUE_USER_ID="$(dscl . -read /Users/$loggedInUser UniqueID | awk '{print $2;}')"
UNIQUE_USER_ID=$(id -u "$loggedInUser")

# logfiles
logfiles_to_open=(
"$LOGDIR"/hosts_file_generator.log
"$LOGDIR"/cert_install_update.log
"$LOGFILE"
)

# other launchd services
other_launchd_services=(
com.hostsfile.install_update
com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)


### checking status of services
for i in "${launchd_services[@]}"
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
