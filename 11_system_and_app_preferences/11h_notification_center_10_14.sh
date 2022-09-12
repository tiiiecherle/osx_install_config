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
""$PATH_TO_APPS"/WhatsApp.app																335"
""$PATH_TO_APPS"/Signal.app																	335"
""$PATH_TO_APPS"/pdf_200dpi_shrink.app/Contents/custom_files/pdf_shrink_done.app			335"
""$PATH_TO_SYSTEM_APPS"/Reminders.app														343"
""$PATH_TO_APPS"/EagleFiler.app																335"
""$PATH_TO_APPS"/VirusScannerPlus.app														335"
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

	APP_PATH=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    FLAGS_VALUE=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    
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

	APP_PATH=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    FLAGS_VALUE=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    
    if [[ -e "$APP_PATH" ]]
    then
    
		BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' $(eval echo "$APP_PATH")/Contents/Info.plist)
		#echo "getting flags for $BUNDLE_IDENTIFIER..."
	
		getting-needed-entry
	
		#echo $NEEDED_ENTRY
		if [[ $NEEDED_ENTRY != "" ]]
		then
		    ACTIVE_FLAG_VALUE=$(/usr/libexec/PlistBuddy -c "Print apps:"$NEEDED_ENTRY":flags" $(eval echo "$PLIST_FILE"))
		    printf "%-5s %-45s %10s %10s\n" "$NEEDED_ENTRY" "$BUNDLE_IDENTIFIER" "$FLAGS_VALUE" "$ACTIVE_FLAG_VALUE"
		else
			echo "entry for $BUNDLE_IDENTIFIER does not exist..."
		fi
		
	else
		echo """$APP_PATH"" does not exist..."
	fi

done


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
echo ''
