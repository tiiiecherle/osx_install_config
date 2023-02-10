#!/bin/zsh

### config file
# this script will not source the config file as it runs as root and does not ask for a password after installation


### checking root
if [[ $(id -u) -ne 0 ]]
then 
    echo "script is not run as root, exiting..."
    exit
else
    :
fi


### trap and tmp file
# make it easier for other services and scripts to check if script has finished
trap "rm -f /tmp/network_select_in_progress" EXIT
touch "/tmp/network_select_in_progress"


### variables
SERVICE_NAME=com.network.select
SCRIPT_INSTALL_NAME=network_select

# other launchd services
# no longer needed as all other services are enabled independetly and check for
# /tmp/network_select_in_progress to determine if network-select is still running
other_launchd_services=(
#com.hostsfile.install_update
#com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)


### functions
wait_for_loggedinuser() {
    ### waiting for logged in user
    # recommended way, but it seems apple deprecated python2 in macOS 12.3.0
    # to keep on using the python command, a python module is needed
    #pip3 install pyobjc-framework-SystemConfiguration
    #loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
    NUM=0
    MAX_NUM=30
    SLEEP_TIME=3
    # waiting for loggedInUser to be available
    while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
    do
        sleep "$SLEEP_TIME"
        NUM=$((NUM+1))
        # recommended way, but it seems apple deprecated python2 in macOS 12.3.0
        # to keep on using the python command, a python module is needed
        #pip3 install pyobjc-framework-SystemConfiguration
        #loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
        loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
    done
    #echo ''
    #echo "NUM is $NUM..."
    echo "it took "$NUM"s for the loggedInUser "$loggedInUser" to be available..."
    #echo "loggedInUser is $loggedInUser..."
    if [[ "$loggedInUser" == "" ]]
    then
        WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
        echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
        exit
    else
        :
    fi
}


# in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script() {
    # using ps aux here sometime causes the script to hang when started from a launchd
    # if ps aux is necessary here use
    # timeout 3 env_check_if_run_from_batch_script
    # to run this function
    #BATCH_PIDS=()
    #BATCH_PIDS+=$(ps aux | grep "/batch_script_part.*.command" | grep -v grep | awk '{print $2;}')
    #if [[ "$BATCH_PIDS" != "" ]] && [[ -e "/tmp/batch_script_in_progress" ]]
    if [[ -e "/tmp/batch_script_in_progress" ]]
    then
        RUN_FROM_BATCH_SCRIPT="yes"
    else
        :
    fi
}

start_log() {
    # prints stdout and stderr to terminal and to logfile
    exec > >(tee -ia "$LOGFILE")
}

env_start_error_log() {
    local ERROR_LOG_DIR=/Users/"$loggedInUser"/Desktop/batch_error_logs
    if [[ ! -e "$ERROR_LOG_DIR" ]]
    then
        local ERROR_LOG_NUM=1
    else
        local ERROR_LOG_NUM=$(($(ls -1 "$ERROR_LOG_DIR" | awk -F'_' '{print $1}' | sort -n | tail -1)+1))
    fi
    #echo "starting error log..."
    mkdir -p "$ERROR_LOG_DIR"
    if [[ "$ERROR_LOG_NUM" -le "9" ]]; then ERROR_LOG_NUM="0"$ERROR_LOG_NUM""; else :; fi
    local ERROR_LOG="$ERROR_LOG_DIR"/"$ERROR_LOG_NUM"_"$SERVICE_NAME"_errorlog.txt
    echo "### "$SERVICE_NAME"" >> "$ERROR_LOG"
    #echo "### $(date "+%Y-%m-%d %H:%M:%S")" >> "$ERROR_LOG"
    start_log
    echo '' >> "$ERROR_LOG"
    exec 2> >(tee -ia "$ERROR_LOG" >&2)
}

env_stop_error_log() {
    exec 2<&-
    exec 2>&1
}

timeout() { perl -e '; alarm shift; exec @ARGV' "$@"; }

create_logfile() {
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
        if [[ "$LOGFILEAGEINSECONDS" -lt "$MAXLOGFILEAGE" ]]
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
    sudo echo "$EXECTIME" >> "$LOGFILE"
}

