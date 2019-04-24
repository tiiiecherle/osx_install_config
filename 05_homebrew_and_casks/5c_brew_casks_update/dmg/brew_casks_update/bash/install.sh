#!/bin/bash

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

APP_NAME="brew_casks_update"

if [[ -e /Applications/"$APP_NAME".app ]]
then
	rm -rf /Applications/"$APP_NAME".app
else
	:
fi

# ownership and permissions
cp -a "$SCRIPT_DIR"/app/"$APP_NAME".app /Applications/
if [[ -e /Applications/"$APP_NAME".app/custom_files/"$APP_NAME".sh ]]
then
	SCRIPT_NAME="$APP_NAME"
else
	SCRIPT_NAME=$(find /Applications/"$APP_NAME".app/custom_files -maxdepth 1 -mindepth 1 -type f -name "*.sh")
	if [[ $(echo "$SCRIPT_NAME" | wc -l | awk '{print $1}') != "1" ]]
	then
		echo "SCRIPT_NAME is not set correctly, exiting..."
		exit
	else
		SCRIPT_NAME=$(basename "$SCRIPT_NAME" .sh)
	fi
fi
chown 501:admin /Applications/"$APP_NAME".app
chown -R 501:admin /Applications/"$APP_NAME".app/custom_files/
chmod 755 /Applications/"$APP_NAME".app
chmod 770 /Applications/"$APP_NAME".app/custom_files/"$SCRIPT_NAME".sh
xattr -dr com.apple.quarantine /Applications/"$APP_NAME".app


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

#open /Applications/"$APP_NAME".app

