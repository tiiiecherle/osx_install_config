#!/bin/zsh

### path to applications
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }


### paths to applications
VERSION_TO_CHECK_AGAINST=10.14
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.14
    PATH_TO_SYSTEM_APPS="/Applications"
    PATH_TO_APPS="/Applications"
else
    # macos versions 10.15 and up
    PATH_TO_SYSTEM_APPS="/System/Applications"
    PATH_TO_APPS="/System/Volumes/Data/Applications"
fi


### variables
SERVICE_NAME=com.screen_resolution.set
SCRIPT_INSTALL_NAME=screen_resolution


### functions
wait_for_loggedinuser() {
    ### waiting for logged in user
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    NUM=0
    MAX_NUM=30
    SLEEP_TIME=3
    # waiting for loggedInUser to be available
    while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
    do
        sleep "$SLEEP_TIME"
        NUM=$((NUM+1))
        loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    done
    #echo ''
    #echo "NUM is $NUM..."
    echo "it took "$NUM"s for the loggedInUser "$loggedInUser" to be available..."
    #echo "loggedInUser is $loggedInUser..."
    if [[ "$loggedInUser" == "" ]]
    then
        WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
        echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
        exit
    else
        :
    fi
}

# in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script() {
    # using ps aux here sometime causes the script to hang when started from a launchd
    # if ps aux is necessary here use
    # timeout 3 env_check_if_run_from_batch_script
    # to run this function
    #BATCH_PIDS=()
    #BATCH_PIDS+=$(ps aux | grep "/batch_script_part.*.command" | grep -v grep | awk '{print $2;}')
    #if [[ "$BATCH_PIDS" != "" ]] && [[ -e "/tmp/batch_script_in_progress" ]]
    if [[ -e "/tmp/batch_script_in_progress" ]]
    then
        RUN_FROM_BATCH_SCRIPT="yes"
    else
        :
    fi
}

env_start_error_log() {
    local ERROR_LOG_DIR=/Users/"$USER"/Desktop/batch_error_logs
    if [[ ! -e "$ERROR_LOG_DIR" ]]
    then
        local ERROR_LOG_NUM=1
    else
        local ERROR_LOG_NUM=$(($(ls -1 "$ERROR_LOG_DIR" | awk -F'_' '{print $1}' | sort -n | tail -1)+1))
    fi
    mkdir -p "$ERROR_LOG_DIR"
    if [[ "$ERROR_LOG_NUM" -le "9" ]]; then ERROR_LOG_NUM="0"$ERROR_LOG_NUM""; else :; fi
    local ERROR_LOG="$ERROR_LOG_DIR"/"$ERROR_LOG_NUM"_"$SERVICE_NAME"_errorlog.txt
    echo "### "$SERVICE_NAME"" >> "$ERROR_LOG"
    #echo "### $(date "+%Y-%m-%d %H:%M:%S")" >> "$ERROR_LOG"
    echo '' >> "$ERROR_LOG"
    exec 2> >(tee -ia "$ERROR_LOG" >&2)
}

env_stop_error_log() {
    exec 2<&-
    exec 2>&1
}

start_log() {
    # prints stdout and stderr to terminal and to logfile
    exec > >(tee -ia "$LOGFILE")
}

timeout() { perl -e '; alarm shift; exec @ARGV' "$@"; }

