#!/bin/bash

echo ''
echo "this script deletes all data (not app preferences plist files) from contacts, calendars and reminders. data will be restored from the respective servers..."
echo ''

###
# attention, this script will delete all locally stored contacts, calendars and reminders
read -r -p "do you really want to delete all locally stored contacts, calendars and reminders? [y/N] " answer
response="$(echo "$answer" | tr '[:upper:]' '[:lower:]')"    # tolower
if [[ $response == "y" || $response == "yes" ]]
then
	
	echo ''
	
	# checking if online
	echo "checking internet connection..."
	ping -c 3 google.com > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
	    echo "we are online, running script..."
	    echo ''
	
		### variables
		PATH_TO_CALENDARS="/Users/""$USER""/Library/Calendars"
		PATH_TO_CONTACTS="/Users/""$USER""/Library/Application Support/AddressBook"
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
		CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep .*.calendar$)"
		HOLIDAY_CALENDAR=""
		for i in $CALENDAR_DIRS
		do
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
		done
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
		CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep .*.calendar$)"
		WEEK_NUMBER_CALENDAR=""
		for i in $CALENDAR_DIRS
		do
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
		done
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
		
		# logout needed
		echo ''
		echo "the changes need a logout to take effect"
		logout_command_line()
		{
		LOGOUT_TIMEOUT=30
		NUM1=0
		#echo ''
		echo 'press '"ctrl + c"' within '"$LOGOUT_TIMEOUT"' to stop logout...'
		echo ''
		while [[ "$NUM1" -le "$LOGOUT_TIMEOUT" ]]
		do 
			NUM1=$((NUM1+1))
			if [[ "$NUM1" -lt "$LOGOUT_TIMEOUT" ]]
			then
				#echo "$NUM1"
				sleep 1
				tput cuu 1 && tput el
				echo "$(($LOGOUT_TIMEOUT-NUM1)) seconds left until logout..."
			else
				echo "logging out..."
				osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout
				exit
			fi
		done
		}
		#logout_command_line
		
		osascript -e 'tell application "System Events" to log out'
		echo ''
		echo "done ;)"
		echo ''
	else
	    echo "not online, this would prevent restoring data - exiting script..."
	    echo ''
	fi
else
	:
	exit
fi
