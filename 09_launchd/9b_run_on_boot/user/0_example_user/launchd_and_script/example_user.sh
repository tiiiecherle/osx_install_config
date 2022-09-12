#!/bin/zsh

### variables
SERVICE_NAME=com.example_user.show
SCRIPT_INSTALL_NAME=example_user


### functions
wait_for_loggedinuser() {
    ### waiting for logged in user
    # recommended way, but it seems apple deprecated python2 in macOS 12.3.0
    # to keep on using the python command, a python module is needed
    #pip3 install pyobjc-framework-SystemConfiguration
    #loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
    NUM=0
    MAX_NUM=30
    SLEEP_TIME=3
    # waiting for loggedInUser to be available
    while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
    do
        sleep "$SLEEP_TIME"
        NUM=$((NUM+1))
        # recommended way, but it seems apple deprecated python2 in macOS 12.3.0
        # to keep on using the python command, a python module is needed
        #pip3 install pyobjc-framework-SystemConfiguration
        #loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
        loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
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

start_log() {
    # prints stdout and stderr to terminal and to logfile
    exec > >(tee -ia "$LOGFILE")
}

env_start_error_log() {
    local ERROR_LOG_DIR=/Users/"$loggedInUser"/Desktop/batch_error_logs
    if [[ ! -e "$ERROR_LOG_DIR" ]]
    then
        local ERROR_LOG_NUM=1
    else
        local ERROR_LOG_NUM=$(($(ls -1 "$ERROR_LOG_DIR" | awk -F'_' '{print $1}' | sort -n | tail -1)+1))
    fi
    #echo "starting error log..."
    mkdir -p "$ERROR_LOG_DIR"
    if [[ "$ERROR_LOG_NUM" -le "9" ]]; then ERROR_LOG_NUM="0"$ERROR_LOG_NUM""; else :; fi
    local ERROR_LOG="$ERROR_LOG_DIR"/"$ERROR_LOG_NUM"_"$SERVICE_NAME"_errorlog.txt
    echo "### "$SERVICE_NAME"" >> "$ERROR_LOG"
    #echo "### $(date "+%Y-%m-%d %H:%M:%S")" >> "$ERROR_LOG"
    start_log
    echo '' >> "$ERROR_LOG"
    exec 2> >(tee -ia "$ERROR_LOG" >&2)
}

env_stop_error_log() {
    exec 2<&-
    exec 2>&1
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

setting_config() {
    echo ''
    ### sourcing .$SHELLrc or setting PATH
    # as the script is run from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # needed if binary is installed in a special directory
    if [[ -n "$BASH_SOURCE" ]] && [[ -e /Users/"$loggedInUser"/.bashrc ]] && [[ $(cat /Users/"$loggedInUser"/.bashrc | grep 'export PATH=.*:$PATH"') != "" ]]
    then
        echo "sourcing .bashrc..."
        #. /Users/"$loggedInUser"/.bashrc
        # avoiding oh-my-zsh errors for root by only sourcing export PATH
        source <(sed -n '/^export\ PATH\=/p' /Users/"$loggedInUser"/.bashrc)
    elif [[ -n "$ZSH_VERSION" ]] && [[ -e /Users/"$loggedInUser"/.zshrc ]] && [[ $(cat /Users/"$loggedInUser"/.zshrc | grep 'export PATH=.*:$PATH"') != "" ]]
    then
        echo "sourcing .zshrc..."
        ZSH_DISABLE_COMPFIX="true"
        #. /Users/"$loggedInUser"/.zshrc
        # avoiding oh-my-zsh errors for root by only sourcing export PATH
        source <(sed -n '/^export\ PATH\=/p' /Users/"$loggedInUser"/.zshrc)
    else
        echo "PATH was not set continuing with default value..."
    fi
    echo "using PATH..." 
    echo "$PATH"
    echo ''
}


### script
create_logfile
wait_for_loggedinuser
#timeout 3 env_check_if_run_from_batch_script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else start_log; fi
# run before main function, e.g. for time format

example_function() {

    setting_config
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config
        
    
    ### script
    echo "running as user ;)"
    
    echo "done ;)"
    echo ''
    
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    ( example_function )
else
    time ( example_function )
    echo ''
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
