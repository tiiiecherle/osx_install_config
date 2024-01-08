#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
        env_sudo
    else
        env_enter_sudo_password
    fi
else
    :
fi



###
### variables
###

# manpage
# https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/networksetup.8.html

# to reset all the network settings completely do
#sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.network.identification.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist
#sudo reboot

# a few commands
# networksetup -detectnewhardware
# networksetup -listallhardwareports
# networksetup -listallnetworkservices
# networksetup -listlocations


### getting logged in user
# loggedIn user and unique user id
# done in config script


### network config
# if the script shall be run standalone without profile all of these variables have to have valid entries and have to be activated
#WLAN_DEVICE="Wi-Fi"
#ETHERNET_DEVICE="USB 10/100/1000 LAN"
#SUBNET="192.168.1"
#IP="$SUBNET".2
#DNS="$SUBNET".1
#CREATE_LOCATION_AUTOMATIC="yes"
#CREATE_LOCATION_CUSTOM="yes"
#CREATE_LOCATION_WLAN="no"
#SHOW_VPN_IN_MENU_BAR="no"
#CONFIGURE_FRITZ_VPN="no"



###
### functions
###

getting_network_device_ids() {
    # get device names
    HARDWARE_TYPE=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F":" '{print $2}' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed -e 's/ //g') 
    WLAN_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: AirPort" | head -n 1 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/:$//g')
    #ETHERNET_DEVICE="USB 10/100/1000 LAN"      # macbook pro 2018 and newer
    #ETHERNET_DEVICE="Ethernet"                         # imacs
    ETHERNET_DEVICE=""
    if [[ "$ETHERNET_DEVICE" == "" ]] && [[ "$HARDWARE_TYPE" == "macbookpro" ]]
    then
        ETHERNET_DEVICE="USB 10/100/1000 LAN"
    elif [[ "$ETHERNET_DEVICE" == "" ]] && [[ "$HARDWARE_TYPE" == "macbookair" ]]
    then
        ETHERNET_DEVICE="USB 10/100/1000 LAN"
    elif [[ "$ETHERNET_DEVICE" == "" ]] && [[ "$HARDWARE_TYPE" == "imac" ]]
    then
        ETHERNET_DEVICE="Ethernet"
    else
            ETHERNET_DEVICE=$(system_profiler SPNetworkDataType | grep -B2 "Type: Ethernet" | sed 's/^[ \t]*//' | sed 's/\:$//g' | grep -v "^--" | grep -v "^Type:" | sed '/^$/d' | grep -v "Bluetooth" | grep -v "Bridge")
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

create_location_tmp_automatic() {
    # creating new location automatic
    echo "adding location tmp_automatic..."
    sudo networksetup -createlocation "tmp_automatic" populate >/dev/null 2>&1
    sleep 2
    sudo networksetup -switchtolocation "tmp_automatic"
    sleep 2
    if [[ "$ETHERNET_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") != "" ]]
    then
        # do not disable ipv6 for automatic profiles as they should keep all default settings
        # as of 2024-01 the client internet connection (macbook) does not work with ipv6 disabled for Wi-Fi when connected to the iphone mobile data access point
        #sudo networksetup -setv6off "$ETHERNET_DEVICE"
        #sudo networksetup -setv6automatic "$ETHERNET_DEVICE"
        sleep 2
    else
        :
    fi
    if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$WLAN_DEVICE$") != "" ]]
    then
        # do not disable ipv6 for automatic profiles as they should keep all default settings
        # as of 2024-01 the client internet connection (macbook) does not work with ipv6 disabled for Wi-Fi when connected to the iphone mobile data access point
        #sudo networksetup -setv6off "$WLAN_DEVICE"
        #sudo networksetup -setv6automatic "$WLAN_DEVICE"
        sleep 2
    else
        :
    fi
    echo ""
    set_ethernet_priority
    sleep 2
}

