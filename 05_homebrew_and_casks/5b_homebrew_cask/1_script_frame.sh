#!/bin/bash

###
### asking password upfront
###

if [[ "$SUDOPASSWORD" != "" ]]
then
    #USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    :
elif [[ -e /tmp/run_for_homebrew ]] && [[ $(cat /tmp/run_for_homebrew) == 1 ]]
then
    function delete_tmp_homebrew_script_fifo() {
        if [ -e "/tmp/tmp_homebrew_script_fifo" ]
        then
            rm -f "/tmp/tmp_homebrew_script_fifo"
        else
            :
        fi
        if [ -e "/tmp/tmp_homebrew_script_mas_fifo" ]
        then
            rm -f "/tmp/tmp_homebrew_script_mas_fifo"
        else
            :
        fi
        if [ -e "/tmp/run_for_homebrew" ]
        then
            rm -f "/tmp/run_for_homebrew"
        else
            :
        fi
    }
    unset SUDOPASSWORD
    unset MAS_APPSTORE_PASSWORD
    SUDOPASSWORD=$(cat "/tmp/tmp_homebrew_script_fifo" | head -n 1)
    MAS_APPSTORE_PASSWORD=$(cat "/tmp/tmp_homebrew_script_mas_fifo" | head -n 1)
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    delete_tmp_homebrew_script_fifo
    #set +a
else
    # function for reading secret string (POSIX compliant)
    enter_password_secret()
    {
        # read -s is not POSIX compliant
        #read -s -p "Password: " SUDOPASSWORD
        #echo ''
        
        # this is POSIX compliant
        # disabling echo, this will prevent showing output
        stty -echo
        # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
        trap 'stty echo' EXIT
        # asking for password
        printf "Password: "
        # reading secret
        read -r "$@" SUDOPASSWORD
        # reanabling echo
        stty echo
        trap - EXIT
        # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
        printf "\n"
        # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
        # has to be part of the function or it wouldn`t be updated during the maximum three tries
        #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    }
    
    # unset the password if the variable was already set
    unset SUDOPASSWORD
    
    # making sure no variables are exported
    set +a
    
    # asking for the SUDOPASSWORD upfront
    # typing and reading SUDOPASSWORD from command line without displaying it and
    # checking if entered password is the sudo password with a set maximum of tries
    NUMBER_OF_TRIES=0
    MAX_TRIES=3
    while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    do
        NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
        #echo "$NUMBER_OF_TRIES"
        if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
        then
            enter_password_secret
            ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
            if [ $? -eq 0 ]
            then 
                break
            else
                echo "Sorry, try again."
            fi
        else
            echo ""$MAX_TRIES" incorrect password attempts"
            exit
        fi
    done
    
fi

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}

# redefining sudo so it is possible to run homebrew install without entering the password again
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
}

function get_running_subprocesses()
{
    SUBPROCESSES_PID_TEXT=$(pgrep -lg $(ps -o pgid= $$) | grep -v $$ | grep -v grep)
    SCRIPT_COMMAND=$(ps -o comm= $$)
	PARENT_SCRIPT_COMMAND=$(ps -o comm= $PPID)
	if [[ $PARENT_SCRIPT_COMMAND == "bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "-bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "" ]]
	then
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | awk '{print $1}')
    else
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | grep -v "$PARENT_SCRIPT_COMMAND" | awk '{print $1}')
    fi
}

function kill_subprocesses() 
{
    # kills only subprocesses of the current process
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    #echo "killing processes..."
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # giving subprocesses the chance to terminate cleanly kill -15
    get_running_subprocesses
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -15 $RUNNING_SUBPROCESSES
        # do not wait here if a process can not terminate cleanly
        #wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # waiting for clean subprocess termination
    TIME_OUT=0
    while [[ $RUNNING_SUBPROCESSES != "" ]] && [[ $TIME_OUT -lt 3 ]]
    do
        get_running_subprocesses
        sleep 1
        TIME_OUT=$((TIME_OUT+1))
    done
    # killing the rest of the processes kill -9
    get_running_subprocesses
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -9 $RUNNING_SUBPROCESSES
        wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # unsetting variable
    unset RUNNING_SUBPROCESSES
}

