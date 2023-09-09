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
if [[ "$MACOS_VERSION_MAJOR" != "14" ]]
then
    echo ''
    echo "this script is only compatible with macos 14, exiting..."
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
### functions
###


opening_calendar() {
	echo ''
	echo "opening calendar..."
	osascript <<EOF	
			tell application "Calendar"
				launch
				delay 3
				#activate
				#delay 2
			end tell
			# do not use visible as it makes the window un-clickable
			#tell application "System Events" to tell process "Calendar" to set visible to true
			#delay 1
			tell application "System Events" to tell process "Calendar" to set frontmost to true
			delay 1
EOF
}

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

quitting_apps() {
	echo "quitting calendar, contacts and reminders..."
	osascript <<EOF
	
		try
			tell application "Calendar"
				quit
			end tell
		end try
		
		try
			tell application "Contacts"
				quit
			end tell
		end try
		
		try
			tell application "Reminders"
				quit
			end tell
		end try
	
EOF
	sleep 3
}



###
### variables
###

CALENDAR_DATABASE=/Users/"$USER"/Library/Calendars/Calendar.sqlitedb
CALENDAR_PREFERENCES_PLIST=/Users/"$USER"/Library/Preferences/com.apple.iCal.plist

# avoiding database locked errors
SQLITE_TIMEOUT="1000"
# all of these work
# PRAGMA busy_timeout outputs timeout value after executing, added grep -v after commands
#SQLITE_CMD=(sqlite3 -cmd ".timeout $SQLITE_TIMEOUT")
#SQLITE_CMD=(sqlite3 -cmd "PRAGMA busy_timeout=$SQLITE_TIMEOUT")
SQLITE_CMD=(sqlite3 -cmd ".timeout $SQLITE_TIMEOUT" -cmd "PRAGMA busy_timeout=$SQLITE_TIMEOUT")


###
### documentation
###

#sqlite3 "/Users/"$USER"/Library/Calendars/Calendar.sqlitedb"
#.tables
#.dump Calendar

# CREATE TABLE Calendar (ROWID INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER, title TEXT, flags INTEGER, color TEXT, symbolic_color_name TEXT, color_is_display INTEGER, type TEXT, supported_entity_types INTEGER, external_id TEXT, external_mod_tag TEXT, external_id_tag TEXT, external_rep BLOB, display_order INTEGER, UUID TEXT, shared_owner_name TEXT, shared_owner_address TEXT, sharing_status INTEGER, sharing_invitation_response INTEGER, published_URL TEXT, is_published INTEGER, invitation_status INTEGER, sync_token TEXT, self_identity_id INTEGER, self_identity_email TEXT, self_identity_phone_number TEXT, owner_identity_id INTEGER, owner_identity_email TEXT, owner_identity_phone_number TEXT, notes TEXT, bulk_requests BLOB, subcal_account_id TEXT, push_key TEXT, digest BLOB, refresh_date REAL, subscription_id TEXT, last_sync_start REAL, last_sync_end REAL, subcal_url TEXT, refresh_interval INTEGER, pubcal_account_id TEXT, error_id INTEGER, max_attendees INTEGER, last_sync_title TEXT, locale TEXT);

# notifications
# flags INTEGER
# 67584		mute notification
# 2048		allow notification
# sqlite3 "/Users/"$USER"/Library/Calendars/Calendar.sqlitedb" "SELECT * from Calendar;"

# set notifications
#sqlite3 "/Users/"$USER"/Library/Calendars/Calendar.sqlitedb" "UPDATE Calendar SET flags = '67584' where title = 'XYZ';"
#sqlite3 "/Users/"$USER"/Library/Calendars/Calendar.sqlitedb" "UPDATE Calendar SET flags = '2048' where title = 'XYZ';"


###
### set calendar and reminder alarms
###

