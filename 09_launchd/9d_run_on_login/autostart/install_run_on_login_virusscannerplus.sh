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
### launchd & applescript to do things when changing network location
###

### installation should be done via restore script after first install
APP_TO_INSTALL="run_on_login_virusscannerplus"

# copy to /Users/$USER/Library/Scripts/
rm -rf /Users/"$USER"/Library/Scripts/"$APP_TO_INSTALL".app
cp -a "$SCRIPT_DIR"/install_files/"$APP_TO_INSTALL".app /Users/"$USER"/Library/Scripts/"$APP_TO_INSTALL".app
chown "$USER":staff /Users/"$USER"/Library/Scripts/"$APP_TO_INSTALL".app
chmod 750 /Users/"$USER"/Library/Scripts/"$APP_TO_INSTALL".app

echo ''

# autostart
AUTOSTART_ITEMS=(
# name													                  start hidden
""$APP_TO_INSTALL"                                                        true"                   
)
env_add_startup_items


### automation
# macos versions 10.14 and up
# source app name							automated app name											allowed (1=yes, 0=no)
AUTOMATION_APPS=(
""$APP_TO_INSTALL"                        	System Events               								1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="no" env_set_apps_automation_permissions


### security
APPS_SECURITY_ARRAY=(
# app name									security service											allowed (1=yes, 0=no)
""$APP_TO_INSTALL"          				kTCCServiceAccessibility                					1"
)
PRINT_SECURITY_PERMISSIONS_ENTRIES="no" env_set_apps_security_permissions

### uninstall
uninstall_run_on_login_autostart() {
	rm -rf ~/Library/Scripts/"$APP_TO_INSTALL".app
	osascript -e 'tell application "System Events" to delete login item "'"$APP_TO_INSTALL"'"'
}
#uninstall_run_on_login_autostart


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then :; else echo ''; fi
