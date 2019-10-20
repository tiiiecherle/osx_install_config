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
### installing and running script and launchd service
### 

### variables
SERVICE_NAME=com.hostsfile.install_update
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_INSTALL_NAME=hosts_file_generator
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log


### uninstalling possible old files
echo ''
echo "uninstalling possible old files..."
. "$SCRIPT_DIR"/launchd_and_script/uninstall_"$SCRIPT_INSTALL_NAME"_and_launchdservice.sh
wait
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables


### script file
echo "installing script..."
sudo mkdir -p "$SCRIPT_INSTALL_PATH"/
sudo cp "$SCRIPT_DIR"/launchd_and_script/"$SCRIPT_INSTALL_NAME".sh "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh
sudo chown -R root:wheel "$SCRIPT_INSTALL_PATH"/
sudo chmod -R 755 "$SCRIPT_INSTALL_PATH"/


### launchd service file
echo "installing launchd service..."
sudo cp "$SCRIPT_DIR"/launchd_and_script/"$SERVICE_NAME".plist "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
sudo chown root:wheel "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
sudo chmod 644 "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist


### forcing update on next run by setting last modification time of /etc/hosts earlier
sudo touch -mt 201512010000 /etc/hosts


### run script
echo ''
echo "running installed script..."

# has to be run as root because sudo cannot write to logfile with root priviliges for the function with sudo tee
# otherwise the privileges of the logfile would have to be changed before running inside the script
# sudo privileges inside the called script will not timeout
# script will run as root later anyway
#echo ''
sudo "$SCRIPT_INTERPRETER" -c "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh &
wait


### installing whitelist(s)
echo ''
echo "installing empty whitelist file..."
sudo cp -a "$PATH_TO_APPS"/hosts_file_generator/whitelist.example "$PATH_TO_APPS"/hosts_file_generator/whitelist
sudo chown root:admin "$PATH_TO_APPS"/hosts_file_generator/whitelist
sudo chmod 644 "$PATH_TO_APPS"/hosts_file_generator/whitelist

# general whitelist entries all users
echo ''
SCRIPTS_DEFAULTS_WRITE_DIR="$SCRIPT_DIR_FIVE_BACK"
#echo "$SCRIPTS_DEFAULTS_WRITE_DIR"
if [[ -e "$PATH_TO_APPS"/hosts_file_generator/whitelist ]] && [[ -e "$SCRIPTS_DEFAULTS_WRITE_DIR"/_scripts_input_keep/hosts/whitelist_general ]]
then
	echo "general whitelist file found, adding entries and re-running script..."
    sudo "$SCRIPT_INTERPRETER" -c 'cat '"$SCRIPTS_DEFAULTS_WRITE_DIR"'/_scripts_input_keep/hosts/whitelist_general >> '"$PATH_TO_APPS"'/hosts_file_generator/whitelist'
    sudo "$SCRIPT_INTERPRETER" -c 'printf "\n" >> '"$PATH_TO_APPS"'/hosts_file_generator/whitelist'
    # script will run a second time when activating service to respect whitelist while updating
    sudo touch -mt 201512010000 /etc/hosts
else
	echo "no general whitelist file found..."
fi

# user specific whitelist entries
if [[ -e "$PATH_TO_APPS"/hosts_file_generator/whitelist ]] && [[ -e "$SCRIPTS_DEFAULTS_WRITE_DIR"/_scripts_input_keep/hosts/whitelist_"$USER" ]]
then
	echo "user specific whitelist file found, adding entries and re-running script..."
    sudo "$SCRIPT_INTERPRETER" -c 'cat '"$SCRIPTS_DEFAULTS_WRITE_DIR"'/_scripts_input_keep/hosts/whitelist_'"$USER"' >> '"$PATH_TO_APPS"'/hosts_file_generator/whitelist'
    sudo "$SCRIPT_INTERPRETER" -c 'printf "\n" >> '"$PATH_TO_APPS"'/hosts_file_generator/whitelist'
    # script will run a second time when activating service to respect whitelist while updating
    sudo touch -mt 201512010000 /etc/hosts
else
	echo "no user specific whitelist file found..."
fi


### launchd service
echo ''
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]];
then
    sudo launchctl unload "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist 2>&1 | grep -v "in progress"
    sudo launchctl disable system/"$SERVICE_NAME"
else
    :
fi
sudo launchctl enable system/"$SERVICE_NAME"
sudo launchctl load "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist

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
while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; sudo lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
sleep 1


### checking installation
echo ''
echo "checking installation..."
sudo "$SCRIPT_DIR"/launchd_and_script/checking_installation.sh
wait

#echo ''
#echo "opening logfile..."
#open "$LOGFILE"


### syncing to install latest version when using backup script
#echo ''
echo "copying script to backup script dir..."
SCRIPTS_FINAL_DIR="$SCRIPT_DIR_FOUR_BACK"
if [[ -e "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script ]]
then
    mkdir -p "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_hosts
    cp "$SCRIPT_DIR"/launchd_and_script/"$SCRIPT_INSTALL_NAME".sh "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_hosts/"$SCRIPT_INSTALL_NAME".sh
else
	echo ""$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script not found, skipping copying file to backup script directory..."
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
echo ''



###
### unsetting password
###

unset SUDOPASSWORD