create_location_automatic() {
    # creating new location automatic
    echo "adding location automatic..."
    sudo networksetup -createlocation "automatic" populate >/dev/null 2>&1
    sleep 2
    sudo networksetup -switchtolocation "automatic"
    sleep 2
    if [[ "$ETHERNET_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") != "" ]]
    then
        # do not disable ipv6 for automatic profiles as they should keep all default settings
        # as of 2024-01 in case a client (e.g. macbook) connects to the mobile data acces point of an iphone the internet connection does not work for the client
        #sudo networksetup -setv6off "$ETHERNET_DEVICE"
        #sudo networksetup -setv6automatic "$ETHERNET_DEVICE"
        sleep 2
    else
        :
    fi
    if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$WLAN_DEVICE$") != "" ]]
    then
        # do not disable ipv6 for automatic profiles as they should keep all default settings
        # as of 2024-01 in case a client (e.g. macbook) connects to the mobile data acces point of an iphone the internet connection does not work for the client
        #sudo networksetup -setv6off "$WLAN_DEVICE"
        #sudo networksetup -setv6automatic "$WLAN_DEVICE"
        sleep 2
    else
        :
    fi
    echo ""
    set_ethernet_priority
    sleep 2
}

create_location_custom() {
    # creating new location
    local LOCATION_NAME="custom"
    echo "adding location custom..."
    
    if [[ "$ETHERNET_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$ETHERNET_DEVICE$") != "" ]]
    then
        # checking SUBNET & IP
        CREATE_ETHERNET_DEVICE="yes"
    	if echo "$SUBNET"."$IP" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null 2>&1
    	then
    		VALID_IP_ADDRESS="$(echo $SUBNET.$IP | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
    		if [[ -z "$VALID_IP_ADDRESS" ]]
    		then
    			echo "subnet or ip not valid, skipping creation of location "$LOCATION_NAME"..."
    			CREATE_ETHERNET_DEVICE="no"
    		else
    			:
    		fi
    	else
    		echo "subnet or ip not valid, skipping creation of location "$LOCATION_NAME"..."
    		CREATE_ETHERNET_DEVICE="no"
    	fi
    	# checking DNS
    	if echo "$DNS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' > /dev/null 2>&1
    	then
    		VALID_IP_ADDRESS="$(echo $DNS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
    		if [[ -z "$VALID_IP_ADDRESS" ]]
    		then
    			echo "dns not valid, skipping creation of location "$LOCATION_NAME"..."
    			CREATE_ETHERNET_DEVICE="no"
    		else
    			:
    		fi
    	else
    		echo "dns not valid, skipping creation of location "$LOCATION_NAME"..."
    		CREATE_ETHERNET_DEVICE="no"
    	fi
    else
        :
    fi
    
    sudo networksetup -createlocation "$LOCATION_NAME"
    sleep 2
    sudo networksetup -switchtolocation "$LOCATION_NAME"
    echo ""
    sleep 2
    if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$WLAN_DEVICE$") != "" ]]
    then
        sudo networksetup -createnetworkservice "$WLAN_DEVICE" "$WLAN_DEVICE"
        sleep 2
        # as of 2024-01 in case a client (e.g. macbook) connects to the mobile data acces point of an iphone the internet connection does not work for the client
        # due to this if no other issue comes up leave the default value (setv6automatic) enabled
        #sudo networksetup -setv6off "$WLAN_DEVICE"
        #sudo networksetup -setv6automatic "$WLAN_DEVICE"
        #sleep 2
    else
        :
    fi
	if [[ "$CREATE_ETHERNET_DEVICE" == "yes" ]]
    then
        sudo networksetup -createnetworkservice "$ETHERNET_DEVICE" "$ETHERNET_DEVICE"
        sleep 2
        sudo networksetup -setmanual "$ETHERNET_DEVICE" "$IP" 255.255.255.0 "$DNS"
        sleep 2
        sudo networksetup -setdnsservers "$ETHERNET_DEVICE" "$DNS"
        sleep 2
        # as of 2024-01 in case a client (e.g. macbook) connects to the mobile data acces point of an iphone the internet connection does not work for the client
        # due to this if no other issue comes up leave the default value (setv6automatic) enabled
        #sudo networksetup -setv6off "$ETHERNET_DEVICE"
        #sudo networksetup -setv6automatic "$ETHERNET_DEVICE"
        #sleep 2
        if [[ -e /Users/"$loggedInUser"/Library/Preferences/network_profile_"$loggedInUser".conf ]]; then rm -f /Users/"$loggedInUser"/Library/Preferences/network_profile_"$loggedInUser".conf; else :;fi
    else
        echo "ethernet device not present or not defined, skipping..."
        cp "$NETWORK_PROFILE" /Users/"$loggedInUser"/Library/Preferences/network_profile_"$loggedInUser".conf
        echo '' >> /Users/"$loggedInUser"/Library/Preferences/network_profile_"$loggedInUser".conf
        echo 'ETHERNET_SETUP_COMPLETE="no"' >> /Users/"$loggedInUser"/Library/Preferences/network_profile_"$loggedInUser".conf
    fi
    set_ethernet_priority
    sleep 2
}

