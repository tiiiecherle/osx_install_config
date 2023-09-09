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
### user config profile
###

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
	SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
	env_check_for_user_profile
else
	:
fi



###
### removing dock notifications
###


### documentation
# https://apple.stackexchange.com/questions/344278/how-can-i-disable-the-red-software-update-notification-bubble-on-the-system-pref
# defaults read com.apple.systempreferences AttentionPrefBundleIDs


### delete all entries
#defaults delete com.apple.systempreferences AttentionPrefBundleIDs
#killall Dock


### set value for specific entry
# macos 10.15 displays a red dot notification if icloud is not used
# "com.apple.preferences.AppleIDPrefPane" = 1;
if [[ "$REMOVE_APPLE_ID_DOCK_NOTIFICATIONS" == "yes" ]] || [[ "$REMOVE_APPLE_ID_DOCK_NOTIFICATIONS" == "" ]]
then
	defaults write com.apple.systempreferences AttentionPrefBundleIDs -dict-add com.apple.preferences.AppleIDPrefPane -integer 0
else
	:
fi

# macos displays a red dot notification if a system software update is available
# reaaperas after search for new software in gui
# "com.apple.preferences.softwareupdate" = 1;
defaults write com.apple.systempreferences AttentionPrefBundleIDs -dict-add com.apple.preferences.softwareupdate -integer 0

if [[ -z $(/usr/libexec/PlistBuddy -c "Print :AttentionPrefBundleIDs:com.apple.preferences.softwareupdate"  ~/Library/Preferences/com.apple.systempreferences.plist) ]] > /dev/null 2>&1
then
	:
else
	/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.systempreferences.plist -c 'Delete AttentionPrefBundleIDs:com.apple.preferences.softwareupdate'
fi

#killall Dock


### activating changes
killall Dock


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''