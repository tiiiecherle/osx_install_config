#!/bin/zsh

if [[ $(id -u) -ne 0 ]]
then 
    echo "script is not run as root, exiting..."
    exit
else
    :
fi

### variables
SERVICE_NAME=com.network.select
SCRIPT_INSTALL_NAME=network_select

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
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
NUM=0
MAX_NUM=15
SLEEP_TIME=3
# waiting for loggedInUser to be available
while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
do
    sleep "$SLEEP_TIME"
    NUM=$((NUM+1))
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
done
#echo ''
#echo "NUM is $NUM..."
#echo "loggedInUser is $loggedInUser..."
if [[ "$loggedInUser" == "" ]]
then
    WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
    echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
    exit
else
    :
fi


### logfile
EXECTIME=$(date '+%Y-%m-%d %T')
LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log

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

### functions
getting_network_device_ids() {
    # sourcing profile variables
    NETWORK_DEVICES_CONFIG_FILE=/Users/"$loggedInUser"/Library/Preferences/network_devices.conf
    if [[ -e "$NETWORK_DEVICES_CONFIG_FILE" ]]
    then
        . "$NETWORK_DEVICES_CONFIG_FILE"
    else
        echo "$NETWORK_DEVICES_CONFIG_FILE not found, exiting..."
        echo ''
        exit
    fi
    # wlan device id
    if [[ "$WLAN_DEVICE" != "" ]]
    then
        if [[ $(networksetup -listallhardwareports | grep "$WLAN_DEVICE$") != "" ]]
        then
            WLAN_DEVICE_ID=$(networksetup -listallhardwareports | awk -v x="$WLAN_DEVICE" '$0 ~ x{getline; print $2}')
            echo "wlan device $WLAN_DEVICE present as $WLAN_DEVICE_ID..."
        else
            echo "wlan device $WLAN_DEVICE not present..."
        fi
    else
        echo "no wlan device in devices profile..."
    fi
    # ethernet device id
    if [[ "$ETHERNET_DEVICE" != "" ]]
    then
        if [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") != "" ]]
        then
            ETHERNET_DEVICE_ID=$(networksetup -listallhardwareports | awk -v x="$ETHERNET_DEVICE" '$0 ~ x{getline; print $2}')
            echo "ethernet device $ETHERNET_DEVICE present as $ETHERNET_DEVICE_ID..."
        else
            echo "ethernet device $ETHERNET_DEVICE not present..."
        fi
    else
        echo "no ethernet device in devices profile..."
    fi
    echo ''
}

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

set_vbox_network_device() {
    if sudo -H -u "$loggedInUser" command -v VBoxManage &> /dev/null
    then
        # installed
        if [[ "$DEVICE_ID" =~ ^en[0-9]$ ]]
        then
            for VBOX in $(sudo -H -u "$loggedInUser" VBoxManage list vms | awk -F'"|"' '{print $2}')
            do
                echo "setting virtualbox network to "$DEVICE_ID" for vbox "$VBOX"..."
                sudo -H -u "$loggedInUser" VBoxManage modifyvm "$VBOX" --nic1 bridged --bridgeadapter1 "$DEVICE_ID"
            done
        else
            echo ""$DEVICE"_DEVICE_ID is empty or has a wrong format..."
        fi
    else
        # virtualbox is not installed
        echo "virtualbox is not installed..."
        :
    fi
}

setting_config() {
    ### sourcing .$SHELLrc or setting PATH
    # as the script is run from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # needed if binary is installed in a special directory
    if [[ -n "$BASH_SOURCE" ]] && [[ -e /Users/"$loggedInUser"/.bashrc ]] && [[ $(cat /Users/"$loggedInUser"/.bashrc | grep 'PATH=.*/usr/local/bin:') != "" ]]
    then
        echo "sourcing .bashrc..."
        . /Users/"$loggedInUser"/.bashrc
    elif [[ -n "$ZSH_VERSION" ]] && [[ -e /Users/"$loggedInUser"/.zshrc ]] && [[ $(cat /Users/"$loggedInUser"/.zshrc | grep 'PATH=.*/usr/local/bin:') != "" ]]
    then
        echo "sourcing .zshrc..."
        ZSH_DISABLE_COMPFIX="true"
        . /Users/"$loggedInUser"/.zshrc
    else
        echo "setting path for script..."
        export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    fi
}
# run before main function, e.g. for time format
setting_config &> /dev/null

check_if_ethernet_is_active() {
    echo ''
    echo "checking ethernet connection..."
    NUM1=0
    FIND_APP_PATH_TIMEOUT=4
    while [[ "$ETHERNET_CONNECTED" != "TRUE" ]]
    do
    	#printf "%.2f\n" "$NUM1"
    	NUM1=$(bc<<<$NUM1+1)
    	if (( $(echo "$NUM1 <= $FIND_APP_PATH_TIMEOUT" | bc -l) ))
    	then
    		# bash builtin printf can not print floating numbers
    		#perl -e 'printf "%.2f\n",'$NUM1''
    		#echo $NUM1 | awk '{printf "%.2f", $1; print $2}' | sed s/,/./g
    		sleep 1
            ETHERNET_CONNECTED=$(printf "get State:/Network/Interface/"$ETHERNET_DEVICE_ID"/Link\nd.show" | scutil | grep Active | awk '{print $NF}')
            #$(ifconfig en0 | grep status | cut -d ":" -f 2 | sed 's/ //g' | sed '/^$/d') == "active"
    	else
    		#printf '\n'
    		break
    	fi
    done
    if [[ "$ETHERNET_CONNECTED" != "TRUE" ]]
    then
        echo "ethernet is not active, activating wlan..."
        echo ''
    else
        echo "ethernet is active..."
    fi
    #echo ''
}

### network select
network_select() {
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    echo''
    
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config
    
    
    ### variables
	# names of devices and decvice ids
    # networksetup -listallhardwareports
    # available devices
    # networksetup -listallnetworkservices
    
    # system_profiler SPNetworkDataType only detects devices that are part of the active location
    # therefore switch to location automatic for detection
    
    # network devices and ids
    getting_network_device_ids
    
    # locations
    ETHERNET_LOCATION="office_lan"
    WLAN_LOCATION="wlan"
    
    ### script
    # changing to lan profile if lan is connected
    if [[ $(networksetup -listlocations | grep "$ETHERNET_LOCATION") != "" ]]
    then
        if [[ "$ETHERNET_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") != "" ]]
        then
            if [[ $(networksetup -getcurrentlocation | grep "$ETHERNET_LOCATION") != "" ]]
            then
                echo "location "$ETHERNET_LOCATION" already enabled..."
                disable_wlan_device
                DEVICE="ETHERNET"
                DEVICE_ID="$ETHERNET_DEVICE_ID"
                set_vbox_network_device
            else
                echo "changing to location "$ETHERNET_LOCATION"..." 
                sudo networksetup -switchtolocation "$ETHERNET_LOCATION"
                disable_wlan_device
                printf '\n\n'
                sleep 6
                DEVICE="ETHERNET"
                DEVICE_ID="$ETHERNET_DEVICE_ID"
                set_vbox_network_device
            fi
        else
            :
        fi
        check_if_ethernet_is_active
    else
        echo "ethernet location not found, skipping..."
    fi
    
    # changing to wlan profile if lan is not connected
    if [[ $(networksetup -listlocations | grep "$WLAN_LOCATION") != "" ]]
    then
        if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") == "" ]] || [[ "$ETHERNET_CONNECTED" != "TRUE" ]]
        then    
            if [[ $(networksetup -getcurrentlocation | grep "$WLAN_LOCATION") != "" ]]
            then
                echo "location "$WLAN_LOCATION" already enabled..."
                enable_wlan_device
                DEVICE="WLAN"
                DEVICE_ID="$WLAN_DEVICE_ID"
                set_vbox_network_device
            else
                echo "changing to location "$WLAN_LOCATION"..."
                sudo networksetup -switchtolocation "$WLAN_LOCATION"
                enable_wlan_device
                printf '\n\n'
                sleep 6
                DEVICE="WLAN"
                DEVICE_ID="$WLAN_DEVICE_ID"
                set_vbox_network_device
            fi
        else
            :
        fi
    else
        echo "wlan location not found, exiting..."
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
    
	echo ''
}

(time ( network_select )) 2>&1 | tee -a "$LOGFILE"
echo '' >> "$LOGFILE"
echo ''