function kill_main_process() 
{
    # kills processes itself
    #kill $$
    kill -13 $$
}

function unset_variables() {
    unset SUDOPASSWORD
    unset SUDO_PID
    unset CHECK_IF_CASKS_INSTALLED
    unset CHECK_IF_FORMULAE_INSTALLED
    unset CHECK_IF_MASAPPS_INSTALLED
    unset INSTALLATION_METHOD
    unset KEEPINGYOUAWAKE
}

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    ( while true; do ${USE_PASSWORD} | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID="$!"
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then
            sudo kill -9 $SUDO_PID &> /dev/null
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}

function activating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
    #echo ''
	echo "activating keepingyouawake..."
    KEEPINGYOUAWAKE="active"
	open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///activate
    sleep 1
    if [ -e /tmp/quarantine_keepingyouawake.xattr ]
    then    
        xattr -w com.apple.quarantine `cat "/tmp/quarantine_keepingyouawake.xattr"` "/Applications/KeepingYouAwake.app"
    else
        :
    fi
else
    :
fi
}

function deactivating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
    echo "deactivating keepingyouawake..."
    KEEPINGYOUAWAKE=""
    #open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///deactivate
    sleep 1
    if [ -e /tmp/quarantine_keepingyouawake.xattr ]
    then    
        xattr -w com.apple.quarantine `cat "/tmp/quarantine_keepingyouawake.xattr"` "/Applications/KeepingYouAwake.app"
    else
        :
    fi
else
    :
fi
}

function delete_tmp_homebrew_script_fifo() {
    if [ -e "/tmp/tmp_homebrew_script_fifo" ]
    then
        rm "/tmp/tmp_homebrew_script_fifo"
    else
        :
    fi
    if [ -e "/tmp/tmp_homebrew_script_mas_fifo" ]
    then
        rm -f "/tmp/tmp_homebrew_script_mas_fifo"
    else
        :
    fi
    if [ -e "/tmp/run_for_homebrew" ]
    then
        rm "/tmp/run_for_homebrew"
    else
        :
    fi
}

function create_tmp_homebrew_script_fifo() {
    delete_tmp_homebrew_script_fifo
    touch "/tmp/run_for_homebrew"
    echo "1" > "/tmp/run_for_homebrew"
    mkfifo -m 600 "/tmp/tmp_homebrew_script_fifo"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_homebrew_script_fifo" &
    mkfifo -m 600 "/tmp/tmp_homebrew_script_mas_fifo"
    builtin printf "$MAS_APPSTORE_PASSWORD\n" > "/tmp/tmp_homebrew_script_mas_fifo" &
}


function databases_apps_security_permissions() {
    DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_SYSTEM"
	DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_USER"
}
    
function identify_terminal() {
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]
    then
    	export SOURCE_APP=com.apple.Terminal
    	export SOURCE_APP_NAME="Terminal"
    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]
    then
        export SOURCE_APP=com.googlecode.iterm2
        export SOURCE_APP_NAME="iTerm"
	else
		export SOURCE_APP=com.apple.Terminal
		echo "terminal not identified, setting automating permissions to apple terminal..."
	fi
}

function give_apps_security_permissions() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        # working, but does not show in gui of system preferences, use csreq for the entry to show
	    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP"',0,1,1,?,NULL,0,'"$AUTOMATED_APP"',?,NULL,?);"
    fi
    sleep 1
}

function remove_apps_security_permissions_stop() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        AUTOMATED_APP=com.apple.systemevents
        # macos versions 10.14 and up
        if [[ $SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1 == "yes" ]]
        then
            # source app was already allowed to control app before running this script, so don`t delete the permission
            :
        elif  [[ $SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1 == "no" ]]
        then
            sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"');"
        else
            :
        fi
        unset AUTOMATED_APP
        #
        if [[ $SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP2 == "yes" ]]
        then
            # source app was already allowed to control app before running this script, so don`t delete the permission
            :
        elif  [[ $SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP2 == "no" ]]
        then
            sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where (service='kTCCServiceAccessibility' and client='"$SOURCE_APP"');"
        else
            :
        fi
    fi
}

