#!/bin/bash

# clears the dock of all apps, then adds your individual dock config
# config file:
# ~/Library/Preferences/com.apple.dock.plist


### variables
DEF_W="/usr/bin/defaults write"
PLB=/usr/libexec/PlistBuddy
OSA=/usr/bin/osascript
DOCK="com.apple.dock"

# XML
APP_HEAD="<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>"
APP_TAIL="</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
FOLDER_HEAD="<dict><key>tile-data</key><dict><key>arrangement</key><integer>0</integer><key>displayas</key><integer>1</integer><key>file-data</key><dict><key>_CFURLString</key><string>"

# script directory
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
SCRIPT_DIR_FINAL=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")

# getting logged in user
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#echo "loggedInUser is $loggedInUser..."

echo ''

### functions
# left dock side (persistent-apps)
add_spacer() {
    $DEF_W $DOCK ''"$ENTRY_POSITION"'' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'
}

add_entry_app() {
    $DEF_W $DOCK ''"$ENTRY_POSITION"'' -array-add "$APP_HEAD/Applications/$APP_NAME/$APP_TAIL"
}

add_entry_folder() {
    FOLDER_TAIL="</string><key>_CFURLStringType</key><integer>0</integer></dict><key>preferreditemsize</key><integer>"$PREFERRED_ITEM_SIZE"</integer><key>showas</key><integer>"$VIEWAS"</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"
    $DEF_W $DOCK ''"$ENTRY_POSITION"'' -array-add "$FOLDER_HEAD/$FOLDER_PATH/$FOLDER_TAIL"
    
    # PREFERRED_ITEM_SIZE
    # -1  	default
    # 2		any number, but only takes effect if viewas is set to grid
    #
    # VIEWAS   
    # 1	    Automatic
    # 2	    Stack
    # 3		Grid
    # 4	    List
}

add_entry_recent() {
    # recents entry
    $DEF_W $DOCK ''"$ENTRY_POSITION"'' -array-add "<dict><key>tile-data</key><dict><key>list-type</key><integer>"$LIST_TYPE"</integer><key>preferreditemsize</key><integer>"$PREFERRED_ITEM_SIZE"</integer><key>viewas</key><integer>"$VIEWAS"</integer></dict><key>tile-type</key><string>recents-tile</string></dict>"
    
    # LIST_TYPE
    # 1		Recent Applications
    # 2		Recent Documents
    # 3		Recent Servers
    # 4		Favorite Volumes
    # 5		Favorite Servers
    #
    # PREFERRED_ITEM_SIZE
    # -1  	default
    # 2		any number, but only takes effect if viewas is set to grid
    #
    # VIEWAS   
    # 0	     	Automatic
    # 1	     	Stack
    # 2		Grid
    # 3	       	List
}

# using profiles
set_dock_from_profile() {
    LINENUMBER="0"
    while IFS='' read -r line || [[ -n "$line" ]]
    do
        i="$line"
        LINENUMBER=$(($LINENUMBER+1))

        ENTRY_POSITION=$(echo "$i" | awk '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
	    #echo "$ENTRY_POSITION"
	    ENTRY_TYPE=$(echo "$i" | awk '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
	    #echo "$ENTRY_TYPE"
	    ENTRY_VALUE1=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^ //g' | sed 's/ $//g')
	    ENTRY_VALUE2=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $4}' | sed 's/^ //g' | sed 's/ $//g')
	    ENTRY_VALUE3=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $5}' | sed 's/^ //g' | sed 's/ $//g')
	    #echo "$ENTRY_VALUE1"
	    #echo "$ENTRY_VALUE2"
	    #echo "$ENTRY_VALUE3"
	    
        if [[ "$i" =~ ^[\#] ]] || [[ "$i" == "" ]]
        then
            #echo "line is commented out or empty..."
            :
	    elif [[ ! "$ENTRY_POSITION" =~ ^(persistent-apps|persistent-others)$ ]] || [[ ! "$ENTRY_TYPE" =~ ^(spacer|app|folder|recent)$ ]]
    	then
            echo "wrong syntax for entry in profile in line "$LINENUMBER": "$i", skipping..."
            SYNTAXERRORS=$(($SYNTAXERRORS+1))
        else
	    	if [[ "$ENTRY_TYPE" == "spacer" ]]
	        then
	            add_spacer
	        elif [[ "$ENTRY_TYPE" == "app" ]]
	        then
	            APP_NAME="$ENTRY_VALUE1"
	            add_entry_app
	        elif [[ "$ENTRY_TYPE" == "folder" ]]
	        then
	            FOLDER_PATH="$(eval echo $ENTRY_VALUE1)"
	            PREFERRED_ITEM_SIZE="$ENTRY_VALUE2"
	            VIEWAS="$ENTRY_VALUE3"
	            add_entry_folder
	        elif [[ "$ENTRY_TYPE" == "recent" ]]
	        then
	            if [[ "$ENTRY_POSITION" == "persistent-others" ]]
	            then
    	            LIST_TYPE="$ENTRY_VALUE1"
    	            PREFERRED_ITEM_SIZE="$ENTRY_VALUE2"
    	            VIEWAS="$ENTRY_VALUE3"
    	            add_entry_recent
    	        else
    	            echo "recent entries are only allowed in the persistent-others section of the dock, skipping profile line $LINENUMBER: $i..."
    	        fi
	        else
	            echo "incorrect profile entry..."
	        fi
        fi      
    done <"$DOCK_PROFILE"    
}

ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}

# profile based user specifc configuration
use_user_costomized_profiles() {
    if [[ -e "$SCRIPT_DIR"/profiles/dock_profile_"$loggedInUser".conf ]]
    then
        echo "dock profile found for $loggedInUser..."
        DOCK_PROFILE="$SCRIPT_DIR"/profiles/dock_profile_"$loggedInUser".conf
    elif [[ -e "$SCRIPT_DIR"/profiles/dock_profile_example.conf ]]
    then
        echo "no dock profile found for $loggedInUser, but example profile found..."
        echo "running script with example profile..."
        DOCK_PROFILE="$SCRIPT_DIR"/profiles/dock_profile_example.conf
    else
        echo "no dock profile found for $loggedInUser and no example profile found, exiting..."
        echo ''
        exit
    fi
}

###
### setting dock items
###


# user customized profiles
use_user_costomized_profiles

# launchpad
$DEF_W $DOCK 'checked-for-launchpad' -bool true
  
# clearing dock
$DEF_W $DOCK 'persistent-apps' -array ''
$DEF_W $DOCK 'persistent-others' -array ''

# entries from profile
set_dock_from_profile


### documentation
# if the script shall be used without a profile just comment out "use_user_costomized_profiles" and "set_dock_from_profile" and add entries here, e.g.
# app on left dock side
#ENTRY_POSITION="persistent-apps"
#APP_NAME="Pages.app"
#add_entry_app

# spacer on left dock side
#ENTRY_POSITION="persistent-apps"
#add_spacer

# folder on right dock side
#ENTRY_POSITION="persistent-others"
#FOLDER_PATH="/Applications/Utilities"
#PREFERRED_ITEM_SIZE=1
#VIEWAS=2
#add_entry_folder

# recent documents folder on right dock side
#ENTRY_POSITION="persistent-others"
#LIST_TYPE=2
#PREFERRED_ITEM_SIZE=-1
#VIEWAS=1
#add_entry_recent


### applying changes
$OSA -e 'tell application "Dock" to quit'


### done
echo ''
echo "done ;)"
echo ''