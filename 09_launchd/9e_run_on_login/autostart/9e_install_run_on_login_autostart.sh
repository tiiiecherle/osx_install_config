#!/bin/bash

###
### launchd & applescript to do things when changing network location
###

### installation should be done via restore script after first install

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

# copy to /Users/$USER/Library/Scripts/
rm -rf /Users/"$USER"/Library/Scripts/run_on_login_signal.app
cp -a "$SCRIPT_DIR"/install_files/run_on_login_signal.app /Users/"$USER"/Library/Scripts/run_on_login_signal.app
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_login_signal.app
chmod 750 /Users/"$USER"/Library/Scripts/run_on_login_signal.app

# add to autostart
if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^ *//' | grep "run_on_login_signal" ) == "" ]]
then
    osascript -e 'tell application "System Events" to make login item at end with properties {name:"run_on_login_signal", path:"/Users/'$USER'/Library/Scripts/run_on_login_signal.app", hidden:true}'
else
	:
fi

rm -rf /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app
cp -a "$SCRIPT_DIR"/install_files/run_on_login_whatsapp.app /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app
chmod 750 /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app

# add to autostart
if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^ *//' | grep "run_on_login_whatsapp" ) == "" ]]
then
    osascript -e 'tell application "System Events" to make login item at end with properties {name:"run_on_login_whatsapp", path:"/Users/'$USER'/Library/Scripts/run_on_login_whatsapp.app", hidden:true}'
else
	:
fi


### automation
if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13 
    :
else
    # macos versions 10.14 and up
	DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
	#echo "$DATABASE_SYSTEM"
	DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
	#echo "$DATABASE_USER"
	#sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.run-on-login-signal',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
	#sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.run-on-login-whatsapp',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
fi


### uninstall
uninstall_run_on_login_autostart() {
	rm -rf ~/Library/Scripts/run_on_login_signal.app
	osascript -e 'tell application "System Events" to delete login item "run_on_login_signal"'
	rm -rf ~/Library/Scripts/run_on_login_whatsapp.app
	osascript -e 'tell application "System Events" to delete login item "run_on_login_whatsapp"'
}
#uninstall_run_on_login_autostart

echo "done"
