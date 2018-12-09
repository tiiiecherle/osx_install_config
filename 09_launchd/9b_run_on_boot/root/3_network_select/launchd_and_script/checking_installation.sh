#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
    echo script is not run as root, exiting...
    exit
else
    :
fi

SERVICE_NAME=com.network.select
SCRIPT_NAME=network_select
    
other_launchd_services=(
com.hostsfile.install_update
com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)

# checking status of services
for i in "${launchd_services[@]}"
do
    echo ''
    echo "checking "$i"..."
    if [[ -e /Library/LaunchDaemons/"$i".plist ]]
    then
        echo "$i is installed..."
        if [[ $(sudo launchctl list | grep "$i") != "" ]]
        then
            echo "$i is running..."
        else
            echo "$i is not running..."
        fi
        #
        #sudo launchctl print-disabled system | grep "$i"
        #
        if [[ $(sudo launchctl print-disabled system | grep "$i" | grep false) != "" ]]
        then
            #echo "$i is installed and enabled..."
            echo "$i is enabled..."
        else
           #echo "$i is installed but disabled..."
           echo "$i is disabled..."
        fi
        #
    else
       echo "$i is not installed..."
    fi
done


# logfiles
echo ''
echo "opening logfiles..."
logfiles_to_open=(
/var/log/hosts_file_update.log
/var/log/cert_update.log
/var/log/"$SCRIPT_NAME".log
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

echo ''
