#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### launchd & applescript to do things when changing network location
###

### installation should be done via restore script after first install

# copy to /Users/$USER/Library/Scripts/
rm -rf /Users/"$USER"/Library/Scripts/run_on_login_signal.app
cp -a "$SCRIPT_DIR"/install_files/run_on_login_signal.app /Users/"$USER"/Library/Scripts/run_on_login_signal.app
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_login_signal.app
chmod 750 /Users/"$USER"/Library/Scripts/run_on_login_signal.app

echo ''

# add to autostart
if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^ *//' | grep "run_on_login_signal" ) == "" ]]
then
    osascript -e 'tell application "System Events" to make login item at end with properties {name:"run_on_login_signal", path:"/Users/'$USER'/Library/Scripts/run_on_login_signal.app", hidden:true}'
else
	osascript -e 'tell application "System Events" to delete login item "run_on_login_signal"'
	osascript -e 'tell application "System Events" to make login item at end with properties {name:"run_on_login_signal", path:"/Users/'$USER'/Library/Scripts/run_on_login_signal.app", hidden:false}'
fi

rm -rf /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app
cp -a "$SCRIPT_DIR"/install_files/run_on_login_whatsapp.app /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app
chmod 750 /Users/"$USER"/Library/Scripts/run_on_login_whatsapp.app

# add to autostart
if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^ *//' | grep "run_on_login_whatsapp" ) == "" ]]
then
    osascript -e 'tell application "System Events" to make login item at end with properties {name:"run_on_login_whatsapp", path:"/Users/'$USER'/Library/Scripts/run_on_login_whatsapp.app", hidden:true}'
else
	osascript -e 'tell application "System Events" to delete login item "run_on_login_whatsapp"'
	osascript -e 'tell application "System Events" to make login item at end with properties {name:"run_on_login_whatsapp", path:"/Users/'$USER'/Library/Scripts/run_on_login_whatsapp.app", hidden:false}'
fi


### automation
# macos versions 10.14 and up
# source app name							automated app name											allowed (1=yes, 0=no)
AUTOMATION_APPS=(
"run_on_login_signal                        System Events               								1"
"run_on_login_whatsapp                      System Events               								1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRYS="no" env_set_apps_automation_permissions


### uninstall
uninstall_run_on_login_autostart() {
	rm -rf ~/Library/Scripts/run_on_login_signal.app
	osascript -e 'tell application "System Events" to delete login item "run_on_login_signal"'
	rm -rf ~/Library/Scripts/run_on_login_whatsapp.app
	osascript -e 'tell application "System Events" to delete login item "run_on_login_whatsapp"'
}
#uninstall_run_on_login_autostart

echo ''
echo "done ;)"
echo ''
