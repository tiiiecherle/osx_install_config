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
if [[ "$MACOS_VERSION_MAJOR" != "10.15" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.15, exiting..."
    echo ''
    exit
else
    :
fi



###
### siri
###


### disable all siri analytics
echo ''
echo "disabling siri analytics..."
# already done in system preferences script before but some apps seem to appear here later
for i in $(/usr/libexec/PlistBuddy -c "Print CSReceiverBundleIdentifierState" /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
do
        echo "$i"
	    /usr/libexec/PlistBuddy -c "Set CSReceiverBundleIdentifierState:$i false" /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist
done
defaults read /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist &> /dev/null
#echo ''
#echo "the changes need a reboot to take effect..."


### disabling siri suggestions and learning
echo ''
echo "disabling siri suggestions and learning..."

APPS_TO_DISABLE_FOR_SIRI=(
"Reminders"
"FaceTime"
"Photos"
"Calendar"
"Maps"
"Contacts"
"Mail"
"Messages"
"Notes"
"Podcasts"
"Safari"
)

CONFIG_FILE="/Users/"$USER"/Library/Preferences/com.apple.suggestions.plist"
/usr/libexec/PlistBuddy -c "Delete :AppCanShowSiriSuggestionsBlacklist" "$CONFIG_FILE" 2> /dev/null
/usr/libexec/PlistBuddy -c "Delete :SiriCanLearnFromAppBlacklist" "$CONFIG_FILE" 2> /dev/null
/usr/libexec/PlistBuddy -c "Add :AppCanShowSiriSuggestionsBlacklist array" "$CONFIG_FILE" 2> /dev/null
/usr/libexec/PlistBuddy -c "Add :SiriCanLearnFromAppBlacklist array" "$CONFIG_FILE" 2> /dev/null

# activating changes
defaults read "$CONFIG_FILE" &> /dev/null

NUM=0
while IFS= read -r line || [[ -n "$line" ]]
do
    if [[ "$line" == "" ]]; then continue; fi
    APP_NAME="$line"
	PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin / | grep -i "/$APP_NAME.app$" | sort -n | head -1)
	APP_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APP/Contents/Info.plist")
	if [[ "$APP_ID" == "" ]];then echo "APP_ID of "$APP_NAME" is empty, skipping entry..." && continue; fi
	echo ""$APP_ID"..."
	/usr/libexec/PlistBuddy -c "Add :AppCanShowSiriSuggestionsBlacklist:"$NUM" string "$APP_ID"" "$CONFIG_FILE"
	/usr/libexec/PlistBuddy -c "Add :SiriCanLearnFromAppBlacklist:"$NUM" string "$APP_ID"" "$CONFIG_FILE"
	NUM=((NUM+1))
	# activating entry
	#defaults read "$CONFIG_FILE" &> /dev/null
done <<< "$(printf "%s\n" "${APPS_TO_DISABLE_FOR_SIRI[@]}")"

# activating changes
defaults read "$CONFIG_FILE" &> /dev/null


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''
