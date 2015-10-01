#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### adding favorite servers
###

# adding favorite servers

/usr/libexec/PlistBuddy -c 'delete favoriteservers:CustomListItems' ~/Library/Preferences/com.apple.sidebarlists.plist
/usr/libexec/PlistBuddy -c 'add favoriteservers:CustomListItems array' ~/Library/Preferences/com.apple.sidebarlists.plist
/usr/libexec/PlistBuddy -c 'add favoriteservers:Controller string "CustomListItems"' ~/Library/Preferences/com.apple.sidebarlists.plist
/usr/libexec/PlistBuddy -c 'add favoriteservers:CustomListItems:0:Name string "smb://192.168.1.200"' ~/Library/Preferences/com.apple.sidebarlists.plist
/usr/libexec/PlistBuddy -c 'add favoriteservers:CustomListItems:0:URL string "smb://192.168.1.200"' ~/Library/Preferences/com.apple.sidebarlists.plist

#for adding more servers replace 0 with 1, 2, 3...

#/usr/libexec/PlistBuddy -c 'add favoriteservers:CustomListItems:1:Name string "smb://192.168.1.205"' ~/Library/Preferences/com.apple.sidebarlists.plist
#/usr/libexec/PlistBuddy -c 'add favoriteservers:CustomListItems:1:URL string "smb://192.168.1.205"' ~/Library/Preferences/com.apple.sidebarlists.plist

# check with
#defaults read com.apple.sidebarlists favoriteservers

echo "done"
echo ""

read -p "You need to log out and back in for the changes to take effect. Do you want to logout now? (y/n)?" CONT
if [ "$CONT" == "y" ]
then
echo "logging out..."

# logout
osascript -e 'tell app "loginwindow" to «event aevtrlgo»'

else
echo "please logout later for the changes to take effect..."
fi