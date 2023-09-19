#!/bin/zsh

### path to applications
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }


### paths to applications
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


### variables
SERVICE_NAME=com.reminders.set
SCRIPT_INSTALL_NAME=reminders


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
    LOGDIR=/Users/"$USER"/Library/Logs
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
            rm "$LOGFILE"
            touch "$LOGFILE"
            chmod 644 "$LOGFILE"
        fi
    else
            touch "$LOGFILE"
            chmod 644 "$LOGFILE"
    fi
    
    echo "" >> "$LOGFILE"
    echo $EXECTIME >> "$LOGFILE"
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
    if [[ -e /Library/LaunchDaemons/com.network.select.plist ]]
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

check_dnd_status_macos11() {
    DND_STATUS=$(plutil -extract dnd_prefs xml1 -o - /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist | xmllint --xpath "string(//data)" - | base64 --decode | plutil -convert xml1 - -o - | xmllint --xpath 'boolean(//key[text()="userPref"]/following-sibling::dict/key[text()="enabled"])' -)
}

enable_dnd_macos11() {
	defaults read /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist >/dev/null
    DND_HEX_DATA=$(plutil -extract dnd_prefs xml1 -o - /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist | xmllint --xpath "string(//data)" - | base64 --decode | plutil -convert xml1 - -o - | plutil -insert userPref -xml "
    <dict>
        <key>date</key>
        <date>$(date -u +"%Y-%m-%dT%H:%M:%SZ")</date>
        <key>enabled</key>
        <true/>
        <key>reason</key>
        <integer>1</integer>
    </dict> " - -o - | plutil -convert binary1 - -o - | xxd -p | tr -d '\n')
    defaults write com.apple.ncprefs.plist dnd_prefs -data "$DND_HEX_DATA"
    PROCESS_LIST=(
    #cfprefsd
    usernoted
    #NotificationCenter
    )
    while IFS= read -r line || [[ -n "$line" ]] 
	do
	    if [[ "$line" == "" ]]; then continue; fi
        i="$line"
        #echo "$i"
        if [[ $(ps aux | grep "$i" | grep -v grep | awk '{print $2;}') != "" ]]
        then
        	killall "$i" && sleep 0.1 && while [[ $(ps aux | grep "$i" | grep -v grep | awk '{print $2;}') == "" ]]; do sleep 0.5; done
		else
			:
		fi
    done <<< "$(printf "%s\n" "${PROCESS_LIST[@]}")"
    sleep 2
}

disable_dnd_macos11() {
	defaults read /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist >/dev/null
    DND_HEX_DATA=$(plutil -extract dnd_prefs xml1 -o - /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist | xmllint --xpath "string(//data)" - | base64 --decode | plutil -convert xml1 - -o - | plutil -remove userPref - -o - | plutil -convert binary1 - -o - | xxd -p | tr -d '\n')
    defaults write com.apple.ncprefs.plist dnd_prefs -data "$DND_HEX_DATA"
    PROCESS_LIST=(
    #cfprefsd
    usernoted
    #NotificationCenter
    )
    while IFS= read -r line || [[ -n "$line" ]] 
	do
	    if [[ "$line" == "" ]]; then continue; fi
        i="$line"
        #echo "$i"
        if [[ $(ps aux | grep "$i" | grep -v grep | awk '{print $2;}') != "" ]]
        then
        	killall "$i" && sleep 0.1 && while [[ $(ps aux | grep "$i" | grep -v grep | awk '{print $2;}') == "" ]]; do sleep 0.5; done
		else
			:
		fi
    done <<< "$(printf "%s\n" "${PROCESS_LIST[@]}")"
    sleep 2
}

check_dnd_status() {
	# check dnd state
	# 0 = off
	# 1 = on
	if [[ $(defaults read com.apple.controlcenter | grep "NSStatusItem Visible FocusModes") != "" ]]
	then
	    DND_STATUS=$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes")
	else
	    DND_STATUS=""
	fi
}

# enable dnd
enable_dnd() {
	echo "enabling dnd..."
	if [[ -e "/System/Applications/Shortcuts.app" ]] && [[ $(shortcuts list | grep -x "dnd-on") != "" ]] 
	then
		shortcuts run dnd-on
		sleep 1
		#defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes"
	else
		echo "shortcuts app or shortcuts name not found..."
	fi
}

disable_dnd() {
    echo "disabling dnd..."
	if [[ -e "/System/Applications/Shortcuts.app" ]] && [[ $(shortcuts list | grep -x "dnd-off") != "" ]] 
	then
		shortcuts run dnd-off
		sleep 1
		#defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes"
	else
		echo "shortcuts app or shortcuts name not found..."
	fi
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

reminders_notifications_and_update() {

    setting_config
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config
    
    
    
    ###
    ### sourcing config file
    ###
    
    if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
    
    
    
    ###
    ### update reminders
    ###
    
    update_reminders() {
    	#echo ''
    	echo "updating reminders..."
    		
    	VERSION_TO_CHECK_AGAINST=10.14
    	if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
    	then
    	    # macos versions until and including 10.14
    		launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.CalendarAgent
    	else
    	    # macos versions 10.15 and up
    	    
    	    if [[ "$RESTART_REMINDER_SERVICE" == "yes" ]]
            then
        		#launchctl bootout gui/"$(id -u "$USER")"/com.apple.remindd 2>&1 | grep -v "in progress" | grep -v "No such process"
        		#sleep 2
        		#launchctl enable gui/"$(id -u "$USER")"/com.apple.remindd
        		#launchctl bootstrap gui/"$(id -u "$USER")" "/System/Library/LaunchAgents/com.apple.remindd.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
        		#launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.remindd
        		#sleep 2
        		
        		#launchctl bootout gui/"$(id -u "$USER")"/com.apple.CalendarAgent 2>&1 | grep -v "in progress" | grep -v "No such process"
        		#sleep 2
        		#launchctl enable gui/"$(id -u "$USER")"/com.apple.CalendarAgent
        		#launchctl bootstrap gui/"$(id -u "$USER")" "/System/Library/LaunchAgents/com.apple.CalendarAgent.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
        		#sleep 2
        	else
        	    :
        	fi
    
    
    osascript <<EOF
    if application "Reminders" is running then
    	tell application "Reminders"
    		quit
    	end tell
    	tell application "Reminders"
    		run
    		delay 15
    	end tell
    else
    	tell application "Reminders"
    		run
    		delay 15
    		quit
    	end tell
    end if
EOF
    
    	fi
    	echo ''
    }
    
    
    
    ###
    ### apps notifications
    ###
    
    osascript <<EOF
    if application "Reminders" is running then
    	tell application "Reminders"
    		quit
    	end tell
    else
    	---
    end if
EOF
    
    
    if [[ "$APP_SETTING_CHANGED" == "yes" ]]
    then
    	:
    else
    	### enable
    	if [[ "$MACOS_VERSION_MAJOR" == "11" ]]
    	then
    	    # macos 11
        	APPLICATIONS_TO_SET_NOTIFICATIONS=(
        	"Reminders														        310911319"
        	)
    	elif [[ "$MACOS_VERSION_MAJOR" == "12" ]]
    	then
    	    # macos 12
        	APPLICATIONS_TO_SET_NOTIFICATIONS=(
        	"Reminders														        1921524055"
        	)
        elif VERSION_TO_CHECK_AGAINST=13; [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
        then
            # macos 13 and higher
        	APPLICATIONS_TO_SET_NOTIFICATIONS=(
        	"Reminders														        10511458647"
        	)
    	else
    	    :
    	fi

    	### setting notification preferences
    	CHECK_APPS_NOTIFICATIONS="yes" PRINT_NOTIFICATION_CHECK_TO_ERROR_LOG="no" env_set_check_apps_notifications
    	#echo "$CHECK_RESULT_EXPORT"
    	if [[ "$CHECK_RESULT_EXPORT" == "wrong" ]]
    	then
    		echo ''
    		echo "enabling app notifications..."
    		# disable dnd
            if [[ "$MACOS_VERSION_MAJOR" == "11" ]]
        	then
        	    # macos 11
        		check_dnd_status_macos11
        		if [[ "$DND_STATUS" == "true" ]]
        		then
        			echo "disabling dnd..."
                    disable_dnd_macos11
                else
                	:
                fi
        	elif [[ "$MACOS_VERSION_MAJOR" -ge "12" ]]
        	then
        		check_dnd_status
        		if [[ "$DND_STATUS" == "1" ]]
        		then
        			echo "disabling dnd..."
                    disable_dnd
                else
                	:
                fi
        	else
        	    :
        	fi
    	
            # usernoted gets killed in env_set_check_apps_notifications and ControlCenter after REMINDER_STATUS
            echo "enabling reminder notifications..."
            # enable reminder notifications
    		SLEEP_AFTER_RESTART_NOTIFICATION_CENTER="no" SET_APPS_NOTIFICATIONS="yes" PRINT_NOTIFICATION_CHECK_TO_ERROR_LOG="no" env_set_check_apps_notifications
    		APP_SETTING_CHANGED="yes"
    		REMINDER_STATUS="on"
    	else
    	    echo "app notifications already enabled..."
    	    echo ''
    		# make sure dnd is disabled
            if [[ "$MACOS_VERSION_MAJOR" == "11" ]]
        	then
        	    # macos 11
        		check_dnd_status_macos11
        		if [[ "$DND_STATUS" == "true" ]]
        		then
        			echo "disabling dnd..."
                    disable_dnd_macos11
                else
                	:
                fi
        	elif [[ "$MACOS_VERSION_MAJOR" -ge "12" ]]
        	then
        		check_dnd_status
        		if [[ "$DND_STATUS" == "1" ]]
        		then
        			echo "disabling dnd..."
                    disable_dnd
                else
                	:
                fi
        	else
        	    :
        	fi
    	fi
    fi
    
    
    ### update reminders
    #if [[ "$APP_SETTING_CHANGED" == "yes" ]] && [[ "$REMINDER_STATUS" == "on" ]]
    #then
    #	# update reminders and restart remindd
    #	update_reminders
    #else
    #	:
    #fi
    update_reminders
    
    
    ### display notification
    if [[ "$REMINDER_STATUS" == "on" ]]
    then
    	osascript -e 'display notification "on" with title "Reminders"'
    elif [[ "$REMINDER_STATUS" == "off" ]]
    then	
    	osascript -e 'display notification "off" with title "Reminders"'
    else
    	:
    fi
    
    # prevent from launching to early again without taking effect of notification center settings
    # 5s needed, already waited 2 after launchctl kickstart
    sleep 3
    
    
    # unsetting variables
    unset APP_SETTING_CHANGED

    
    #echo ''
    echo "done ;)"
    echo ''
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    ( reminders_notifications_and_update )
else
    time ( reminders_notifications_and_update )
    echo ''
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
