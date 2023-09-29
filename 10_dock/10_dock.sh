#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### dock
###

# clears the dock of all apps, then adds your individual dock config
# config file:
# ~/Library/Preferences/com.apple.dock.plist


### variables
DOCK="com.apple.dock"

# XML
APP_HEAD="<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>"
APP_TAIL="</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
FOLDER_HEAD="<dict><key>tile-data</key><dict><key>arrangement</key><integer>0</integer><key>displayas</key><integer>1</integer><key>file-data</key><dict><key>_CFURLString</key><string>"

# script directory
SCRIPT_DIR_FINAL="$SCRIPT_DIR_ONE_BACK"

echo ''

### functions
# left dock side (persistent-apps)
add_spacer() {
    defaults write $DOCK "$ENTRY_POSITION" -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'
}
# small spacer
# defaults write com.apple.dock persistent-others -array-add '{ "tile-data" = {}; "tile-type"="small-spacer-tile"; }' && \

add_entry_app() {
    defaults write $DOCK "$ENTRY_POSITION" -array-add "$APP_HEAD$PATH_TO_APPS/$APP_NAME/$APP_TAIL"
}

add_entry_system_app() {
    defaults write $DOCK "$ENTRY_POSITION" -array-add "$APP_HEAD$PATH_TO_SYSTEM_APPS/$APP_NAME/$APP_TAIL"
}

add_entry_preboot_app() {
    defaults write $DOCK "$ENTRY_POSITION" -array-add "$APP_HEAD$PATH_TO_PREBOOT_APPS/$APP_NAME/$APP_TAIL"
}

add_entry_folder() {
    FOLDER_TAIL="</string><key>_CFURLStringType</key><integer>0</integer></dict><key>preferreditemsize</key><integer>"$PREFERRED_ITEM_SIZE"</integer><key>showas</key><integer>"$VIEWAS"</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"
    defaults write $DOCK "$ENTRY_POSITION" -array-add "$FOLDER_HEAD/$FOLDER_PATH/$FOLDER_TAIL"
    
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
    defaults write $DOCK "$ENTRY_POSITION" -array-add "<dict><key>tile-data</key><dict><key>list-type</key><integer>"$LIST_TYPE"</integer><key>preferreditemsize</key><integer>"$PREFERRED_ITEM_SIZE"</integer><key>viewas</key><integer>"$VIEWAS"</integer></dict><key>tile-type</key><string>recents-tile</string></dict>"
        
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
    # 0	     Automatic
    # 1	     Stack
    # 2		 Grid
    # 3	     List
}

# using profiles
set_dock_from_profile() {
    LINENUMBER="0"
    while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
        i="$line"
        LINENUMBER=$((LINENUMBER+1))

        ENTRY_POSITION=$(echo "$i" | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    #echo "$ENTRY_POSITION"
	    ENTRY_TYPE=$(echo "$i" | awk '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    #echo "$ENTRY_TYPE"
	    ENTRY_VALUE1=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    ENTRY_VALUE2=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $4}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    ENTRY_VALUE3=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $5}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    #echo "$ENTRY_VALUE1"
	    #echo "$ENTRY_VALUE2"
	    #echo "$ENTRY_VALUE3"
	    
        if [[ "$i" =~ ^[\#] ]] || [[ "$i" == "" ]]
        then
            #echo "line is commented out or empty..."
            :
	    elif [[ ! "$ENTRY_POSITION" =~ ^(persistent-apps|persistent-others)$ ]] || [[ ! "$ENTRY_TYPE" =~ ^(spacer|app|system_app|preboot_app|system_volumes_data_app|folder|recents)$ ]]
    	then
            echo "wrong syntax for entry in profile in line "$LINENUMBER": "$i", skipping..."
            SYNTAXERRORS=$((SYNTAXERRORS+1))
        else
	    	if [[ "$ENTRY_TYPE" == "spacer" ]]
	        then
	            add_spacer
	        elif [[ "$ENTRY_TYPE" == "app" ]]
	        then
	            APP_NAME="$ENTRY_VALUE1"
	            add_entry_app
	        elif [[ "$ENTRY_TYPE" == "system_app" ]]
	        then
	            APP_NAME="$ENTRY_VALUE1"
	            add_entry_system_app
	        elif [[ "$ENTRY_TYPE" == "preboot_app" ]]
	        then
	            APP_NAME="$ENTRY_VALUE1"
	            add_entry_preboot_app
	        elif [[ "$ENTRY_TYPE" == "folder" ]]
	        then
	            FOLDER_PATH="$(eval echo $ENTRY_VALUE1)"
	            PREFERRED_ITEM_SIZE="$ENTRY_VALUE2"
	            VIEWAS="$ENTRY_VALUE3"
	            add_entry_folder
	        elif [[ "$ENTRY_TYPE" == "recents" ]]
	        then
	            if [[ "$ENTRY_POSITION" == "persistent-others" ]]
	            then
    	            LIST_TYPE="$ENTRY_VALUE1"
    	            PREFERRED_ITEM_SIZE="$ENTRY_VALUE2"
    	            VIEWAS="$ENTRY_VALUE3"
    	            add_entry_recent
    	        else
    	            echo "recents entries are only allowed in the persistent-others section of the dock, skipping profile line $LINENUMBER: $i..."
    	        fi
	        else
	            echo "incorrect profile entry..."
	        fi
        fi
    done <<< "$(cat "$DOCK_PROFILE")"
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
        echo "no dock profile found for "$loggedInUser" and no example profile found for this version of macos, exiting..."
        echo ''
        exit
    fi
}

###
### setting dock items
###

# user customized profiles
use_user_costomized_profiles

echo "setting dock items..."

# launchpad
defaults write $DOCK 'checked-for-launchpad' -bool true

# making sure dock file is available (if changed recently before running this script)
sleep 2
  
# clearing dock
defaults write $DOCK 'persistent-apps' -array ''
# hiding recent section in dock is a system settings value which is re-set in 11c_macos_preferences
# show last used applications in the dock
defaults write com.apple.dock show-recents -bool false
defaults write $DOCK 'recent-apps' -array ''
defaults write $DOCK 'persistent-others' -array ''

# making sure dock file is available (if changed recently before running this script)
sleep 2

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
#FOLDER_PATH=""$PATH_TO_APPS"/Utilities"
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
#osascript -e 'tell application "Dock" to quit'
killall Dock


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


### done
echo ''
echo "done ;)"
echo ''
