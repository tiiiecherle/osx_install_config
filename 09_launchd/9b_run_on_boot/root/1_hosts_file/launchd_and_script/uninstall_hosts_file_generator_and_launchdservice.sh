#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### uninstall service
###

### variables
UNINSTALL_SCRIPT_DIR="$SCRIPT_DIR"

SERVICE_NAME=com.hostsfile.install_update
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_INSTALL_NAME=hosts_file_generator
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log


### deleting script
if [[ -f "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh ]]
then
    sudo rm -f "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh
else
    :
fi


### stopping, disabling and removing launchd service
if [[ $(sudo launchctl list | grep "$SERVICE_NAME") != "" ]] || [[ $(launchctl print-disabled system | grep "$SERVICE_NAME" | grep true) != "" ]]
then
    # if kill was used to stop the service kickstart is needed to restart it, bootstrap will not work
	sudo launchctl bootout system "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist 2>&1 | grep -v "in progress" | grep -v "No such process"
	#sudo launchctl kill 15 system/"$SERVICE_NAME"
	sleep 2
	sudo launchctl disable system/"$SERVICE_NAME"
    sudo launchctl remove "$SERVICE_NAME"
else
    :
fi


### deleting launchd service
if [[ -f "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist ]]
then
    sudo rm -f "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
else
    :
fi


### deleting logfile
if [[ -f "$LOGFILE" ]]
then
    sudo rm -f "$LOGFILE"
else
    :
fi


### uninstalling hosts file generator
if [[ -d "$PATH_TO_APPS"/hosts_file_generator ]]
then
    sudo rm -rf "$PATH_TO_APPS"/hosts_file_generator
else
    :
fi


### moving back original hosts file
if [[ -f /etc/hosts.orig ]]
then
    sudo cp -a /etc/hosts.orig /etc/hosts
else
    :
fi


### activating changed hosts file
echo ''
echo "activating changed hosts file..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder


### deleting virtual python environment
PYTHON_VIRTUALENVIRONMENT="/Users/"$USER"/Library/Python/hosts_file_generator"
if [[ -e "$PYTHON_VIRTUALENVIRONMENT" ]]
then
    rm -rf "$PYTHON_VIRTUALENVIRONMENT"
else
    :
fi


### checking installation
if [[ $(ps aux | grep /install_"$SCRIPT_INSTALL_NAME"_and_launchdservice.sh | grep -v grep) == "" ]]
then
    echo ''
    echo "checking installation..."
    sudo "$UNINSTALL_SCRIPT_DIR"/checking_installation.sh
    wait
else
    :
fi



#echo ''
echo "uninstalling done..."
echo ''

