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
### compatibility
###

# specific macos version only
if [[ "$MACOS_VERSION_MAJOR" != "11" ]]
then
    echo ''
    echo "this script is only compatible with macos 11, exiting..."
    echo ''
    exit
else
    :
fi



###
### security permissions
###

echo ''    
env_databases_apps_security_permissions
env_identify_terminal


echo "setting security and automation permissions..."
### automation
# macos versions 10.14 and up
AUTOMATION_APPS=(
# source app name							automated app name										    allowed (1=yes, 0=no)
"$SOURCE_APP_NAME                           System Events                                               1"
"$SOURCE_APP_NAME                           Finder		                                                1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions


### sfltool
# sfltool restore|add-item|save-lists|test|archive|enable-modern|dump-server-state|clear|disable-modern|dump-storage|list-info [options]


### alternative to mysides
# https://github.com/robperc/FinderSidebarEditor


### mysides
# BREW_PATH_PREFIX=$(brew --prefix)
# installs to "$BREW_PATH_PREFIX"/bin/mysides
# -rwxr-xr-x    1 root  wheel  47724 14 Apr 02:07 mysides
# https://github.com/mosen/mysides
# newer version here
# https://github.com/Tatsh/mysides

echo ''
if command -v mysides &> /dev/null
then
    # installed
    echo "mysides is installed..."
else
    # not installed
    echo "mysides is not installed, trying via homebrew cask..."
    if command -v brew &> /dev/null
    then
        # installed
        echo ''
        brew install --cask --force mysides
        echo ''
    else
        # not installed      
        echo ''
        echo "homebrew and mysides are not installed, exiting..." &>2
        echo ''
        exit
    fi
fi


### finder sidebar
echo ''
echo "clearing and setting finder sidebar items..."

# clearing out settings and removes icloud
#sfltool clear
# if everything is cleared with this command, block three (device, external drives, cds, dvds and ipods) would need a second reboot and applying settings again to work after first reboot
#sleep 5

# currently only working with latest git version, not with 1.0.0
# disable sip
# BREW_PATH_PREFIX=$(brew --prefix)
# copy build file to "$BREW_PATH_PREFIX"/bin/mysides
# sudo chown root:wheel ""$BREW_PATH_PREFIX"/bin/mysides"
# sudo chmod 755 ""$BREW_PATH_PREFIX"/bin/mysides"
mysides remove all
#
#mysides remove "Alle meine Dateien"
#mysides remove myDocuments.cannedSearch
#mysides remove iCloud
#mysides add domain-AirDrop nwnode://domain-AirDrop
#mysides remove domain-AirDrop >/dev/null 2>&1
#mysides add Programme file://"$PATH_TO_APPS"
#mysides add Schreibtisch file://Users/"$USER"/Desktop
#mysides add Dokumente file://Users/"$USER"/Documents
#mysides add Downloads file://Users/"$USER"/Downloads
#mysides add Filme file://Users/"$USER"/Movies
#mysides add Musik file://Users/"$USER"/Music
#mysides add Bilder file://Users/"$USER"/Pictures
#mysides add "$USER" file://Users/"$USER"

#touch ~/Library/Preferences/com.apple.sidebarlists.plist
#if [[ -e ~/Library/Preferences/com.apple.sidebarlists.plist ]]
#then
#	rm ~/Library/Preferences/com.apple.sidebarlists.plist
#else
#	:
#fi


### settings and functions
FINDER_SIDEBAR_ITEMS=(
# entry name						    position		        toggle status
"last used                              1                       off"
"airdrop                                2                       off"
"applications                           3                       on"
"desktop                                4                       on"
"documents                              5                       on"
"downloads                              6                       on"
"movies                                 7                       on"
"music                                  8                       on"
"pictures                               9                       on"
"user                                   10                      on"
"icloud_drive                           11                      off"
"mac                                    12                      off"
"internal drives                        13                      on"
"external drives                        14                      on"
"removable media                        15                      on"
"icloud                                 16                      off"
"bonjour                                17                      off"
"connected server                       18                      on"
"tags                                   19                      off"
)
FINDER_SIDEBAR_ITEMS_ARRAY=$(printf "%s\n" "${FINDER_SIDEBAR_ITEMS[@]}")

open_finder_preferences() {
    osascript <<EOF
        tell application "System Events"
        	tell process "Finder"
        		set frontmost to true
        		#click menu item "Einstellungen …" of menu "Finder" of menu bar item "Finder" of menu bar 1
        		keystroke "," using {command down}
        		delay 1
        		#click button "Seitenleiste" of toolbar 1 of window "Finder-Einstellungen"
        		click button 3 of toolbar 1 of window 1
        		delay 1
        	end tell
        end tell
EOF
}

toggle_sidebar_item_status() {
    osascript <<EOF
        tell application "System Events"
        	tell process "Finder"
            	set theCheckbox to checkbox $POSITION of window 1
            	tell theCheckbox
            		set checkboxStatus to value of theCheckbox as boolean
            		if checkboxStatus is $CHECK_CHECKBOXSTATUS then click theCheckbox
            	end tell
            	delay 0.2
            end tell
        end tell	
EOF
}

close_finder_preferences() {
    osascript <<EOF
        tell application "System Events"		
    	    delay 1
    	    #tell application "Finder" to close window "Finder-Einstellungen"
    	    tell application "Finder" to close window 1
    	end tell
EOF
}


### set sidebar preferences
open_finder_preferences

while IFS= read -r line || [[ -n "$line" ]]
do
    if [[ "$line" == "" ]]; then continue; fi
    local ITEM_ENTRY="$line"
    #echo "$APP_ENTRY"
    
   	local SIDEBAR_ITEM=$(echo "$ITEM_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    local POSITION=$(echo "$ITEM_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    local TOGGLE_STATUS=$(echo "$ITEM_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    
    if [[ "$TOGGLE_STATUS" == "on" ]]
    then
        local CHECK_CHECKBOXSTATUS="false"
    else
        local CHECK_CHECKBOXSTATUS="true"
    fi
    
    if [[ "$SIDEBAR_ITEM" == "icloud_drive" ]]
    then
        ICLOUD_DRIVE_POSITION="$POSITION"
    else
        :
    fi
    
    toggle_sidebar_item_status
    
    # unset variables for next entry
    unset SIDEBAR_ITEM
    unset POSITION
    unset TOGGLE_STATUS
    unset CHECK_CHECKBOXSTATUS     

done <<< "$(printf "%s\n" "${FINDER_SIDEBAR_ITEMS_ARRAY[@]}")"
			
close_finder_preferences 1>/dev/null


### user specific customization
SCRIPT_NAME="finder_sidebar_"$USER""
SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
SCRIPT_DIR_INPUT_KEEP="$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep
if [[ -e "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh ]]
then
    echo ''
    echo "user specific sidebar customization script found..."
    USER_ID=`id -u`
    chown "$USER_ID":staff "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    chmod 700 "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    . "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
else
    echo ''
    echo "user specific sidebar customization script not found......"
fi


### do not show icloud drive in drives
defaults write com.apple.finder SidebarShowingiCloudDesktop -bool false
defaults write com.apple.finder SidebarShowingSignedIntoiCloud -bool false


### show tags
defaults write com.apple.finder ShowRecentTags -bool false

# settings are in 
# ~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteVolumes.sfl2
# and
# ~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl2


### restarting finder
killall cfprefsd
killall Finder
sleep 5


### icloud drive
open_finder_preferences

POSITION=$ICLOUD_DRIVE_POSITION
CHECK_CHECKBOXSTATUS="true"

toggle_sidebar_item_status

close_finder_preferences 1>/dev/null

killall cfprefsd
killall Finder
sleep 5


### removing security permissions
#remove_apps_security_permissions_stop


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''
