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


### variables
SERVICE_NAME=com.cert.install_update
SCRIPT_INSTALL_NAME=cert_install_update


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

wait_for_network_select() {
    ### waiting for network select script
    if [[ $(sudo launchctl list | grep com.network.select) != "" ]]
    then
        # as the script start at launch on boot give network select time to create the tmp file
        sleep 3
        if [[ -e /tmp/network_select_in_progress ]]
        then
            NUM=1
            MAX_NUM=30
            SLEEP_TIME=3
            # waiting for network select script
            while [[ -e /tmp/network_select_in_progress ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
            do
                sleep "$SLEEP_TIME"
                NUM=$((NUM+1))
            done
            #echo ''
            WAIT_TIME=$((NUM*SLEEP_TIME))
            echo "waited "$WAIT_TIME"s for network select to finish..."
        else
            echo "network select not running, continuing..."
        fi
    else
        echo "network select not installed, continuing..."
    fi
}

certificate_variable_check() {
    
    # macos
    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
    env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }

    # keychain
    KEYCHAIN_SYSTEM="/System/Library/Keychains/SystemRootCertificates.keychain"
    KEYCHAIN_USER="/Users/"$loggedInUser"/Library/Keychains/login.keychain"
    
    # variable for search/replace by install script
    CERTIFICATES_TO_INSTALL=(
    # SERVER-IP or domain				server name								certificate name						
    ""FILL_IN_SERVER1_HERE"             "FILL_IN_SERVER_NAME1_HERE"             "FILL_IN_CERT_NAME1_HERE""
    ""FILL_IN_SERVER2_HERE"             "FILL_IN_SERVER_NAME2_HERE"             "FILL_IN_CERT_NAME2_HERE""                 
    )

}

install_update_certificate() {

    # mounting system as read/write until next reboot
    if [[ "$MACOS_VERSION_MAJOR" != 10.15 ]]
    then
        # macos versions other than 10.15
        # more complicated and risky on 11 and newer due to signed system volume (ssv)
		echo ''
	    echo "this script is only compatible with macos 10.15 exiting..."
	    echo ''
	    exit
    else
        # macos versions 10.15
        # in 10.15 /System default gets mounted read-only
        # can only be mounted read/write with according SIP settings
        sudo mount -uw /
        # stays mounted rw until next reboot
        sleep 0.5
    fi

    # deleting old installed certificate
    if [[ $(security find-certificate -a -c "$CERTIFICATE_NAME" "$KEYCHAIN") != "" ]]
    then
        #CERT_SHA1=$(security find-certificate -c "$CERTIFICATE_NAME" -a -Z "$KEYCHAIN" | awk '/SHA-1/{print $NF}')
        #sudo security delete-certificate -Z "$CERT_SHA1" "$KEYCHAIN"
        sudo security delete-certificate -c "$CERTIFICATE_NAME" "$KEYCHAIN"
    else
        :
    fi
    
    # downloading new certificate
    if [[ -e /tmp/"$CERTIFICATE_NAME".crt ]]
    then
        rm -f /tmp/"$CERTIFICATE_NAME".crt
    else
        :
    fi
    echo quit | openssl s_client -showcerts -servername "$SERVER_NAME" -connect "$SERVER_LOCAL":443 2>/dev/null > /tmp/"$CERTIFICATE_NAME".crt

    # add certificate to keychain and trust all
    #sudo security add-trusted-cert -d -r trustAsRoot -k "$KEYCHAIN" "/Users/$USER/Desktop/cacert.pem"

    # add certificate to keychain and no value set
    #sudo security add-trusted-cert -r trustAsRoot -k "$KEYCHAIN" "/Users/$USER/Desktop/cacert.pem"
    
    # add certificate to keychain and trust ssl
    if [[ "$KEYCHAIN" == "$KEYCHAIN_SYSTEM" ]]
    then
        # needed for generally trusting the certificate and connecting via ip
        sudo security add-trusted-cert -d -r trustAsRoot -p ssl -e hostnameMismatch -k "$KEYCHAIN" /tmp/"$CERTIFICATE_NAME".crt
    elif [[ "$KEYCHAIN" == "$KEYCHAIN_USER" ]]
    then
        # needed for connecting via name.local
        # this seems to be just a warning: SecTrustSettingsSetTrustSettings: One or more parameters passed to a function were not valid.
        sudo security add-trusted-cert -d -r trustRoot -p ssl -e hostnameMismatch -k "$KEYCHAIN_USER" /tmp/"$CERTIFICATE_NAME".crt 2>&1 | grep -v "parameters passed to a function"
    else
        :
    fi
    
    # checking that certificate is installed, not untrusted and matches the domain
    # exporting certificate
    security find-certificate -a -p -c "$CERTIFICATE_NAME" "$KEYCHAIN" > /tmp/local_"$CERTIFICATE_NAME".pem
    if [[ $(security verify-cert -r /tmp/local_"$CERTIFICATE_NAME".pem -p ssl -s "$CERTIFICATE_NAME" | grep "successful") != "" ]]
    then
        printf '%-15s %-40s\n' "check" "the certificate is installed, trusted and working..."       
    else
        printf '%-15s %-40s\n' "check"  "there seems to be a problem with the installation of the certificate..."      
    fi

}

check_weekday() {
    # checking if it is needed to check the certificates by weekday
    if [[ "$(LANG=en_US date +%A)" != "Thursday" ]]
    then
        echo "it's not thursday, no need to check certificates..."
        echo "exiting script..."
        exit
    else
        :
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


### script
create_logfile
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
wait_for_loggedinuser
wait_for_network_select
# run before main function, e.g. for time format

cert_check() {

    setting_config
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config
    
    
    ### script
	certificate_variable_check

    #check_weekday
    
    # checking homebrew and script dependencies
    if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
    then
    	# installed
        echo "homebrew is installed..."
        # checking for missing dependencies
        for formula in openssl@1.1
        #for formula in 123
        do
        	if [[ $(sudo -H -u "$loggedInUser" brew list --formula | grep "^$formula$") == '' ]]
        	then
        		#echo """$formula"" is NOT installed..."
        		MISSING_SCRIPT_DEPENDENCY="yes"
        		osascript -e 'tell app "System Events" to display dialog "the script cert_install_update.sh needs '$formula' to be installed via homebrew..."'
        	else
        		#echo """$formula"" is installed..."
        		:
        	fi
        done
        if [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
        then
            echo "at least one needed homebrew tool is missing, exiting..."
            exit
        else
            echo "needed homebrew tools are installed..."   
        fi
        unset MISSING_SCRIPT_DEPENDENCY
    else
        # not installed
        echo "homebrew is not installed, exiting..."
        exit
    fi
    
      
    for i in "${CERTIFICATES_TO_INSTALL[@]}"
    do
    
        SERVER_LOCAL=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        SERVER_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        CERTIFICATE_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        #echo "LOCAL_SERVER is "$SERVER_LOCAL""
        #echo "CERTIFICATE_NAME is "$CERTIFICATE_NAME""
        
        echo ''
        #echo "checking"
        printf '%-15s %-40s\n' "server" "$SERVER_LOCAL"
        printf '%-15s %-40s\n' "servername" "$SERVER_NAME"
        printf '%-15s %-40s\n' "certificate" "$CERTIFICATE_NAME"
        
        if [[ $(echo "$SERVER_NAME" | grep "^FILL_IN_*") != "" ]] || [[ $(echo "$SERVER_LOCAL" | grep "^FILL_IN_*") != "" ]] || [[ $(echo "$CERTIFICATE_NAME" | grep "^FILL_IN_*") != "" ]]
        then
            echo "at least one variable is not set correctly, skipping..."
            continue
        else
            :
        fi
    
        # checking if online
        ping -c5 "$SERVER_LOCAL" >/dev/null 2>&1
        if [[ "$?" = 0 ]]
        then
            printf '%-15s %-40s\n' "availability" "server found, checking certificates..."
        else
            printf '%-15s %-40s\n' "availability" "server not found, waiting 10s for next try..."
            sleep 10
            ping -c5 "$SERVER_LOCAL" >/dev/null 2>&1
            if [[ "$?" = 0 ]]
            then
                printf '%-15s %-40s\n' "availability" "server found, checking certificates..."
            else
                printf '%-15s %-40s\n' "availability" "server not found, skipping..."
                #echo ''
                continue
            fi
        fi

        # server cert in pem format
        if [[ -e /tmp/server_"$CERTIFICATE_NAME".pem ]]
        then
            rm -f /tmp/server_"$CERTIFICATE_NAME".pem
        else
            :
        fi
        
        SERVER_CERT_PEM=$(echo quit | openssl s_client -servername "$SERVER_NAME" -connect "$SERVER_LOCAL":443 2>/dev/null | openssl x509) &> /dev/null
        if [[ "$?" -eq 0 ]]
        then
        
            for KEYCHAIN in "$KEYCHAIN_SYSTEM" "$KEYCHAIN_USER"
            do
                printf '%-15s %-40s\n' "keychain" "$KEYCHAIN"
                
                # checking if certificate is installed
                if [[ $(security find-certificate -a -c "$CERTIFICATE_NAME" "$KEYCHAIN") == "" ]]
                then
                    printf '%-15s %-40s\n' "status" "certificate not found, installing..."
                    install_update_certificate
                else
                    :
                fi
                
                # local cert in pem format
                if [[ -e /tmp/local_"$CERTIFICATE_NAME".pem ]]
                then
                    rm -f /tmp/local_"$CERTIFICATE_NAME".pem
                else
                    :
                fi
                LOCAL_CERT_PEM=$(security find-certificate -a -p -c "$CERTIFICATE_NAME" "$KEYCHAIN")
                #security find-certificate -a -p -c "$CERTIFICATE_NAME" "$KEYCHAIN" > /tmp/local_"$CERTIFICATE_NAME".pem
                #LOCAL_CERT_PEM=$(cat /tmp/local_"$CERTIFICATE_NAME".pem)
        
                # checking if update needed
                if [[ "$SERVER_CERT_PEM" == "$LOCAL_CERT_PEM" ]]
                then
                    printf '%-15s %-40s\n' "update" "server and local certificate match, no need to update..."
                else
                    printf '%-15s %-40s\n' "update" "server and local certificate do not match, updating..."
                    install_update_certificate
                fi
            done
            
            # cleaning up
            if [[ -e /tmp/"$CERTIFICATE_NAME".crt ]]
            then
                rm -f /tmp/"$CERTIFICATE_NAME".crt
            else
                :
            fi
            if [[ -e /tmp/server_"$CERTIFICATE_NAME".pem ]]
            then
                rm -f /tmp/server_"$CERTIFICATE_NAME".pem
            else
                :
            fi
            if [[ -e /tmp/local_"$CERTIFICATE_NAME".pem ]]
            then
                rm -f /tmp/local_"$CERTIFICATE_NAME".pem
            else
                :
            fi
        else
            printf '%-15s %-40s\n' "status" "certificate could not be loaded from server, skipping..."
        fi
    done
    
    echo ''
    echo "done ;)"
    echo ''
    
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    ( cert_check )
else
    time ( cert_check )
fi

echo ''


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
