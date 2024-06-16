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
    # recommended way, but it seems apple deprecated python2 in macOS 12.3.0
    # to keep on using the python command, a python package is needed
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
        # to keep on using the python command, a python package is needed
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
    # macos sip limits installing pip and installing/updating python packages - as a consequence only support homebrew python3
    echo ''
    if [[ "$PYTHON3_HOMEBREW_INSTALLED" == "yes" ]]
    then
        # installed
        # should be enough to use python3 here as $PYTHON3_INSTALLED checks if it is installed via homebrew
        #PYTHON_VERSION='python3'
        PYTHON_VERSION="$(sudo -H -u "$loggedInUser" brew --prefix)/bin/python3"
        # no longer needed as python 3.4 and newer have pip included as a module (python3 -m pip install [...])
        #PIP_VERSION='pip3'
        #PIP_VERSION="$(sudo -H -u "$loggedInUser" brew --prefix)/bin/pip3"
    else
        # not installed
        echo "only python3 via homebrew is supported, exiting..."
        exit
    fi
    
    #echo ''
    printf "%-36s %-15s\n" "python used in script" "$PYTHON_VERSION"
    #printf "%-36s %-15s\n" "pip used in script" "$PIP_VERSION"
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
echo ''
wait_for_network_select
echo ''
wait_for_getting_online
# run before main function, e.g. for time format

hosts_file_install_update() {

    setting_config
    
    ### loggedInUser
    #echo ''
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
                git config pull.rebase false    # merge (the default strategy)
                #git config pull.rebase true    # rebase
                #git config pull.ff only        # fast-forward only
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
        
        
        ### version of dependencies
        change_dependencies_versions() {
            if [[ $(cat "$PATH_TO_APPS"/hosts_file_generator/requirements.txt | grep "beautifulsoup4==4.6.1") != "" ]]
            then
                sed -i '' "s|beautifulsoup4.*|beautifulsoup4>=4.6.1|" "$PATH_TO_APPS"/hosts_file_generator/requirements.txt
            else
                :
            fi
        }
        #change_dependencies_versions  
                   
                   
        ### homebrew and python versions
        # no longer needed as the system or homebrew python version is only used to create an virtual python environment with its own version that ist used for the python commands in this script
        # see below for more details on virtual python environment
        #check_homebrew_and_python_versions
    
    
        ### python changes
        # python 3.11 implements the new PEP 668, marking python base environments as "externally managed"
        # homebrew reflects these changes in python 3.12 and newer
        # there are two recoomended ways of using python
        
        # 1     usage of two special commands --break-system-packages --user (not used in this script)
        # use python3 -m pip [command] --break-system-packages --user to install to /Users/$USER/Library/Python/3.xx/ (it does not break system packages, just a scary name)
        # the disadvantage of this usage is that all python project would use the same directory/virtualenv and it would not be possible to use different versions of python or the packages for each project
        # therefore the directory has to exist and has to be in PATH when using sudo -H -u "$loggedInUser" python3 -m pip [...]
        #echo ''
        #echo "using new PATH including user python directory..."
        #PYTHON_VERSION_FOLDER_TO_CREATE="$(echo $PYTHON3_VERSION | awk '{print $2}' | awk -F'.' '{print $1 "." $2}')"
        #sudo -H -u "$loggedInUser" mkdir -p /Users/"$loggedInUser"/Library/Python/"$PYTHON_VERSION_FOLDER_TO_CREATE"/bin
        #PATH=$PATH:/Users/"$loggedInUser"/Library/Python/"$PYTHON_VERSION_FOLDER_TO_CREATE"/bin
        #echo "$PATH"
        #echo ''
        
        # 2     virtual environments (used in this script)
        # the best way is to create a virtual environment for each python usage/script/project and maintain them separately
        # this gives the best fexiblility, testing possibilities and stability on the final used environment
        PYTHON_VERSION="python3"
        
        # checking system python version (including homebrew)
        echo ''
        echo 'system python version incl. homebrew outside of the virtual environment...'
        sudo -H -u "$loggedInUser" which "${PYTHON_VERSION}"
        sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -V
        # will be deactivated later after last python command of the script
        #echo ''
        
        # creating and activating virtual python environment
        echo ''
        echo "creating and activating virtual python environment..."
        PYTHON_VIRTUALENVIRONMENT="/Users/"$loggedInUser"/Library/Python/hosts_file_generator"
        sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m venv "$PYTHON_VIRTUALENVIRONMENT"
        source "$PYTHON_VIRTUALENVIRONMENT"/bin/activate
        
        # virtual environment python version
        echo ''
        echo 'virtual environment python version...'
        sudo -H -u "$loggedInUser" which "${PYTHON_VERSION}"
        sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -V
        # will be deactivated later after last python command of the script
        #echo ''


        ### updating
        echo ''
        echo "updating pip..."
        
        # updating pip itself
        sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip install --upgrade pip 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        
        # requirements 
        echo ''
        echo "installing requirements..."
        # installing dependencies into virtual python environment
        for i in $(cat "$PATH_TO_APPS"/hosts_file_generator/requirements.txt | awk '{ print $1 }')
        do
            if [[ $(sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip list | cut -f1 -d' ' | tr " " "\n" | awk '{if(NR>=3)print}' | cut -d' ' -f1 | grep "$i") == "" ]]
            then
                echo ''
                echo "installing python package "$i"..."
                sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip install "$i"
            else
                echo "python package "$i" already installed..."
            fi
        done
        
        # updating all packages to latest versions
        echo ''
        echo "updating all packages..."
        #sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip --disable-pip-version-check list --outdated --format=json | sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))"
        sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip --disable-pip-version-check list --outdated --format=json | sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -c "import json, sys; print('\n'.join([x['name'] for x in json.load(sys.stdin)]))" | xargs -n1 sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip install --upgrade 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        # or (both working)
        #sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip --disable-pip-version-check list --outdated --user | cut -f1 -d' ' | tr " " "\n" | awk '{if(NR>=3)print}' | cut -d' ' -f1 | xargs -n1 sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip install --upgrade 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        
        # installs the exact version of the requirement and even downgrades them if a lower version is specified in requirements.txt
        # therefore it is recommended to use a virtual python environment (see above)
        echo ''
        echo "installing exact versions from requirements.txt..."
        sudo -H -u "$loggedInUser" "${PYTHON_VERSION}" -m pip install -r "$PATH_TO_APPS"/hosts_file_generator/requirements.txt 2>&1 | grep -v 'already up-to-date' | grep -v 'already satisfied'
        
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
        
        # deactivating/leaving python virtual environment
        echo ''
        echo "deactivating virtual python environment..."
        deactivate
        #sudo -H -u "$loggedInUser" which "${PYTHON_VERSION}"

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
        
        # ocsp.apple.com
        # https://forums.macrumors.com/threads/regarding-the-news-yesterday-that-apps-on-macos-needs-to-phone-home.2267988/page-6
        # https://sneak.berlin/20201112/your-computer-isnt-yours/
        # https://blog.jacopo.io/en/post/apple-ocsp/
        #sudo echo '' >> /etc/hosts
        #sudo echo "# ocsp.apple.com" >> /etc/hosts
        #sudo echo "::1 ocsp.apple.com" >> /etc/hosts
        #sudo echo "127.0.0.1 ocsp.apple.com" >> /etc/hosts
        
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
    echo ''
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
