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

opening_calendar_in_background() {
	echo ''
	echo "opening calendar in background..."
	osascript <<EOF	
			tell application "Calendar"
				run
			end tell	
			delay 3
EOF
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

deleting_cache() {
	echo ''
	echo "cleaning caches..."
	for CACHE_ENTRY in "com.apple.dataaccess.dataaccessd" "com.apple.remindd" "com.apple.AppleMediaServices"
		do
		if [[ -e "$CACHE_ENTRY" ]]
		then
			rm -rf /Users/"$USER"/Library/Caches/"$CACHE_ENTRY"/
		else
			:
		fi
	done
}



###
### converting all calendars to new format
###

convert_calendars_to_sqlite() {
	if [[ "$MACOS_VERSION_MAJOR" == "13" ]]
	then
		
		STOP_CALENDAR_REMINDER_SERVICES="yes" env_stopping_services
		START_CALENDAR_REMINDER_SERVICES="yes" env_starting_services
		
		#opening_calendar
		
		# waiting for conversation
		WAITING_TIME=30
		NUM1=0
		echo '' && echo ''
		while [[ "$NUM1" -le "$WAITING_TIME" ]]
		do 
			NUM1=$((NUM1+1))
			if [[ "$NUM1" -le "$WAITING_TIME" ]]
			then
				#echo "$NUM1"
				sleep 1
				tput cuu 1 && tput el
				echo "waiting $((WAITING_TIME-NUM1)) seconds to give macos time to convert calendars to new format..."
			else
				:
			fi
		done
		
		quitting_apps
		
	else
	    :
	fi
}
#convert_calendars_to_sqlite

if [[ "$MACOS_VERSION_MAJOR" == "13" ]]
then
	:
	#convert_calendars_to_sqlite
else
    :
fi



###
### backup calendar table from database to save subscriptions like week numbers and holidays
###

echo ''
echo "exporting subscription calendars..."

CALENDAR_DATABASE=/Users/"$USER"/Library/Calendars/Calendar.sqlitedb
BACKUP_CALENDAR_DATABASE=/Users/"$USER"/DESKTOP/backup_calendar.sqlitedb

if [[ -e "$BACKUP_CALENDAR_DATABASE" ]]
then
	rm -f "$BACKUP_CALENDAR_DATABASE"
else
	:
fi

# new empty database
sqlite3 "$BACKUP_CALENDAR_DATABASE" "VACUUM;"

# does not add complete entry row and therefore does not work
#sqlite3 "$BACKUP_CALENDAR_DATABASE" <<EOF
#ATTACH DATABASE "$CALENDAR_DATABASE" AS db2;
#CREATE TABLE Calendar AS SELECT * FROM db2.Calendar where title = "KWs";
#INSERT INTO Calendar SELECT * FROM db2.Calendar where title = "Feiertage in Deutschland";
#DETACH DATABASE db2;
#EOF

# due to the upper solution not working import complete table and delete other entries
# this way the entries are complete
# backup calendar table
sqlite3 "$CALENDAR_DATABASE" ".dump Calendar" | sqlite3 "$BACKUP_CALENDAR_DATABASE"

# keeping the caldav entries would lead to showing the account (with or without calendars) in the sidebar, but content would not be downloaded
#sqlite3 "$BACKUP_CALENDAR_DATABASE" 'DELETE from Calendar WHERE title != "KWs";'
sqlite3 "$BACKUP_CALENDAR_DATABASE" 'DELETE from Calendar WHERE title != "KWs" AND title != "Feiertage";'

# re-gaining free space
sqlite3 "$BACKUP_CALENDAR_DATABASE" "VACUUM;"

# show entries
echo ''
echo "restored subscriptions..."
sqlite3 "$BACKUP_CALENDAR_DATABASE" 'SELECT title from Calendar;'



###
### reset calendar, contacts & reminders
###

echo ''
echo "this script deletes all data (not app preferences plist files) from contacts, calendars and reminders. data will be restored from the respective servers..."

# attention, this script will delete all locally stored contacts, calendars and reminders
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    :
else
    echo ''
fi
VARIABLE_TO_CHECK="$CLEAR_LOCAL_DATA"
QUESTION_TO_ASK="do you really want to delete all locally stored contacts, calendars and reminders? (Y/n) "
env_ask_for_variable
CLEAR_LOCAL_DATA="$VARIABLE_TO_CHECK"

if [[ "$CLEAR_LOCAL_DATA" =~ ^(yes|y)$ ]]
then	
	# checking if online
	env_check_if_online
	if [[ "$ONLINE_STATUS" == "online" ]]
	then
    	# online
	    echo ''
	
	
		### variables
		PATH_TO_CALENDARS="/Users/"$USER"/Library/Calendars"
		CALENDAR_PREFERENCES_PLIST=/Users/"$USER"/Library/Preferences/com.apple.iCal.plist
		PATH_TO_CONTACTS="/Users/"$USER"/Library/Application Support/AddressBook"
		PATH_TO_REMINDERS="/Users/"$USER"/Library/Reminders"
		
		
		### quitting apps
		quitting_apps
		
		
		# without this there could be confusions when the system tries to sync while the files get deleted
		# this would lead to multiple new entries in the reminders and the calendars app 
		STOP_CALENDAR_REMINDER_SERVICES="yes" env_stopping_services
		echo ''

			
		### cleaning contacs directory
		if [[ -e "$PATH_TO_CONTACTS"/ ]]
		then
			echo "cleaning contacts directory..."
			rm -rf "$PATH_TO_CONTACTS"/*
			#echo ''
		else
			:
		fi
		
		
		### cleaning reminders directory
		if [[ -e "$PATH_TO_REMINDERS"/ ]]
		then
			echo "cleaning reminders directory..."
			rm -rf "$PATH_TO_REMINDERS"/*
			#echo ''
		else
			:
		fi
		
		
		### cleaning calendar directory
		if [[ -e "$PATH_TO_CALENDARS"/ ]]
		then
			echo "cleaning calendars directory..."
			rm -rf "$PATH_TO_CALENDARS"/*
			#echo ''
		else
			:
		fi
		
		
		### deleting cache
		deleting_cache
		
		
		### restoring calendar table from backup to restore subscriptions like week numbers and holidays
		# it takes some time after restarting the services for the subscriptions to appear in the sidebar as they only appear after finishing downloading all other calendar data
		
		echo ''
		echo "restoring subscription calendars..."
		#cp -a "$BACKUP_CALENDAR_DATABASE" "$CALENDAR_DATABASE"
		mv "$BACKUP_CALENDAR_DATABASE" "$CALENDAR_DATABASE"


		### tests and documentation
		#sqlite3 "/Users/"$USER"/Library/Calendars/Calendar.sqlitedb" 'SELECT * from Calendar where title = "KWs";'
		#sqlite3 "/Users/"$USER"/Library/Calendars/Calendar.sqlitedb" 'SELECT title from Calendar;'
		
		# read calendar table
		#sqlite3 "$CALENDAR_DATABASE" ".dump Calendar"
		
		# new empty database
		#sqlite3 "$CALENDAR_DATABASE" "VACUUM;"
		
		#sqlite3 "$BACKUP_CALENDAR_DATABASE" <<EOF
		#ATTACH DATABASE "$CALENDAR_DATABASE" AS db2;
		#CREATE TABLE Calendar AS SELECT * FROM db2.Calendar where title = "KWs";
		#INSERT INTO Calendar SELECT * FROM db2.Calendar where title = "Feiertage";
		#DETACH DATABASE db2;
		#EOF
		
		
		### preferences
		# display birthdays calendar
	    defaults write com.apple.iCal "display birthdays calendar" -bool true
    
    	# display holiday calendar
    	# does no longer work in 10.13, now done in 15a_applications_manual_preferences_open.sh by applescript
    	#defaults write com.apple.iCal "add holiday calendar" -bool false
		
		# show week numbers
    	defaults write com.apple.iCal "Show Week Numbers" -bool false
    	
    	#defaults read com.apple.iCal >/dev/null
    	
    	# file - new calendar subscription - local (on my mac) - paste link - change name - rest accept defaults
		# change color for calendar #CAABE4
		# holidays
		# https://p30-calendars.icloud.com/holidays/de_de.ics
		# or
		# https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics
		
		# file - new calendar subscription - local (on my mac) - paste link - change name - rest accept defaults
		# change color for calendar #CAABE4
		# week numbers
		# https://calendar.google.com/calendar/ical/e_2_de%23weeknum%40group.v.calendar.google.com/public/basic.ics
		
		# disable siri analytics, suggestions and learning
		# done in macos_preferences and separate script
		
		
		### starting services
		START_CALENDAR_REMINDER_SERVICES="yes" env_starting_services
		
		# this time has to be long enough to start downloading the calendars data
		# subscriptions will be available in the sibebar after all other downloads will have finished
		WAITING_TIME=10
		NUM1=0
		echo '' && echo ''
		while [[ "$NUM1" -le "$WAITING_TIME" ]]
		do 
			NUM1=$((NUM1+1))
			if [[ "$NUM1" -le "$WAITING_TIME" ]]
			then
				#echo "$NUM1"
				sleep 1
				tput cuu 1 && tput el
				echo "waiting $((WAITING_TIME-NUM1)) seconds to give macos time to start re-downloading calendar data..."
			else
				:
			fi
		done
		
		#opening_calendar_in_background
		#quitting_apps
		
		### starting services
		#STOP_CALENDAR_REMINDER_SERVICES="yes" env_stopping_services
		#START_CALENDAR_REMINDER_SERVICES="yes" env_starting_services
		
		
		### opening app
		#opening_calendar
		#echo ''
		#sleep 5
		#quitting_apps
		
		
		echo ''
		echo "done ;)"
		echo ''
	else
		# offline
	    echo "this would prevent restoring data, exiting..."
	    echo ''
	    exit
	fi
else
	:
	exit
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