# checking if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    echo ''
    
    env_identify_terminal

	
	### quitting apps
	quitting_apps
	
	
	### calendar notifications
	echo ''
	echo "setting calendar notifications..."
	
	CALENDARS=$("${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "SELECT rowid,title,external_id,external_mod_tag from Calendar;" | grep -v grep | grep -v '.*\..*@.*\..*' | grep -v "Found in Mail" | grep -v "Found in Natural Language" | grep -v "Facebook Birthdays" | grep -v "ServerDoesNotSupportCTags" | grep -v "\/inbox\/" | grep -v -x "$SQLITE_TIMEOUT")
	
	while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
	    i="$line"
		#echo $i
		
		CALENDAR_ID=$(echo "$line" | awk -F'[|]' '{print $1}')
		CALENDAR_TITLE=$(echo "$line" | awk -F'[|]' '{print $2}')
		#echo "CALENDAR_TITLE is "$CALENDAR_TITLE""
		
		if [[ "$CALENDAR_TITLE" == ("$USER"|"allgemein"|""$USER"_privat"|"Feiertage"|"Geburtstage") ]]
		then
			# notifications enabled
			"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET flags = '2048' WHERE rowid = '$CALENDAR_ID' AND title = '$CALENDAR_TITLE';" | grep -v -x "$SQLITE_TIMEOUT"
		elif [[ "$CALENDAR_TITLE" == "service" ]] && [[ "$ENABLE_SERVICE_CALENDAR_NOTIFICATIONS" == "yes" ]]
		then
			# notifications enabled if activated in profile
			"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET flags = '2048' WHERE rowid = '$CALENDAR_ID' AND title = '$CALENDAR_TITLE';" | grep -v -x "$SQLITE_TIMEOUT"
		else
			# notifications disabled
			"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET flags = '67584' WHERE rowid = '$CALENDAR_ID' AND title = '$CALENDAR_TITLE';" | grep -v -x "$SQLITE_TIMEOUT"
		fi
		
		#sleep 1
		
		# results
		NOTIFICATION_FLAGS=$("${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "SELECT flags FROM Calendar WHERE rowid = '$CALENDAR_ID' AND title = '$CALENDAR_TITLE';" | grep -v -x "$SQLITE_TIMEOUT")
		#echo "NOTIFICATION_FLAGS is "$NOTIFICATION_FLAGS""
		if [[ $NOTIFICATION_FLAGS == "2048" ]]
		then
			NOTIFICATION_STATUS="enabled"
		elif [[ $NOTIFICATION_FLAGS == "67584" ]]
		then
			NOTIFICATION_STATUS="disabled"
		else
			NOTIFICATION_STATUS="undefined"
		fi
		
		CALENDAR_TITLE_PRINT=$(printf '%s\n' "$CALENDAR_TITLE" | awk -v len=23 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
		printf "%-24s %-24s\n" "$CALENDAR_TITLE_PRINT" "$NOTIFICATION_STATUS"
		
		#sleep 1
	
	done <<< "$(printf "%s\n" "${CALENDARS[@]}")"
	
	
	### disabling calendars
	echo ''
	#echo "disabling calendars..."
	while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
	    i="$line"
		#echo $i

		CALENDAR_ID=$(echo "$line" | awk -F'[|]' '{print $1}')
		CALENDAR_TITLE=$(echo "$line" | awk -F'[|]' '{print $2}')
		#echo "CALENDAR_TITLE is "$CALENDAR_TITLE""

		# disable calendars
		if [[ "$CALENDAR_TITLE" == ("add-on"|"Deutsche Feiertage") ]]
		then
			CALENDAR_TO_DISABLE=$("${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "SELECT UUID FROM Calendar WHERE rowid = '$CALENDAR_ID' AND title = '$CALENDAR_TITLE';" | grep -v -x "$SQLITE_TIMEOUT")
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

	done <<< "$(printf "%s\n" "${CALENDARS[@]}")"
	
	
	### making sure changes take effect
	#STOP_CALENDAR_REMINDER_SERVICES="yes" env_stopping_services
	#START_CALENDAR_REMINDER_SERVICES="yes" env_starting_services
	
	
	### setting calendar colors
	#echo ''
	echo "setting color for holiday and week number calendar to #CAABE4"
	#sqlite3 "$CALENDAR_DATABASE" "SELECT color FROM Calendar WHERE title = 'KWs';"
	#sqlite3 "$CALENDAR_DATABASE" "SELECT symbolic_color_name FROM Calendar WHERE title = 'KWs';"
	
	"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET color = '#CAABE4' WHERE title = 'KWs';"  | grep -v -x "$SQLITE_TIMEOUT"
	"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET symbolic_color_name = 'custom' WHERE title = 'KWs';"  | grep -v -x "$SQLITE_TIMEOUT"
	"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET color = '#CAABE4' WHERE title = 'Feiertage';"  | grep -v -x "$SQLITE_TIMEOUT"
	"${SQLITE_CMD[@]}" "$CALENDAR_DATABASE" "UPDATE Calendar SET symbolic_color_name = 'custom' WHERE title = 'Feiertage';"  | grep -v -x "$SQLITE_TIMEOUT"
	
	sleep 1
	
	
	### openning app
	opening_and_closing_calendar_after_wait() {
		
		opening_calendar
		
		WAITING_TIME=10
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
    
    }
    #opening_and_closing_calendar_after_wait

	echo ''
	echo "done ;)"
	echo ''
else
    echo "not online, this would prevent restoring cache and data - exiting script..."
	echo ''
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

