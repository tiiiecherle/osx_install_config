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
SERVICE_NAME=com.run_on.shutdown
SCRIPT_INSTALL_NAME=run_on_shutdown


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
        echo "not online after "$WAIT_TIME"s, exiting..."
        exit
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
wait_for_loggedinuser
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
# only if needed
#wait_for_network_select
#wait_for_getting_online
# run before main function, e.g. for time format
setting_config

run_on_boot() {
        
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    ### script
	#echo "running as root ;)"
	
    echo "run_on_boot was run `date`..."
    tail -f /dev/null &
    wait $!
}


run_on_shutdown() {
    # run on shutdown
    
    ### getting the starttime
	local STARTTIME=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
	echo ''
	echo "run_on_shutdown was run `date`..."
	
	### all commands to run before shutdown
	# see important information below
	
	#sleep 1.5
	
    # getting sum of number of reboots and shutdowns since installation
    NUM1=$(last reboot | grep reboot | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    #echo $NUM1
    NUM2=$(last shutdown | grep shutdown | wc -l | sed 's/ //g')
    #echo $NUM2
    NUM3=$((NUM1+NUM2))
    #echo $NUM3
    
    # cleaning function1
    run_cleaning1 () {
    	
    	echo "running cleaning function 1..."
    	
    	# cleaning safari
    	if [[ $(find /Users/"$loggedInUser"/Library/Safari -mindepth 1 -maxdepth 1 -name "History.db*") != "" ]]
    	then
    		sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/History.db*
    	else
    		:
    	fi
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/LastSession.plist
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/Downloads.plist
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/KnownSitesUsingPlugIns.plist
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/TopSites.plist
    	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Safari/LocalStorage
    	#find /Users/"$loggedInUser"/Library/Safari/LocalStorage/* -type f -not -name "*.nba.*" -print0 | xargs -0 rm -f
    	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Safari/Databases
    	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Safari/Favicon Cache"
    	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Safari/Template Icons"
    	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Safari/Touch Icons Cache"
    	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Caches
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Cookies/com.apple.Safari.SearchHelper.binarycookies
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/com.apple.Safari.SearchHelper.binarycookies
    	
    	# cookies moved to run_cleaning2
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Cookies/HSTS.plist
    	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/HSTS.plist
    	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Preferences/Macromedia/Flash Player/"
    	
    	# cleaning firefox storage
    	FIREFOX_PROFILE_PATH=$(find "/Users/""$loggedInUser""/Library/Application Support/Firefox/" -name "*.default*")
    	FIREFOX_PREFERENCES="/Users/"$loggedInUser"/Library/Application Support/Firefox/"
    	if [[ -e "$FIREFOX_PROFILE_PATH" ]]
    	then 		
    		cd "$FIREFOX_PROFILE_PATH"/storage
    		ls -1 "$FIREFOX_PROFILE_PATH"/storage | \
    		grep -v default | \
    		xargs sudo -H -u "$loggedInUser" rm -rf
    		cd - >/dev/null 2>&1
    		
    		cd "$FIREFOX_PROFILE_PATH"/storage/default
    		ls -1 "$FIREFOX_PROFILE_PATH"/storage/default | \
    		grep -v moz-extension+++ | \
    		xargs sudo -H -u "$loggedInUser" rm -rf
    		cd - >/dev/null 2>&1
    	else
    		:
    	fi
    	
    	# cleaning progressive downloader
    	PSD_INSTALLATION=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin / | grep -i "/Progressive Downloader.app$")
    	if [[ "$PSD_INSTALLATION" != "" ]] && [[ -e "$PSD_INSTALLATION" ]]
    	then
    		sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Application Support/Progressive Downloader Data"
    		# has to be run as user (sudo -H -u "$loggedInUser") or permissions would change and file would no longer work
    		if [[ -e /Users/"$loggedInUser"/Library/Preferences/com.PS.PSD.plist ]]
    		then
    			if [[ $(defaults read /Users/"$loggedInUser"/Library/Preferences/com.PS.PSD.plist | grep psDownloadedBytes) != "" ]]
    			then
    				#echo "deleting entry..."
    				sudo -H -u "$loggedInUser" defaults delete /Users/"$loggedInUser"/Library/Preferences/com.PS.PSD.plist psDownloadedBytes
    			else
    				:
    			fi
    		else
    			:
    		fi
    	else
    		:
    	fi
    
    }
    
    # cleaning function2
    run_cleaning2 () {
    	
    	echo "running cleaning function 2..."
    	
    	# cleaning caches
    	# do not clean /System/Library/Caches/* as it leads to not opening third party system settings panes
    	# can be solved by installing the latest combo update afterwards
    	#rm -rf /System/Library/Caches/*
    	rm -rf /Library/Caches/*
    	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Caches/*
    	
    	# safari cookies
    	#sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Cookies/Cookies.binarycookies
    	#sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies
    	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Cookies/
    	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/*
    
    	# restoring basic cookies
    	# deprecated, use super agent browser extension instead
    	restore_basic_cookies() {
    		if [[ -e /Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies ]]
    		then
    			sudo -H -u "$loggedInUser" mkdir -p /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/
    			sudo -H -u "$loggedInUser" cp -a /Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies
    		else
    			:
    		fi
    	}
    	#restore_basic_cookies
    	
    	# cleaning dnscaches
    	dns_caches () {
    		dscacheutil -flushcache
    		killall -HUP mDNSResponder
    	}
    	dns_caches
    
    }
    
    reset_safari_download_location () {
    
        sudo -H -u "$loggedInUser" defaults write com.apple.Safari AlwaysPromptForDownloadFolder -bool false
        if [[ -d "/Users/"$loggedInUser"/Desktop/files" ]]
        then
            #sudo -H -u "$loggedInUser" mkdir -p "/Users/"$loggedInUser"/Desktop/files"
            #mkdir -p "~/Desktop/files"
            sudo -H -u "$loggedInUser" defaults write com.apple.Safari DownloadsPath -string "/Users/"$loggedInUser"/Desktop/files"
            #defaults write com.apple.Safari DownloadsPath -string "~/Desktop/files"
        else
            sudo -H -u "$loggedInUser" defaults write com.apple.Safari DownloadsPath -string "/Users/"$loggedInUser"/Downloads"
        fi
        
        # testing
        #echo "$loggedInUser" > /Users/"$loggedInUser"/Desktop/login_script.txt
            
    }
    
    deactivate_hidden_login_items_workaround () {
    # explanation see scripts 11c and 11k
    
    	ACTIVE_LOGIN_ITEMS=(
    	com.DigiDNA.iMazing2Mac.Mini.plist
    	com.adobe.ARMDCHelper.\*.plist
    	com.adobe.ARMDC.Communicator.plist
    	com.adobe.ARMDC.SMJobBlessHelper.plist
    	com.microsoft.teams.TeamsUpdaterDaemon.plist
    	#com.microsoft.update.agent
    	#com.microsoft.autoupdate.helper
    	com.google.keystone.agent.plist
    	com.google.keystone.xpcservice.plist
    	com.google.keystone.daemon.plist
    	org.xquartz.startx.plist
    	com.teamviewer.Helper.plist
    	com.teamviewer.UninstallerHelper.plist
    	com.teamviewer.UninstallerWatcher.plist
    	org.xquartz.privileged_startx.plist
    	)
    	ACTIVE_LOGIN_ITEMS_LIST=$(printf "%s\n" "${ACTIVE_LOGIN_ITEMS[@]}")
    
    	LOGIN_ITEMS_DIRECTORIES=(
    	/Library/LaunchAgents
    	/Library/LaunchDaemons
    	/Users/"$loggedInUser"/Library/LaunchAgents
    	)
    	LOGIN_ITEMS_DIRECTORIES_LIST=$(printf "%s\n" "${LOGIN_ITEMS_DIRECTORIES[@]}")
    	
    	while IFS= read -r line || [[ -n "$line" ]]
    	do
    		if [[ "$line" == "" ]]; then continue; fi
    		local LOGIN_ITEM="$line"
    		
    			while IFS= read -r line || [[ -n "$line" ]]
    			do
    				if [[ "$line" == "" ]]; then continue; fi
    				local LOGIN_ITEM_DIRECTORY="$line"
    				
    				LOGIN_ITEMS_PATH=
    				if [[ $(ls -1 "$LOGIN_ITEM_DIRECTORY" | grep "$LOGIN_ITEM") != "" ]]
    				then
    					LOGIN_ITEM_COMPLETE_PATH="$LOGIN_ITEM_DIRECTORY"/$(ls -1 "$LOGIN_ITEM_DIRECTORY" | grep "$LOGIN_ITEM")
    					#echo "$LOGIN_ITEM_COMPLETE_PATH"
    					if [[ -e "$LOGIN_ITEM_COMPLETE_PATH" ]]
    					then
    						echo ""$LOGIN_ITEM_COMPLETE_PATH" exists, deleting..."
    						rm -f "$LOGIN_ITEM_COMPLETE_PATH"
    					else	
    						:
    					fi
    				else
    					:
    				fi
    			done <<< "$(printf "%s\n" "${LOGIN_ITEMS_DIRECTORIES_LIST[@]}")"
    	done <<< "$(printf "%s\n" "${ACTIVE_LOGIN_ITEMS_LIST[@]}")"
    
    }
    
    DIVIDER=10
    # every reboot is counted as shutdown, too
    # using NUM3 would result in counting +2 on every boot
    if (( NUM1 % $DIVIDER == 0 ))
    then
        echo "number $NUM1 divisible by $DIVIDER"
        run_cleaning1
        run_cleaning2
    else
    	echo "number $NUM1 NOT divisible by $DIVIDER"
    	run_cleaning1
    fi
    
    sleep 0.1
    
    #reset_safari_download_location
    #sleep 0.1
    
    deactivate_hidden_login_items_workaround
    sleep 0.1
    
    # last reboot | grep reboot | wc -l | sed 's/ //g'
    # last shutdown | grep reboot | wc -l | sed 's/ //g'
	

	### getting the endtime
	local ENDTIME=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
	local ELAPSED_TIME_IN_MILLISECONDS=$(($ENDTIME - $STARTTIME))
	#echo $ELAPSED_TIME_IN_MILLISECONDS
	local ELAPSED_TIME_IN_SECONDS=$(echo "scale=2;$ELAPSED_TIME_IN_MILLISECONDS/1000" | bc)
	echo "run_on_shutdown took $(printf "%.2f\n" $ELAPSED_TIME_IN_SECONDS) seconds"
	
	### script done
	echo "done ;)"
	echo ''
	exit 0
}	


measure_time_for_shutdown_script() {

  sleep 1
  echo 1
  sleep 1
  echo 2
  sleep 1
  echo 3
  sleep 1
  echo 4
  sleep 1
  echo 5
  sleep 1
  echo 6
  sleep 1
  echo 7
  sleep 1
  echo 8
  sleep 1
  echo 9
  sleep 1
  echo 10
  echo ''
  echo "done ;)"
  echo ''
  exit 0
  
}


### important information
# Both hooks are deprecated and do not work anymore:

#sudo defaults write com.apple.loginwindow LogoutHook /Users/"$USER"/Library/Scripts/run_on_logout.sh
#sudo defaults write com.apple.loginwindow LoginHook /Users/"$USER"/Library/Scripts/run_on_login.sh

# It is recommended to use launchd instead.
# As of 2023-09 launchd offers a run on boot option (RunAtLoad) but no options for run before shutdown, run on login or run before logout.
# This is an example workaround script for run before shutdown.
# IMPORTANT
# This script can not delay the shutdown progress and is killed by macos after a certain amount of time during the shutdown. Using macos 14 and a macbook pro the script has about 4 seconds to finish before it gets terminated. 
# For testing measuring the time before the script gets terminated by macos uncomment this line
# trap measure_time_for_shutdown_script SIGINT SIGHUP SIGTERM; run_on_boot
# reinstall the script and boot twice.
# The log can be found in the Console.app

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    trap 'run_on_shutdown' SIGINT SIGHUP SIGTERM; run_on_boot &
else
    # for testing measuring the time before the script gets terminated by macos
    #trap measure_time_for_shutdown_script SIGINT SIGHUP SIGTERM; run_on_boot
    # running the script
    trap 'run_on_shutdown' SIGINT SIGHUP SIGTERM; run_on_boot
fi
echo ''

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
