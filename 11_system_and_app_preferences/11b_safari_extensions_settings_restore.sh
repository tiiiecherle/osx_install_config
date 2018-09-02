#!/bin/bash

# this can not be included in the restore script if the keychain is restored
# a reboot is needed after restoring the keychain before running this script
# or the changes to safari would not be kept

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo "script dir is $SCRIPT_DIR$"
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

# getting logged in user
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#echo "loggedInUser is $loggedInUser..."

echo "please select restore master directory..."
RESTOREMASTERDIR=$(sudo -u "$loggedInUser" osascript "$SCRIPT_DIR"/11b_script/ask_restore_master_dir.scpt 2> /dev/null | sed s'/\/$//')
SELECTEDUSER="$loggedInUser"
MASTERUSER=$(ls "$RESTOREMASTERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared")
#RESTOREMASTERDIR=/Users/$USER/Desktop/restore/master
HOMEFOLDER=Users/$USER

#echo "SELECTEDUSER is "$SELECTEDUSER""
#echo "MASTERUSER is "$MASTERUSER""
#echo "RESTOREMASTERDIR is "$RESTOREMASTERDIR""
#echo "HOMEFOLDER is "$HOMEFOLDER""

# restore file
if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13 
	EXTENSIONS_PREFERENCESFILE_DESTINATION="/$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist"
else
    # macos versions 10.14 and up
    EXTENSIONS_PREFERENCESFILE_DESTINATION="/$HOMEFOLDER/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.Extensions.plist"
    if [[ -e "/$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist" ]]
    then
    	rm -rf "$EXTENSIONS_PREFERENCESFILE_DESTINATION"
    	mv "/$HOMEFOLDER/Library/Preferences/com.apple.Safari.Extensions.plist" "$EXTENSIONS_PREFERENCESFILE_DESTINATION"
	else
		:
	fi

fi

# backup file
if [[ $(cat $RESTOREMASTERDIR/_backup_macos_version.txt | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
	# macos versions until and including 10.13 
	EXTENSIONS_PREFERENCESFILE_SOURCE="$RESTOREMASTERDIR/Users/$MASTERUSER/Library/Preferences/com.apple.Safari.Extensions.plist"
else
    # macos versions 10.14 and up
	EXTENSIONS_PREFERENCESFILE_SOURCE="$RESTOREMASTERDIR/Users/$MASTERUSER/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.Extensions.plist"
fi	


###


#osascript -e 'tell application "Safari" to quit'
#sleep 2

if [ -e "$EXTENSIONS_PREFERENCESFILE_SOURCE" ] && [ -e $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions ]
then
	echo""
	echo "deleting local preferences file and extensions before restoring them from backup..."
	cp -a $RESTOREMASTERDIR/Users/"$MASTERUSER"/Library/Safari/Extensions /$HOMEFOLDER/Desktop/
	rm -rf /$HOMEFOLDER/Library/Safari/Extensions/*
	sleep 2
else
	echo ""
	echo "master backup safari preferences file /Library/Preferences/com.apple.Safari.Extensions.plist or master backup folder /Library/Safari/Extensions does not exist, skipping restore..."
	exit
fi

#open -g /Applications/Safari.app
#sleep 10

#osascript -e 'tell application "Safari" to quit'
#sleep 2

echo "restoring safari extensions..."
find /$HOMEFOLDER/Desktop/Extensions -name "*.safariextz" -print0 | while IFS= read -r -d '' file; do
    open "$file"
    sleep 10
done

sleep 2

#open -g /Applications/Safari.app
echo "safari has to be quit before continuing..."
while ps aux | grep 'Safari.app' | grep -v grep > /dev/null; do sleep 1; done

sleep 1

echo "restoring preferences of safari extensions..."
rm "$EXTENSIONS_PREFERENCESFILE_DESTINATION"
cp -a "$EXTENSIONS_PREFERENCESFILE_SOURCE" "$EXTENSIONS_PREFERENCESFILE_DESTINATION"
chmod 600 "$EXTENSIONS_PREFERENCESFILE_DESTINATION"
chown 501:staff "$EXTENSIONS_PREFERENCESFILE_DESTINATION"

sleep 1

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