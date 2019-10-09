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
"$SOURCE_APP_NAME                           System Preferences                                         	1"
"$SOURCE_APP_NAME                           System Events                                           	1"
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
# without using it on a clean install the com.apple.Spotlight.plist will be missing
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

sleep 1
defaults read ~/Library/Preferences/com.apple.Spotlight.plist &> /dev/null
sleep 1

# another way of stopping indexing AND searching for a volume (very helpful for network volumes) is putting an empty file ".metadata_never_index"
# in the root directory of the volume and run "mdutil -E /Volumes/*" afterwards, check if it worked with sudo mdutil -s /Volumes/*
# to turn indexing back on delete ".metadata_never_index" on the volume run mdutil -i followed by mdutil -E for that volume
#sudo touch /Volumes/VOLUMENAME/.metadata_never_index

# stop indexing before rebuilding the index
#killall mds &> /dev/null

# listing spotlight folder content
#sudo ls -a -l /.Spotlight-V100

# deleting spotlight indexes folder
echo ''
echo "removing the Spotlight index files..."
#if [[ -e /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/.Spotlight-V100 ]]
#then
#	echo ''
#	echo "cleaning spotlight index..."
#	sudo find /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/.Spotlight-V100 -mindepth 1 -maxdepth 1 -name "Store*" -print0 | xargs -0 sudo rm -rf
#	#sudo rm -rf /private/var/db/Spotlight-V100/Volumes/*
#else
#	:
#fi
# using /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/ with -X does not work
sudo mdutil -X /
echo ''

# stop indexing for some volumes which will not be indexed again
VERSION_TO_CHECK_AGAINST=10.14
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.14
	:
else
    # macos versions 10.15 and up
	env_use_password | sudo mount -uw /
	sleep 1
fi
sudo defaults write /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes/office" "/Volumes/extra" "/Volumes/scripts"

# disable spotlight indexing for any volume that gets mounted and has not yet been indexed before.
#sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"

# check entries
#sudo defaults read /.Spotlight-V100/VolumeConfiguration Exclusions

# deleting and reindexing volumes
# all turned on volumes (mdutil -i)
#sudo mdutil -E /Volumes/*
# currently booted volume
#sudo mdutil -E /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"
sudo mdutil -E /

# turning indexing off
#sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
# all volumes
#sudo mdutil -i off /Volumes/*
# currently booted volume
echo ''
echo "disabling indexing..."
#sudo mdutil -i off /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"
sudo mdutil -i off /

# turning indexing on for all volumes
#sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist
#sudo mdutil -i on /Volumes/*

# turn on indexing
# all volumes
#sudo mdutil -i on /Volumes/*
# currently booted volume
echo ''
echo "enabling indexing..."
#sudo mdutil -i on -E /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"
sudo mdutil -i on /

# turning on indexing for all volumes named macintosh*
#MACINTOSH_VOLUMES=$(ls -1 /Volumes | grep macintosh | grep -v "Daten$")
#while IFS= read -r line || [[ -n "$line" ]]
#do
#    if [[ "$line" == "" ]]; then continue; fi
#    i="$line"
#    #echo $i
#    sudo mdutil -i on -E /Volumes/"$i"
#done <<< "$(printf "%s\n" "${MACINTOSH_VOLUMES[@]}")"

# checking status of volumes
echo ''
echo "checking status of volumes..."
sudo mdutil -s /Volumes/*

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
"System Preferences"
#"Activity Monitor"
#"Address Book"
#"Calendar"
#"Contacts"
#"cfprefsd"
#"Dock"
#"Finder"
#"Mail"
#"Messages"
#"System Preferences"
#"Safari"
#"SystemUIServer"
#"TextEdit"
)

while IFS= read -r line || [[ -n "$line" ]]
do
    if [[ "$line" == "" ]]; then continue; fi
    app="$line"
    killall "$app" > /dev/null 2>&1
done <<< "$(printf "%s\n" "${apps_to_kill[@]}")"


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''
#echo "a few changes need a reboot or logout to take effect"
#echo "initializing reboot"

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