create_logfile() {
    ### logfile
    EXECTIME=$(date '+%Y-%m-%d %T')
    LOGDIR=/Users/"$USER"/Library/Logs
    LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log
    
    if [[ -f "$LOGFILE" ]]
    then
        # only macos takes care of creation time, linux doesn`t because it is not part of POSIX
        LOGFILEAGEINSECONDS="$(( $(date +"%s") - $(stat -f "%B" $LOGFILE) ))"
        MAXLOGFILEAGE=$(echo "30*24*60*60" | bc)
        #echo $LOGFILEAGEINSECONDS
        #echo $MAXLOGFILEAGE
        # deleting logfile after 30 days
        if [[ "$LOGFILEAGEINSECONDS" -lt "$MAXLOGFILEAGE" ]]
        then
            echo "logfile not older than 30 days..."
        else
            # deleting logfile
            echo "deleting logfile..."
            rm "$LOGFILE"
            touch "$LOGFILE"
            chmod 644 "$LOGFILE"
        fi
    else
            touch "$LOGFILE"
            chmod 644 "$LOGFILE"
    fi
    
    echo "" >> "$LOGFILE"
    echo $EXECTIME >> "$LOGFILE"
}

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
    
    # homebrew python versions
    # homebrew python2
    #if [[ $(sudo -H -u "$loggedInUser" brew list | grep "^python@2$") == '' ]]
    if sudo -H -u "$loggedInUser" command -v python2 | grep $(sudo -H -u "$loggedInUser" brew --prefix) &> /dev/null
    then
        echo "python2 is installed via homebrew..."
        PYTHON2_HOMEBREW_INSTALLED="yes"
    else
        echo "python2 is not installed via homebrew..."
        PYTHON2_HOMEBREW_INSTALLED="no"
    fi
    # homebrew python3
    #if [[ $(sudo -H -u "$loggedInUser" brew list | grep "^python$") == '' ]]
    if sudo -H -u "$loggedInUser" command -v python3 | grep $(sudo -H -u "$loggedInUser" brew --prefix) &> /dev/null
    then
        echo "python3 is installed via homebrew..."
        PYTHON3_HOMEBREW_INSTALLED="yes"
    else
        echo "python3 is not installed via homebrew..."
        PYTHON3_HOMEBREW_INSTALLED="no"
    fi

    # listing installed python versions
    echo ''
    echo "installed python versions..."
    APPLE_PYTHON_VERSION=$(python --version 2>&1)
    printf "%-15s %-20s %-15s\n" "python" "$APPLE_PYTHON_VERSION" "apple"
    if [[ $PYTHON2_HOMEBREW_INSTALLED == "yes" ]]
    then
        PYTHON2_VERSION=$(python2 --version 2>&1)
        printf "%-15s %-20s %-15s\n" "python2" "$PYTHON2_VERSION" "homebrew"
    else
        :
    fi
    if [[ $PYTHON3_HOMEBREW_INSTALLED == "yes" ]]
    then
        PYTHON3_VERSION=$(python3 --version 2>&1)
        printf "%-15s %-20s %-15s\n" "python3" "$PYTHON3_VERSION" "homebrew"
    else
        :
    fi
    
    # the project is python3 only (from 2018-09), so make sure python3 is used
    # python2 deprecated 2020-01, only use python3
    # macos sip limits installing pip and installing/updating python modules - as a consequence only support homebrew python3
    echo ''
    if [[ "$PYTHON3_HOMEBREW_INSTALLED" == "yes" ]]
    then
        # installed
        # should be enough to use python3 here as $PYTHON3_INSTALLED checks if it is installed via homebrew
        PYTHON_VERSION='python3'
        PIP_VERSION='pip3'
        #PYTHON_VERSION="$(sudo -H -u "$loggedInUser" brew --prefix)/bin/python3"
        #PIP_VERSION="$(sudo -H -u "$loggedInUser" brew --prefix)/bin/pip3"
    else
        # not installed
        echo "only python3 via homebrew is supported, exiting..."
        exit
    fi
    
    #echo ''
    printf "%-36s %-15s\n" "python used in script" "$PYTHON_VERSION"
    printf "%-36s %-15s\n" "pip used in script" "$PIP_VERSION"
}

setting_config() {
    ### sourcing .$SHELLrc or setting PATH
    # as the script is run from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # needed if binary is installed in a special directory
    if [[ -n "$BASH_SOURCE" ]] && [[ -e /Users/"$loggedInUser"/.bashrc ]] && [[ $(cat /Users/"$loggedInUser"/.bashrc | grep 'PATH=.*/usr/local/bin:') != "" ]]
    then
        echo "sourcing .bashrc..."
        . /Users/"$loggedInUser"/.bashrc
    elif [[ -n "$ZSH_VERSION" ]] && [[ -e /Users/"$loggedInUser"/.zshrc ]] && [[ $(cat /Users/"$loggedInUser"/.zshrc | grep 'PATH=.*/usr/local/bin:') != "" ]]
    then
        echo "sourcing .zshrc..."
        ZSH_DISABLE_COMPFIX="true"
        . /Users/"$loggedInUser"/.zshrc
    else
        echo "setting path for script..."
        export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
    fi
}


