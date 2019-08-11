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
SERVICE_NAME=com.network.select
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_INSTALL_NAME=network_select
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log

# other launchd services
other_launchd_services=(
com.hostsfile.install_update
com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)


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


### unloading and disabling launchd services launched by network_select
echo ''
echo "unloading other launchd services..."
for i in "${other_launchd_services[@]}"
do
    if [[ $(sudo launchctl list | grep "$i") != "" ]];
    then
        echo "unloading "$i"..."
        sudo launchctl unload /Library/LaunchDaemons/"$i".plist 2>&1 | grep -v "in progress"
    else
        :
    fi
done


echo ''
echo "disabling other launchd services..."
for i in "${other_launchd_services[@]}"
do
    if [[ $(sudo launchctl print-disabled system | grep "$i" | grep false) != "" ]];
    then
        echo "disabling "$i"..."
        sudo launchctl disable system/"$i"
    else
        :
    fi
done


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

echo "waiting 10s for launchd services to load before checking installation..."
sleep 10


### checking installation
echo ''
echo "checking installation..."
sudo "$SCRIPT_DIR"/launchd_and_script/checking_installation.sh
wait

#echo ''
#echo "opening logfile..."
#open "$LOGFILE"


#echo ''
echo 'done ;)'
echo ''



###
### unsetting password
###

unset SUDOPASSWORD

