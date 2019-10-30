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
    echo "it took "$NUM"s for the loggedInUser to be available..."
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
    BATCH_PIDS=()
    BATCH_PIDS+=$(ps aux | grep "/batch_script_part.*.command" | grep -v grep | awk '{print $2;}')
    if [[ "$BATCH_PIDS" != "" ]] && [[ -e "/tmp/batch_script_in_progress" ]]
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

env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi


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

timeout() { perl -e '; alarm shift; exec @ARGV' "$@"; }

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
    if [[ $(timeout 2 2>/dev/null dig +short -4 "$PINGTARGET1" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        if [[ $(timeout 2 2>/dev/null dig +short -4 "$PINGTARGET2" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
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
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi
wait_for_loggedinuser >> "$LOGFILE"
# run before main function, e.g. for time format
setting_config &> /dev/null

hosts_file_install_update() {
    
    ### loggedInUser
    echo "loggedInUser is $loggedInUser..."
    
    ### sourcing .$SHELLrc or setting PATH
    #setting_config


    ### script
	# checking modification date of /etc/hosts
    UPDATEEACHDAYS=4
    if [[ "$(find /etc/* -name 'hosts' -maxdepth 0 -type f -mtime +"$UPDATEEACHDAYS"d | grep -x '/etc/hosts')" == "" ]]
    then
        echo "/etc/hosts was already updated in the last "$UPDATEEACHDAYS" days, no need to update..."
        echo "exiting script..."
        exit
    else
        echo "/etc/hosts is older than "$UPDATEEACHDAYS" days, updating..."
    fi
    
    # giving the online check some time if run on laptop to switch to correct network profile on boot
    check_if_online
    if [[ "$ONLINE_STATUS" == "online" ]]
    then
        # online
        :
    else
        # offline
        #echo "not online, waiting 120s for next try..."
        echo "waiting 120s for next try..."
        sleep 120
    fi
 
    # checking if online
    check_if_online
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
            
                   
        ### python version
        if sudo -H -u "$loggedInUser" command -v brew &> /dev/null
        then
    	    # installed
            echo ''
            echo "homebrew is installed..."
            # do not autoupdate homebrew
            export HOMEBREW_NO_AUTO_UPDATE=1
            # checking installed python versions
            if [[ $(sudo -H -u "$loggedInUser" brew list | grep "^python@2$") == '' ]]
            then
                echo "python2 is not installed via homebrew..."
                PYTHON2_INSTALLED="no"
            else
                echo "python2 is installed via homebrew..."
                PYTHON2_INSTALLED="yes"
                #sudo -H -u "$loggedInUser" brew uninstall --ignore-dependencies python@2
            fi
            if [[ $(sudo -H -u "$loggedInUser" brew list | grep "^python$") == '' ]]
            then
                # the project drops python2 support, so make sure python3 is installed
                echo "python3 is not installed via homebrew..."
                PYTHON3_INSTALLED="no"
                #sudo -H -u "$loggedInUser" brew install python
            else
                echo "python3 is installed via homebrew..."
                PYTHON3_INSTALLED="yes"
                #sudo -H -u "$loggedInUser" brew uninstall --ignore-dependencies python@3
            fi
        else
            # not installed
            echo ''
            echo "homebrew is not installed..."
        fi
        
        # listing installed python versions
        echo ''
        echo "installed python versions..."
        APPLE_PYTHON_VERSION=$(python --version 2>&1)
        printf "%-25s %-25s\n" "apple python" "$APPLE_PYTHON_VERSION"
        if [[ $PYTHON2_INSTALLED == "yes" ]]
        then
            PYTHON2_VERSION=$(python2 --version 2>&1)
            printf "%-25s %-25s\n" "python2" "$PYTHON2_VERSION"
        else
            :
        fi
        if [[ $PYTHON3_INSTALLED == "yes" ]]
        then
            PYTHON3_VERSION=$(python3 --version 2>&1)
            printf "%-25s %-25s\n" "python3" "$PYTHON3_VERSION"
        else
            :
        fi
        
        # the project is python3 only (from 2018-09), so make sure python3 is used
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
        echo "python version used in script is $PYTHON_VERSION with $PIP_VERSION..."
        echo ''


        ### updating
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
        
        # updating
        if [[ "$PYTHON_VERSION" == 'python' ]] && [[ "$PIP_VERSION" == 'pip' ]]
        then
            # updating pip itself
            sudo -H pip install --upgrade pip 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
            
            # updating all pip modules
            # do not update internal apple site-packages to ensure compatibility
            :
            
            # installing dependencies
            #sudo pip install -r "$PATH_TO_APPS"/hosts_file_generator/requirements.txt
            sudo -H pip install --user -r "$PATH_TO_APPS"/hosts_file_generator/requirements.txt 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        else
            # updating pip itself
            sudo -H -u "$loggedInUser" "${PIP_VERSION}" install --upgrade pip 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
            
            # updating all pip modules
            "${PIP_VERSION}" freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 sudo -H -u "$loggedInUser" "${PIP_VERSION}" install -U 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
            
            # installing dependencies
            sudo -H -u "$loggedInUser" "${PIP_VERSION}" install -r "$PATH_TO_APPS"/hosts_file_generator/requirements.txt 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        fi
        
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
        echo ''
    else
        # offline
        echo "we are not not online, skipping update of hosts file, exiting script..."
    fi
	
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    (time ( hosts_file_install_update )) | tee -a "$LOGFILE"
else
    (time ( hosts_file_install_update )) 2>&1 | tee -a "$LOGFILE"
fi

echo '' >> "$LOGFILE"

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
