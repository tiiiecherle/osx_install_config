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
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
        env_sudo
    else
        env_enter_sudo_password
    fi
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
"$SOURCE_APP_NAME   	                    $SYSTEM_GUI_SETTINGS_APP                                    1"
"$SOURCE_APP_NAME	                       	System Events                                           	1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions
#echo ''



###
### preferences spotlight
###

echo ''
echo "preferences spotlight"

env_start_sudo

trap_function_exit_middle() { env_stop_sudo; unset SUDOPASSWORD; unset USE_PASSWORD; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

open_system_prefs_spotlight() {
    
if [[ -e ~/Library/Preferences/com.apple.Spotlight.plist ]]
then
	rm ~/Library/Preferences/com.apple.Spotlight.plist
else
	:
fi

sleep 5


VERSION_TO_CHECK_AGAINST=12
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos until and including 12

#osascript 2>/dev/null <<EOF
osascript <<EOF
	
	tell application "System Preferences"
	    reopen
	    delay 3
		#activate
		#delay 2
		set current pane to pane "com.apple.preference.spotlight"
		#set tabnames to (get the name of every anchor of pane id "com.apple.preference.spotlight")
		#display dialog tabnames
		get the name of every anchor of pane id "com.apple.preference.spotlight"
		reveal anchor "searchResults" of pane id "com.apple.preference.spotlight"
	end tell
	
	# do not use visible as it makes the window un-clickable
	#tell application "System Events" to tell process "System Settings" to set visible to true
    #delay 1
    tell application "System Events" to tell process "System Preferences" to set frontmost to true
    delay 1
	
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

else
    # macos versions 13 and up
	# ls -la /System/Library/PreferencePanes/
	# if there is no prefpane in this directory, see defaults_write/_scripts_final/_mobileconfig/install_profiles_13.scpt
	# for using applescript to open prefpane
  	#open /System/Library/PreferencePanes/Spotlight.prefPane
  	open "x-apple.systempreferences:com.apple.Siri-Settings.extension"
  	
  	sleep 2

	osascript <<EOF  	
  		tell application "System Events"
		tell process "System Settings"
			set theCheckbox to (checkbox 1 of UI element 1 of row 1 of table 1 of scroll area 1 of group 3 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1)
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
	
	tell application "System Settings"
		quit
	end tell
EOF
  	
fi

# waiting for the applescript settings to be applied to the preferences file to make the script work
echo "waiting for the applescript settings to be applied to the preferences file to make the script work..."
sleep 10

}
# only use the function if the spotlight preferences shall be reset completely
# without using it on a clean install the com.apple.Spotlight.plist will be missing
open_system_prefs_spotlight

# if script hangs it has to be run with an app that has the the right to write to accessibility settings
# in system settings - security - assistance devices
# e.g. terminal or iterm

# change indexing order and disable some search results
# yosemite (and newer) specific search results
# 	MENU_DEFINITION
# 	MENU_CONVERSION
# 	MENU_EXPRESSION
# 	MENU_SPOTLIGHT_SUGGESTIONS (send search queries to Apple)
# 	MENU_WEBSEARCH             (send search queries to Apple)
# 	MENU_OTHER

echo "settings spotlight system settings options..."
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :orderedItems" ~/Library/Preferences/com.apple.Spotlight.plist) ]] > /dev/null 2>&1
then
	:
else
	/usr/libexec/PlistBuddy -c 'Delete orderedItems' ~/Library/Preferences/com.apple.Spotlight.plist
fi
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

sleep 1
defaults read ~/Library/Preferences/com.apple.Spotlight.plist &> /dev/null
sleep 1

# mounting system as read/write until next reboot
if [[ "$MACOS_VERSION_MAJOR" != 10.15 ]]
then
    # macos versions other than 10.15
    # not necessary on 10.14
    # more complicated and risky on 11 and newer due to signed system volume (ssv)
	:
else
    # macos versions 10.15 and up
    # in 10.15 /System default gets mounted read-only
    # can only be mounted read/write with according SIP settings
    sudo mount -uw /
    # stays mounted rw until next reboot
    sleep 0.5
fi

# another way of stopping indexing AND searching for a volume (very helpful for network volumes) is putting an empty file ".metadata_never_index"
# in the root directory of the volume and run "mdutil -E /VOLUMENAME" afterwards, check if it worked with sudo mdutil -s /VOLUMENAME
# to turn indexing back on delete ".metadata_never_index" on the volume run mdutil -i followed by mdutil -E for that volume
#sudo touch /VOLUMENAME/.metadata_never_index

SPOTLIGHT_FOLDER_CONFIG="/Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/System/Volumes/Data/.Spotlight-V100"
SPOTLIGHT_FOLDER="/private/var/db/Spotlight-V100"
SPOTLIGHT_INDEX_FOLDERS=(
"$SPOTLIGHT_FOLDER_CONFIG"
"$SPOTLIGHT_FOLDER"
)
env_get_mounted_disks
SPOTLIGHT_VOLUMES=$(printf "%s\n" "${LIST_OF_ALL_MOUNTED_VOLUMES_ON_BOOT_VOLUME[@]}" | grep -v '/Update$' | grep -v '/Preboot$' | grep -iv '/vm$')
run_spotlight_command() {
	if [[ "$SPOTLIGHT_COMMAND" == "" ]]
	then
		echo "SPOTLIGHT_COMMAND is empty, skipping..."
	else
		while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
		    SPOTLIGHT_VOLUME="$line"
		    #echo "$SPOTLIGHT_VOLUME"
		    #eval sudo "${COMMAND1}" "$SPOTLIGHT_VOLUME"
			"$SHELL" -c ""${SPOTLIGHT_COMMAND}" /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME""$SPOTLIGHT_VOLUME""
		done <<< "$(printf "%s\n" "${SPOTLIGHT_VOLUMES[@]}")"
	fi
}

# stop indexing before rebuilding the index
#killall mds &> /dev/null

get_sizes_spotlight_folders() {
	# sizes of spotlight folders
	echo ''
	echo "sizes of spotlight folders..."
	while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
	    SPOTLIGHT_INDEX_FOLDER="$line"
	    #echo "$SPOTLIGHT_FOLDER"
		if [[ -e "$SPOTLIGHT_INDEX_FOLDER" ]]
		then
			sudo du -hs "$SPOTLIGHT_INDEX_FOLDER"
		else
			echo ""$SPOTLIGHT_INDEX_FOLDER" does not exist, skipping..."
		fi
	done <<< "$(printf "%s\n" "${SPOTLIGHT_INDEX_FOLDERS[@]}")"
}
get_sizes_spotlight_folders

# turning indexing off
#sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.metadata.mds.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
#sleep 2
#sudo launchctl disable system/com.apple.metadata.mds
# currently booted volume
echo ''
echo "disabling indexing..."
SPOTLIGHT_COMMAND='sudo mdutil -i off'
run_spotlight_command

# listing spotlight folder content
#sudo ls -a -l "$SPOTLIGHT_FOLDER"

# getting size of spotlight folder
#sudo du -hs "$SPOTLIGHT_FOLDER"

# deleting spotlight indexes folder
echo ''
echo "removing the Spotlight index files..."
while IFS= read -r line || [[ -n "$line" ]]
do
    if [[ "$line" == "" ]]; then continue; fi
    SPOTLIGHT_INDEX_FOLDER="$line"
    #echo "$SPOTLIGHT_FOLDER"
	if [[ -e "$SPOTLIGHT_INDEX_FOLDER" ]]
	then
		sudo rm -rf "$SPOTLIGHT_INDEX_FOLDER"
	else
		echo ""$SPOTLIGHT_INDEX_FOLDER" does not exist, skipping..."
	fi
done <<< "$(printf "%s\n" "${SPOTLIGHT_INDEX_FOLDERS[@]}")"

# this does the same as sudo rm -rf "$SPOTLIGHT_FOLDER"
#SPOTLIGHT_COMMAND='sudo mdutil -X'
#run_spotlight_command

# stop indexing for some volumes which will not be indexed again
# only shows in system settings if connected
sudo defaults write "$SPOTLIGHT_FOLDER_CONFIG"/VolumeConfiguration Exclusions -array "/Volumes/office" "/Volumes/extra" "/Volumes/scripts"
# check entries
#sudo defaults read /.Spotlight-V100/VolumeConfiguration Exclusions
# activating changes in system settings
#sudo killall mds		# done in restarting affected apps

# waiting for volume information to be available after deleting the indexes and killing mds
sleep 5

# currently booted volume
echo ''
echo "enabling indexing..."
SPOTLIGHT_COMMAND='sudo mdutil -i on'
run_spotlight_command

# deleting and reindexing volumes
# all turned on volumes (mdutil -i)
echo ''
echo "reindexing volumes..."
SPOTLIGHT_COMMAND='sudo mdutil -E'
run_spotlight_command

# checking status of volumes
echo ''
echo "checking status of volumes..."
SPOTLIGHT_COMMAND='sudo mdutil -s'
run_spotlight_command

# disabling lookup / spotlight suggestions
#/usr/libexec/PlistBuddy -c "Set lookupEnabled:suggestionsEnabled bool false" ~/Library/Preferences/com.apple.lookup.plist
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true

# spotlight menu bar icon
# hide or move with bartender

### removing security permissions
#remove_apps_security_permissions_stop


###
### killing affected applications
###

echo ''
echo "restarting affected apps..."

apps_to_kill=(
"cfprefsd"
"$SYSTEM_GUI_SETTINGS_APP"
"mds"
"mds_stores"
)

while IFS= read -r line || [[ -n "$line" ]]
do
    if [[ "$line" == "" ]]; then continue; fi
    app="$line"
    killall "$app" > /dev/null 2>&1
done <<< "$(printf "%s\n" "${apps_to_kill[@]}")"


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

get_sizes_spotlight_folders

echo ''
echo "done ;)"
echo ''
#echo "a few changes need a reboot or logout to take effect"
#echo "initializing reboot"

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


### documentation
# add a folder to the Spotlight index
#mdimport -i /FOLDER_TO_ADD

