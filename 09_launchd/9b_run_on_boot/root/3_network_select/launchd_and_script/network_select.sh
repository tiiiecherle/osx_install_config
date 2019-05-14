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
SCRIPT_NAME=network_select

# other launchd services
other_launchd_services=(
com.hostsfile.install_update
com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)

echo ''


### waiting for logged in user
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
NUM=0
MAX_NUM=15
SLEEP_TIME=3
# waiting for loggedInUser to be available
while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
do
    sleep "$SLEEP_TIME"
    NUM=$(($NUM+1))
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
done
#echo ''
#echo "NUM is $NUM..."
#echo "loggedInUser is $loggedInUser..."
if [[ "$loggedInUser" == "" ]]
then
    WAIT_TIME=$(($MAX_NUM*$SLEEP_TIME))
    echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
    exit
else
    :
fi


### logfile
EXECTIME=$(date '+%Y-%m-%d %T')
LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log

if [[ -f "$LOGFILE" ]]
then
    # only macos takes care of creation time, linux doesn`t because it is not part of POSIX
    LOGFILEAGEINSECONDS="$(( $(date +"%s") - $(stat -f "%B" $LOGFILE) ))"
    MAXLOGFILEAGE=$(echo "30*24*60*60" | bc)
    #echo $LOGFILEAGEINSECONDS
    #echo $MAXLOGFILEAGE
    # deleting logfile after 30 days
    if [ "$LOGFILEAGEINSECONDS" -lt "$MAXLOGFILEAGE" ];
    then
        echo "logfile not older than 30 days..."
    else
        # deleting logfile
        echo "deleting logfile..."
        sudo rm "$LOGFILE"
        sudo touch "$LOGFILE"
        sudo chmod 644 "$LOGFILE"
    fi
else
    sudo touch "$LOGFILE"
    sudo chmod 644 "$LOGFILE"
fi

sudo echo "" >> "$LOGFILE"
sudo echo $EXECTIME >> "$LOGFILE"


