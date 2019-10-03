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

PLIST_FILE="/Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist"

set_extended_attribute() {
	# this sets some extended attributes on the file
	# without this the changes will be written but restored to the old version by killall usernoted or reboot
	#com.apple.lastuseddate#PS
	# check with 
	#xattr /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
	#xattr -l /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
	# clean all extended attributes
	#xattr -c /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
	open "$PLIST_FILE"
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
""$PATH_TO_APPS"/WhatsApp.app																41943375"
""$PATH_TO_APPS"/Signal.app																	41943375"
""$PATH_TO_APPS"/pdf_200dpi_shrink.app/Contents/custom_files/pdf_shrink_done.app			41943375"
""$PATH_TO_SYSTEM_APPS"/Reminders.app														41943383"
""$PATH_TO_SYSTEM_APPS"/Calendar.app														41943375"
""$PATH_TO_SYSTEM_APPS"/Notes.app															41943375"
""$PATH_TO_SYSTEM_APPS"/Photos.app															41943375"
""$PATH_TO_APPS"/EagleFiler.app																41943375"
""$PATH_TO_APPS"/VirusScannerPlus.app														41943375"
""$PATH_TO_APPS"/MacPass.app																41943375"
""$PATH_TO_APPS"/Microsoft Word.app															41943375"
""$PATH_TO_APPS"/Microsoft Excel.app														41943375"
""$PATH_TO_APPS"/Microsoft PowerPoint.app													41943375"
""$PATH_TO_APPS"/Microsoft Remote Desktop.app												41943375"
""$PATH_TO_APPS"/Alfred 4.app																41943375"
""$PATH_TO_APPS"/Better.app																	41943375"
""$PATH_TO_APPS"/BresinkSoftwareUpdater.app													41943375"
""$PATH_TO_APPS"/Commander One.app															41943375"
""$PATH_TO_APPS"/iTerm.app																	41943375"
""$PATH_TO_APPS"/KeepingYouAwake.app														41943375"
""$PATH_TO_APPS"/PrefEdit.app																41943375"
""$PATH_TO_APPS"/TextMate.app																41943375"
""$PATH_TO_APPS"/Keka.app																	41943375"
""$PATH_TO_APPS"/Burn.app																	41943375"
""$PATH_TO_APPS"/2Do.app																	41943375"
""$PATH_TO_APPS"/Cyberduck.app																41943375"
""$PATH_TO_APPS"/HandBrake.app																41943375"
""$PATH_TO_APPS"/nextcloud.app																41943375"
""$PATH_TO_APPS"/Progressive Downloader.app													41943375"
""$PATH_TO_APPS"/Spotify.app																41943375"
""$PATH_TO_APPS"/Transmission.app															41943375"
""$PATH_TO_APPS"/Tunnelblick.app															41943375"
""$PATH_TO_APPS"/TinkerTool.app																41943375"
""$PATH_TO_APPS"/Vox.app																	41943375"
""$PATH_TO_APPS"/X-Lite.app																	41943375"
""$PATH_TO_APPS"/TotalFinder.app															41943375"
""$PATH_TO_APPS"/Firefox.app																41943375"
)


# functions
getting-needed-entry() {

	#NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" $(eval echo "$PLIST_FILE") | awk '/^[[:blank:]]*Dict {/' | wc -l)
	NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" "$PLIST_FILE" | awk '/^[[:blank:]]*bundle-id =/' | wc -l)
	#echo $NUMBER_OF_ENTRIES
	# -1 because counting of items starts with 0, not with 1
	LISTED_ENTRIES=$((NUMBER_OF_ENTRIES-1))
	#echo $LISTED_ENTRIES
	
	NEEDED_ENTRY=""
	
	for i in $(seq 0 $LISTED_ENTRIES)
	do 
	    #if [[ $(/usr/libexec/PlistBuddy -c "Print apps:"$i"" $(eval echo "$PLIST_FILE") | grep "$BUNDLE_IDENTIFIER") != "" ]] 2> /dev/null
	   	(/usr/libexec/PlistBuddy -c "Print apps:"$i"" "$PLIST_FILE" | grep "$BUNDLE_IDENTIFIER") >/dev/null 2>&1
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

	APP_PATH=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
	#echo "$APP_PATH"
    FLAGS_VALUE=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
    
    if [[ -e "$APP_PATH" ]]
    then
    
		BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH"/Contents/Info.plist)
		echo "setting flags for $BUNDLE_IDENTIFIER..."
	
		getting-needed-entry
	
		#echo $NEEDED_ENTRY
		if [[ "$NEEDED_ENTRY" != "" ]]
		then
		    /usr/libexec/PlistBuddy -c "Set apps:"$NEEDED_ENTRY":flags "$FLAGS_VALUE"" "$PLIST_FILE"
		else
			echo "entry for $BUNDLE_IDENTIFIER does not exist, creating it..."
		    ITEM1=$(echo \'Item $NUMBER_OF_ENTRIES\')
		    #echo $ITEM1
		   	/usr/libexec/PlistBuddy -c "Add apps:"$ITEM1":bundle-id string "$BUNDLE_IDENTIFIER"" "$PLIST_FILE"
		   	
			getting-needed-entry
			
			/usr/libexec/PlistBuddy -c "Add apps:"$NEEDED_ENTRY":flags integer "$FLAGS_VALUE"" "$PLIST_FILE"
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
sleep 2
defaults read "$PLIST_FILE" &> /dev/null
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

	APP_PATH=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
    FLAGS_VALUE=$(echo "$application" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
    
    if [[ -e "$APP_PATH" ]]
    then
    
		BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH"/Contents/Info.plist)
		#echo "getting flags for $BUNDLE_IDENTIFIER..."
	
		getting-needed-entry
	
		#echo $NEEDED_ENTRY
		if [[ $NEEDED_ENTRY != "" ]]
		then
		    ACTIVE_FLAG_VALUE=$(/usr/libexec/PlistBuddy -c "Print apps:"$NEEDED_ENTRY":flags" "$PLIST_FILE")
		    BUNDLE_IDENTIFIER_PRINT=$(printf '%s\n' "$BUNDLE_IDENTIFIER" | awk -v len=35 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
		    if [[ "$FLAGS_VALUE" == "$ACTIVE_FLAG_VALUE" ]]
	        then
	            CHECK_RESULT_PRINT=$(echo -e '\033[1;32m    ok\033[0m')
	            #CHECK_RESULT_PRINT=$(echo -e '\033[1;31m outdated\033[0m')
			else
	            CHECK_RESULT_PRINT=$(echo -e '\033[1;31m  wrong\033[0m' >&2)
	        fi
		    printf "%-5s %-35s %12s %12s %12s\n" "$NEEDED_ENTRY" "$BUNDLE_IDENTIFIER_PRINT" "$FLAGS_VALUE" "$ACTIVE_FLAG_VALUE" "$CHECK_RESULT_PRINT"
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
