#!/bin/bash

echo ''

# checking if online
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "we are online, running script..."
    echo ''
	   
	# checking for time logged in to give macos time to build the calendar cache
	#TIME_USER_IS_LOGGED_IN=$(w | grep console | grep -o '[0-9]\+' | tail -n1)
	# or
	# w | sed 1d | awk 'NR==1{for(i=1;i<=NF;i++)if($i~/IDLE/)f[n++]=i}{for(i=0;i<n;i++)printf"%s%s",i?" ":"",$f[i];print""}' | grep -o '[0-9]*' | sed '/^\s*$/d'
	# or
	# w | grep console | awk '{print $(NF-1)}'
	
	WAITING_TIME=60
	echo "waiting ""$WAITING_TIME"" seconds to give macos time to rebuild the calendar cache..."
	NUM1=0
	#echo ''
	echo ''
	while [[ "$NUM1" -le "$WAITING_TIME" ]]
	do 
		NUM1=$((NUM1+1))
		if [[ "$NUM1" -lt "$WAITING_TIME" ]]
		then
			#echo "$NUM1"
			sleep 1
			tput cuu 1 && tput el
			echo "$(($WAITING_TIME-NUM1)) seconds waiting..."
		else
			:
		fi
	done
	
	### variables
	PATH_TO_CALENDARS=/Users/"$USER"/Library/Calendars
	
	
	### opening app
	#echo "opening calendar..."
	#echo "please wait 10s for calendar to quit..." 
	#osascript <<EOF
	#	
	#		tell application "Calendar"
	#			launch
	#			#delay 3
	#			#activate
	#			#delay 3
	#		end tell
	#		
	#		delay 10
	#	
	#		try
	#			tell application "Calendar"
	#				quit
	#			end tell
	#		end try
	#	
#EOF
	
	
	### quitting calandar and contacts 
	echo "quitting calendar and contacts..."
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
	
EOF
	echo ''
	sleep 2
	
	
	### identify caldav directory
	# holiday calendar
	CALDAV_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep .*.caldav$)"
	CALDAV_CALENDAR=""
	for i in $CALDAV_DIRS
	do
		#echo $i
		if [[ -e "$PATH_TO_CALENDARS"/"$i"/Info.plist ]]
		then
			CALENDAR_TO_LOOK_FOR="gep_radicale"
			if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$i"/Info.plist) != "$CALENDAR_TO_LOOK_FOR" ]]
			then
				:
			else
				CALDAV_CALENDAR="$i"
			fi
		else
			:
		fi
	done
	if [[ "$CALDAV_CALENDAR" != "" ]]
	then
		echo "expected caldav is ""$CALDAV_CALENDAR"""
	else
		echo "expected caldav directory not found..."
		echo "perhaps waiting time above was to short for rebuilding calendar cache, please try again..."
		echo "exiting script..."
		exit
	fi
	echo ''
	
	if [[ $(echo "$CALDAV_CALENDAR") != "" ]]
	then
		CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/ | grep .*.calendar$)"
		for i in $CALENDAR_DIRS
		do
			#echo $i
			#ls "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/
			if [[ -e "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist ]]
			then
				#echo $i
				CALENDAR_TITLE=$(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
				#echo "$CALENDAR_TITLE"
				if [[ "$CALENDAR_TITLE" == "$USER" ]] || [[ "$CALENDAR_TITLE" == "allgemein" ]]
				then
					/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
				else
					if [[ "$CALENDAR_TITLE" == "service" ]] && [[ "$USER" == "wolfgang" ]]
					then
						echo "$USER"
						/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
						/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					else
						/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
						/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool true" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					fi
				fi
				ALARM_SET=$(/usr/libexec/PlistBuddy -c "Print :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
				echo "calendar alarms for ""$CALENDAR_TITLE"" set to ""$ALARM_SET"""
				#echo ''
			else
				:
			fi
		done
	else
		:
	fi
	
	echo ''
	echo "cleaning calendar cache..."
	### deleting cache
	# without this the changes will not take effect
	while [[ $(find "$PATH_TO_CALENDARS"/* -type f -name "Calendar Cache*" -print) != "" ]]
	do 
		#rm -f "$PATH_TO_CALENDARS"/"Calendar Cache"*
		#find "$PATH_TO_CALENDARS"/* -type f -name "Calendar Cache*" -print
		find "$PATH_TO_CALENDARS"/* -type f -name "Calendar Cache*" -print0 | xargs -0 rm -f
		sleep 5
	done
	
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
    echo "not online, this would prevent restoring cache and data - exiting script..."
	echo ''
fi

