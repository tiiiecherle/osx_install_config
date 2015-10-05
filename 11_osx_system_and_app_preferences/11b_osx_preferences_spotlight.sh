#!/usr/bin/env bash

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
defaults write com.apple.spotlight orderedItems -array \
'{"enabled" = 1;"name" = "APPLICATIONS";}' \
'{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
'{"enabled" = 1;"name" = "DIRECTORIES";}' \
'{"enabled" = 1;"name" = "PDF";}' \
'{"enabled" = 0;"name" = "FONTS";}' \
'{"enabled" = 1;"name" = "DOCUMENTS";}' \
'{"enabled" = 1;"name" = "MESSAGES";}' \
'{"enabled" = 1;"name" = "CONTACT";}' \
'{"enabled" = 1;"name" = "EVENT_TODO";}' \
'{"enabled" = 1;"name" = "IMAGES";}' \
'{"enabled" = 1;"name" = "BOOKMARKS";}' \
'{"enabled" = 1;"name" = "MUSIC";}' \
'{"enabled" = 1;"name" = "MOVIES";}' \
'{"enabled" = 1;"name" = "PRESENTATIONS";}' \
'{"enabled" = 1;"name" = "SPREADSHEETS";}' \
'{"enabled" = 0;"name" = "SOURCE";}' \
'{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
'{"enabled" = 0;"name" = "MENU_OTHER";}' \
'{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
'{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
'{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
'{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

# another way of stopping indexing AND searching for a volume (very helpful for network volumes) is putting an empty file ".metadata_never_index"
# in the root directory of the volume and run "mdutil -E /Volumes/*" afterwards, check if it worked with sudo mdutil -s /Volumes/*
# to turn indexing back on delete ".metadata_never_index" on the volume run mdutil -i followed by mdutil -E for that volume
#sudo touch /Volumes/VOLUMENAME/.metadata_never_index

# stop indexing before rebuilding the index
killall mds > /dev/null 2>&1

# turning indexing off for all volumes
#sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
sudo mdutil -i off /Volumes/*

# listing spotlight folder content
#sudo ls -a -l /.Spotlight-V100

# deleting spotlight indexes folder
sudo rm -rf /.Spotlight-V100/Store*
#sudo rm -rf /private/var/db/Spotlight-V100/Volumes/*

# turning indexing on for all volumes
#sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
#sudo mdutil -i on /Volumes/*

# deleting and reindexing all turned on (mdutil -i) volumes
sudo mdutil -E /Volumes/*

# only turn on indexing of the local harddrive named "macintosh_hd"
sudo mdutil -i on /Volumes/macintosh_hd

# disable spotlight indexing for any volume that gets mounted and has not yet been indexed before.
#sudo mdutil -i off "/Volumes/VOLUMENAME"
#sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

# stop indexing for some volumes which will not be indexed again
sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes/office" "/Volumes/extra" "/Volumes/scripts"

# check entries
#sudo defaults read /.Spotlight-V100/VolumeConfiguration Exclusions

# checking status of volumes
sudo mdutil -s /Volumes/*

# disabling lookup / spotlight suggestions
/usr/libexec/PlistBuddy -c "Add lookupEnabled:suggestionsEnabled bool false" ~/Library/Preferences/com.apple.lookup.plist


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