show_vpn_in_menu_bar() {
    
    ### enabling icon in menu bar/adding entry
    show_vpn_menu_bar_icon() {
        if [[ $(defaults read com.apple.systemuiserver menuExtras | grep "vpn.menu") == "" ]]
        then
            defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/vpn.menu" >/dev/null 2>&1
            # do not show vpm connection time in menu bar
            # 0 = no
            # 1 = yes
            defaults write com.apple.networkConnect VPNShowTime 0
            # make changes take effect
            killall SystemUIServer -HUP
        else
            :
        fi
    }
    show_vpn_machine_menu_bar_icon

    ### disabling icon in menu bar/deleting entry
    hide_vpn_menu_bar_icon() {
        defaults write ~/Library/Preferences/ByHost/com.apple.systemuiserver.$uuid1.plist dontAutoLoad -array "/System/Library/CoreServices/Menu Extras/vpn.menu" >/dev/null 2>&1
        
        NotPreferredMenuExtras=(
        "/System/Library/CoreServices/Menu Extras/vpn.menu"
        )
        
        for varname in "${NotPreferredMenuExtras[@]}"; 
        do
            /usr/libexec/PlistBuddy -c "Delete 'menuExtras:$(defaults read ~/Library/Preferences/com.apple.systemuiserver.plist menuExtras | cat -n | grep "$varname" | awk '{print SUM $1-2}') string'" ~/Library/Preferences/com.apple.systemuiserver.plist >/dev/null 2>&1 | grep -v "Does Not Exist" | grep -v "does not exist"
            :
        done
        
        # make changes take effect
        sleep 2
        killall cfprefsd -HUP
        killall SystemUIServer -HUP
        sleep 5
    }
    #hide_vpn_menu_bar_icon
    
}