homebrew_update() {
    if [[ "$UPDATE_HOMEBREW" == "no" ]]
    then
        :
    else
        echo ''
        echo "updating homebrew..."
        # brew prune deprecated as of 2019-01, using brew cleanup instead
        brew update-reset 1>/dev/null 2> >(grep -v "Reset branch" 1>&2) && brew analytics off 1>/dev/null && brew update 1>/dev/null && brew doctor 1>/dev/null && brew cleanup 1>/dev/null 2> >(grep -v "Skipping" 1>&2)
        
        BREW_PATH=$(brew --repository)
        # working around a --json=v1 bug until it`s fixed
        # https://github.com/Homebrew/homebrew-cask/issues/52427
        #sed -i '' '/"conflicts_with" =>/s/.to_a//g' "$(brew --repository)"/Library/Homebrew/cask/cask.rb
        #sed -i '' '/"conflicts_with" =>/s/.to_a//g' "$BREW_PATH"/Library/Homebrew/cask/cask.rb
        # fixed 2019-01-28
        # https://github.com/Homebrew/brew/pull/5597
    
        echo 'updating homebrew finished ;)'
    fi
}

cleanup_all_homebrew() {
    # making sure brew cache exists
    HOMEBREW_CACHE_DIR=$(brew --cache)
    mkdir -p "$HOMEBREW_CACHE_DIR"
    chown "$USER":staff "$HOMEBREW_CACHE_DIR"/
    chmod 755 "$HOMEBREW_CACHE_DIR"/
    
    brew cleanup 1> /dev/null
    # also seems to clear cleans hidden files and folders
    brew cleanup --prune=0 1> /dev/null
    
    rm -rf "$HOMEBREW_CACHE_DIR"/{,.[!.],..?}*
    # brew cask cleanup is deprecated from 2018-09
    #brew cask cleanup
    #brew cask cleanup 1> /dev/null
    
    # brew cleanup has to be run after the rm -rf "$HOMEBREW_CACHE_DIR"/{,.[!.],..?}* again
    # if not it will delete a file /Users/$USER/Library/Caches/Homebrew/.cleaned
    # this file is produced by brew cleanup and is checked if brew cleanup was run in the last x days
    # without the file brew thinks brew cleanup was not run and complains about it
    # https://github.com/Homebrew/brew/issues/5644
    brew cleanup 1> /dev/null
    
    # fixing red dots before confirming commit to cask-repair that prevent the commit from being made
    # https://github.com/vitorgalvao/tiny-scripts/issues/88
    #sudo gem uninstall -ax rubocop rubocop-cask 1> /dev/null
    #brew cask style 1> /dev/null
}


###
### variables
###

MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

# macos 10.14 and higher
#if [[ $(echo $MACOS_VERSION | cut -f1 -d'.') == "10" ]] && [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
#then
#    echo "this script is only compatible with macos 10.14 mojave and newer, exiting..."
#    echo ''
#else
#    :
#fi

# macos 10.14 only
#if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.') != "10.14" ]]
#then
#    echo "this script is only compatible with macos 10.14 mojave, exiting..."
#    echo ''
#    exit
#else
#    :
#fi

###

echo''    
databases_apps_security_permissions
identify_terminal

if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13 
	:
else
    echo "setting security permissions..."
    if [[ "$FIRST_RUN_DONE" == "" ]]
    then
        AUTOMATED_APP=com.apple.systemevents
        if [[ $(sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"' and allowed='1');") != "" ]]
    	then
    	    SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1="yes"
    	    #echo "$SOURCE_APP is already allowed to control $AUTOMATED_APP..."
    	else
    		SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1="no"
    		#echo "$SOURCE_APP is not allowed to control $AUTOMATED_APP..."
    		give_apps_security_permissions
    	fi
        #
    	if [[ $(sudo sqlite3 "$DATABASE_SYSTEM" "select * from access where (service='kTCCServiceAccessibility' and client='"$SOURCE_APP"' and allowed='1');") != "" ]]
    	then
    	    SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP2="yes"
    	    #echo "$SOURCE_APP is already allowed to control accessibility..."
    	else
    		SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP2="no"
    		#echo "$SOURCE_APP is not allowed to control accessibility..."
    		sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','"$SOURCE_APP"',0,1,1,NULL,NULL,NULL,?,NULL,0,?);"
    	fi
    else
        :
    fi
    echo ''
