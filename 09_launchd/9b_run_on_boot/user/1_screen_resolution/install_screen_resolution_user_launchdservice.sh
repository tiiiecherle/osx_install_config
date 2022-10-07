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


### functions
check_homebrew_and_python_versions() {
    # homebrew
    if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
    then
	    # installed
        echo ''
        echo "homebrew is installed..."
        # do not autoupdate homebrew
        export HOMEBREW_NO_AUTO_UPDATE=1
    else
        # not installed
        echo ''
        echo "homebrew is not installed, exiting..."
        exit
    fi
    
    ### checking python versions
    # homebrew python2
    #if [[ $(sudo -H -u "$loggedInUser" brew list --formula | grep "^python@2$") == '' ]]
    #if sudo -H -u "$loggedInUser" which -a python2 | grep $(sudo -H -u "$loggedInUser" brew --prefix) &> /dev/null
    if sudo -H -u "$loggedInUser" command -v $(sudo -H -u "$loggedInUser" brew --prefix)/bin/python2 &> /dev/null
    then
        echo "python2 is installed via homebrew..."
        PYTHON2_HOMEBREW_INSTALLED="yes"
        PYTHON2_VERSION=$($(sudo -H -u "$loggedInUser" brew --prefix)/bin/python2 --version 2>&1)
    else
        echo "python2 is not installed via homebrew..."
        PYTHON2_HOMEBREW_INSTALLED="no"
    fi
    # homebrew python3
    #if [[ $(sudo -H -u "$loggedInUser" brew list --formula | grep "^python$") == '' ]]
    #if sudo -H -u "$loggedInUser" which -a python3 | grep $(sudo -H -u "$loggedInUser" brew --prefix) &> /dev/null
    if sudo -H -u "$loggedInUser" command -v $(sudo -H -u "$loggedInUser" brew --prefix)/bin/python3 &> /dev/null
    then
        echo "python3 is installed via homebrew..."
        PYTHON3_HOMEBREW_INSTALLED="yes"
        PYTHON3_VERSION=$($(sudo -H -u "$loggedInUser" brew --prefix)/bin/python3 --version 2>&1)
    else
        echo "python3 is not installed via homebrew..."
        PYTHON3_HOMEBREW_INSTALLED="no"
    fi
    # apple python
    #if sudo -H -u "$loggedInUser" which -a python3 | grep "/usr/bin" &> /dev/null
    if sudo -H -u "$loggedInUser" command -v /usr/bin/python3 &> /dev/null
    then
        echo "apple python is installed..."
        APPLE_PYTHON_VERSION_INSTALLED="yes"
        APPLE_PYTHON_VERSION=$(/usr/bin/python3 --version 2>&1)
    else
        echo "apple python is not installed..."
        APPLE_PYTHON_VERSION_INSTALLED="no"
    fi
    

    ### listing installed python versions
    echo ''
    echo "installed python versions..."
    if [[ $APPLE_PYTHON_VERSION_INSTALLED == "yes" ]]
    then
        printf "%-20s %-25s\n" "$APPLE_PYTHON_VERSION" "apple"
    else
        :
    fi
    if [[ $PYTHON2_HOMEBREW_INSTALLED == "yes" ]]
    then
        printf "%-20s %-25s\n" "$PYTHON2_VERSION" "homebrew"
    else
        :
    fi
    if [[ $PYTHON3_HOMEBREW_INSTALLED == "yes" ]]
    then
        printf "%-20s %-25s\n" "$PYTHON3_VERSION" "homebrew"
    else
        :
    fi
    
    
    ### the project is python3 only (from 2018-09), so make sure python3 is used
    # python2 deprecated 2020-01, only use python3
    # macos sip limits installing pip and installing/updating python modules - as a consequence only support homebrew python3
    echo ''
    if [[ "$PYTHON3_HOMEBREW_INSTALLED" == "yes" ]]
    then
        # installed
        # should be enough to use python3 here as $PYTHON3_INSTALLED checks if it is installed via homebrew
        #PYTHON_VERSION='python3'
        #PIP_VERSION='pip3'
        PYTHON_VERSION="$(sudo -H -u "$loggedInUser" brew --prefix)/bin/python3"
        PIP_VERSION="$(sudo -H -u "$loggedInUser" brew --prefix)/bin/pip3"
    else
        # not installed
        echo "only python3 via homebrew is supported, exiting..."
        exit
    fi
    
    #echo ''
    printf "%-36s %-15s\n" "python used in script" "$PYTHON_VERSION"
    printf "%-36s %-15s\n" "pip used in script" "$PIP_VERSION"
}


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


    ### creating installation directory
    mkdir -p "$PATH_TO_APPS"/display_manager
    chown "$USER":admin "$PATH_TO_APPS"/display_manager
    chmod 755 "$PATH_TO_APPS"/display_manager


    ### downloading display manager from git repository
    # display manager
    # https://github.com/univ-of-utah-marriott-library-apple/display_manager
    echo ''
    echo "downloading display manager..."
    git clone --depth 1 https://github.com/univ-of-utah-marriott-library-apple/display_manager.git "$PATH_TO_APPS"/display_manager/
      
        
    ### homebrew and python versions
    check_homebrew_and_python_versions
    
    
    ### python modules
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
            if [[ $(sudo -H -u "$loggedInUser" command -v "$PIP_VERSION" | grep "$BREW_PATH_PREFIX") == "" ]]
            then
                sudo "$PIP_VERSION" install "$i"
            else
                sudo -H -u "$loggedInUser" "$PIP_VERSION" install "$i"
            fi
        else
            echo "python module "$i" already installed..."
        fi
    done
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
echo ''
if [[ $(launchctl list | grep "$SERVICE_NAME") != "" ]];
then    
    # if kill was used to stop the service kickstart is needed to restart it, bootstrap will not work
	launchctl bootout gui/"$UNIQUE_USER_ID"/"$SERVICE_NAME" 2>&1 | grep -v "in progress" | grep -v "No such process"
	#launchctl kill 15 gui/"$SERVICE_NAME"
	sleep 2
	launchctl disable gui/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
else
    :
fi
launchctl enable gui/"$UNIQUE_USER_ID"/"$SERVICE_NAME"
launchctl bootstrap gui/"$UNIQUE_USER_ID" "$SERVICE_INSTALL_PATH"/"$SERVICE_NAME".plist | grep -v "in progress" | grep -v "already bootstrapped"
sleep 2

WAITING_TIME=5
NUM1=0
#echo ''
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
