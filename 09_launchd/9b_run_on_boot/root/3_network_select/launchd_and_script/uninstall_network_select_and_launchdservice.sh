#!/bin/bash

# variables
SERVICE_NAME=com.network.select
SCRIPT_NAME=network_select

UNINSTALL_SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

other_launchd_services=(
com.hostsfile.install_update
com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)

# deleting update script
if [ -f /Library/Scripts/custom/"$SCRIPT_NAME".sh ];
then
    sudo rm /Library/Scripts/custom/"$SCRIPT_NAME".sh
else
    :
fi

# unloading and disabling (-w) launchd service
# unloading launchd service
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]];
then
    sudo launchctl unload /Library/LaunchDaemons/"$SERVICE_NAME".plist
    sudo launchctl disable system/"$SERVICE_NAME"
    sudo launchctl remove "$SERVICE_NAME"
else
    :
fi

# enabling launchd service
# checking if installed and disabled, if yes, enable
for i in "${other_launchd_services[@]}"
do
    if [[ $(sudo launchctl print-disabled system | grep "$i" | grep true) != "" ]];
    then
        #echo "enabling "$i"..."
        sudo launchctl enable system/"$i"
    else
        :
    fi
done

# deleting launchd service
if [ -f /Library/LaunchDaemons/"$SERVICE_NAME".plist ];
then
    sudo rm /Library/LaunchDaemons/"$SERVICE_NAME".plist
else
    :
fi

# deleting logfile
if [ -f /var/log/"$SERVICE_NAME".log ];
then
    sudo rm /var/log/"$SERVICE_NAME".log
else
    :
fi

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

