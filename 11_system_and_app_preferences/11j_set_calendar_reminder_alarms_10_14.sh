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
### set calendar and reminder alarms
###

# checking if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    echo ''
	   
	# checking for time logged in to give macos time to build the calendar cache
	#TIME_USER_IS_LOGGED_IN=$(w | grep "console" | grep -o '[0-9]\+' | tail -n1)
	# or
	# w | sed 1d | awk 'NR==1{for(i=1;i<=NF;i++)if($i~/IDLE/)f[n++]=i}{for(i=0;i<n;i++)printf"%s%s",i?" ":"",$f[i];print""}' | grep -o '[0-9]*' | sed '/^\s*$/d'
	# or
	# w | grep "console" | awk '{print $(NF-1)}'
	
	WAITING_TIME=3
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
			echo "waiting $((WAITING_TIME-NUM1)) seconds to give macos time to rebuild the calendar cache..."
		else
			:
		fi
	done
	
	
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
				
				tell application "$SOURCE_APP_NAME"
					activate
				end tell
				
EOF
	
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
				echo "waiting $((WAITING_TIME-NUM1)) seconds to give the calendar time to download calendar entries..."
			else
				:
			fi
		done
		
		osascript <<EOF					
				try
					tell application "Calendar"
						quit
					end tell
				end try
EOF
	
		sleep 2
	}
	#opening_calendar
	
	### quitting calandar and contacts
	echo ''
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
	#echo ''
	sleep 5
	
	
	### identify caldav directory
	# holiday calendar
	CALDAV_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/ | grep ".*.caldav$")"
	#echo "$CALDAV_DIRS"
	for CALENDAR_TO_LOOK_FOR in gep_radicale fw_radicale wr_radicale office_radicale ts_radicale "$USER"_icloud
	do
		unset CALDAV_CALENDAR
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    i="$line"
			#echo $i
			if [[ -e "$PATH_TO_CALENDARS"/"$i"/Info.plist ]]
			then
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$i"/Info.plist) != "$CALENDAR_TO_LOOK_FOR" ]]
				then
					:
				else
					CALDAV_CALENDAR="$i"
				fi
			else
				:
			fi
		done <<< "$(printf "%s\n" "${CALDAV_DIRS[@]}")"
		
		if [[ "$CALDAV_CALENDAR" != "" ]]
		then
			echo ''
			echo "expected caldav is ""$CALDAV_CALENDAR"""
			CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/ | grep ".*.calendar$")"
			while IFS= read -r line || [[ -n "$line" ]]
			do
			    if [[ "$line" == "" ]]; then continue; fi
			    i="$line"
				#echo $i
				#ls "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/
				if [[ -e "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist ]]
				then
					#echo $i
					CALENDAR_TITLE=$(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
					#echo "$CALENDAR_TITLE"
					
					# calender notifications
					if [[ "$CALENDAR_TITLE" == "$USER" ]] || [[ "$CALENDAR_TITLE" == "allgemein" ]] || [[ "$CALENDAR_TITLE" == ""$USER"_privat" ]]
					then
						#echo "enabling "$i"..."
						/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
						/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					elif [[ "$CALENDAR_TITLE" == "service" ]] && [[ "$USER" == "wolfgang" ]]
					then
						#echo "$USER"
						#echo "enabling "$i"..."
						/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
						/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					else
						#echo "disabling "$i"..."
						/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
						/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool true" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					fi
					
					sleep 0.1
					
					# enable all reminder notifications
					IS_REMINDER=$(/usr/libexec/PlistBuddy -c 'Print TaskContainer' "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
					#echo $IS_REMINDER
					if [[ "$IS_REMINDER" == "true" ]]
					then
						#echo "$CALENDAR_TITLE is a reminder..."
						#ENTRY_TYPE="reminder"
						ENTRY_TYPE="tasks"
						/usr/libexec/PlistBuddy -c "Delete :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
						/usr/libexec/PlistBuddy -c "Add :AlarmsDisabled bool false" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist
					else
						#echo "$CALENDAR_TITLE is a calendar..."
						ENTRY_TYPE="calendar"
						:
					fi
					
					sleep 0.1
					
					# results
					ALARM_SET_TO_OFF=$(/usr/libexec/PlistBuddy -c "Print :AlarmsDisabled" "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
					if [[ $ALARM_SET_TO_OFF == "true" ]]
					then
						NOTIFICATION_STATUS="disabled"
					else
						NOTIFICATION_STATUS="enabled"
					fi
					
					printf "%-30s %-15s %-15s\n" "$CALENDAR_TITLE" "$ENTRY_TYPE" "$NOTIFICATION_STATUS"
	
					#echo ''
				else
					:
				fi
			done <<< "$(printf "%s\n" "${CALENDAR_DIRS[@]}")"
		else
			:
		fi
	done
	
	
	### disabling calendars
	echo ''
	for CALENDAR_TO_LOOK_FOR in "$USER"_icloud
	do
		unset CALDAV_CALENDAR
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    i="$line"
			#echo $i
			if [[ -e "$PATH_TO_CALENDARS"/"$i"/Info.plist ]]
			then
				if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$i"/Info.plist) != "$CALENDAR_TO_LOOK_FOR" ]]
				then
					:
				else
					CALDAV_CALENDAR="$i"
				fi
			else
				:
			fi
		done <<< "$(printf "%s\n" "${CALDAV_DIRS[@]}")"
		
		if [[ "$CALDAV_CALENDAR" != "" ]]
		then
			#echo ''
			#echo "expected caldav is ""$CALDAV_CALENDAR"""
			CALENDAR_DIRS="$(ls -1 "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/ | grep ".*.calendar$")"
			
			while IFS= read -r line || [[ -n "$line" ]]
			do
			    if [[ "$line" == "" ]]; then continue; fi
			    i="$line"
				#echo $i
				#ls "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/
				if [[ -e "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist ]]
				then
					
					CALENDAR_TITLE=$(/usr/libexec/PlistBuddy -c 'Print Title' "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
					
					# disable calendar add-on
					if [[ "$CALENDAR_TITLE" == "add-on" ]]
					then
						CALENDAR_TO_DISABLE=$(/usr/libexec/PlistBuddy -c 'Print Key' "$PATH_TO_CALENDARS"/"$CALDAV_CALENDAR"/"$i"/Info.plist)
						echo "disabling calendar "$CALENDAR_TO_DISABLE"..."
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
		else
			:
		fi
	done
	
	
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
	echo ''
	echo "stopping calendar service..."
	#osascript -e 'tell application "System Events" to log out'
	killall Calendar &> /dev/null
	#killall CalendarAgent
	#killall remindd
	# launchctl list
	launchctl unload /System/Library/LaunchAgents/com.apple.CalendarAgent.plist 2>&1 | grep -v "in progress"
	sleep 2
	deleting_cache
	sleep 2
	echo ''
	echo "starting calendar service..."
	launchctl load /System/Library/LaunchAgents/com.apple.CalendarAgent.plist
	
	
	echo ''
	echo "done ;)"
	echo ''
else
    echo "not online, this would prevent restoring cache and data - exiting script..."
	echo ''
fi