getting_network_device_ids() {
    # get device names
    WLAN_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: AirPort" | head -n 1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/:$//g')
    ETHERNET_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: Ethernet" | sed 's/^[ \t]*//' | sed 's/\:$//g' | grep -v "^--" | grep -v "^Type:" | sed '/^$/d' | grep -v "Bluetooth" | grep -v "iPhone" | grep -v "Bridge")
    #ETHERNET_DEVICE="USB 10/100/1000 LAN"      # macbook pro 2018 and newer
    #ETHERNET_DEVICE="Ethernet"                 # imacs
    HARDWARE_TYPE=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F":" '{print $2}' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed -e 's/ //g') 
    if [[ "$ETHERNET_DEVICE" == "" ]] && [[ "$HARDWARE_TYPE" == "macbookpro" ]]
    then
        ETHERNET_DEVICE="USB 10/100/1000 LAN"
    elif [[ "$ETHERNET_DEVICE" == "" ]] && [[ "$HARDWARE_TYPE" == "imac" ]]
    then
        ETHERNET_DEVICE="Ethernet"
    else
        :
    fi
    BLUETOOTH_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: Ethernet" | sed 's/^[ \t]*//' | sed 's/\:$//g' | grep -v "^--" | grep -v "^Type:" | sed '/^$/d' | grep "Bluetooth")
    THUNDERBOLT_BRIDGE_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: Ethernet" | sed 's/^[ \t]*//' | sed 's/\:$//g' | grep -v "^--" | grep -v "^Type:" | sed '/^$/d' | grep "Bridge")
    
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

