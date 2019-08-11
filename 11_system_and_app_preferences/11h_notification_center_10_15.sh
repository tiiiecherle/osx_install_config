#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### compatibility
###

# macos 10.15 only
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

#launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
#killall NotificationCenter

PLIST_FILE='~/Library/Preferences/com.apple.ncprefs.plist'

set_extended_attribute() {
	# this sets some extended attributes on the file
	# without this the changes will be written but restored to the old version by killall usernoted or reboot
	#com.apple.lastuseddate#PS
	# check with 
	#xattr /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
	#xattr -l /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
	# clean all extended attributes
	#xattr -c /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
	open $(eval echo "$PLIST_FILE")
	#open -a BBEdit.app $(eval echo "$PLIST_FILE")
	sleep 5
	#osascript -e "tell application (path to frontmost application as text) to quit saving no"
	osascript -e "tell application \"Prefs Editor\" to quit saving no"
	sleep 1
}
#set_extended_attribute


### setting flags
echo ''
echo "setting flags..."


# attributes
applications_to_set_values=(
"/Applications/WhatsApp.app																41943375"
"/Applications/Signal.app																41943375"
"/Applications/pdf_200dpi_shrink.app/Contents/custom_files/pdf_shrink_done.app			41943375"
"/System/Applications/Reminders.app														41943383"
"/Applications/EagleFiler.app															41943375"
"/Applications/VirusScannerPlus.app														41943375"
"/Applications/MacPass.app																41943375"
)


# functions
getting-needed-entry() {

	#NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" $(eval echo "$PLIST_FILE") | awk '/^[[:blank:]]*Dict {/' | wc -l)
	NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" $(eval echo "$PLIST_FILE") | awk '/^[[:blank:]]*bundle-id =/' | wc -l)
	#echo $NUMBER_OF_ENTRIES
	# -1 because counting of items starts with 0, not with 1
	LISTED_ENTRIES=$((NUMBER_OF_ENTRIES-1))
	#echo $LISTED_ENTRIES
	
	NEEDED_ENTRY=""
	
	for i in $(seq 0 $LISTED_ENTRIES)
	do 
	    #if [[ $(/usr/libexec/PlistBuddy -c "Print apps:"$i"" $(eval echo "$PLIST_FILE") | grep "$BUNDLE_IDENTIFIER") != "" ]] 2> /dev/null
	   	(/usr/libexec/PlistBuddy -c "Print apps:"$i"" $(eval echo "$PLIST_FILE") | grep "$BUNDLE_IDENTIFIER") >/dev/null 2>&1
	   	if [[ $? -eq 0 ]]
	    then
	        #echo $i
	        NEEDED_ENTRY=$i
	    else
	        :
	        #echo $i
	    fi
	done
	
}

for application in "${applications_to_set_values[@]}"
do

	APP_PATH=$(echo "$application" | awk '{print $1}')
    FLAGS_VALUE=$(echo "$application" | awk '{print $2}')
    
    if [[ -e "$APP_PATH" ]]
    then
    
		BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' $(eval echo "$APP_PATH")/Contents/Info.plist)
		echo "setting flags for $BUNDLE_IDENTIFIER..."
	
		getting-needed-entry
	
		#echo $NEEDED_ENTRY
		if [[ "$NEEDED_ENTRY" != "" ]]
		then
		    /usr/libexec/PlistBuddy -c "Set apps:"$NEEDED_ENTRY":flags $(eval echo "$FLAGS_VALUE")" $(eval echo "$PLIST_FILE")
		else
			echo "entry for $BUNDLE_IDENTIFIER does not exist, creating it..."
		    ITEM1=$(echo \'Item $NUMBER_OF_ENTRIES\')
		    #echo $ITEM1
		   	/usr/libexec/PlistBuddy -c "Add apps:"$ITEM1":bundle-id string $BUNDLE_IDENTIFIER" $(eval echo "$PLIST_FILE")
		   	
			getting-needed-entry
			
			/usr/libexec/PlistBuddy -c "Add apps:"$NEEDED_ENTRY":flags integer $(eval echo "$FLAGS_VALUE")" $(eval echo "$PLIST_FILE")
		fi
	else
		echo """$APP_PATH"" does not exist..."
	fi

done



### restarting notification center
echo ''
echo "restarting notification center..."
#launchctl load -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
#open /System/Library/CoreServices/NotificationCenter.app
# applying changes without having to logout
#sudo killall usernoted
#sudo killall NotificationCenter
#killall sighup usernoted
#killall sighup NotificationCenter
killall usernoted
killall NotificationCenter
echo ''

echo ''
SLEEP_TIME=10
NUM1=0
#echo ''
while [[ "$NUM1" -le "$SLEEP_TIME" ]]
do 
	NUM1=$((NUM1+1))
	if [[ "$NUM1" -le "$SLEEP_TIME" ]]
	then
		#echo "$NUM1"
		sleep 1
		tput cuu 1 && tput el
		echo "waiting $((SLEEP_TIME-NUM1)) seconds for the changes to take effect..."
	else
		:
	fi
done


#### checking preferences
echo ''
echo "checking settings..."
for application in "${applications_to_set_values[@]}"
do

	APP_PATH=$(echo "$application" | awk '{print $1}')
    FLAGS_VALUE=$(echo "$application" | awk '{print $2}')
    
    if [[ -e "$APP_PATH" ]]
    then
    
		BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' $(eval echo "$APP_PATH")/Contents/Info.plist)
		#echo "getting flags for $BUNDLE_IDENTIFIER..."
	
		getting-needed-entry
	
		#echo $NEEDED_ENTRY
		if [[ $NEEDED_ENTRY != "" ]]
		then
		    ACTIVE_FLAG_VALUE=$(/usr/libexec/PlistBuddy -c "Print apps:"$NEEDED_ENTRY":flags" $(eval echo "$PLIST_FILE"))
		    BUNDLE_IDENTIFIER_PRINT=$(printf '%s\n' "$BUNDLE_IDENTIFIER" | awk -v len=35 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
		    if [[ "$FLAGS_VALUE" == "$ACTIVE_FLAG_VALUE" ]]
	        then
	            CHECK_RESULT_PRINT=$(echo -e '\033[1;32m    ok\033[0m')
	            #CHECK_RESULT_PRINT=$(echo -e '\033[1;31m outdated\033[0m')
			else
	            CHECK_RESULT_PRINT=$(echo -e '\033[1;31m  wrong\033[0m')
	        fi
		    printf "%-5s %-35s %12s %12s %12s\n" "$NEEDED_ENTRY" "$BUNDLE_IDENTIFIER_PRINT" "$FLAGS_VALUE" "$ACTIVE_FLAG_VALUE" "$CHECK_RESULT_PRINT"
		else
			echo "entry for $BUNDLE_IDENTIFIER does not exist..."
		fi
		
	else
		echo """$APP_PATH"" does not exist..."
	fi

done

echo ''
echo 'done ;)'
echo ''
