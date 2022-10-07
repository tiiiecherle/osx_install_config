#!/bin/zsh

### config file
# this script will not source the config file as it runs as root and does not ask for a password after installation
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }

# trap
trap "echo '' && echo 'stopping clamd and fswatch...' && echo '' && stop_if_running; exit" SIGHUP SIGINT SIGTERM
#trap "" EXIT

# text output
if [[ "$RUN_IN_TERMINAL_FROM_INSTALL_SCRIPT" == "yes" ]]
then
    bold_text=$(tput bold)
    red_text=$(tput setaf 1)
    green_text=$(tput setaf 2)
    blue_text=$(tput setaf 4)
    default_text=$(tput sgr0)
else
    # console log does not support tput text styles
    bold_text=""
    red_text=""
    green_text=""
    blue_text=""
    default_text=""
fi

# paths to applications
VERSION_TO_CHECK_AGAINST=10.14
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.14
    PATH_TO_SYSTEM_APPS="/Applications"
    PATH_TO_APPS="/Applications"
else
    # macos versions 10.15 and up
    PATH_TO_SYSTEM_APPS="/System/Applications"
    PATH_TO_APPS="/System/Volumes/Data/Applications"
fi


### checking root
if [[ $(id -u) -ne 0 ]]
then 
    echo "script is not run as root, exiting..."
    exit
else
    :
fi


### variables
SERVICE_NAME=com.clamav.monitor
SCRIPT_INSTALL_NAME=clamav_monitor

     
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
        sudo -H -u "$loggedInUser" open "$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_stopped.app
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

