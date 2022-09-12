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
### compatibility
###

# specific macos version only
if [[ "$MACOS_VERSION_MAJOR" != "10.15" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.15, exiting..."
    echo ''
    exit
else
    :
fi



###
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile




###
### set calendar and reminder alarms
###

# checking if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    echo ''	
	
	### variables
	PATH_TO_CALENDARS=/Users/"$USER"/Library/Calendars

	env_identify_terminal

	### opening app
	opening_calendar() {
		echo ''
		echo "opening calendar..."
		osascript <<EOF	
				tell application "Calendar"
					launch
					#delay 3
					#activate
					#delay 3
				end tell
				
				delay 3
				
				tell application "Calendar"
					activate
				end tell
				
EOF
	}
	#opening_calendar
	
	waiting_and_quitting_calendar() {
		WAITING_TIME=20
		NUM1=0
		#echo ''
		echo ''
		while [[ "$NUM1" -le "$WAITING_TIME" ]]
		do 
			NUM1=$((NUM1+1))
			if [[ "$NUM1" -le "$WAITING_TIME" ]]
			then
				#echo "$NUM1"
				sleep 1
				tput cuu 1 && tput el
				echo "waiting $((WAITING_TIME-NUM1)) seconds to give the calendar time to download calendar entries..."
			else
				:
			fi
		done
	}
	#waiting_and_quitting_calendar
	
	### quitting calandar and contacts
	#echo ''
	echo "quitting calendar..."
	osascript <<EOF
	
		try
			tell application "Calendar"
				quit
			end tell
		end try
	
EOF
	#echo ''
	sleep 5
	
	
	### calendar notifications
	echo ''
	echo "setting calendar notifications..."
	
	#CALDAV_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep ".*.caldav$")"
	CALENDAR_DIRS=$(find "$PATH_TO_CALENDARS" -name "*.calendar")
	
	while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
	    i="$line"
		#echo $i
		if [[ -e "$i"/Info.plist ]]
		then

			ACCOUNT_DIR=$(dirname "$i")
			#echo "ACCOUNT_DIR is "$ACCOUNT_DIR""
			if [[ $(echo "$ACCOUNT_DIR" | grep ".*.caldav$") != "" ]]
			then
				if [[ -e "$ACCOUNT_DIR"/Info.plist ]]
				then
					ACCOUNT_TITLE=$(/usr/libexec/PlistBuddy -c 'Print Title' "$ACCOUNT_DIR"/Info.plist 2> /dev/null)
				else
					:
				fi
			else
				:
			fi
			#echo $i
			CALENDAR_TITLE=$(/usr/libexec/PlistBuddy -c 'Print Title' "$i"/Info.plist 2> /dev/null)
			#echo "CALENDAR_TITLE is "$CALENDAR_TITLE""
			
			# calender notifications
			#if [[ "$CALENDAR_TITLE" == "$USER" ]] || [[ "$CALENDAR_TITLE" == "allgemein" ]] || [[ "$CALENDAR_TITLE" == ""$USER"_privat" ]] || [[ "$CALENDAR_TITLE" == "Feiertage" ]]
			if [[ "$CALENDAR_TITLE" == ("$USER"|"allgemein"|""$USER"_privat"|"Feiertage"|"Geburtstage") ]]
			then
				#echo "enabling "$i"..."
				/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$i"/Info.plist
				/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$i"/Info.plist
			elif [[ "$CALENDAR_TITLE" == "service" ]] && [[ "$ENABLE_SERVICE_CALENDAR_NOTIFICATIONS" == "yes" ]]
			then
				#echo "$USER"
				#echo "enabling "$i"..."
				/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$i"/Info.plist
				/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$i"/Info.plist
			else
				#echo "disabling "$i"..."
				/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$i"/Info.plist
				/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool true" "$i"/Info.plist
			fi
			# activating entry
			#sleep 0.5
			#defaults read "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist &> /dev/null
			#sleep 0.5
			sleep 0.1
			
			# enable all reminder notifications
			IS_REMINDER=$(/usr/libexec/PlistBuddy -c 'Print TaskContainer' "$i"/Info.plist)
			#echo $IS_REMINDER
			if [[ "$IS_REMINDER" == "true" ]]
			then
				#echo "$CALENDAR_TITLE is a reminder..."
				#ENTRY_TYPE="reminder"
				ENTRY_TYPE="tasks"
				/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$i"/Info.plist
				/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$i"/Info.plist
			else
				#echo "$CALENDAR_TITLE is a calendar..."
				ENTRY_TYPE="calendar"
			fi
			
			sleep 0.1
			
			# results
			ALARM_SET_TO_OFF=$(/usr/libexec/PlistBuddy -c "Print :AlarmsDisabled" "$i"/Info.plist)
			if [[ $ALARM_SET_TO_OFF == "true" ]]
			then
				NOTIFICATION_STATUS="disabled"
			elif [[ $ALARM_SET_TO_OFF == "false" ]]
			then
				NOTIFICATION_STATUS="enabled"
			else
				NOTIFICATION_STATUS="undefined"
			fi
			
			CALENDAR_TITLE_PRINT=$(printf '%s\n' "$CALENDAR_TITLE" | awk -v len=23 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
			printf "%-24s %-24s %-14s %-14s\n" "$CALENDAR_TITLE_PRINT" "$ACCOUNT_TITLE" "$ENTRY_TYPE" "$NOTIFICATION_STATUS"
	
		else
			:
		fi
	done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"
	
	
	### disabling calendars
	echo ''
	#echo "disabling calendars..."
	while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
	    i="$line"
		#echo $i
		if [[ -e "$i"/Info.plist ]]
		then
		
			#echo $i
			CALENDAR_TITLE=$(/usr/libexec/PlistBuddy -c 'Print Title' "$i"/Info.plist 2> /dev/null)
			#echo "CALENDAR_TITLE is "$CALENDAR_TITLE""

			# disable calendar add-on
			if [[ "$CALENDAR_TITLE" == "add-on" ]]
			then
				CALENDAR_TO_DISABLE=$(/usr/libexec/PlistBuddy -c 'Print Key' "$i"/Info.plist)
				#echo "disabling calendar "$CALENDAR_TO_DISABLE"..."
				echo "disabling calendar "$CALENDAR_TITLE"..."
				/usr/libexec/PlistBuddy -c "Add :DisabledCalendars dict" /Users/"$USER"/Library/Preferences/com.apple.iCal.plist 2> /dev/null 
				/usr/libexec/PlistBuddy -c "Add :DisabledCalendars:MainWindow array" /Users/"$USER"/Library/Preferences/com.apple.iCal.plist 2> /dev/null
				/usr/libexec/PlistBuddy -c "Add :DisabledCalendars:MainWindow:'Item 0' string "$CALENDAR_TO_DISABLE"" /Users/"$USER"/Library/Preferences/com.apple.iCal.plist
				# activating entry
				defaults read /Users/"$USER"/Library/Preferences/com.apple.iCal.plist &> /dev/null
				#/usr/libexec/PlistBuddy -c "Set :DisabledCalendars:MainWindow:0 string "$CALENDAR_TO_DISABLE"" /Users/"$USER"/Library/Preferences/com.apple.iCal.plist
			else
				:
			fi
			
		else
			:
		fi
	done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"	
	
	
	### deleting cache
	deleting_cache() {
		echo ''
		echo "cleaning calendar cache..."
		while [[ $(find "$PATH_TO_CALENDARS"/* -type f -name "Calendar Cache*" -print) != "" ]]
		do 
			#rm -f "$PATH_TO_CALENDARS"/"Calendar Cache"*
			#find "$PATH_TO_CALENDARS"/* -type f -name "Calendar Cache*" -print
			find "$PATH_TO_CALENDARS"/* -type f -name "Calendar Cache*" -print0 | xargs -0 rm -f
			sleep 5
		done
	}
	
	
	### making sure changes take effect
	restart_service() {
		echo ''
		echo "stopping calendar agent..."
		#osascript -e 'tell application "System Events" to log out'
		killall Calendar &> /dev/null
		#killall CalendarAgent
		#killall remindd
		# launchctl list
		#launchctl unload /System/Library/LaunchAgents/com.apple.CalendarAgent.plist 2>&1 | grep -v "in progress"
		launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.CalendarAgent
		sleep 2
		# without this the changes will not take effect
		deleting_cache
		sleep 2
		echo ''
		echo "starting calendar agent..."
		#launchctl load /System/Library/LaunchAgents/com.apple.CalendarAgent.plist
		launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.CalendarAgent
		sleep 2
	}
	restart_service
	
	echo ''
	echo "color for holiday and week number calendar is #CAABE4"
	
	opening_calendar
	
	if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
	then
		WAITING_TIME=30
		NUM1=0
		#echo ''
		echo ''
		while [[ "$NUM1" -le "$WAITING_TIME" ]]
		do 
			NUM1=$((NUM1+1))
			if [[ "$NUM1" -le "$WAITING_TIME" ]]
			then
				#echo "$NUM1"
				sleep 1
				tput cuu 1 && tput el
				echo "waiting $((WAITING_TIME-NUM1)) seconds before quitting calendar..."
			else
				:
			fi
		done
	    osascript -e "tell application \"Calendar\" to quit"
	else  
		:
	fi

	echo ''
	echo "done ;)"
	echo ''
else
    echo "not online, this would prevent restoring cache and data - exiting script..."
	echo ''
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

