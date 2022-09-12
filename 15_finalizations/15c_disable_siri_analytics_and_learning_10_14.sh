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
if [[ "$MACOS_VERSION_MAJOR" != "10.14" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.14, exiting..."
    echo ''
    exit
else
    :
fi



###
### siri
###

# disable all siri analytics
# already done in system preferences script before but some apps seam to appear here later
for i in $(/usr/libexec/PlistBuddy -c "Print CSReceiverBundleIdentifierState" /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
do
        #echo $i
	    /usr/libexec/PlistBuddy -c "Set CSReceiverBundleIdentifierState:$i false" /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist
done


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "the changes need a reboot to take effect..."
echo ''
echo "done ;)"
echo ''
