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

WAITING_TIME=5
NUM1=0
echo ''
while [[ "$NUM1" -le "$WAITING_TIME" ]]
do 
	NUM1=$((NUM1+1))
	if [[ "$NUM1" -le "$WAITING_TIME" ]]
	then
		#echo "$NUM1"
		sleep 1
		tput cuu 1 && tput el
		echo "waiting $((WAITING_TIME-NUM1)) seconds for launchd service to load before checking installation..."
	else
		:
	fi
done

echo ''
echo "waiting for script from launchd to finish..."
#echo ''
sleep 3
WAIT_PIDS=()
WAIT_PIDS+=$(ps aux | grep /"$SCRIPT_INSTALL_NAME".sh | grep -v grep | awk '{print $2;}')
#echo "$WAIT_PIDS"
#if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
sleep 1


### checking installation
echo ''
echo "checking installation..."
"$SCRIPT_DIR"/launchd_and_script/checking_installation.sh
wait

#echo ''
#echo "opening logfile..."
#open "$LOGFILE"


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


#echo ''
echo 'done ;)'
echo ''
