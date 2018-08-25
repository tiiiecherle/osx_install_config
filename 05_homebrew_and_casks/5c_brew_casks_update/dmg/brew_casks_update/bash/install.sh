#!/bin/bash

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

BREW_CASKS_UPDATE_APP="brew_casks_update"

if [ -e /Applications/"$BREW_CASKS_UPDATE_APP".app ]
then
	rm -rf /Applications/"$BREW_CASKS_UPDATE_APP".app
else
	:
fi
cp -a "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_APP".app /Applications/
chown 501:admin /Applications/"$BREW_CASKS_UPDATE_APP".app
chown -R 501:admin /Applications/"$BREW_CASKS_UPDATE_APP".app/custom_files/
chmod 755 /Applications/"$BREW_CASKS_UPDATE_APP".app
chmod 770 /Applications/"$BREW_CASKS_UPDATE_APP".app/custom_files/"$BREW_CASKS_UPDATE_APP".sh
xattr -dr com.apple.quarantine /Applications/"$BREW_CASKS_UPDATE_APP".app


### security permissions
DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_SYSTEM"
DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_USER"

if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13
    :
else
    # macos versions 10.14 and up
    # removing old permissions
    sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where client='com.apple.ScriptEditor.id.brew-casks-update';"
    
    sleep 1
    
	# accessibility
	sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.brew-casks-update',0,1,1,NULL,NULL,NULL,?,NULL,0,?);"	
	# automation
	# working, but does not show in gui of system preferences, use csreq for the entry to show
	#sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.brew-casks-update',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
	#sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.brew-casks-update',0,1,1,?,NULL,0,'com.apple.Terminal',?,NULL,?);"
fi

#open /Applications/"$BREW_CASKS_UPDATE_APP".app

