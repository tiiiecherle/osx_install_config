#!/bin/bash

###
### asking password upfront
###

# function for reading secret string (POSIX compliant)
enter_password_secret()
{
    # read -s is not POSIX compliant
    #read -s -p "Password: " SUDOPASSWORD
    #echo ''
    
    # this is POSIX compliant
    # disabling echo, this will prevent showing output
    stty -echo
    # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
    trap 'stty echo' EXIT
    # asking for password
    printf "Password: "
    # reading secret
    read -r "$@" SUDOPASSWORD
    # reanabling echo
    stty echo
    trap - EXIT
    # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
    printf "\n"
    # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
    # has to be part of the function or it wouldn`t be updated during the maximum three tries
    #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
}

# unset the password if the variable was already set
unset SUDOPASSWORD

# making sure no variables are exported
set +a

# asking for the SUDOPASSWORD upfront
# typing and reading SUDOPASSWORD from command line without displaying it and
# checking if entered password is the sudo password with a set maximum of tries
NUMBER_OF_TRIES=0
MAX_TRIES=3
while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
do
    NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
    #echo "$NUMBER_OF_TRIES"
    if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    then
        enter_password_secret
        ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
        if [ $? -eq 0 ]
        then 
            break
        else
            echo "Sorry, try again."
        fi
    else
        echo ""$MAX_TRIES" incorrect password attempts"
        exit
    fi
done

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}



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
### preferences spotlight
###

echo "preferences spotlight"

function open_system_prefs_spotlight() {
    
if [ -e ~/Library/Preferences/com.apple.Spotlight.plist ]
then
	rm ~/Library/Preferences/com.apple.Spotlight.plist
else
	:
fi

sleep 2

#osascript 2>/dev/null <<EOF
osascript <<EOF

tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.spotlight"
	#set tabnames to (get the name of every anchor of pane id "com.apple.preference.spotlight")
	#display dialog tabnames
	get the name of every anchor of pane id "com.apple.preference.spotlight"
	reveal anchor "searchResults" of pane id "com.apple.preference.spotlight"
end tell

delay 2

tell application "System Events"
	tell process "System Preferences"
		# first checkbox in main window
		#click checkbox 1 of tab group 1 of window 1
		# first checkbox of first row in table in window
		#click checkbox 1 of row 1 of table 1 of scroll area 1 of tab group 1 of window 1
		set theCheckbox to (checkbox 1 of row 1 of table 1 of scroll area 1 of tab group 1 of window 1)
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 1
	end tell
end tell

delay 2

tell application "System Preferences"
	quit
end tell

EOF

# waiting for the applescript settings to be applied to the preferences file to make the script work
sleep 10

}
# only use the function if the spotlight preferences shall be reset completely
open_system_prefs_spotlight

# if script hangs it has to be run with an app that has the the right to write to accessibility settings
# in system preferences - security - assistance devices
# e.g. terminal or iterm

# change indexing order and disable some search results
# yosemite (and newer) specific search results
# 	MENU_DEFINITION
# 	MENU_CONVERSION
# 	MENU_EXPRESSION
# 	MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
# 	MENU_WEBSEARCH             (send search queries to Apple)
# 	MENU_OTHER

echo "settings spotlight system preferences options..."

/usr/libexec/PlistBuddy -c 'Delete orderedItems' ~/Library/Preferences/com.apple.Spotlight.plist
/usr/libexec/PlistBuddy -c 'Add orderedItems array' ~/Library/Preferences/com.apple.Spotlight.plist

spotlightconfig=(
"0      APPLICATIONS                    false"
"1      SYSTEM_PREFS                    false"
"2      DIRECTORIES                     false"
"3      PDF                             false"
"4      FONTS                           false"
"5      DOCUMENTS                       false"
"6      MESSAGES                        false"
"7      CONTACT                         false"
"8      EVENT_TODO                      false"
"9      IMAGES                          false"
"10     BOOKMARKS                       false"
"11     MUSIC                           false"
"12     MOVIES                          false"
"13     PRESENTATIONS                   false"
"14     SPREADSHEETS                    false"
"15     SOURCE                          false"
"16     MENU_DEFINITION                 false"
"17     MENU_OTHER                      false"
"18     MENU_CONVERSION                 false"
"19     MENU_EXPRESSION                 false"
"20     MENU_WEBSEARCH                  false"
"21     MENU_SPOTLIGHT_SUGGESTIONS      false"
)

for entry in "${spotlightconfig[@]}"
do
    #echo $entry
    ITEMNR=$(echo $entry | awk '{print $1}')
    SPOTLIGHTENTRY=$(echo $entry | awk '{print $2}')
    ENABLED=$(echo $entry | awk '{print $3}')
    #echo $ITEMNR
    #echo $SPOTLIGHTENTRY
    #echo $ENABLED
    /usr/libexec/PlistBuddy -c 'Add orderedItems:'$ITEMNR' dict' ~/Library/Preferences/com.apple.Spotlight.plist
    /usr/libexec/PlistBuddy -c 'Add orderedItems:'$ITEMNR':enabled bool '$ENABLED'' ~/Library/Preferences/com.apple.Spotlight.plist
    /usr/libexec/PlistBuddy -c 'Add orderedItems:'$ITEMNR':name string '$SPOTLIGHTENTRY'' ~/Library/Preferences/com.apple.Spotlight.plist
done

echo ''

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

# only turn on indexing of the currently booted volume
#CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | awk '{print $3}')
#sudo mdutil -i on /Volumes/"$CURRENTLY_BOOTED_VOLUME"

#turning on indexing for all volumes named macintosh*
MACINTOSH_VOLUMES=$(ls -1 /Volumes | grep macintosh*)
#echo "$MACINTOSH_VOLUMES"
for i in $(echo "$MACINTOSH_VOLUMES" | cat )
do
	sudo mdutil -i on /Volumes/"$i"
done

echo "done ;)"

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
#/usr/libexec/PlistBuddy -c "Set lookupEnabled:suggestionsEnabled bool false" ~/Library/Preferences/com.apple.lookup.plist
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true

# spotlight menu bar icon
# hide or move with bartender


### removing security permissions
remove_apps_security_permissions_stop


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

###
### unsetting password
###

unset SUDOPASSWORD

