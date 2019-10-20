#!/bin/zsh

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### launchd & applescript to do things on every boot after user login
###


### variables
SERVICE_NAME=com.screen_resolution.set
SERVICE_INSTALL_PATH=/Users/$USER/Library/LaunchAgents
SCRIPT_INSTALL_NAME=screen_resolution
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
mkdir -p "$SCRIPT_INSTALL_PATH"
chown "$USER":staff "$SCRIPT_INSTALL_PATH"
chmod 700 "$SCRIPT_INSTALL_PATH"
cp "$SCRIPT_DIR"/launchd_and_script/"$SCRIPT_INSTALL_NAME".sh "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh
chown -R "$USER":staff "$SCRIPT_INSTALL_PATH"/
chmod -R 750 "$SCRIPT_INSTALL_PATH"/


### launchd service file
echo "installing launchd service..."
mkdir -p "$SERVICE_INSTALL_PATH"
chown "$USER":staff "$SERVICE_INSTALL_PATH"
chmod 700 "$SERVICE_INSTALL_PATH"
cp "$SCRIPT_DIR"/launchd_and_script/"$SERVICE_NAME".plist "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
chown "$USER":staff "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist
chmod 640 "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist


### installing display manager
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    echo "installing display manager..."

    # creating installation directory
    mkdir -p "$PATH_TO_APPS"/display_manager
    chown "$USER":admin "$PATH_TO_APPS"/display_manager
    chmod 755 "$PATH_TO_APPS"/display_manager

    # downloading display manager from git repository
    # display manager
    # https://github.com/univ-of-utah-marriott-library-apple/display_manager
    echo ''
    echo "downloading display manager..."
    git clone --depth 1 https://github.com/univ-of-utah-marriott-library-apple/display_manager.git "$PATH_TO_APPS"/display_manager/
        
    # python2 deprecated 2020-01, checking if python3 and pip3 are installed
    echo ''
    if sudo -H -u "$loggedInUser" command -v python3 &> /dev/null && sudo -H -u "$loggedInUser" command -v pip3 &> /dev/null
    then
        # installed
        echo "python3 is installed..."
        PYTHON_VERSION='python3'
        PIP_VERSION='pip3'
    else
        # not installed
        echo "python3 is not installed, trying apple python..."
        
        # checking if pip is installed
        if sudo -H -u "$loggedInUser" command -v pip &> /dev/null
        then
            # installed
            echo "pip is installed..."
        else
            # not installed
            echo "pip is not installed, installing..."
            sudo -H python -m ensurepip
            sudo -H easy_install pip
        fi
        
        # checking version of default apple python
        if sudo -H -u "$loggedInUser" command -v python &> /dev/null && sudo -H -u "$loggedInUser" command -v pip &> /dev/null && [[ $(python --version 2>&1 | awk '{print $NF}' | cut -d'.' -f1) == "3" ]] && [[ $(pip --version 2>&1 | grep "python 3") != "" ]]
        then
            PYTHON_VERSION='python'
            PIP_VERSION='pip'
        else
            echo "python3 or pip3 are not installed, exiting..."
            echo ''
            exit
        fi
    fi
    
    echo ''
    echo "checking python modules..."
    for i in pyobjc-framework-Cocoa pyobjc-framework-Quartz
    do
        if [[ $("$PIP_VERSION" list | grep "$i") == "" ]]
        then
            echo ''
            echo "installing python module "$i"..."
            echo ''
            echo "installing python module "$i"..."
            if [[ $(sudo -H -u "$loggedInUser" command -v "$PIP_VERSION" | grep "/usr/local") == "" ]]
            then
                sudo "$PIP_VERSION" install "$i"
            else
                sudo -H -u "$loggedInUser" "$PIP_VERSION" install "$i"
            fi
        else
            echo "python module "$i" already installed..."
        fi
    done
    
    echo ''
    echo "python version used in script is $PYTHON_VERSION with $PIP_VERSION..."
    #echo ''
else
    # offline
	echo "exiting..."
	echo ''
	exit
	
fi


### run script
echo ''
echo "running installed script..."

# be sure to have the correct path to the user logfiles specified for the logfile
# /var/log is only writable as root
#echo ''
"$SCRIPT_INTERPRETER" -c "$SCRIPT_INSTALL_PATH"/"$SCRIPT_INSTALL_NAME".sh &
wait


### launchd service
echo ""
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


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


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