### function
network_select() {
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .bash_profile or setting PATH
    # as the script is run as root from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # needed if binary is installed in a special directory
    if [[ -e /Users/$loggedInUser/.bash_profile ]] && [[ $(cat /Users/$loggedInUser/.bash_profile | grep '/usr/local/bin:') != "" ]]
    then
        . /Users/$loggedInUser/.bash_profile
    else
        #export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
        PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
    fi
    
    
    ### variables
	# names of devices and decvice ids
    # networksetup -listallhardwareports
    # available devices
    # networksetup -listallnetworkservices
    echo ''
    WLAN_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: AirPort" | head -n 1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/:$//g')
    #WLAN_DEVICE="Wi-Fi"
    if [[ "$WLAN_DEVICE" != "" ]]
    then
        echo "wlan device $WLAN_DEVICE found..."
        WLAN_DEVICE_ID=$(networksetup -listallhardwareports | awk -v x="$WLAN_DEVICE" '$0 ~ x{getline; print $2}')
    else
        echo "no wlan device found..."
    fi
    ETHERNET_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: Ethernet" | head -n 1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/:$//g')
    #ETHERNET_DEVICE="USB 10/100/1000 LAN"      # macbook pro 2018
    #ETHERNET_DEVICE="Ethernet"                 # imacs
    if [[ "$ETHERNET_DEVICE" != "" ]]
    then
        echo "ethernet device $ETHERNET_DEVICE found..."
        ETHERNET_DEVICE_ID=$(networksetup -listallhardwareports | awk -v x="$ETHERNET_DEVICE" '$0 ~ x{getline; print $2}')
    else
        echo "no ethernet device found..."
    fi
    echo ''
    # locations
    ETHERNET_LOCATION="office_lan"
    WLAN_LOCATION="wlan"
    
    
    ### functions
    enable_wlan_device() {
        # make sure wlan device is enabled when using wlan profile
        if [[ "$WLAN_DEVICE_ID" != "" ]]
        then
            sleep 1
            if [[ $(sudo networksetup -getairportpower "$WLAN_DEVICE_ID" | awk '{print $NF}') == "Off" ]]
            then
                sudo networksetup -setairportpower "$WLAN_DEVICE_ID" On
            else
                :
            fi
        else
            :
        fi
    }
    
    disable_wlan_device() {
        # make sure wlan device is enabled when using wlan profile
        if [[ "$WLAN_DEVICE_ID" != "" ]]
        then
            sleep 1
            if [[ $(sudo networksetup -getairportpower "$WLAN_DEVICE_ID" | awk '{print $NF}') == "On" ]]
            then
                sudo networksetup -setairportpower "$WLAN_DEVICE_ID" Off
            else
                :
            fi
        else
            :
        fi
    }
    
    
    ### script
    # changing to lan profile if lan is connected
    if [[ $(networksetup -listlocations | grep "$ETHERNET_LOCATION") != "" ]]
    then
        if [[ "$ETHERNET_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE") != "" ]]
        then
            if [[ $(networksetup -getcurrentlocation | grep "$ETHERNET_LOCATION") != "" ]]
            then
                echo "location "$ETHERNET_LOCATION" already enabled..."
                disable_wlan_device
            else
                echo "changing to location "$ETHERNET_LOCATION"..." 
                sudo networksetup -switchtolocation "$ETHERNET_LOCATION"
                disable_wlan_device
                printf '\n\n'
                sleep 10
                if [[ $(sudo -u $loggedInUser command -v VBoxManage) != "" ]]
                then
                    if [[ "$ETHERNET_DEVICE_ID" =~ ^en[0-9]$ ]]
                    then
                        for VBOX in $(sudo -u $loggedInUser VBoxManage list vms | awk -F'"|"' '{print $2}')
                        do
                            echo "changing virtualbox network to "$ETHERNET_DEVICE_ID" for vbox "$VBOX"..."
                            sudo -u $loggedInUser VBoxManage modifyvm "$VBOX" --nic1 bridged --bridgeadapter1 "$ETHERNET_DEVICE_ID"
                        done
                    else
                        echo "ETHERNET_DEVICE_ID is empty or has a wrong format..."
                    fi
                else
                    # virtualbox is not installed
                    echo "virtualbox is not installed..."
                    :
                fi
            fi
        else
            :
        fi
    else
        echo "ethernet location invalid, skipping..."
    fi
    
    # changing to wlan profile if lan is not connected
    if [[ $(networksetup -listlocations | grep "$WLAN_LOCATION") != "" ]]
    then
        if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE") == "" ]]
        then    
            if [[ $(networksetup -getcurrentlocation | grep "$WLAN_LOCATION") != "" ]]
            then
                echo "location "$WLAN_LOCATION" already enabled..."
                enable_wlan_device
            else
                echo "changing to location "$WLAN_LOCATION"..."
                sudo networksetup -switchtolocation "$WLAN_LOCATION"
                enable_wlan_device
                printf '\n\n'
                sleep 10
                if [[ $(sudo -u $loggedInUser command -v VBoxManage) != "" ]]
                then
                    if [[ "$WLAN_DEVICE_ID" =~ ^en[0-9]$ ]]
                    then
                        for VBOX in $(sudo -u $loggedInUser VBoxManage list vms | awk -F'"|"' '{print $2}')
                        do
                            echo "changing virtualbox network to "$WLAN_DEVICE_ID" for vbox "$VBOX"..."
                            sudo -u $loggedInUser VBoxManage modifyvm "$VBOX" --nic1 bridged --bridgeadapter1 "$WLAN_DEVICE_ID"
                        done
                    else
                        echo "WLAN_DEVICE_ID is empty or has a wrong format..."
                    fi
                else
                    # virtualbox is not installed
                    echo "virtualbox is not installed..."
                    :
                fi
            fi
        else
            :
        fi
    else
        echo "wlan location invalid, exiting..."
        echo ''
        exit
    fi
        
    # loading and disabling other launchd services
    for i in "${other_launchd_services[@]}"
    do
        echo ''
        echo "checking "$i"..."
        if [[ -e /Library/LaunchDaemons/"$i".plist ]]
        then
            #echo "$i is installed..."
            if [[ $(sudo launchctl list | grep "$i") != "" ]]
            then
                echo "$i is already loaded..."
                :
            else
                #echo "$i is not running..."
                echo "loading "$i"..."
                # starting service and ignoring the disabled status, will not be enabled after boot
                sudo launchctl load -F /Library/LaunchDaemons/"$i".plist
            fi
            #
            #sudo launchctl print-disabled system | grep "$i"
            #
            if [[ $(sudo launchctl print-disabled system | grep "$i" | grep false) != "" ]]
            then
                #echo "$i is enabled..."
                echo "disabling "$i"..."
                sudo launchctl disable system/"$i"
            else
               echo "$i is already disabled..."
               :
            fi
            #
        else
           echo "$i is not installed..."
        fi
    done
	
}

(time network_select) 2>&1 | tee -a "$LOGFILE"
echo '' >> "$LOGFILE"