check_if_online() {
    PINGTARGET1=google.com
    PINGTARGET2=duckduckgo.com
    # check 1
    # ping -c 3 "$PINGTARGET1" >/dev/null 2>&1'
    # check 2
    # resolving dns (dig +short xxx 80 or resolveip -s xxx) even work when connection (e.g. dhcp) is established but security confirmation is required to go online, e.g. public wifis
    # during testing dig +short xxx 80 seemed more reliable to work within timeout
    # timeout 3 dig +short -4 "$PINGTARGET1" 80 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1'
    #
    echo ''
    echo "checking internet connection..."
    if [[ $(timeout 3 2>/dev/null dig +short -4 "$PINGTARGET1" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        if [[ $(timeout 3 2>/dev/null dig +short -4 "$PINGTARGET2" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
}

wait_for_getting_online() {
    ### waiting for getting online
    echo "checking internet connection..."
    NUM=0
    MAX_NUM=6
    SLEEP_TIME=6
    # waiting for getting online
    # around 4s for check_if_online + 6s = 10s per try
    check_if_online &>/dev/null
    while [[ "$ONLINE_STATUS" != "online" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
    do
        sleep "$SLEEP_TIME"
        check_if_online &>/dev/null
        NUM=$((NUM+1))
    done
    #echo ''
    WAIT_TIME=$((NUM*SLEEP_TIME))
    echo "waited "$WAIT_TIME"s for getting online..."
    if [[ "$ONLINE_STATUS" != "online" ]]
    then
        WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
        echo "not online after "$WAIT_TIME"s, continuing without updating the signatures..."
        #exit
    else
        echo "we are online..."
    fi
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
            echo "waiting for network select..."
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

check_homebrew() {
    # homebrew
    if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
    then
	    # installed
        echo ''
        echo "homebrew is installed..."
        # do not autoupdate homebrew
        export HOMEBREW_NO_AUTO_UPDATE=1
        export BREW_PATH_PREFIX=$(brew --prefix)
    else
        # not installed
        echo ''
        echo "homebrew is not installed, exiting..."
        sudo -H -u "$loggedInUser" open "$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_stopped.app
        exit
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

ownership_permissions_structure() {  
    
    ### directories and permissions
    # homebrew and installation
    HOMEBREW_PATH=$(sudo -H -u "$loggedInUser" brew --prefix)
    #echo "HOMEBREW_PATH is "$HOMEBREW_PATH""
    HOMEBREW_BIN_PATH=""$HOMEBREW_PATH"/bin"
    #echo "HOMEBREW_BIN_PATH is "$HOMEBREW_BIN_PATH""
    CUSTOM_SCAN_PROFILE=""$HOMEBREW_PATH"/etc/clamav/clamd_custom.conf"
    #echo "CUSTOM_SCAN_PROFILE is "$CUSTOM_SCAN_PROFILE""
    DIRNAME_CUSTOM_SCAN_PROFILE="$(dirname "$CUSTOM_SCAN_PROFILE")"
    LOCAL_SOCKET=""$HOMEBREW_PATH"/var/run/clamav/clamd.sock"
    
    # user and logging
    CLAMD_MONITOR_USER_DIR="/Users/"$loggedInUser"/Library/Application Support/clamav_monitor"
    CLAMD_MONITOR_QUARANTINE_DIR=""$CLAMD_MONITOR_USER_DIR"/quarantine"
    CLAMD_MONITOR_LOG_DIR=""$CLAMD_MONITOR_USER_DIR"/log"
    CLAMD_MONITOR_LOG=""$CLAMD_MONITOR_LOG_DIR"/clamav_monitor.log"
    
    # creating structure
    sudo -H -u "$loggedInUser" mkdir -p "$CLAMD_MONITOR_USER_DIR"
    sudo -H -u "$loggedInUser" mkdir -p "$CLAMD_MONITOR_QUARANTINE_DIR"
    sudo -H -u "$loggedInUser" mkdir -p "$CLAMD_MONITOR_LOG_DIR"
    sudo -H -u "$loggedInUser" touch "$CLAMD_MONITOR_LOG"
    sudo -H -u "$loggedInUser" echo '' >> "$CLAMD_MONITOR_LOG"
    sudo -H -u "$loggedInUser" echo "### $(date '+%Y-%m-%d %H:%M:%S')" >> "$CLAMD_MONITOR_LOG"
    sudo -H -u "$loggedInUser" mkdir -p "$CLAMD_MONITOR_QUARANTINE_DIR"
    
    # ownership and permissions
    sudo -H -u "$loggedInUser" find "$CLAMD_MONITOR_USER_DIR" -type d -print0 | xargs -0 -n100 sudo chmod 700
    sudo -H -u "$loggedInUser" find "$CLAMD_MONITOR_USER_DIR" -type f -print0 | xargs -0 -n100 sudo chmod 600
    sudo -H -u "$loggedInUser" chown -R "$loggedInUser":staff "$CLAMD_MONITOR_USER_DIR"
}
    
installation_and_configuration() {
    
    ### installation/update
    echo ''
    echo "${bold_text}formula installation...${default_text}"
    
    ### formula dependencies
    for FORMULA in clamav fswatch gnu-tar
    do
    	if sudo -H -u "$loggedInUser" command -v "$FORMULA" &> /dev/null
    	then
    	    # installed
    	    echo ""$FORMULA" is already installed..."
    	else
    		# not installed
    		if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
    		then
    		    # installed
    		    if [[ $(sudo -H -u "$loggedInUser" brew list --formula | grep "^$FORMULA$") == "" ]]
    		    then
    			    #echo ''
    				echo "installing missing dependency "$FORMULA"..."
    				sudo -H -u "$loggedInUser" brew install "$FORMULA"
    			else
    				echo ""$FORMULA" is already installed..."
    			fi
    		else
    			# not installed
    			echo ''
    			echo "homebrew is not installed, exiting..."
    			echo ''
    			sudo -H -u "$loggedInUser" open "$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_stopped.app
    			exit
    		fi
    	fi
    done
    
    
    ### clamav configuration
    #echo ''
    echo "clamav configuration..."
    
    if [[ -e "$HOMEBREW_PATH"/etc/clamav/freshclam.conf ]]
    then
    	# configured
    	:
    else
    	# not configured
    	sudo -H -u "$loggedInUser" cp -a "$HOMEBREW_PATH"/etc/clamav/freshclam.conf.sample "$HOMEBREW_PATH"/etc/clamav/freshclam.conf
    	sudo -H -u "$loggedInUser" sed -i '' 's/^Example/#Example/g' "$HOMEBREW_PATH"/etc/clamav/freshclam.conf
    	sudo -H -u "$loggedInUser" cp -a "$HOMEBREW_PATH"/etc/clamav/clamd.conf.sample "$HOMEBREW_PATH"/etc/clamav/clamd.conf
    	sudo -H -u "$loggedInUser" sed -i '' 's/^Example/#Example/g' "$HOMEBREW_PATH"/etc/clamav/clamd.conf
    	sudo -H -u "$loggedInUser" touch "$CUSTOM_SCAN_PROFILE"
    	sudo -H -u "$loggedInUser" chown "$loggedInUser":admin "$CUSTOM_SCAN_PROFILE"
    	sudo -H -u "$loggedInUser" chmod 644 "$CUSTOM_SCAN_PROFILE"
    	FRESH_INSTALL="yes"
    fi
    
    # make sure socket directory exists
    sudo -H -u "$loggedInUser" mkdir -p "$HOMEBREW_PATH"/var/run/clamav
    sudo chown "$loggedInUser":admin "$HOMEBREW_PATH"/var/run/clamav
    sudo chmod 755 "$HOMEBREW_PATH"/var/run/clamav
    
    # custom config file
    sudo -H -u "$loggedInUser" cat > "$CUSTOM_SCAN_PROFILE" << EOF
    LogTime yes
    TemporaryDirectory /tmp
    LocalSocket $LOCAL_SOCKET
    User clamav
    MaxDirectoryRecursion 50
    MaxRecursion 50
    MaxScanSize 0
    MaxFileSize 0
    MaxFiles 0
    BytecodeTimeout 30000
EOF
    
    
    ### unofficial sigs
    # https://github.com/extremeshok/clamav-unofficial-sigs
    # https://github.com/extremeshok/clamav-unofficial-sigs/blob/master/guides/macosx.md
    echo ''
    echo "${bold_text}unofficial sigs installation...${default_text}"
    
    if [[ -e ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh" ]]
    then
    	# installed
    	echo "clamav-unofficial-sigs.sh is already installed, upgrading..."
    else
    	# not installed
    	echo "installing clamav-unofficial-sigs.sh..."
    	FRESH_INSTALL="yes"
    fi
    
    DOWNLOAD_FILE=clamav-unofficial-sigs.sh
    sudo -H -u "$loggedInUser" curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh"
    if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, skipping..."; fi
    chmod 755  ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh"
    sudo -H -u "$loggedInUser" mkdir -p "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs
    chown "$loggedInUser":admin "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs
    DOWNLOAD_FILE=master.conf
    sudo -H -u "$loggedInUser" curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/master.conf
    if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, skipping..."; fi
    DOWNLOAD_FILE=os.macosx.conf
    sudo -H -u "$loggedInUser" curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.macosx.conf --output "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
    if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, skipping..."; fi
    DOWNLOAD_FILE=user.conf
    sudo -H -u "$loggedInUser" curl -s https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/user.conf
    if [[ $? -eq 0 ]]; then echo "successfully downloaded "$DOWNLOAD_FILE"..."; else echo "download of "$DOWNLOAD_FILE" unsuccessful, skipping..."; fi
    
    # configuration
    echo "unofficial sigs configuration..."
    sudo -H -u "$loggedInUser" sed -i '' 's|^clam_dbs=.*|clam_dbs="'"$HOMEBREW_PATH"'/var/homebrew/linked/clamav/share/clamav"|g' "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
    sudo -H -u "$loggedInUser" sed -i '' 's|^work_dir=.*|work_dir="'"$HOMEBREW_PATH"'/var/db/clamav-unofficial-sigs"|g' "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
    sudo -H -u "$loggedInUser" sed -i '' 's|^log_file_path=.*|log_file_path="'"$HOMEBREW_PATH"'/var/log"|g' "$HOMEBREW_PATH"/etc/clamav-unofficial-sigs/os.conf
    
    # fixing LinuxMalwareDetect Database File Updates
    # tar: Option --wildcards is not supported
    # Clamscan reports LinuxMalwareDetect rfxn.ndb database integrity tested BAD
    if sudo -H -u "$loggedInUser" command -v gtar &> /dev/null
    then
    	# installed
    	sudo -H -u "$loggedInUser" sed -i '' 's/command -v tar/command -v gtar/g' ""$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh"
    else
    	# not installed
    	:
    fi
}

update_signatures() {
    echo ''
    echo "${bold_text}updating official definitions...${default_text}"
    # does not provide output in terminal or logfile
    #freshclam
    #sudo -H -u "$loggedInUser" freshclam
    if [[ "$RUN_IN_TERMINAL_FROM_INSTALL_SCRIPT" == "yes" ]]
    then
        sudo -H -u "$loggedInUser" script -q /dev/null "$HOMEBREW_BIN_PATH"/freshclam
    else
        sudo -H -u "$loggedInUser" freshclam
    fi
    
    echo ''
    echo "${bold_text}updating unofficial definitions...${default_text}"
    # does not provide output in terminal or logfile
    #clamav-unofficial-sigs.sh --force
    #sudo -H -u "$loggedInUser" clamav-unofficial-sigs.sh --force
    if [[ "$FRESH_INSTALL" == "yes" ]]
    then
    	sudo -H -u "$loggedInUser" script -q /dev/null "$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh --force
    else
    	sudo -H -u "$loggedInUser" script -q /dev/null "$HOMEBREW_BIN_PATH"/clamav-unofficial-sigs.sh
    fi
}

stop_if_running() {
    for COMMAND in fswatch clamdscan clamd
    do
        #if [[ $(ps aux | grep -v grep | grep "$COMMAND") != "" ]]
        if [[ $(pgrep "$COMMAND") != "" ]]
        then
            killall -15 "$COMMAND" &>/dev/null
        else
            :
        fi
        NUM=0
        MAX_NUM=6
        SLEEP_TIME=1
        while [[ $(pgrep "$COMMAND") != "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
        do
            NUM=$((NUM+1))
            sleep "$SLEEP_TIME"
        done
        #if [[ $(ps aux | grep -v grep | grep "$COMMAND") != "" ]]
        if [[ $(pgrep "$COMMAND") != "" ]]
        then
            killall -9 "$COMMAND" &>/dev/null
        else
            :
        fi
        while [[ $(pgrep "$COMMAND") != "" ]]
        do
            sleep 1
        done
        sleep 1
    done
}


### script
create_logfile
wait_for_loggedinuser
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
echo ''
wait_for_network_select
echo ''
wait_for_getting_online
# run before main function, e.g. for time format

clamav_monitor() {

    setting_config
    
    ### loggedInUser
    #echo ''
    echo "loggedInUser is $loggedInUser..."
    #echo ''

    ### script
    ### stop commands if already running
    stop_if_running
        
    if [[ "$ONLINE_STATUS" == "online" ]]
    then
        # online
        ### homebrew
        check_homebrew
    else
        :
    fi
    
    ### ownership, permissions and directory structure
    ownership_permissions_structure
    
    if [[ "$ONLINE_STATUS" == "online" ]]
    then
       
        ### installation and configuration (as user)
        installation_and_configuration
    
        ### sigs update
        update_signatures
    else
        :
    fi
    
    ### monitoring and scanning
    BREW_PATH_PREFIX=$(brew --prefix)
    
    # directories to monitor
    MONITOR_DIRS=(
        "/Users/"$loggedInUser"/"
        "/System/Volumes/Data/Applications/"
        ""$BREW_PATH_PREFIX"/"
    )
    
    # directories to exclude from monitoring
    EXCLUDE_DIR_PATTERNS=(
        #"/clamav-[^/]*/test/" #leave test files alone
        #"^$HOME/Library/"
        "^/mnt/"
        "^/Users/"$loggedInUser"/.Trash/"
        "^/Users/"$loggedInUser"/virtualbox/"
        "^/Users/"$loggedInUser"/Desktop/clamav_scan_quarantine/"
        "^"$PATH_TO_APPS"/hosts_file_generator/"
        "^/Applications/hosts_file_generator/"
        "^"$PATH_TO_APPS"/Rambox.app"
        "^/Applications/Rambox.app"
        "^/Users/"$loggedInUser"/Library/Containers/com.adguard.safari.AdGuard/Data/Library/Application Support/AdGuardSafariApp/config.json"
        "^/Users/"$loggedInUser"/Library/Group Containers/UBF8T346G9.Office/User Content.localized/Queries/"
        "^"$BREW_PATH_PREFIX"/Caskroom/joplin/"
        "^/Users/"$loggedInUser"/Library/Caches/Homebrew/downloads/.*Joplin.*dmg"
        "^/Applications/Joplin.app"
    )
    
    # matching patterns to exclude from monitoring
    EXCLUDE_FILE_PATTERNS=(
        #'\.txt$'
        '\.001$'
        '\.download/.*'
        '/index\.spotlightV.*/journalAttr.*'
    )

    # starting clamd
    echo ''
    echo "${bold_text}starting clamd...${default_text}"
    sleep 1
    sudo -H -u "$loggedInUser" clamd --config-file="$CUSTOM_SCAN_PROFILE" &
    # waiting for clamd to start
    while [[ $(pgrep "clamd") == "" ]]
    do
        sleep 1
    done
    while [[ ! -e "$LOCAL_SOCKET" ]]
    do
        sleep 1
    done
    # avoiding socket errors on start
    sleep 10
    
    # starting fswatch
    echo ''
    echo "${bold_text}watching files with fswatch and clamd in...${default_text}"
    printf "%s\n" "${MONITOR_DIRS[@]}"
    echo ''
    
    # starting fswatch and scanning changed files in specified directories and excluding specified directories and patterns
    fswatch -E -e "$CLAMD_MONITOR_QUARANTINE_DIR" "${EXCLUDE_DIR_PATTERNS[@]/#/-e}" "${EXCLUDE_FILE_PATTERNS[@]/#/-e}" -e "$CLAMD_MONITOR_LOG" "${MONITOR_DIRS[@]}" | while read line;
    do
        # do not process empty lines
    	if [[ "$line" == "" ]]; then continue; fi
    	# do not process directories and check if file still exists
    	if [[ ! -f "$line" ]]; then continue; fi
    	# a lot of files were displayed twice, by checking if the same file was recognized twice in a very short time
    	if [[ "$LAST_LINE" == "" ]]
    	then
    	    :
    	else
        	END_TIME=$(date +%s)
        	END_TIME_MILLI=$(python3 -c "import time; print(int(time.time()*1000))")
        	ELAPSED=$(expr $END_TIME - $START_TIME)
        	ELAPSED_MILLI=$(expr $END_TIME_MILLI - $START_TIME_MILLI)
        fi
    	# lowest working ELAPSED_MILLI is 30
    	# if ELAPSED_MILLI is 50 or higher not all changes get registerd if saving fast in a row
    	if [[ "$line" == "$LAST_LINE" ]] && [[ "$ELAPSED_MILLI" -lt "45" ]]; then LAST_LINE="$line" && continue; fi
    	#echo ""$line" is a file ;)"
    	clamdscan -v --config-file="$CUSTOM_SCAN_PROFILE" --move="$CLAMD_MONITOR_QUARANTINE_DIR" --no-summary "$line" 1>/dev/null 2>&1 | grep -v "\: OK$" | grep -v "Can\'t access file" | grep -v "\: moved to \'"
    	# exit code from first command from pipe (bash & zsh compatible)
        # bash starts to count at 0 for first entry, zsh at 1
        exit_code_bash="${PIPESTATUS[0]}" exit_code_zsh="${pipestatus[1]}" exit_code_final=$?
        EXIT_CODE_TO_CHECK=$(echo $exit_code_bash $exit_code_zsh $exit_code_final | awk '{ print $1 }')
    	if [[ "$EXIT_CODE_TO_CHECK" == 1 ]]
    	then
    	      echo "$(date '+%Y-%m-%d %H:%M:%S')   "$line" is infected..."
    	      sudo -H -u "$loggedInUser" open "$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_found.app
    	else
    		#echo ""$line" is clean ;)"
    		:
    	fi
    	LAST_LINE="$line"
    	START_TIME=$(date +%s)
    	START_TIME_MILLI=$(python3 -c "import time; print(int(time.time()*1000))")
    	# avoiding socket errors
    	#sleep 0.1
    done >> "$CLAMD_MONITOR_LOG" 2>&1 &
    
    sleep 5
    
    # the script is supposed to "hold" here after starting fswatch as long as its running
    # due to the trap it stops fswatch and clamd on exit 
    while ps -p $(pgrep "clamd") &> /dev/null && ps -p $(pgrep "fswatch") &> /dev/null
    do
        sleep 5
    done
    
    if [[ "$RUN_IN_TERMINAL_FROM_INSTALL_SCRIPT" == "yes" ]]
    then
        :
    else
        #osascript -e 'tell app "System Events" to display dialog "at least one of the two needed commands clamd and fswatch stopped...
        #please see '"$LOGFILE"' for possible reasons..."'
        sudo -H -u "$loggedInUser" open "$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_stopped.app
    fi
	
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    time ( clamav_monitor )
else
    time ( clamav_monitor )
fi

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


### done
echo ''
echo "done ;)"
echo ''
