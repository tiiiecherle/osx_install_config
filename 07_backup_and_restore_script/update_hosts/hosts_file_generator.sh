#!/bin/zsh

### config file
# this script will not source the config file as it runs as root and does not ask for a password after installation

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


### checking root
if [[ $(id -u) -ne 0 ]]
then 
    echo "script is not run as root, exiting..."
    exit
else
    :
fi


### variables
SERVICE_NAME=com.hostsfile.install_update
SCRIPT_INSTALL_NAME=hosts_file_generator


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
    local ERROR_LOG_DIR=/Users/"$loggedInUser"/Desktop/batch_error_logs
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
    LOGDIR=/var/log
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
            sudo rm "$LOGFILE"
            sudo touch "$LOGFILE"
            sudo chmod 644 "$LOGFILE"
        fi
    else
        sudo touch "$LOGFILE"
        sudo chmod 644 "$LOGFILE"
    fi
    
    sudo echo "" >> "$LOGFILE"
    sudo echo "$EXECTIME" >> "$LOGFILE"
}

check_if_online() {
    PINGTARGET1=google.com
    PINGTARGET2=duckduckgo.com
    # check 1
    # ping -c 3 "$PINGTARGET1" >/dev/null 2>&1'
    # check 2
    # resolving dns (dig +short xxx 80 or resolveip -s xxx) even work when connection (e.g. dhcp) is established but security confirmation is required to go online, e.g. public wifis
    # during testing dig +short xxx 80 seemed more reliable to work within timeout
    # timeout 3 dig +short -4 "$PINGTARGET1" 80 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1'
    #
    echo ''
    echo "checking internet connection..."
    if [[ $(timeout 3 2>/dev/null dig +short -4 "$PINGTARGET1" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        if [[ $(timeout 3 2>/dev/null dig +short -4 "$PINGTARGET2" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
}

wait_for_getting_online() {
    ### waiting for getting online
    echo "checking internet connection..."
    NUM=0
    MAX_NUM=6
    SLEEP_TIME=6
    # waiting for getting online
    # around 4s for check_if_online + 6s = 10s per try
    check_if_online &>/dev/null
    while [[ "$ONLINE_STATUS" != "online" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
    do
        sleep "$SLEEP_TIME"
        check_if_online &>/dev/null
        NUM=$((NUM+1))
    done
    #echo ''
    WAIT_TIME=$((NUM*SLEEP_TIME))
    echo "waited "$WAIT_TIME"s for getting online..."
    if [[ "$ONLINE_STATUS" != "online" ]]
    then
        WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
        echo "not online after "$WAIT_TIME"s, exiting..."
        exit
    else
        echo "we are online..."
    fi
}

wait_for_network_select() {
    ### waiting for network select script
    if [[ $(sudo launchctl list | grep com.network.select) != "" ]]
    then
        # as the script start at launch on boot give network select time to create the tmp file
        sleep 3
        if [[ -e /tmp/network_select_in_progress ]]
        then
            NUM=1
            MAX_NUM=30
            SLEEP_TIME=3
            # waiting for network select script
            echo "waiting for network select..."
            while [[ -e /tmp/network_select_in_progress ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
            do
                sleep "$SLEEP_TIME"
                NUM=$((NUM+1))
            done
            #echo ''
            WAIT_TIME=$((NUM*SLEEP_TIME))
            echo "waited "$WAIT_TIME"s for network select to finish..."
        else
            echo "network select not running, continuing..."
        fi
    else
        echo "network select not installed, continuing..."
    fi
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
echo ''
wait_for_network_select
echo ''
wait_for_getting_online
# run before main function, e.g. for time format
setting_config &> /dev/null

hosts_file_install_update() {
    
    ### loggedInUser
    echo ''
    echo "loggedInUser is $loggedInUser..."
    echo ''

    ### script
	# checking modification date of /etc/hosts
    UPDATEEACHDAYS=4
    if [[ "$(find /etc/* -name 'hosts' -maxdepth 0 -type f -mtime +"$UPDATEEACHDAYS"d | grep -x '/etc/hosts')" == "" ]]
    then
        echo "/etc/hosts was already updated in the last "$UPDATEEACHDAYS" days, no need to update, exiting..."
        echo ''
        exit
    else
        echo "/etc/hosts is older than "$UPDATEEACHDAYS" days, updating..."
    fi
 
    # checking if online
    if [[ "$ONLINE_STATUS" == "online" ]]
    then
        # online
        #echo "we are online, updating hosts file..."
    
        # creating installation directory
        mkdir -p ""$PATH_TO_APPS"/hosts_file_generator/"
    
        # downloading / updating hosts file creator from git repository
        if [[ -d ""$PATH_TO_APPS"/hosts_file_generator/.git" ]]
        then
            # updating
            echo "updating hosts file generator..."
            if [[ -d ""$PATH_TO_APPS"/hosts_file_generator/" ]]
            then
                cd ""$PATH_TO_APPS"/hosts_file_generator/"
                sudo git fetch --all
                sudo git reset --hard origin/master
                sudo git pull origin master
                cd -
            else
                :
            fi
        else
            # installing
            echo "downloading hosts file generator..."
            if [[ -d ""$PATH_TO_APPS"/hosts_file_generator/" ]]
            then
                sudo rm -rf ""$PATH_TO_APPS"/hosts_file_generator/"
                mkdir -p ""$PATH_TO_APPS"/hosts_file_generator/"
                git clone --depth 5 https://github.com/StevenBlack/hosts.git ""$PATH_TO_APPS"/hosts_file_generator/"
            else
                :
            fi
        fi
            
                   
        ### homebrew and python versions
        check_homebrew_and_python_versions


        ### updating
        echo ''
        echo "updating pip and script dependencies..."
        
        # version of dependencies
        change_dependencies_versions() {
            if [[ $(cat "$PATH_TO_APPS"/hosts_file_generator/requirements.txt | grep "beautifulsoup4==4.6.1") != "" ]]
            then
                sed -i '' "s|beautifulsoup4.*|beautifulsoup4>=4.6.1|" "$PATH_TO_APPS"/hosts_file_generator/requirements.txt
            else
                :
            fi
        }
        change_dependencies_versions
        
        ### updating
        # updating pip itself
        sudo -H -u "$loggedInUser" "${PIP_VERSION}" install --upgrade pip 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        
        # updating all pip modules
        sudo -H -u "$loggedInUser" "${PIP_VERSION}" freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H -u "$loggedInUser" "${PIP_VERSION}" install -U 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        
        # installing dependencies
        sudo -H -u "$loggedInUser" "${PIP_VERSION}" install -r "$PATH_TO_APPS"/hosts_file_generator/requirements.txt 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        
        # backing up original hosts file
        if [[ ! -f "/etc/hosts.orig" ]]
        then
            echo "backing up original hosts file..."
            sudo cp -a "/etc/hosts" "/etc/hosts.orig"
        else
            :
        fi
    
        # updating / creating hostsfile
        echo ''
        echo "updating hosts file..."
        cd ""$PATH_TO_APPS"/hosts_file_generator/"

        # as the script is run as root from a launchd some env variables are not set, e.g. all locales
        # setting LC_ALL for root solves
        # UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 in position 13: ordinal not in range(128)
        LANG_SCRIPT="de_DE.UTF-8"
        
        sudo LC_ALL=$LANG_SCRIPT "${PYTHON_VERSION}" updateHostsFile.py -a -r -o alternates/fakenews-gambling-porn -e fakenews gambling porn
        if [[ $? -eq 0 ]]
        then
            echo ''
            echo "updating hosts file SUCCESSFULL..."
            echo ''
        else
            echo ''
            echo "updating hosts file FAILED..."
            echo ''
        fi
        
        #sudo python updateHostsFile.py -a -n -r -o alternates/fakenews-gambling-porn -e fakenews gambling porn
        #sudo python updateReadme.py
        cd - >/dev/null 2>&1
    
        ### customization
        # commenting out lines
        #sudo sed -i '' '/cdn-static.liverail.com/s/^/#/g' /etc/hosts
        #or
        #sudo awk -i inplace '/cdn-static.liverail.com/ {$0="#"$0}1' /etc/hosts
        ## sport1
        #sudo sed -i '' '/probe.yieldlab.net/s/^/#/g' /etc/hosts
        # anti-adblock
        #sudo sed -i '' '/0.0.0.0 prod.appnexus.map.fastly.net/s/^/#/g' /etc/hosts
        #sudo sed -i '' '/0.0.0.0 acdn.adnxs.com/s/^/#/g' /etc/hosts
        ## spiegel.de
        #sudo sed -i '' '/imagesrv.adition.com/s/^/#/g' /etc/hosts        
		## google shopping
        #sudo sed -i '' '/www.googleadservices.com/s/^/#/g' /etc/hosts
        #sudo sed -i '' '/0.0.0.0 ad.doubleclick.net/s/^/#/g' /etc/hosts
        #sudo sed -i '' '/pagead.l.doubleclick.net/s/^/#/g' /etc/hosts
        ## wimbledon
        #sudo sed -i '' '/0.0.0.0 secure.brightcove.com/s/^/#/g' /etc/hosts
        ## sma
        #sudo sed -i '' '/0.0.0.0 eu.*.force.com/s/^/#/g' /etc/hosts
        #sudo sed -i '' '/0.0.0.0 eu1.*.force.com/s/^/#/g' /etc/hosts
        #sudo sed -i '' '/0.0.0.0 eu10.force.com/s/^/#/g' /etc/hosts
        
        # wimbledon test
        #for i in $(sudo cat /etc/hosts | grep "^0.*" | awk '{print $NF}' | head -n 10000)
        #do
        #    sudo sed -i '' "/$i/s/^/#/g" /etc/hosts
        #done
        
        #sudo sed -i '' '/spiegel-de.spiegel.de/s/^/#/g' /etc/hosts
        # solved in
        # https://github.com/StevenBlack/hosts/issues/1155#issuecomment-589870171
        
        # testing
        # open respective website in browser
        # deactivate adblocker for the website
        # open /etc/hosts in gas mask and add / delete entries
        #sudo killall -HUP mDNSResponder && sleep 2 && open -a "$PATH_TO_APPS"/Firefox.app && sleep 2 && open -a "$PATH_TO_APPS"/Firefox.app http://www.wimbledon.com/en_GB/video/highlights.html


        ### activating hosts file
        echo "activating hosts file..."
        # older osx versions
        #sudo dscacheutil -flushcache
        # newer macos versions
        sudo killall -HUP mDNSResponder
        
        # done
        echo ''
        echo 'done ;)'
    else
        # offline
        echo "we are not not online, skipping update of hosts file, exiting script..."
    fi
    
	echo ''
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    ( hosts_file_install_update )
else
    time ( hosts_file_install_update )
fi

echo ''

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