### script
create_logfile
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
wait_for_loggedinuser
# run before main function, e.g. for time format
setting_config &> /dev/null

screen_resolution() {
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config
    

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
    
    
    ### variables
    DISPLAY_TO_SET="EV2785"
    SYSTEM_PROFILER_DISPLAY_DATA=$(system_profiler SPDisplaysDataType -xml)
    #DISPLAYS=$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')
    DISPLAYS=$(echo "$SYSTEM_PROFILER_DISPLAY_DATA" | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')
    #echo "$DISPLAYS"
    #NUMBER_OF_CONNECTED_DISPLAYS=$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}' | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    NUMBER_OF_CONNECTED_DISPLAYS=$(echo "$SYSTEM_PROFILER_DISPLAY_DATA" | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}' | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')  
    #DISPLAY_RESOLUTION=$(system_profiler SPDisplaysDataType -xml | awk -F'>|<' '/_spdisplays_resolution/{getline; print $3}')
    #DISPLAY_RESOLUTION=$(echo "$SYSTEM_PROFILER_DISPLAY_DATA" | awk -F'>|<' '/_spdisplays_resolution/{getline; print $3}')
    #echo "$DISPLAY_RESOLUTION"
    WANTED_RESOLUTION="2304"
    DISPLAY_MANAGER_INSTALL_PATH=""$PATH_TO_APPS"/display_manager"
    DISPLAY_MANAGER_RESOLUTION='2304 1296 60 only-hidpi'
    
    
    ### display manager
    # https://github.com/univ-of-utah-marriott-library-apple/display_manager
    
    if [[ -e "$DISPLAY_MANAGER_INSTALL_PATH"/display_manager.py ]]
    then
        echo ''
        
        # internal display tests macbook pro 2018
        #DISPLAY_MANAGER_RESOLUTION='1440 900 only-hidpi'
        #DISPLAY_MANAGER_RESOLUTION='1680 1050 only-hidpi'
        
        # showing current resolution and infos
        #"$PYTHON_VERSION" "$DISPLAY_MANAGER_INSTALL_PATH"/display_manager.py show all
        
        # showing possible only-hidpi resolution
        #"$PYTHON_VERSION" "$DISPLAY_MANAGER_INSTALL_PATH"/display_manager.py show available only-hidpi all
        
        # checking / setting resolution
        if [[ "$NUMBER_OF_CONNECTED_DISPLAYS" == "1" ]]
        then
            if [[ $(echo $DISPLAYS | grep "$DISPLAY_TO_SET") == "" ]]
            then
                echo "display "$DISPLAY_TO_SET" is not connected..."
            else
                # checking current display resolution
                DISPLAY_RESOLUTION=$("$PYTHON_VERSION" "$DISPLAY_MANAGER_INSTALL_PATH"/display_manager.py show all | awk '/"main"/{getline; print $2}')
                if [[ $(echo "$DISPLAY_RESOLUTION" | grep "$WANTED_RESOLUTION") != "" ]]
                then
                    echo "wanted resolution "$DISPLAY_MANAGER_RESOLUTION" already enabled..."
                else
                    # setting resolution
                    echo "changing resolution to "$DISPLAY_MANAGER_RESOLUTION"..."
                    #"$PYTHON_VERSION" "$DISPLAY_MANAGER_INSTALL_PATH"/display_manager.py res "${DISPLAY_MANAGER_RESOLUTION}" main
                    "$PYTHON_VERSION" "$DISPLAY_MANAGER_INSTALL_PATH"/display_manager.py res "$DISPLAY_MANAGER_RESOLUTION" main
                fi
            fi
        else
            echo "more than one display available, not making any changes..."
        fi
    else
        echo ''
        echo "display manager not installed, exiting..."
        echo ''
        exit
    fi
    
    echo ''
    echo "done ;)"
    echo ''
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    time ( screen_resolution )
else
    time ( screen_resolution )
fi

echo ''

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
