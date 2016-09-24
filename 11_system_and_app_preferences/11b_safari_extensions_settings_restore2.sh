#!/bin/bash

SELECTEDUSER=$USER
MASTERUSER=$(ls /Users/$USER/Desktop/restore/master/Users | egrep -v "^[.]" | egrep -v "Shared")
RESTOREMASTERDIR=/Users/$USER/Desktop/restore/master
HOMEFOLDER=Users/$USER

#echo "SELECTEDUSER is "$SELECTEDUSER""
#echo "MASTERUSER is "$MASTERUSER""
#echo "RESTOREMASTERDIR is "$RESTOREMASTERDIR""
#echo "HOMEFOLDER is "$HOMEFOLDER""

EXTENSIONS_PREFERENCESFILE="/$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist"

if [ -e $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Preferences/com.apple.Safari.Extensions.plist ] && [ -e $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions ]
	echo "deleting local preferences file and restoring from backup..."
	rm "$EXTENSIONS_PREFERENCESFILE"
else
	echo "master backup safari preferences file /Library/Preferences/com.apple.Safari.Extensions.plist does not exist, skipping restore..."
	exit
fi

cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions /$HOMEFOLDER/Desktop/
rm -rf /$HOMEFOLDER/Library/Safari/Extensions/*

for i in $(find /$HOMEFOLDER/Desktop/Extensions -name "*.safariextz")
do
	open "$i"
	sleep 2
done

cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Preferences/com.apple.Safari.Extensions.plist /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
chmod 600 /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist
chown 501:staff /$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist

sleep 2

open -g /Applications/Safari.app
sleep 10

osascript -e 'tell application "Safari" to quit'

rm -rf /$HOMEFOLDER/Desktop/Extensions