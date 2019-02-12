#!/bin/bash

### variables
SERVICE_NAME=com.screen_resolution.set
SCRIPT_NAME=screen_resolution

echo ''


### getting logged in user before starting the log
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
NUM=0
MAX_NUM=15
SLEEP_TIME=3
# waiting for loggedInUser to be available
while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
do
    sleep "$SLEEP_TIME"
    NUM=$(($NUM+1))
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
done
#echo ''
#echo "NUM is $NUM..."
#echo "loggedInUser is $loggedInUser..."
if [[ "$loggedInUser" == "" ]]
then
    WAIT_TIME=$(($MAX_NUM*$SLEEP_TIME))
    echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
    exit
else
    :
fi


### logfile
EXECTIME=$(date '+%Y-%m-%d %T')
LOGDIR=/Users/"$loggedInUser"/Library/Logs
LOGFILE="$LOGDIR"/"$SCRIPT_NAME".log

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


### function
screen_resolution() {
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    
    ### sourcing .bash_profile or setting PATH
    # as the script is run as root from a launchd it would not detect the binary commands and would fail checking if binaries are installed
    # needed if binary is installed in a special directory
    if [[ -e /Users/$loggedInUser/.bash_profile ]] && [[ $(cat /Users/$loggedInUser/.bash_profile | grep '/usr/local/bin:') != "" ]]
    then
        . /Users/$loggedInUser/.bash_profile
    else
        #export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
        PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
    fi
    
    
    ### script
    # checking if python3 is installed
    echo ''
    if [[ $(python --version 2>&1 | awk '{print $NF}' | cut -d'.' -f1) != "3" ]] && [[ $(compgen -c python | grep "^python3$") == "" ]]
    then
        echo "python3 is not installed, using apple python2..."
        PYTHON_VERSION='python'
        PIP_VERSION='pip'
        for i in pyobjc-framework-Cocoa pyobjc-framework-Quartz
        do
            if [[ $("$PIP_VERSION" list | grep "$i") == "" ]]
            then
                echo ''
                echo "installing python module "$i"..."
                sudo "$PIP_VERSION" install "$i"
            else
                echo "python module "$i" already installed..."
            fi
        done
    else
        echo "python3 is installed, checking modules..."
        PYTHON_VERSION='python3'
        PIP_VERSION='pip3'
        for i in pyobjc-framework-Cocoa pyobjc-framework-Quartz
        do
            if [[ $("$PIP_VERSION" list | grep "$i") == "" ]]
            then
                echo ''
                echo "installing python module "$i"..."
                sudo -u $loggedInUser "$PIP_VERSION" install "$i"
            else
                echo "python3 module "$i" already installed..."
            fi
        done
    fi
    
    # variables
    DISPLAY_TO_SET="EV2785"
    SYSTEM_PROFILER_DISPLAY_DATA=$(system_profiler SPDisplaysDataType -xml)
    #DISPLAYS=$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')
    DISPLAYS=$(echo "$SYSTEM_PROFILER_DISPLAY_DATA" | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')
    #echo "$DISPLAYS"
    #NUMBER_OF_CONNECTED_DISPLAYS=$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}' | wc -l | sed 's/^ *//' | sed 's/ *$//')
    NUMBER_OF_CONNECTED_DISPLAYS=$(echo "$SYSTEM_PROFILER_DISPLAY_DATA" | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}' | wc -l | sed 's/^ *//' | sed 's/ *$//')  
    #DISPLAY_RESOLUTION=$(system_profiler SPDisplaysDataType -xml | awk -F'>|<' '/_spdisplays_resolution/{getline; print $3}')
    #DISPLAY_RESOLUTION=$(echo "$SYSTEM_PROFILER_DISPLAY_DATA" | awk -F'>|<' '/_spdisplays_resolution/{getline; print $3}')
    #echo "$DISPLAY_RESOLUTION"
    WANTED_RESOLUTION="2304"
    DISPLAY_MANAGER_INSTALL_PATH="/Applications/display_manager"
    DISPLAY_MANAGER_RESOLUTION='2304 1296 60 only-hidpi'
    
    # display manager
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
        exit
    fi
}

(time screen_resolution) 2>&1 | tee -a "$LOGFILE"
echo '' >> "$LOGFILE"
