#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### compatibility
###

# macos 10.14 only
if [[ "$MACOS_VERSION_MAJOR" != "10.14" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.14, exiting..."
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
echo ''

# attention, this script will delete all locally stored contacts, calendars and reminders
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
		# reminders are also stored inside the calendars folder
		
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
		
		
		### cleaning contacs directory
		if [[ -e "$PATH_TO_CONTACTS"/ ]]
		then
			echo "cleaning contacts directory..."
			rm -rf "$PATH_TO_CONTACTS"/*
			echo ''
		else
			:
		fi
		
		
		### identifying week numbers and holidays calendar
		# holiday calendar
		CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep ".*.calendar$")"
		unset HOLIDAY_CALENDAR
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    i="$line"
			#echo $i
			if [[ -e "$PATH_TO_CALENDARS"/"$i"/Info.plist ]]
			then
				CALENDAR_TO_LOOK_FOR="Feiertage"
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$i"/Info.plist) != "$CALENDAR_TO_LOOK_FOR" ]]
				then
					:
				else
					HOLIDAY_CALENDAR="$i"
				fi
			else
				:
			fi
		done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"
		if [[ "$HOLIDAY_CALENDAR" != "" ]]
		then
			echo "holiday calendar is ""$HOLIDAY_CALENDAR"""
		else
			echo "holiday calendar not found..."
			#echo "exiting script..."
			#exit
		fi
		#echo ''
		
		# week number calendar
		CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep ".*.calendar$")"
		unset WEEK_NUMBER_CALENDAR
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    i="$line"
			#echo $i
			if [[ -e "$PATH_TO_CALENDARS"/"$i"/Info.plist ]]
			then
				CALENDAR_TO_LOOK_FOR="KWs"
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$i"/Info.plist) != "$CALENDAR_TO_LOOK_FOR" ]]
				then
					:
				else
					WEEK_NUMBER_CALENDAR="$i"
				fi
			else
				:
			fi
		done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"
		if [[ "$WEEK_NUMBER_CALENDAR" != "" ]]
		then
			echo "week number calendar is ""$WEEK_NUMBER_CALENDAR"""
		else
			echo "week number calendar not found..."
			#echo "exiting script..."
			#exit
		fi
		#echo ''
		
		### backup week numbers and holidays calendar
		echo "backing up holiday and week number calendar..."
		if [[ "$HOLIDAY_CALENDAR" != "" ]]
		then
			cp -a "$PATH_TO_CALENDARS"/"$HOLIDAY_CALENDAR" /tmp/
		else
			:
		fi
		if [[ "$WEEK_NUMBER_CALENDAR" != "" ]]
		then
			cp -a "$PATH_TO_CALENDARS"/"$WEEK_NUMBER_CALENDAR" /tmp/
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
		
		### restore week numbers and holidays calendar
		echo "restoring holiday and week number calendar..."
		if [[ "$HOLIDAY_CALENDAR" != "" ]]
		then
			cp -a /tmp/"$HOLIDAY_CALENDAR" "$PATH_TO_CALENDARS"/
		else
			:
		fi
		if [[ "$WEEK_NUMBER_CALENDAR" != "" ]]
		then
			cp -a /tmp/"$WEEK_NUMBER_CALENDAR" "$PATH_TO_CALENDARS"/
		else
			:
		fi
		
		### making sure changes take effect
		echo ''
		echo "restarting calendar and reminder services..."
		#osascript -e 'tell application "System Events" to log out'
		killall Calendar &> /dev/null
		#killall CalendarAgent
		#killall remindd
		# launchctl list
		launchctl unload /System/Library/LaunchAgents/com.apple.CalendarAgent.plist 2>&1 | grep -v "in progress"
		sleep 2
		launchctl load /System/Library/LaunchAgents/com.apple.CalendarAgent.plist
		

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
