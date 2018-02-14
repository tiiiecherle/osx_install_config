#!/bin/bash

# this can not be included in the restore script if the keychain is restored
# a reboot is needed after restoring the keychain before running this script
# or the changes to safari would not be kept

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo "script dir is $SCRIPT_DIR$"

echo "please select restore master directory..."
RESTOREMASTERDIR=$(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c "osascript \"$SCRIPT_DIR\"/11b_script/ask_restore_master_dir.scpt 2> /dev/null" | sed s'/\/$//')

SELECTEDUSER=$USER
MASTERUSER=$(ls "$RESTOREMASTERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared")
#RESTOREMASTERDIR=/Users/$USER/Desktop/restore/master
HOMEFOLDER=Users/$USER

#echo "SELECTEDUSER is "$SELECTEDUSER""
#echo "MASTERUSER is "$MASTERUSER""
#echo "RESTOREMASTERDIR is "$RESTOREMASTERDIR""
#echo "HOMEFOLDER is "$HOMEFOLDER""

EXTENSIONS_PREFERENCESFILE="/$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist"

osascript -e 'tell application "Safari" to quit'
sleep 2

if [ -e $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Preferences/com.apple.Safari.Extensions.plist ] && [ -e $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions ]
then
	echo""
	echo "deleting local preferences file and extensions before restoring them from backup..."
	rm "$EXTENSIONS_PREFERENCESFILE"
	cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions /$HOMEFOLDER/Desktop/
	rm -rf /$HOMEFOLDER/Library/Safari/Extensions/*
	sleep 2
else
	echo ""
	echo "master backup safari preferences file /Library/Preferences/com.apple.Safari.Extensions.plist or master backup folder /Library/Safari/Extensions does not exist, skipping restore..."
	exit
fi

open -g /Applications/Safari.app
sleep 10

osascript -e 'tell application "Safari" to quit'
sleep 2

echo "restoring preferences of safari extensions..."
cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Preferences/com.apple.Safari.Extensions.plist /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
chmod 600 /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
chown 501:staff /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist

echo "restoring safari extensions..."
find /$HOMEFOLDER/Desktop/Extensions -name "*.safariextz" -print0 | while IFS= read -r -d '' file; do
    open "$file"
    sleep 8
done

sleep 2

#open -g /Applications/Safari.app
echo "safari has to be quit before continuing..."
while ps aux | grep 'Safari.app' | grep -v grep > /dev/null; do sleep 1; done

# opening safari again to accept self signed certificate for possible calendar error on sync
echo ''
echo "please accept self-signed certificate by showing details, opening the webiste and entering the password..."
open -a /Applications/Safari.app https://172.16.1.200	
echo "safari has to be quit before continuing..."
while ps aux | grep 'Safari.app' | grep -v grep > /dev/null; do sleep 1; done

#osascript -e 'tell application "Safari" to quit'

# restoring settings for extensions
# enabled / disabled - displayed in menu bar or not...
#cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions/Extensions.plist /$HOMEFOLDER/Library/Safari/Extensions/Extensions.plist
#chmod 600 /$HOMEFOLDER/Library/Safari/Extensions/Extensions.plist
#chown 501:staff /$HOMEFOLDER/Library/Safari/Extensions/Extensions.plist

rm -rf /$HOMEFOLDER/Desktop/Extensions

echo 'done restoring safari extensions and their preferences ;)'