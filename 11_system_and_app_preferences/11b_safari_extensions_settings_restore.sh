#!/bin/bash

SELECTEDUSER=$USER
MASTERUSER=$USER
RESTOREMASTERDIR=/Users/$USER/Desktop/restore/master
HOMEFOLDER=Users/$USER

#echo "SELECTEDUSER is "$SELECTEDUSER""
#echo "MASTERUSER is "$MASTERUSER""
#echo "RESTOREMASTERDIR is "$RESTOREMASTERDIR""
#echo "HOMEFOLDER is "$HOMEFOLDER""

EXTENSIONS_PREFERENCESFILE="/$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist"

if [ -e "$EXTENSIONS_PREFERENCESFILE" ] && [ -e $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Preferences/com.apple.Safari.Extensions.plist ]
then
	echo "deleting local preferences file and restoring from backup..."
	rm "$EXTENSIONS_PREFERENCESFILE"
else
	echo "local or backup safari preferences file /Library/Preferences/com.apple.Safari.Extensions.plist does not exist, skipping restore..."
	exit
fi

sleep 2

open -g /Applications/Safari.app
sleep 10

osascript -e 'tell application "Safari" to quit'
sleep 2

open -g /Applications/Safari.app
sleep 10

osascript -e 'tell application "Safari" to quit'
sleep 2

cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Preferences/com.apple.Safari.Extensions.plist /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
chmod 600 /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
chown 501:staff /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
