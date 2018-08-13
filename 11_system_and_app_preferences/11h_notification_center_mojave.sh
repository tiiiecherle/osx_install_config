#!/usr/bin/env bash

#launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
#killall NotificationCenter

PLIST_FILE='~/Library/Preferences/com.apple.ncprefs.plist'

# this sets some extended attributes on the file
# without this the changes will be written but restored to the old version by killall usernoted or reboot
#com.apple.lastuseddate#PS
# check with 
#xattr /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
#xattr -l /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
# clean all extended attributes
#xattr -c /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
open $(eval echo "$PLIST_FILE")
sleep 2

# attributes
applications_to_set_values=(
"/Applications/WhatsApp.app															335"
"/Applications/Signal.app															335"
"/Applications/pdf_200dpi_shrink.app/custom_files/pdf_shrink_done.app				335"
"/Applications/Reminders.app														343"
"/Applications/EagleFiler.app														335"
"/Applications/VirusScannerPlus.app													335"
)


# functions
getting-needed-entry () {

	#NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" $(eval echo "$PLIST_FILE") | awk '/^[[:blank:]]*Dict {/' | wc -l)
	NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" $(eval echo "$PLIST_FILE") | awk '/^[[:blank:]]*bundle-id =/' | wc -l)
	#echo $NUMBER_OF_ENTRIES
	# -1 because counting of items starts with 0, not with 1
	LISTED_ENTRIES=$(($NUMBER_OF_ENTRIES-1))
	#echo $LISTED_ENTRIES
	
	NEEDED_ENTRY=""
	
	for i in $(seq 0 $LISTED_ENTRIES)
	do 
	    #if [[ $(/usr/libexec/PlistBuddy -c "Print apps:$i" $(eval echo "$PLIST_FILE") | grep "$BUNDLE_IDENTIFIER") != "" ]] 2> /dev/null
	   	(/usr/libexec/PlistBuddy -c "Print apps:$i" $(eval echo "$PLIST_FILE") | grep "$BUNDLE_IDENTIFIER") >/dev/null 2>&1
	   	if [ $? -eq 0 ]
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
    
	BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' $(eval echo "$APP_PATH")/Contents/Info.plist)
	echo "setting flags for $BUNDLE_IDENTIFIER..."

	getting-needed-entry

	#echo $NEEDED_ENTRY
	if [[ $NEEDED_ENTRY != "" ]]
	then
	    /usr/libexec/PlistBuddy -c "Set apps:$NEEDED_ENTRY:flags $(eval echo "$FLAGS_VALUE")" $(eval echo "$PLIST_FILE")
	else
		echo "entry for $BUNDLE_IDENTIFIER does not exist, creating it..."
	    ITEM1=$(echo \'Item $NUMBER_OF_ENTRIES\')
	    #echo $ITEM1
	   	/usr/libexec/PlistBuddy -c "Add apps:$ITEM1:bundle-id string $BUNDLE_IDENTIFIER" $(eval echo "$PLIST_FILE")
	   	
		getting-needed-entry
		
		/usr/libexec/PlistBuddy -c "Add apps:$NEEDED_ENTRY:flags integer $(eval echo "$FLAGS_VALUE")" $(eval echo "$PLIST_FILE")
	fi

done

#launchctl load -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
#open /System/Library/CoreServices/NotificationCenter.app
# applying changes without having to logout
#sudo killall usernoted
#sudo killall NotificationCenter
#killall sighup usernoted
#killall sighup NotificationCenter
killall usernoted
killall NotificationCenter
