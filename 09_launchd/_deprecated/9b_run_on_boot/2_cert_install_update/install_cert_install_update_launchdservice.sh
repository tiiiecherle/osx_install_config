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
### compatibility
###

# mounting system as read/write until next reboot
if [[ "$MACOS_VERSION_MAJOR" != 10.15 ]]
then
    # macos versions other than 10.15
    # more complicated and risky on 11 and newer due to signed system volume (ssv)
	echo ''
    echo "this script is only compatible with macos 10.15 exiting..."
    echo ''
    exit
else
    # macos versions 10.15
    # in 10.15 /System default gets mounted read-only
    # can only be mounted read/write with according SIP settings
    sudo mount -uw /
    # stays mounted rw until next reboot
    sleep 0.5
fi
    


###
### installing and running script and launchd service
### 

### variables
SERVICE_NAME=com.cert.install_update
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_INSTALL_NAME=cert_install_update
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log


### homebrew and script dependencies

echo ''

# checking homebrew and script dependencies
if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
then
	# installed
    echo "homebrew is installed..."
else
    # not installed
    echo "please install homebrew, then run this installer again..."
    echo "homebrew is not installed, exiting..."
    exit
fi

# checking if all script dependencies are installed
#echo ''
echo "checking for script dependencies..."
if [[ $(brew list --formula | grep "^openssl@1.1$") == '' ]]
then
    echo "not all script dependencies installed, installing..."
    env_use_password | brew install openssl@1.1
else
    echo "all script dependencies installed..."
fi


### certificate variables
SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_FIVE_BACK"
if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh ]]
then
    #"$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh
    #CERTIFICATE_NAME_VARIABLE=$(cat "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh | grep "^CERTIFICATE_NAME")
    #echo "CERTIFICATE_NAME_VARIABLE is $CERTIFICATE_NAME_VARIABLE..."
    #SERVER_IP_VARIABLE=$(cat "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh | grep "^SERVER_IP")
    #echo "SERVER_IP_VARIABLE is $SERVER_IP_VARIABLE..."
    . "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh
else
    echo ''
    echo "script with variables not found, exiting..."
    exit
fi


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
# setting certificate variables
sudo sed -i '' '/CERTIFICATES_TO_INSTALL=(/,/)$/{//!d;}' "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh
for i in "${CERTIFICATES_TO_INSTALL[@]}"
do
    SERVER_LOCAL=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    SERVER_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    CERTIFICATE_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    #echo "LOCAL_SERVER is "$LOCAL_SERVER""
    #echo "CERTIFICATE_NAME is "$CERTIFICATE_NAME""
    sudo sed -i '' -e '/CERTIFICATES_TO_INSTALL=(/a\'$'\n\\\ \t"'"$(printf "%-30s %-40s %-40s\n" \"$SERVER_LOCAL\" \"$SERVER_NAME\" \"$CERTIFICATE_NAME\"\")"'' "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh
done


### launchd service file
echo "installing launchd service..."
sudo cp "$SCRIPT_DIR"/launchd_and_script/"$SERVICE_NAME".plist "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
sudo chown root:wheel "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
sudo chmod 644 "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist


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


### launchd service
echo ''
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]];
then    
    # if kill was used to stop the service kickstart is needed to restart it, bootstrap will not work
	sudo launchctl bootout system "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist 2>&1 | grep -v "in progress" | grep -v "No such process"
	#sudo launchctl kill 15 system/"$SERVICE_NAME"
	sleep 2
	sudo launchctl disable system/"$SERVICE_NAME"
else
    :
fi
sudo launchctl enable system/"$SERVICE_NAME"
sudo launchctl bootstrap system "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
sleep 2

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


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


#echo ''
echo 'done ;)'
echo ''



###
### unsetting password
###

unset SUDOPASSWORD