configure_fritz_vpn() {
    echo ''
    echo "vpn_connections..."
    echo ''

    ### checking homebrew and script dependencies
    if command -v brew &> /dev/null
    then
    	# installed
        echo "homebrew is installed..."
        # checking for missing dependencies
        for formula in gnu-tar pigz pv coreutils gnupg
        do
        	if [[ $(brew list --formula | grep "^$formula$") == '' ]]
        	then
        		echo """$formula"" is NOT installed, installing..."
                brew install --formula "$formula"
        	else
        		#echo """$formula"" is installed..."
        		:
        	fi
        done
        
        ### configuring vpn connections
        # script uses https://github.com/halo/macosvpn
        #echo "configuring vpn connections..."
        SCRIPT_NAME="vpn_connections_network_macos_wr"
        SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
        SCRIPT_DIR_INPUT_KEEP="$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep
        if [[ -e "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".tar.gz.gpg ]]
        then
            echo ''
    		echo "unarchiving and decrypting vpn configuration script..."
    		
    		item="$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".tar.gz.gpg
    		OUTPUT_PATH="$SCRIPT_DIR_INPUT_KEEP"/
    		
            # pure .gpg
            #"$SCRIPT_INTERPRETER" -c 'cat '"$item"' | pv -s $(gdu -scb '"$item"' | tail -1 | awk "{print $1}" | grep -o "[0-9]\+") | gpg --batch --passphrase='"$SUDOPASSWORD"' --quiet -d -o '"$SCRIPT_DIR_INPUT_KEEP"/'"$SCRIPT_NAME"'.sh' && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m"'
            
            # .tar.gz.gpg
            "$SCRIPT_INTERPRETER" -c 'cat '"$item"' | pv -s $(gdu -scb '"$item"' | tail -1 | awk "{print $1}" | grep -o "[0-9]\+") | gpg --batch --passphrase='"$SUDOPASSWORD"' --quiet -d - | unpigz -dc - | gtar --same-owner -C '"$OUTPUT_PATH"' -xpf - >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m"'
            
            #echo ''			
    		if [[ -e "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh ]]
    		then
    		    USER_ID=`id -u`
    		    chown "$USER_ID":staff "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    		    chmod 700 "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    		    . "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    		    rm -f "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    		    show_vpn_in_menu_bar
    		else
    		    echo "script to configure vpn connections not found..."
            fi
        else
            echo ''
            echo "encrypted script to configure vpn connections not found..."
        fi
        echo ''
    else
        # not installed
    	echo "homebrew is not installed, skipping vpn profiles installation..."
    fi 
}

# profile based user specifc configuration
profile_based_config() {
    if [[ -e "$SCRIPT_DIR"/profiles/network_profile_"$loggedInUser".conf ]]
    then
        echo "network profile found for $loggedInUser..."
        NETWORK_PROFILE="$SCRIPT_DIR"/profiles/network_profile_"$loggedInUser".conf
    elif [[ -e "$SCRIPT_DIR"/profiles/network_profile_example.conf ]]
    then
        echo "no network profile found for $loggedInUser, but example profile found..."
        NETWORK_PROFILE="$SCRIPT_DIR"/profiles/network_profile_example.conf
    else
        echo "no network profile found for $loggedInUser and no example profile found, exiting..."
        echo ''
        exit
    fi    
    
    #echo "NETWORK_PROFILE is $NETWORK_PROFILE..."
    . "$NETWORK_PROFILE"
    #echo ''
    while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
        if [[ $(echo "$line" | grep "^#") != "" ]]
        then
            :
        else
            PROFILE_VARIABLE=$(echo "$line" | cut -d= -f 1)
            # | awk -F'=' '{print $1}'
            VARIABLE_VALUE=$(eval echo "$line" | cut -d= -f 2 | tr -d '"')
            printf "%-30s %-10s\n" "$PROFILE_VARIABLE" "$VARIABLE_VALUE"
        fi       
    done <<< "$(cat "$NETWORK_PROFILE")"
    
    if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
    then
        :
    else
        echo ''
    fi
    VARIABLE_TO_CHECK="$RUN_WITH_PROFILE"
    QUESTION_TO_ASK="do you want to use these settings (Y/n)? "
    env_ask_for_variable
    RUN_WITH_PROFILE="$VARIABLE_TO_CHECK"
    sleep 0.1
    
    if [[ "$RUN_WITH_PROFILE" =~ ^(yes|y)$ ]]
    then
        echo ''
        . "$NETWORK_PROFILE"
    else
        echo ''
        echo "exiting..."
        echo ''
        exit
    fi
}

set_location() {
    if [[ "$LOCATION_ALREADY_SET" == "yes" ]]
    then
        :
    else
        if [[ $(networksetup -listlocations | grep "$LOCATION_TO_SET") != "" ]]
        then
            if [[ $(networksetup -getcurrentlocation) != "$LOCATION_TO_SET" ]]
            then
                echo "changing to location "$LOCATION_TO_SET"" 
                sudo networksetup -switchtolocation "$LOCATION_TO_SET"
                sleep 2
            else
                echo "location "$LOCATION_TO_SET" already enabled..."
            fi
            if [[ "$WLAN_DEVICE" != "" ]] && [[ $(networksetup -listallhardwareports | grep "$WLAN_DEVICE$") != "" ]]
            then
                sudo networksetup -setairportpower "$WLAN_DEVICE_ID" "$WLAN_ON_OR_OFF"
                sleep 2
                #echo ''
            else
                :
            fi
            LOCATION_ALREADY_SET="yes"
            #printf '\n'
        else
            :
        fi
    fi
    unset LOCATION_TO_SET
    unset WLAN_ON_OR_OFF
}

check_if_ethernet_is_active() {
    #echo ''
    echo "checking ethernet connection..."
    NUM1=0
    FIND_ETHERNET_DEVICE_TIMEOUT=4
    while [[ "$ETHERNET_CONNECTED" != "TRUE" ]]
    do
    	#printf "%.2f\n" "$NUM1"
    	NUM1=$(bc<<<$NUM1+1)
    	if (( $(echo "$NUM1 <= $FIND_ETHERNET_DEVICE_TIMEOUT" | bc -l) ))
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
        LOCATION_ALREADY_SET=""
        echo ''
    else
        echo "ethernet is active..."
        echo ''
    fi
    #echo ''
}

set_wifi_joinmodefallback() {
    # ask to join new networks (JoinModeFallback)
    # has to be done for every network profile, only works when the respective profile is active
    # no = DoNothing
    # yes = Prompt
    # list options /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
    sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport "$WLAN_DEVICE_ID" prefs JoinModeFallback=DoNothing
    sleep 2
}


###
### configuring network
###

echo '' 
echo "configuring network..."
echo ''

getting_network_device_ids

# check if wifi is connected
# https://stackoverflow.com/questions/4481005/get-wireless-ssid-through-shell-script-on-mac-os-x
WIFI_SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I  | awk -F' SSID: '  '/ SSID: / {print $2}')
if [[ "$WIFI_SSID" != "" ]]
then
    echo "wifi is connected to ssid "$WIFI_SSID"..."
    echo ''
else
    :
fi

profile_based_config


### deleting all network locations
#echo please ignore error about missing preferences.plist file, it will be created automatically
# this would delete wireguard configurations
#sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist >/dev/null 2>&1

create_location_tmp_automatic

echo ''
while IFS= read -r line || [[ -n "$line" ]] 
do
    if [[ "$line" == "" ]]; then continue; fi
    i="$line"
    #echo "$i"
    echo "deleting location "$i""
    sudo networksetup -deletelocation "$i"
    echo ''
done <<< "$(networksetup -listlocations | grep -v tmp_automatic)"
sleep 2


### location automatic
if [[ "$CREATE_LOCATION_AUTOMATIC" == "yes" ]]
then
    echo ''
    create_location_automatic
    set_wifi_joinmodefallback
else
    :
fi


### location custom
if [[ "$CREATE_LOCATION_CUSTOM" == "yes" ]]
then
    echo ''
    create_location_custom
    set_wifi_joinmodefallback
else
    :
fi


### location wlan
if [[ "$CREATE_LOCATION_WLAN" == "yes" ]]
then
    echo ''
    create_location_wlan
    set_wifi_joinmodefallback
else
    :
fi


### vpn menu bar
if [[ "$SHOW_VPN_IN_MENU_BAR" == "yes" ]]
then
    show_vpn_in_menu_bar
else
    :
fi


### fritz vpn config
if [[ "$CONFIGURE_FRITZ_VPN" == "yes" ]]
then
    configure_fritz_vpn
else
    :
fi


### cleaning temp location
echo ''
echo "deleting location tmp_automatic..."
sudo networksetup -deletelocation "tmp_automatic"
echo ''
sleep 2


### auto join hotspots
# macos 10.14 and newer
VERSION_TO_CHECK_AGAINST=10.14
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.14
    :
else
    # macos versions 10.15 and newer
    # Automatic
    # AskToJoin
    # Never
    echo ''
    echo "setting wlan auto hotspot mode..."
    sudo /usr/libexec/PlistBuddy -c "Add :AutoHotspotMode string" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist &> /dev/null
    sudo /usr/libexec/PlistBuddy -c "Set :AutoHotspotMode 'Never'" /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
fi

###
# ask to join new networks (JoinModeFallback)
# has to be done for every network profile, only works when the respective profile is active
# no = DoNothing
# yes = Prompt
# list options /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
# sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport en0 prefs JoinModeFallback=DoNothing




### locations created
echo ''
echo "network locations created ;)"
echo ''


### changing to location
unset LOCATION_ALREADY_SET

LOCATION_TO_SET="custom"
WLAN_ON_OR_OFF="off"
set_location
echo ''
check_if_ethernet_is_active

LOCATION_TO_SET="custom"
WLAN_ON_OR_OFF="on"
set_location

LOCATION_TO_SET=$(networksetup -listlocations | grep --ignore-case "^auto")
WLAN_ON_OR_OFF="on"
set_location

if [[ "$LOCATION_ALREADY_SET" == "yes" ]]
then
    :
else
    echo "no defined location found, not selecting one specifically..."
fi

# reconnect to wifi if it was connected on script start
if [[ "$WIFI_SSID" != "" ]]
then
    sudo networksetup -setairportpower "$WLAN_DEVICE_ID" off
    sleep 3
    sudo networksetup -setairportpower "$WLAN_DEVICE_ID" on
    sleep 3
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s
    sleep 5
    sudo networksetup -setairportnetwork "$WLAN_DEVICE_ID" "$WIFI_SSID"
    sleep 3
else
    :
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


if [[ "$ETHERNET_CONNECTED" == "TRUE" ]]; then :; else echo ''; fi
echo "done ;)"
echo ''



###
### unsetting password
###

unset SUDOPASSWORD
