#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
    echo script is not run as root, exiting...
    exit
else
    :
fi

# variables
SERVICE_NAME=com.network.select
SCRIPT_NAME=network_select

echo ''

# logfile
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
        #sudo chmod 666 "$LOGFILE"
    fi
else
    sudo touch "$LOGFILE"
    sudo chmod 644 "$LOGFILE"
    #sudo chmod 666 "$LOGFILE"
fi

sudo echo "" >> "$LOGFILE"
sudo echo $EXECTIME >> "$LOGFILE"

network_select() {
    
    ###
    ### configuring network
    ###
    
    ### getting logged in user
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
    echo "loggedInUser is $loggedInUser..."
    if [[ "$loggedInUser" == "" ]]
    then
        WAIT_TIME=$(($MAX_NUM*$SLEEP_TIME))
        echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
        exit
    else
        :
    fi
    
    # sourcing .bash_profile or setting PATH
    # as the script is run as root from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # virtualbox installed through homebrew-cask installs command line binary to /usr/local/bin/VBoxManage
    if [[ -e /Users/$loggedInUser/.bash_profile ]] && [[ $(cat /Users/$loggedInUser/.bash_profile | grep '/usr/local/bin:') != "" ]]
    then
        . /Users/$loggedInUser/.bash_profile
    else
        #export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
        PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
    fi
    
    # names of devices
    # networksetup -listallhardwareports
    ETHERNET_DEVICE="USB 10/100/1000 LAN"
    WLAN_DEVICE="Wi-Fi"
    ETHERNET_LOCATION="office_lan"
    WLAN_LOCATION="wlan"
    
    # checking if locations are valid
    if [[ $(networksetup -listlocations | grep "$ETHERNET_LOCATION") != "" ]] && [[ $(networksetup -listlocations | grep "$WLAN_LOCATION") != "" ]]
    then
        echo "all locations valid, continuing script..."
    else
        echo "at least one location is invalid, exiting..."
        exit
    fi
    
    # changing to lan profile if lan is connected
    if [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE") != "" ]]
    then
        if [[ $(networksetup -getcurrentlocation | grep "$ETHERNET_LOCATION") != "" ]]
        then
            echo "location "$ETHERNET_LOCATION" already enabled..."
        else
            echo "changing to location "$ETHERNET_LOCATION"..." 
            sudo networksetup -switchtolocation "$ETHERNET_LOCATION"
            printf '\n\n'
            sleep 10
            # special characters in the device name need to be escaped or worked around
            #ETHERNET_DEVICE_ESCAPED="$(echo $ETHERNET_DEVICE | sed 's/\//\\\//g')"
            #echo "$ETHERNET_DEVICE_ESCAPED"
            #ETHERNET_DEVICE_ID=$(networksetup -listallhardwareports | awk '/Hardware Port: '"$ETHERNET_DEVICE_ESCAPED"'/{getline; print $2}')
            ETHERNET_DEVICE_ID=$(networksetup -listallhardwareports | awk -v x="$ETHERNET_DEVICE" '$0 ~ x{getline; print $2}')
            #echo "$ETHERNET_DEVICE_ID"
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
    
    # changing to wlan profile if lan is not connected
    if [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE") == "" ]]
    then
        if [[ $(networksetup -getcurrentlocation | grep "$WLAN_LOCATION") != "" ]]
        then
            echo "location "$WLAN_LOCATION" already enabled..."
        else
            echo "changing to location "$WLAN_LOCATION"..." 
            sudo networksetup -switchtolocation "$WLAN_LOCATION"
            printf '\n\n'
            sleep 10
            #WLAN_DEVICE_ID=$(networksetup -listallhardwareports | awk '/Hardware Port: '"$WLAN_DEVICE"'/{getline; print $2}')
            WLAN_DEVICE_ID=$(networksetup -listallhardwareports | awk -v x="$WLAN_DEVICE" '$0 ~ x{getline; print $2}')
            #echo "$WLAN_DEVICE_ID"
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
    
    other_launchd_services=(
    com.hostsfile.install_update
    com.cert.install_update
    )
    
    launchd_services=(
    "${other_launchd_services[@]}"
    "$SERVICE_NAME"
    )
    
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
