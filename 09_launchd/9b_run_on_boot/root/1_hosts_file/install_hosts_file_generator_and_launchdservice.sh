#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

env_enter_sudo_password



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


### installing whitelist
echo ''
echo "checking for whitelist..."
SCRIPTS_DEFAULTS_WRITE_DIR="$SCRIPT_DIR_FIVE_BACK"
#echo "$SCRIPTS_DEFAULTS_WRITE_DIR"
if [[ -e /Applications/hosts_file_generator/whitelist ]] && [[ -e "$SCRIPTS_DEFAULTS_WRITE_DIR"/_scripts_input_keep/hosts/whitelist_"$USER" ]]
then
	echo "user whitelist file found, installing and re-running script..."
    sudo "$SCRIPT_INTERPRETER" -c 'cat '"$SCRIPTS_DEFAULTS_WRITE_DIR"'/_scripts_input_keep/hosts/whitelist_'"$USER"' > /Applications/hosts_file_generator/whitelist'
    # script will run a second time when activating service to respect whitelist while updating
    sudo touch -mt 201512010000 /etc/hosts
else
	echo "no user whitelist file found..."
fi


### launchd service
echo ''
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]];
then
    sudo launchctl unload "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
    sudo launchctl disable system/"$SERVICE_NAME"
else
    :
fi
sudo launchctl enable system/"$SERVICE_NAME"
sudo launchctl load "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist

echo "waiting 5s for launchd service to load before checking installation..."
sleep 5


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


echo ''
echo 'done ;)'
echo ''



###
### unsetting password
###

unset SUDOPASSWORD

