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

SERVICE_NAME=com.clamav.monitor
SERVICE_INSTALL_PATH=/Library/LaunchDaemons
SCRIPT_INSTALL_NAME=clamav_monitor
SCRIPT_INSTALL_PATH=/Library/Scripts/custom

LOGDIR=/var/log
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log

launchd_services=(
"$SERVICE_NAME"
)


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


### uninstall formulae
uninstall_formulae() {
	for FORMULA in clamav fswatch
	do
		if sudo -H -u "$loggedInUser" command -v "$FORMULA" &> /dev/null
		then
		    # installed
		    brew uninstall "$FORMULA"
		else
			# not installed
			if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
			then
			    # installed
			    if [[ $(sudo -H -u "$loggedInUser" brew list --formula | grep "^$FORMULA$") == "" ]]
			    then
				    # not installed
				    :
				else
				    # installed
				    brew uninstall "$FORMULA"
				fi
			else
	        	# not installed
	        	echo ''
	            echo "homebrew is not installed, skipping uninstall of formulae..."
	        	echo ''
			fi
		fi
	done
}
uninstall_formulae

### uninstall clamav
#brew uninstall clamav
if command -v brew &> /dev/null
then
    # installed
    BREW_PATH_PREFIX=$(brew --prefix)
else
    # not installed
    echo "homebrew is not installed, exiting..."
    echo ''
    exit
fi
rm -rf ""$BREW_PATH_PREFIX"/etc/clamav"
rm -rf ""$BREW_PATH_PREFIX"/bin/clamav-unofficial-sigs.sh"
rm -rf ""$BREW_PATH_PREFIX"/var/db/clamav-unofficial-sigs"
rm -rf ""$BREW_PATH_PREFIX"/var/run/clamav"
rm -rf ""$BREW_PATH_PREFIX"/opt/clamav"
rm -rf ""$BREW_PATH_PREFIX"/etc/clamav-unofficial-sigs"
rm -rf ""$BREW_PATH_PREFIX"/var/log/clamav-unofficial-sigs.log"
#dscl . list /Users UniqueID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
#dscl . list /Groups PrimaryGroupID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
#sudo -v
#sudo find /Volumes/macintosh_hd -type d -name "*clamav*"
#sudo dscl . delete /Users/_clamav
#sudo dscl . delete /Groups/_clamav
#sudo dscl . delete /Users/clamav
#sudo dscl . delete /Groups/clamav


### uninstall user files and .app
rm -rf "/Users/"$loggedInUser"/Library/Application Support/clamav_monitor"
rm -rf ""$PATH_TO_APPS"/clamav_scan.app"


### uninstall fswatch
#brew uninstall fswatch


### re-add clamav user if deleted
re-add_user() {
    dscl . list /Users UniqueID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
    dscl . list /Groups PrimaryGroupID | tr -s ' ' | sort -n -t ' ' -k2,2 | grep clamav
    sudo dscl . create /Groups/clamav
    sudo dscl . create /Groups/clamav RealName "clamav"
    sudo dscl . create /Groups/clamav gid 82           # Ensure this is unique!
    sudo dscl . create /Users/clamav
    sudo dscl . create /Users/clamav RealName "clamav"
    sudo dscl . create /Users/clamav UserShell /bin/false
    sudo dscl . create /Users/clamav UniqueID 82       # Ensure this is unique!
    sudo dscl . create /Users/clamav PrimaryGroupID 82 # Must match the above gid!
}
#re-add_user


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