set_ethernet_priority() {
    # make sure lan has a higher priority than wlan if both are enabled
    # all available network devices have be be used in this order or an arror will occur
    NETWORKSERVICES_ETHERNET_WLAN_PRIORIZED=(
    # priority sorted order
    "$ETHERNET_DEVICE"
    "$WLAN_DEVICE"
    )

    ALL_ACTIVE_NETWORKSERVICES=$(networksetup -listnetworkserviceorder | cut -d')' -f2 | sed '/^$/d' | sed '1d' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    ALL_ACTIVE_NETWORKSERVICES_FILTERED="$ALL_ACTIVE_NETWORKSERVICES"
    if [[ "$ETHERNET_DEVICE" != "" ]] || [[ "$ETHERNET_DEVICE_ID" != "" ]]
    then
        NETWORKSERVICES_ETHERNET_WLAN_PRIORIZED=$(printf '%s\n' "${NETWORKSERVICES_ETHERNET_WLAN_PRIORIZED[@]}" | grep -v "$ETHERNET_DEVICE")
    else
        ALL_ACTIVE_NETWORKSERVICES_FILTERED=$(printf '%s\n' "${ALL_ACTIVE_NETWORKSERVICES_FILTERED[@]}" | grep -v "$ETHERNET_DEVICE")
    fi
    if [[ "$WLAN_DEVICE" != "" ]] || [[ "$WLAN_DEVICE_ID" != "" ]]
    then
        NETWORKSERVICES_ETHERNET_WLAN_PRIORIZED=$(printf '%s\n' "${NETWORKSERVICES_ETHERNET_WLAN_PRIORIZED[@]}" | grep -v "$WLAN_DEVICE")
    else
        ALL_ACTIVE_NETWORKSERVICES_FILTERED=$(printf '%s\n' "${ALL_ACTIVE_NETWORKSERVICES_FILTERED[@]}" | grep -v "$WLAN_DEVICE")
    fi
    ALL_ACTIVE_NETWORKSERVICES_PRIORIZED=(
    # priority sorted order
    "${NETWORKSERVICES_ETHERNET_WLAN_PRIORIZED[@]}"
    "${ALL_ACTIVE_NETWORKSERVICES_FILTERED[@]}"
    )
    ALL_ACTIVE_DEVICES_PRIORIZED_TO_SET=$(printf '%s\n' "${ALL_ACTIVE_NETWORKSERVICES_PRIORIZED[@]}" | sed '/^$/d' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed -n 's/.*/"&"/; $! s/$//; 1 h; 1 ! H; $ { x; s/\n/ /g; p; }')
    #echo "$ALL_ACTIVE_DEVICES_PRIORIZED_TO_SET"
    eval "sudo networksetup -ordernetworkservices $ALL_ACTIVE_DEVICES_PRIORIZED_TO_SET"
}

finish_ethernet_setup() {
    NETWORK_PROFILE=/Users/"$loggedInUser"/Library/Preferences/network_profile_"$loggedInUser".conf

    FILES_TO_SOURCE=(
    "$NETWORK_PROFILE"
    )
    
    while IFS= read -r line || [[ -n "$line" ]] 
	do
	    if [[ "$line" == "" ]]; then continue; fi
        i="$line"
        if [[ -e "$i" ]]
        then
            #echo "sourcing "$i"..."
            . "$i"
        else
            :
        fi
    done <<< "$(printf "%s\n" "${FILES_TO_SOURCE[@]}")"
    
    #echo "NETWORK_PROFILE is "$NETWORK_PROFILE""
    #echo "ETHERNET_SETUP_COMPLETE is "$ETHERNET_SETUP_COMPLETE""
    #echo "ETHERNET_DEVICE_ID is "$ETHERNET_DEVICE_ID""
    #echo "ETHERNET_DEVICE is "$ETHERNET_DEVICE""
    #echo "WLAN_DEVICE is "$WLAN_DEVICE""
    if [[ -e "$NETWORK_PROFILE" ]] && [[ "$ETHERNET_SETUP_COMPLETE" == "no" ]] && [[ "$ETHERNET_DEVICE_ID" != "" ]]
    then
        #echo ''
        echo "finishing ethernet setup..."
        
        while IFS= read -r line || [[ -n "$line" ]] 
    	do
    	    if [[ "$line" == "" ]]; then continue; fi
            LOCATION_NAME="$line"
            
            sudo networksetup -switchtolocation "$LOCATION_NAME" &>/dev/null
            sleep 2
            sudo networksetup -createnetworkservice "$ETHERNET_DEVICE" "$ETHERNET_DEVICE" &>/dev/null
            sleep 2
            sudo networksetup -setv6off "$ETHERNET_DEVICE"
            #sudo networksetup -setv6automatic "$ETHERNET_DEVICE"
            sleep 2
            if [[ "$LOCATION_NAME" == "$CUSTOM_LOCATION" ]]
            then
                sudo networksetup -setmanual "$ETHERNET_DEVICE" "$IP" 255.255.255.0 "$DNS"
                sleep 2
                sudo networksetup -setdnsservers "$ETHERNET_DEVICE" "$DNS"
                sleep 2
            else
                :
            fi
            set_ethernet_priority
            sleep 2
        done <<< "$(printf "%s\n" "${NETWORK_LOCATIONS[@]}")"
        
        # ethernet setup complete
        if [[ -e "$NETWORK_PROFILE" ]]
        then
            sed -i '' 's|^ETHERNET_SETUP_COMPLETE=.*|ETHERNET_SETUP_COMPLETE="yes"|g' "$NETWORK_PROFILE"
            rm -f "$NETWORK_PROFILE"
        else
            :
        fi
    else
        :
    fi
}

enable_wlan_device() {
    # make sure wlan device is enabled when using wlan profile
    if [[ "$WLAN_DEVICE_ID" != "" ]]
    then
        if [[ $(sudo networksetup -getairportpower "$WLAN_DEVICE_ID" | awk '{print $NF}') == "Off" ]]
        then
            sudo networksetup -setairportpower "$WLAN_DEVICE_ID" On
            sleep 10
        else
            :
        fi
    else
        :
    fi
}

disable_wlan_device() {
    if [[ "$WLAN_DEVICE_ID" != "" ]]
    then
        if [[ $(sudo networksetup -getairportpower "$WLAN_DEVICE_ID" | awk '{print $NF}') == "On" ]]
        then
            sudo networksetup -setairportpower "$WLAN_DEVICE_ID" Off
            sleep 2
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
        if [[ $(sudo -H -u "$loggedInUser" VBoxManage list vms) != "" ]]
        then
            if [[ "$DEVICE_ID" =~ ^en[0-9]$ ]]
            then
                for VBOX in $(sudo -H -u "$loggedInUser" VBoxManage list vms | awk -F'"|"' '{print $2}')
                do
                    echo "setting virtualbox network to "$DEVICE_ID" for vbox "$VBOX"..."
                    
                    sudo -H -u "$loggedInUser" VBoxManage modifyvm "$VBOX" --nic1 bridged --bridgeadapter1 "$DEVICE_ID"
                    sleep 1
                    
                    if [[ $(sudo -H -u "$loggedInUser" VBoxManage showvminfo "$VBOX" --machinereadable | grep bridgeadapter1 | grep "$DEVICE_ID") == "" ]]
                    then
                        echo "setting virtualbox network to "$DEVICE_ID" for vbox "$VBOX"..."
                        DEVICE_ID=$(sudo -H -u "$loggedInUser" VBoxManage list bridgedifs | grep "^Name:" | grep "$DEVICE_ID" | cut -d':' -f2- | sed -e 's/^[ \t]*//')
                        sudo -H -u "$loggedInUser" VBoxManage modifyvm "$VBOX" --nic1 bridged --bridgeadapter1 "$DEVICE_ID"
                        sleep 1
                    else
                        :
                    fi
                        
                done
            else
                echo ""$DEVICE"_DEVICE_ID is empty or has a wrong format..."
            fi
        else
            echo "no virtualbox vms found, skipping..."
        fi
    else
        # virtualbox is not installed
        echo "virtualbox is not installed..."
    fi
}

set_utm_network_device() {
    if [[ -e "/Applications/UTM.app" ]]
    then
        # installed
        if [[ -e /Users/"$loggedInUser"/Library/Containers/com.utmapp.UTM/Data/Documents ]]
        then
            if [[ $(find /Users/"$loggedInUser"/Library/Containers/com.utmapp.UTM/Data/Documents -mindepth 1 -maxdepth 1 -name "*.utm" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d') -gt "0" ]]
            then
                if [[ "$DEVICE_ID" =~ ^en[0-9]$ ]]
                then
                    while IFS= read -r line || [[ -n "$line" ]]
            		do
            		    if [[ "$line" == "" ]]; then continue; fi
                        UTM_VM="$line"
                        echo "setting utm network to "$DEVICE_ID" for vm $(basename "$UTM_VM")..."
                        if [[ -z $(/usr/libexec/PlistBuddy -c "Print :Network:BridgeInterface:BridgeInterface" "$UTM_VM/config.plist") ]] > /dev/null 2>&1
                        then
                            /usr/libexec/PlistBuddy -c "Add :Network:BridgeInterface:BridgeInterface string" "$UTM_VM/config.plist"
                        	/usr/libexec/PlistBuddy -c "Set :Network:BridgeInterface:BridgeInterface "$DEVICE_ID"" "$UTM_VM/config.plist"
                        else
                            /usr/libexec/PlistBuddy -c "Set :Network:BridgeInterface:BridgeInterface "$DEVICE_ID"" "$UTM_VM/config.plist"
                        fi  
            			#echo ''
                    done <<< "$(find /Users/"$loggedInUser"/Library/Containers/com.utmapp.UTM/Data/Documents -mindepth 1 -maxdepth 1 -name "*.utm")"
                else
                    echo ""$DEVICE"_DEVICE_ID is empty or has a wrong format..."
                fi
            else
                echo "no utm vms found, skipping..."
            fi
        else
            echo "directory for utm vms not found, skipping..."
        fi
    else
        # virtualbox is not installed
        echo "utm is not installed..."
    fi
}

setting_config() {
    echo ''
    ### sourcing .$SHELLrc or setting PATH
    # as the script is run from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # needed if binary is installed in a special directory
    if [[ -n "$BASH_SOURCE" ]] && [[ -e /Users/"$loggedInUser"/.bashrc ]] && [[ $(cat /Users/"$loggedInUser"/.bashrc | grep 'export PATH=.*:$PATH"') != "" ]]
    then
        echo "sourcing .bashrc..."
        #. /Users/"$loggedInUser"/.bashrc
        # avoiding oh-my-zsh errors for root by only sourcing export PATH
        source <(sed -n '/^export\ PATH\=/p' /Users/"$loggedInUser"/.bashrc)
    elif [[ -n "$ZSH_VERSION" ]] && [[ -e /Users/"$loggedInUser"/.zshrc ]] && [[ $(cat /Users/"$loggedInUser"/.zshrc | grep 'export PATH=.*:$PATH"') != "" ]]
    then
        echo "sourcing .zshrc..."
        ZSH_DISABLE_COMPFIX="true"
        #. /Users/"$loggedInUser"/.zshrc
        # avoiding oh-my-zsh errors for root by only sourcing export PATH
        source <(sed -n '/^export\ PATH\=/p' /Users/"$loggedInUser"/.zshrc)
    else
        echo "PATH was not set continuing with default value..."
    fi
    echo "using PATH..." 
    echo "$PATH"
    echo ''
}

check_if_ethernet_is_active() {
    echo "checking ethernet connection..."
    sleep 1
    NUM1=0
    COMMAND_TIMEOUT=3
    ETHERNET_CONNECTED=$(printf "get State:/Network/Interface/"$ETHERNET_DEVICE_ID"/Link\nd.show" | scutil | grep Active | awk '{print $NF}')
    if [[ "$ETHERNET_CONNECTED" != "TRUE" ]]
    then
        echo "ethernet is not active..."
        echo ''
    else
        echo "ethernet is active..."
    fi
    #echo ''
}

check_if_online() {
    ONLINECHECK1=google.com
    ONLINECHECK2=duckduckgo.com
    #echo ''
    #echo "checking internet connection..."
    if [[ $(timeout 3 2>/dev/null dig +short -4 "$ONLINECHECK1" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        if [[ $(timeout 3 2>/dev/null dig +short -4 "$ONLINECHECK2" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
}

change_to_location_custom() {
    if [[ $(networksetup -getcurrentlocation) != "$CUSTOM_LOCATION" ]]
    then
        if [[ $(networksetup -listlocations | grep "$CUSTOM_LOCATION") != "" ]]
        then
            echo "changing to location "$CUSTOM_LOCATION"..."
            #echo ''
            sudo networksetup -switchtolocation "$CUSTOM_LOCATION" &>/dev/null
            sleep 2
            CHANGED_PROFILE="yes"
        else
            echo ""$CUSTOM_LOCATION" location not found, skipping..."
            #echo ''
        fi
    else
        echo "location "$CUSTOM_LOCATION" already enabled..."
        #echo ''
    fi
}


### script
create_logfile
wait_for_loggedinuser
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
# run before main function, e.g. for time format

network_select() {

    setting_config
    
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
    AUTOMATIC_LOCATION="automatic"
    CUSTOM_LOCATION="custom"
    
    NETWORK_LOCATIONS=(
    "$AUTOMATIC_LOCATION"
    "$CUSTOM_LOCATION"
    )
    
    ### finishig ethernet setup if necessary
    finish_ethernet_setup
        
    # try custom location first
    change_to_location_custom
    
    # check if ethernet is connected and online
    # check if ethernet interface is present
    if [[ "$ETHERNET_DEVICE_ID" != "" ]]
    then
        # check if ethernet cable is connected
        check_if_ethernet_is_active
        if [[ "$ETHERNET_CONNECTED" == "TRUE" ]]
        then
            disable_wlan_device
            echo "checking internet connection for ethernet - location $(networksetup -getcurrentlocation)..."
            check_if_online
            if [[ "$ONLINE_STATUS" == "offline" ]]
            then
                # check again if first online check fails
                sleep 3
                check_if_online
            fi
            if [[ "$ONLINE_STATUS" == "offline" ]]
            then
                # switch to (ethernet) automatic dhcp profile
                echo ''
                echo "changing to location $(networksetup -listlocations | grep --ignore-case '^auto')..."
                sudo networksetup -switchtolocation $(networksetup -listlocations | grep --ignore-case '^auto') &>/dev/null
                sleep 2
                disable_wlan_device
                #echo ''
                echo "checking internet connection for ethernet - location $(networksetup -getcurrentlocation)..."
                check_if_online
                if [[ "$ONLINE_STATUS" == "offline" ]]
                then
                    ETHERNET_ONLINE="no"
                else
                    ETHERNET_ONLINE="yes"
                fi
            else
                ETHERNET_ONLINE="yes"
            fi
        else
            ETHERNET_ONLINE="no"
        fi
    else
        ETHERNET_ONLINE="no"
    fi
            
    #echo "ETHERNET_ONLINE is "$ETHERNET_ONLINE""
    if [[ "$ETHERNET_ONLINE" == "yes" ]]
    then
        DEVICE="ETHERNET"
        DEVICE_ID="$ETHERNET_DEVICE_ID"
        echo ''
        echo "enabling "$DEVICE" for vms..."
        set_vbox_network_device
        set_utm_network_device
    else
        change_to_location_custom
        enable_wlan_device
        DEVICE="WLAN"
        DEVICE_ID="$WLAN_DEVICE_ID"
        echo ''
        echo "enabling "$DEVICE" for vms..."
        set_vbox_network_device
        set_utm_network_device
    fi
        
    # loading and disabling other launchd services
    # no longer needed as all other services are enabled independetly and check for
    # /tmp/network_select_in_progress to determine if network-select is still running
    configure_other_launchd_services() {
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
                    sudo launchctl enable system/"$i"
                    sudo launchctl bootstrap system /Library/LaunchDaemons/"$i".plist 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"	
                    sleep 2
					sudo launchctl disable system/"$i"  
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
    #configure_other_launchd_services
    
    echo ''
    echo "done ;)"
    echo ''
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    ( network_select )
else
    time ( network_select )
    echo ''
fi



### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
