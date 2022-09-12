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

env_start_error_log() {
    local ERROR_LOG_DIR=/Users/"$loggedInUser"/Desktop/batch_error_logs
    if [[ ! -e "$ERROR_LOG_DIR" ]]
    then
        local ERROR_LOG_NUM=1
    else
        local ERROR_LOG_NUM=$(($(ls -1 "$ERROR_LOG_DIR" | awk -F'_' '{print $1}' | sort -n | tail -1)+1))
    fi
    mkdir -p "$ERROR_LOG_DIR"
    if [[ "$ERROR_LOG_NUM" -le "9" ]]; then ERROR_LOG_NUM="0"$ERROR_LOG_NUM""; else :; fi
    local ERROR_LOG="$ERROR_LOG_DIR"/"$ERROR_LOG_NUM"_"$SERVICE_NAME"_errorlog.txt
    echo "### "$SERVICE_NAME"" >> "$ERROR_LOG"
    #echo "### $(date "+%Y-%m-%d %H:%M:%S")" >> "$ERROR_LOG"
    echo '' >> "$ERROR_LOG"
    exec 2> >(tee -ia "$ERROR_LOG" >&2)
}

env_stop_error_log() {
    exec 2<&-
    exec 2>&1
}

start_log() {
    # prints stdout and stderr to terminal and to logfile
    exec > >(tee -ia "$LOGFILE")
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
    #echo ''
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
            #$(ifconfig en0 | grep status | cut -d ":" -f 2 | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d') == "active"
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


### script
create_logfile
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
wait_for_loggedinuser
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
                echo ''
                disable_wlan_device
            else
                echo "changing to location "$ETHERNET_LOCATION"..."
                echo '' 
                sudo networksetup -switchtolocation "$ETHERNET_LOCATION"
                disable_wlan_device
                printf '\n\n'
                sleep 10
            fi
            DEVICE="ETHERNET"
            DEVICE_ID="$ETHERNET_DEVICE_ID"
            set_vbox_network_device
        else
            :
        fi
        check_if_ethernet_is_active
    else
        echo "ethernet location not found, skipping..."
        echo ''
    fi
    
    # changing to wlan profile if lan is not connected
    if [[ "$ETHERNET_CONNECTED" == "TRUE" ]]
    then
        :
    else
        if [[ $(networksetup -listlocations | grep "$WLAN_LOCATION") != "" ]]
        then
            if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") == "" ]] || [[ "$ETHERNET_CONNECTED" != "TRUE" ]]
            then    
                if [[ $(networksetup -getcurrentlocation | grep "$WLAN_LOCATION") != "" ]]
                then
                    echo "location "$WLAN_LOCATION" already enabled..."
                    echo ''
                    enable_wlan_device
                else
                    echo "changing to location "$WLAN_LOCATION"..."
                    echo ''
                    sudo networksetup -switchtolocation "$WLAN_LOCATION"
                    enable_wlan_device
                    printf '\n\n'
                    sleep 10
                fi
                DEVICE="WLAN"
                DEVICE_ID="$WLAN_DEVICE_ID"
                set_vbox_network_device
            else
                :
            fi
        else
            echo "wlan location not found, skipping..."
            echo ''
        fi
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
fi

echo ''


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
