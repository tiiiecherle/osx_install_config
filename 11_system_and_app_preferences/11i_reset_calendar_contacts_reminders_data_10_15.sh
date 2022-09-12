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
		PATH_TO_CONTACTS="/Users/"$USER"/Library/Application Support/AddressBook"
		PATH_TO_REMINDERS="/Users/"$USER"/Library/Reminders"
		
		### quitting calandar and contacts 
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
		echo ''
		sleep 2
		
		# without this there could be confusions when the system tries to sync while the files get deleted
		# this would lead to multiple new entries in the reminders and the calendars app 
		echo "stopping service agents..."
		launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.CalendarAgent
		launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.remindd
		echo ''
		
		### identifying holidays calendar
		#CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep ".*.calendar$")"
		CALENDAR_DIRS="$(find "$PATH_TO_CALENDARS" -mindepth 1 -maxdepth 2 -type d -name "*calendar")"
		#unset HOLIDAY_CALENDAR
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    i="$line"
			#echo $i
			if [[ -e "$i"/Info.plist ]]
			then
				CALENDAR_TO_LOOK_FOR="Feiertage"
				#/usr/libexec/PlistBuddy -c 'Print Title' "$i"/Info.plist
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$i"/Info.plist 2> /dev/null) != "$CALENDAR_TO_LOOK_FOR" ]]
				then
					:
				else
					HOLIDAY_CALENDAR="$i"
					#echo "$HOLIDAY_CALENDAR"
				fi
			else
				:
			fi
		done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"
		if [[ "$HOLIDAY_CALENDAR" != "" ]]
		then
			#echo "holiday calendar is ""$HOLIDAY_CALENDAR"""
			echo "backing up holiday calendar..."
			if [[ $(dirname "$HOLIDAY_CALENDAR" | grep ".caldav$") != "" ]]
			then
				HOLIDAY_CALENDAR_BACKUP="$(dirname "$HOLIDAY_CALENDAR")"
				HOLIDAY_CALENDAR_RESTORE=$(/usr/libexec/PlistBuddy -c 'Print Key' "$HOLIDAY_CALENDAR_BACKUP"/Info.plist).caldav
			else
				HOLIDAY_CALENDAR_BACKUP="$HOLIDAY_CALENDAR"
				HOLIDAY_CALENDAR_RESTORE=$(/usr/libexec/PlistBuddy -c 'Print Key' "$HOLIDAY_CALENDAR_BACKUP"/Info.plist).calendar
			fi
			cp -a "$HOLIDAY_CALENDAR_BACKUP" /tmp/
			#echo "HOLIDAY_CALENDAR_RESTORE is "$HOLIDAY_CALENDAR_RESTORE"..."
		else
			echo "holiday calendar not found..."
			#echo "exiting script..."
			#exit
		fi
		echo ''
		
		
		### identifying week number calendar
		#CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep ".*.calendar$")"
		CALENDAR_DIRS="$(find "$PATH_TO_CALENDARS" -mindepth 1 -maxdepth 2 -type d -name "*calendar")"
		#unset HOLIDAY_CALENDAR
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    i="$line"
			#echo $i
			if [[ -e "$i"/Info.plist ]]
			then
				CALENDAR_TO_LOOK_FOR="KWs"
				#/usr/libexec/PlistBuddy -c 'Print Title' "$i"/Info.plist
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$i"/Info.plist 2> /dev/null) != "$CALENDAR_TO_LOOK_FOR" ]]
				then
					:
				else
					WEEK_NUMBER_CALENDAR="$i"
					#echo "$WEEK_NUMBER_CALENDAR"
				fi
			else
				:
			fi
		done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"
		if [[ "$WEEK_NUMBER_CALENDAR" != "" ]]
		then
			#echo "week number calendar is ""$HOLIDAY_CALENDAR"""
			echo "backing up week number calendar..."
			if [[ $(dirname "$WEEK_NUMBER_CALENDAR" | grep ".caldav$") != "" ]]
			then
				WEEK_NUMBER_CALENDAR_BACKUP="$(dirname "$WEEK_NUMBER_CALENDAR")"
				WEEK_NUMBER_CALENDAR_RESTORE=$(/usr/libexec/PlistBuddy -c 'Print Key' "$WEEK_NUMBER_CALENDAR_BACKUP"/Info.plist).caldav
			else
				WEEK_NUMBER_CALENDAR_BACKUP="$WEEK_NUMBER_CALENDAR"
				WEEK_NUMBER_CALENDAR_RESTORE=$(/usr/libexec/PlistBuddy -c 'Print Key' "$WEEK_NUMBER_CALENDAR_BACKUP"/Info.plist).calendar
			fi
			cp -a "$WEEK_NUMBER_CALENDAR_BACKUP" /tmp/
			#echo "WEEK_NUMBER_CALENDAR_RESTORE is "$WEEK_NUMBER_CALENDAR_RESTORE"..."
		else
			echo "week number not found..."
			#echo "exiting script..."
			#exit
		fi
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
		
		
		### restore holidays calendar
		if [[ "$HOLIDAY_CALENDAR" != "" ]]
		then
			echo ''
			echo "restoring holiday calendar..."
			cp -a /tmp/"$HOLIDAY_CALENDAR_RESTORE" "$PATH_TO_CALENDARS"/
		else
			:
		fi
		
		
		### restore week numbers and holidays calendar
		if [[ "$WEEK_NUMBER_CALENDAR" != "" ]]
		then
			echo ''
			echo "restoring week number calendar..."
			cp -a /tmp/"$WEEK_NUMBER_CALENDAR_RESTORE" "$PATH_TO_CALENDARS"/
		else
			:
		fi
		
		
		### deleting cache
		deleting_cache() {
			echo ''
			echo "cleaning calendar cache..."
			# without this the changes will not take effect
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
			echo "stopping service agents..."
			#osascript -e 'tell application "System Events" to log out'
			killall Calendar &> /dev/null
			#killall CalendarAgent
			#killall remindd
			# launchctl list
			# already done at the beginnning of the script
			#launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.CalendarAgent
			#launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.remindd
			#sleep 2
			#deleting_cache
			sleep 2
			echo ''
			echo "starting service agents..."
			launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.CalendarAgent
			launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.remindd
			sleep 2
		}
		restart_service
		
		# this time has to be long enough to download the needed data or some preferences (e.g. setting notifications) will not work in the next script
		WAITING_TIME=90
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
				echo "waiting $((WAITING_TIME-NUM1)) seconds to give macos time to re-download calendar data..."
			else
				:
			fi
		done
		
		
		### enabling delegates
		enable_delegates() {
			# cache cleaning and restarting service has to be run after this to work
			echo ''
			echo "enabling delegates..."
			INFO_PLISTS=$(find "$PATH_TO_CALENDARS" -name "Info.plist" -mindepth 2 -maxdepth 2)
			# leaving DELEGATES_TO_ENABLE empty enables all delegates
			DELEGATES_TO_ENABLE=(
			""
			)
			while IFS= read -r line || [[ -n "$line" ]]
			do
		    	if [[ "$line" == "" ]]; then continue; fi
		    	i="$line"
				#echo $i
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Delegate' "$i" 2> /dev/null) == "true" ]]
				then
					#echo "yes"
					DELEGATE_IN_PLIST=$(/usr/libexec/PlistBuddy -c 'Print Title' "$i")
					if [[ "$DELEGATES_TO_ENABLE" == "" ]]
					then
						# enable all delegates
						/usr/libexec/PlistBuddy -c "Set :Enabled true" "$i"
						echo "enabled delegate "$DELEGATE_IN_PLIST"..."
					else
						# enable only specified delegates
						while IFS= read -r line || [[ -n "$line" ]]
						do
		    				if [[ "$line" == "" ]]; then continue; fi
		    				DELEGATE="$line"
							#echo $i	
							if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$i" 2> /dev/null) == "$DELEGATE" ]]
							then
								/usr/libexec/PlistBuddy -c "Set :Enabled true" "$i"
								echo "enabled delegate "$DELEGATE_IN_PLIST"..."
							else
								echo "disabled delegate "$DELEGATE_IN_PLIST"..."
							fi
						done <<< "$(printf "%s\n" "${DELEGATES_TO_ENABLE[@]}")"
					fi
				else
					#echo "no"
				fi
			done <<< "$(printf "%s\n" "${INFO_PLISTS[@]}")"
			deleting_cache
			restart_service
			
			# waiting for delegates to be loaded
			WAITING_TIME=45
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
					echo "waiting $((WAITING_TIME-NUM1)) seconds for the delegates to get loaded..."
				else
					:
				fi
			done
		}
		enable_delegates
		
		
		### enabling KWs and holiday calendar in preferences
		echo ''
		#echo "enabling KWs and holiday calendar in preferences..."
		echo "enabling birthday calendar in preferences..."
		# also done in system preferences script
		# display birthdays calendar
	    defaults write com.apple.iCal "display birthdays calendar" -bool true
    
    	# display holiday calendar
    	#defaults write com.apple.iCal "add holiday calendar" -bool false
		
		# show week numbers
    	#defaults write com.apple.iCal "Show Week Numbers" -bool false
    	
    	# file - new calendar abo - local - paste link
		# change color for calendar #CAABE4
		# holidays
		# https://p30-calendars.icloud.com/holidays/de_de.ics
		# or
		# https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics
		
		# week numbers
		# https://calendar.google.com/calendar/ical/e_2_de%23weeknum%40group.v.calendar.google.com/public/basic.ics
		
		# disable siri analytics, suggestions and learning
		# done in macos_preferences and separate script
		
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
					
					#tell application "Calendar"
					#	activate
					#end tell
					
EOF
		}
		opening_calendar
		
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
					echo "waiting $((WAITING_TIME-NUM1)) seconds to give the calendar time to sync and apply settings..."
				else
					:
				fi
			done
		}
		waiting_and_quitting_calendar
		
		# quitting calendar
		osascript <<EOF
		
			try
				tell application "Calendar"
					quit
				end tell
			end try
		
EOF

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

