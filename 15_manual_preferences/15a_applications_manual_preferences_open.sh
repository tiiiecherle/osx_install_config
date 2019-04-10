#!/bin/bash

###
### variables
###

MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)



###
### functions
###

function databases_apps_security_permissions() {
    DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_SYSTEM"
	DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_USER"
}
    
function identify_terminal() {
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]
    then
    	export SOURCE_APP=com.apple.Terminal
    	export SOURCE_APP_NAME="Terminal"
    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]
    then
        export SOURCE_APP=com.googlecode.iterm2
        export SOURCE_APP_NAME="iTerm"
	else
		export SOURCE_APP=com.apple.Terminal
		echo "terminal not identified, setting automating permissions to apple terminal..."
	fi
}

function give_apps_security_permissions() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        # working, but does not show in gui of system preferences, use csreq for the entry to show
	    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP"',0,1,1,?,NULL,0,'"$AUTOMATED_APP"',?,NULL,?);"
    fi
    sleep 1
}

function remove_apps_security_permissions_start() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        AUTOMATED_APP=com.apple.systempreferences
        sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"');"
    fi
    sleep 1
}

function remove_apps_security_permissions_stop() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        AUTOMATED_APP=com.apple.systempreferences
        # macos versions 10.14 and up
        if [[ $SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1 == "yes" ]]
        then
            # source app was already allowed to control app before running this script, so don`t delete the permission
            :
        else
            sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"');"
        fi
    fi
}


###


databases_apps_security_permissions
identify_terminal

if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13 
	:
else
    echo ''
    echo "setting security permissions..."
    AUTOMATED_APP=com.apple.systempreferences
    if [[ $(sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"' and allowed='1');") != "" ]]
	then
	    SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1="yes"
	    #echo "$SOURCE_APP is already allowed to control $AUTOMATED_APP..."
	else
		SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1="no"
		#echo "$SOURCE_APP is not allowed to control $AUTOMATED_APP..."
		give_apps_security_permissions
	fi
    echo ''
fi

# trap
trap 'printf "\n"; remove_apps_security_permissions_stop' SIGHUP SIGINT SIGTERM EXIT


###
### opening apps for applying manual preferences
###

echo "opening apps for applying preferences manually..."

applications_to_open=(
#"/Applications/Safari.app"
#"/Applications/Firefox.app"
"/Applications/Adobe Acrobat Reader DC.app"
"/Applications/Adobe Acrobat X Pro/Adobe Acrobat Pro.app"
"/Applications/AppCleaner.app"
"/Applications/FaceTime.app"
"/Applications/iStat Menus.app"
"/Applications/iTunes.app"
"/Applications/Calendar.app"
"/Applications/Contacts.app"
"/Applications/Mail.app"
"/Applications/Microsoft Word.app"
"/Applications/Microsoft Excel.app"
"/Applications/Messages.app"
"/Applications/The Unarchiver.app"
#"/Applications/Xcode.app"
"/Applications/iMazing.app"
"/Applications/VirusScannerPlus.app"
#"/Applications/Macs Fan Control.app"
#"/Applications/Signal.app"
#"/Applications/Keka.app"
"/Applications/Overflow 3.app"
)

for i in "${applications_to_open[@]}"
do
	if [ -e "$i" ]
	then
	    echo "opening $(basename "$i")"
		open "$i"
	else
		:
	fi
done

# google consent
open -a "/Applications/Safari.app" "https://consent.google.com/ui/?continue=https%3A%2F%2Fwww.google.com%2F&origin=https%3A%2F%2Fwww.google.com&m=1&wp=47&gl=DE&hl=de&pc=s&uxe=4133096&ae=1"
open "/Applications/Firefox.app" && sleep 2 && open -a "/Applications/Firefox.app" "https://consent.google.com/ui/?continue=https%3A%2F%2Fwww.google.com%2F&origin=https%3A%2F%2Fwww.google.com&m=1&wp=47&gl=DE&hl=de&pc=s&uxe=4133096&ae=1"

if [[ "$USER" == "wolfgang" ]]
then
    i="/Users/$USER/PVGuardClient/installer/pvdownload.jnlp"
    echo "opening $(basename "$i")"
	open "$i"
else
    :
fi

# disable all siri analytics
echo "waiting 30s for all apps to open..."
sleep 30
# already done in system preferences script before but some apps seam to appear here later
for i in $(/usr/libexec/PlistBuddy -c "Print CSReceiverBundleIdentifierState" /Users/$USER/Library/Preferences/com.apple.corespotlightui.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
do
        #echo $i
	    /usr/libexec/PlistBuddy -c "Set CSReceiverBundleIdentifierState:$i false" /Users/$USER/Library/Preferences/com.apple.corespotlightui.plist
done

# opening system preferences for the monitor
function open_system_prefs_monitor() {
#osascript 2>/dev/null <<EOF
osascript <<EOF

tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.displays"
	set tabnames to (get the name of every anchor of pane id "com.apple.preference.displays")
	#display dialog tabnames
	#get the name of every anchor of pane id "com.apple.preference.displays"
	reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
end tell

delay 2

EOF
}
open_system_prefs_monitor

### removing security permissions
remove_apps_security_permissions_stop

echo "done ;)"