fi

#SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")


### trapping
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_SOURCED="yes" || SCRIPT_SOURCED="no"
[[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"
# a sourced script does not exit, it ends with return, so checking for session master is sufficent
# subprocesses will not be killed on return, only on exit
#if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_SOURCED" == "no" ]]
if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]]
then
    if [[ "$FIRST_RUN_DONE" == "" ]]
    then
        # script is session master and not run from another script (S on mac Ss on linux)
        trap "stop_sudo; printf '\n'; stty sane; pkill ruby; delete_tmp_homebrew_script_fifo; remove_apps_security_permissions_stop; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
        trap "stop_sudo; stty sane; delete_tmp_homebrew_script_fifo; remove_apps_security_permissions_stop; kill_subprocesses >/dev/null 2>&1; deactivating_keepingyouawake >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
        #set -e
    else
        # do not stop keeping you awake in the scripts executed by run_all in separate tabs
        #echo "no stopping of keepingyouawake..."
        # script is not session master and run from another script (S+ on mac and linux) 
        trap "stop_sudo; printf '\n'; stty sane; pkill ruby; delete_tmp_homebrew_script_fifo; remove_apps_security_permissions_stop; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
        trap "stop_sudo; stty sane; delete_tmp_homebrew_script_fifo; remove_apps_security_permissions_stop; unset SUDOPASSWORD; exit" EXIT
    fi
else    
    # script is session master and not run from another script (S on mac Ss on linux)
    trap "stop_sudo; printf '\n'; stty sane; pkill ruby; delete_tmp_homebrew_script_fifo; remove_apps_security_permissions_stop; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "stop_sudo; stty sane; delete_tmp_homebrew_script_fifo; remove_apps_security_permissions_stop; kill_subprocesses >/dev/null 2>&1; deactivating_keepingyouawake >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
fi


### checking if online
#echo ''
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "we are online, running script..."
    #echo ''   
else
    echo "not online, exiting..."
    echo ''
    exit
fi


### more variables
# keeping hombrew from updating each time brew install is used
HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_AUTO_UPDATE
# number of max parallel processes
NUMBER_OF_CORES=$(sysctl hw.ncpu | awk '{print $NF}')
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
#NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
# due to connection issues with too many downloads at the same time limiting the maximum number of jobs for now
NUMBER_OF_MAX_JOBS_ROUNDED=6
#echo $NUMBER_OF_MAX_JOBS_ROUNDED


### checking if command line tools are installed
function checking_command_line_tools() {
    if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -nz "$(ls -A "$(xcode-select -print-path)")" ]]
    then
      	#echo command line tools are installed...
      	:
    else
    	#echo command line tools are not installed, installing...
    	# prompting the softwareupdate utility to list the command line tools
        if [[ -e "$SCRIPT_DIR"/2_command_line_tools.sh ]]
        then
            . "$SCRIPT_DIR"/2_command_line_tools.sh
        else
            echo ''
            echo "command line tools and install script are missing, exiting..."
            echo ''
            exit
        fi
    fi
}
# done in scripts
#checking_command_line_tools


### checking if parallel is installed
function checking_parallel() {
    if [[ "$(which parallel)" == "" ]]
    then
        # parallel is not installed
        export INSTALLATION_METHOD="sequential"
    else
        # parallel is installed
        export INSTALLATION_METHOD="parallel"
    fi
    #echo ''
    echo INSTALLATION_METHOD is "$INSTALLATION_METHOD"...
    echo ''
}
# done in scripts
#checking_parallel


### checking if homebrew is installed
function checking_homebrew() {
    if [[ $(which brew) == "" ]]
    then        
        if [[ -e "$SCRIPT_DIR"/3_homebrew_caskbrew.sh ]]
        then
            . "$SCRIPT_DIR"/3_homebrew_caskbrew.sh
        else
            echo ''
            echo "homebrew and install script are missing, exiting..."
            echo ''
            exit
        fi
    else
        #echo "homebrew is installed..."
        :
    fi
}
# done in scripts
#checking_homebrew


### first run done
export FIRST_RUN_DONE="yes"

