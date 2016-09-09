#!/bin/bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 30; kill -0 "$$" || exit; done 2>/dev/null &

###
### preferences spotlight
###

echo "preferences spotlight"

# change indexing order and disable some search results
# yosemite (and newer) specific search results
# 	MENU_DEFINITION
# 	MENU_CONVERSION
# 	MENU_EXPRESSION
# 	MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
# 	MENU_WEBSEARCH             (send search queries to Apple)
# 	MENU_OTHER

/usr/libexec/PlistBuddy -c 'Delete orderedItems' ~/Library/Preferences/com.apple.spotlight.plist
/usr/libexec/PlistBuddy -c 'Add orderedItems array' ~/Library/Preferences/com.apple.spotlight.plist

spotlightconfig=(
"0      APPLICATIONS                    true"
"1      SYSTEM_PREFS                    false"
"2      DIRECTORIES                     true"
"3      PDF                             true"
"4      FONTS                           true"
"5      DOCUMENTS                       true"
"6      MESSAGES                        false"
"7      CONTACT                         true"
"8      EVENT_TODO                      false"
"9      IMAGES                          true"
"10     BOOKMARKS                       false"
"11     MUSIC                           true"
"12     MOVIES                          true"
"13     PRESENTATIONS                   true"
"14     SPREADSHEETS                    true"
"15     SOURCE                          true"
"16     MENU_DEFINITION                 false"
"17     MENU_OTHER                      true"
"18     MENU_CONVERSION                 false"
"19     MENU_EXPRESSION                 false"
"20     MENU_WEBSEARCH                  false"
"21     MENU_SPOTLIGHT_SUGGESTIONS      false"
)

for entry in "${spotlightconfig[@]}"
do
    #echo $entry
    ITEMNR=$(echo $entry | awk '{print $1}')
    SPOTLIGHTENTRY=$(echo $entry | awk '{print $2}')
    ENABLED=$(echo $entry | awk '{print $3}')
    #echo $ITEMNR
    #echo $SPOTLIGHTENTRY
    #echo $ENABLED
    /usr/libexec/PlistBuddy -c 'Add orderedItems:'$ITEMNR' dict' ~/Library/Preferences/com.apple.spotlight.plist
    /usr/libexec/PlistBuddy -c 'Add orderedItems:'$ITEMNR':enabled bool '$ENABLED'' ~/Library/Preferences/com.apple.spotlight.plist
    /usr/libexec/PlistBuddy -c 'Add orderedItems:'$ITEMNR':name string '$SPOTLIGHTENTRY'' ~/Library/Preferences/com.apple.spotlight.plist
done

###
### killing affected applications
###

echo "restarting affected apps"

for app in "cfprefsd" "System Preferences"; do
killall "${app}" > /dev/null 2>&1
done

#for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" "Dock" "Finder" "Mail" "Messages" "System Preferences" "Safari" "SystemUIServer" "TextEdit"; do
#	killall "${app}" > /dev/null 2>&1
#done

echo "done ;)"
#echo "a few changes need a reboot or logout to take effect"
#echo "initializing reboot"

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


