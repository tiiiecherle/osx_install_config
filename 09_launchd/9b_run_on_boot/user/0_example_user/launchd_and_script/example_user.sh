#!/bin/zsh

### variables
SERVICE_NAME=com.example_user.show
SCRIPT_INSTALL_NAME=example_user

echo ''


### getting logged in user before starting the log
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
NUM=0
MAX_NUM=15
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
#echo "loggedInUser is $loggedInUser..."
if [[ "$loggedInUser" == "" ]]
then
    WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
    echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
    exit
else
    :
fi


### logfile
EXECTIME=$(date '+%Y-%m-%d %T')
LOGDIR=/Users/"$loggedInUser"/Library/Logs
LOGFILE="$LOGDIR"/"$SCRIPT_INSTALL_NAME".log

if [[ -f "$LOGFILE" ]]
then
    # only macos takes care of creation time, linux doesn`t because it is not part of POSIX
    LOGFILEAGEINSECONDS="$(( $(date +"%s") - $(stat -f "%B" $LOGFILE) ))"
    MAXLOGFILEAGE=$(echo "30*24*60*60" | bc)
    #echo $LOGFILEAGEINSECONDS
    #echo $MAXLOGFILEAGE
    # deleting logfile after 30 days
    if [ "$LOGFILEAGEINSECONDS" -lt "$MAXLOGFILEAGE" ];
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


### functions
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
# run before main function, e.g. for time format
setting_config &> /dev/null


### example
example_function() {
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config
        
    
    ### script
    echo "running as user ;)"
    
}

(time ( example_function )) 2>&1 | tee -a "$LOGFILE"
echo '' >> "$LOGFILE"
