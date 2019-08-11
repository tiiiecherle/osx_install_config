#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### launchd & applescript to do things on every boot as user after user login
###

### variables
SERVICE_NAME=com.example_user.show
SERVICE_INSTALL_PATH=/Users/$USER/Library/LaunchAgents
SCRIPT_INSTALL_NAME=example_user
SCRIPT_INSTALL_PATH=/Users/$USER/Library/Scripts

LOGDIR=/Users/"$USER"/Library/Logs
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log


### uninstalling possible old files
echo ''
echo "uninstalling possible old files..."
. "$SCRIPT_DIR"/launchd_and_script/uninstall_"$SCRIPT_INSTALL_NAME"_and_launchdservice.sh
wait
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables


### script file
echo "installing script..."
cp "$SCRIPT_DIR"/launchd_and_script/"$SCRIPT_INSTALL_NAME".sh "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh
chown -R "$USER":staff "$SCRIPT_INSTALL_PATH"/
chmod -R 750 "$SCRIPT_INSTALL_PATH"/


### launchd service file
echo "installing launchd service..."
cp "$SCRIPT_DIR"/launchd_and_script/"$SERVICE_NAME".plist "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
chown "$USER":staff "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
chmod 640 "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist


### run script
echo ''
echo "running installed script..."

# be sure to have the correct path to the user logfiles specified for the logfile
# /var/log is only writable as root
#echo ''
"$SCRIPT_INTERPRETER" -c "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh &
wait


### launchd service
echo ''
if [[ $(launchctl list | grep "$SERVICE_NAME") != "" ]];
then
    launchctl unload "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
    launchctl disable user/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
else
    :
fi
launchctl enable user/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
launchctl load "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist

echo "waiting 5s for launchd service to load before checking installation..."
sleep 5


### checking installation
echo ''
echo "checking installation..."
"$SCRIPT_DIR"/launchd_and_script/checking_installation.sh
wait

#echo ''
#echo "opening logfile..."
#open "$LOGFILE"


#echo ''
echo 'done ;)'
echo ''
