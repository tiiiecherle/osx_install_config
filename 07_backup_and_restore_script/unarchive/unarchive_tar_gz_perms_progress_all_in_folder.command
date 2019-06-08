#!/bin/bash

###
### asking password upfront
###

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

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
# can not be used in untar pipe "| sudo gtar", use start sudo with ${USE_PASSWORD} instead
#sudo()
#{
#    ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
#    ${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
#    ${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
#}

# getting logged in user
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
#echo "loggedInUser is $loggedInUser..."



###
### checking installation of needed tools
###

echo ''
echo checking if all needed tools are installed...

# installing command line tools
if xcode-select --install 2>&1 | grep installed >/dev/null
then
  	echo command line tools are installed...
else
  	echo command line tools are not installed, installing...
  	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
  	#sudo xcodebuild -license accept
fi

# checking homebrew including script dependencies
if [[ $(sudo -u $loggedInUser command -v brew) == "" ]]
then
    echo homebrew is not installed, exiting...
    exit
else
    echo homebrew is installed...
    # checking for missing dependencies
    for formula in gnu-tar pigz pv coreutils parallel gnupg
    do
    	if [[ $(sudo -u "$loggedInUser" brew list | grep "$formula") == '' ]]
    	then
    		#echo """$formula"" is NOT installed..."
    		MISSING_SCRIPT_DEPENDENCY="yes"
    	else
    		#echo """$formula"" is installed..."
    		:
    	fi
    done
    if [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
    then
        echo at least one needed homebrew tools of gnu-tar, pigz, pv, coreutils, parallel, and gnupg is missing, exiting...
        exit
    else
        echo needed homebrew tools are installed...     
    fi
    unset MISSING_SCRIPT_DEPENDENCY
fi            


###
### decrypting and unarchiving
###

# this script finds all .tar.gz.gpg files in the folder where the script is located,
# decrypts and unarchives them if they have the same password
# if there are multiple files

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

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    #sudo -v
    #( while true; do ${USE_PASSWORD} | builtin command sudo -p '' -S -v; sleep 60; done; ) &
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
            kill -9 $SUDO_PID
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}

# trap
trap "printf '\n'; stop_sudo; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
trap "stop_sudo; kill_subprocesses >/dev/null 2>&1; exit" EXIT
#set -e

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

echo ''
echo 'please enter decryption password...'
stty -echo
trap 'stty echo' EXIT
printf 'gpg decryption password: '
read -r $@ GPG_PASSWORD
echo ''
stty echo
trap - EXIT
echo ''

NUMBER_OF_CORES=$(parallel --number-of-cores)
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
#echo $NUMBER_OF_MAX_JOBS_ROUNDED
#

decrypt_and_unarchive_parallel () {
    start_sudo
    
    do_it_parallel() {
    	if [[ "$USE_PARALLELS" == "yes" ]]
    	then
    		# if parallels is used i needs to redefined
    		item="$1"
    	else
    		:
    	fi        
    	echo ''
    	echo "decrypting and unarchiving..."
    	echo "$item"
    	echo to "$SCRIPT_DIR"/
    	cat "$item" | gpg --batch --passphrase="$GPG_PASSWORD" --quiet -d - | unpigz -dc - | sudo gtar --same-owner -C "$SCRIPT_DIR" -xpf - >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m"
    }
    export -f do_it_parallel
    
    echo "decrypting and unarchiving is set to parallel mode, no progress will be shown..."
    echo ''
    export USE_PARALLELS="yes"
    export SCRIPT_DIR
    export GPG_PASSWORD
    find "$SCRIPT_DIR" -mindepth 1 -name '*.tar.gz.gpg' | parallel --will-cite -j4 do_it_parallel

    stop_sudo
}

decrypt_and_unarchive_sequential () {
    start_sudo
    
    echo "decrypting and unarchiving is set to sequential mode..."
    echo ''
    
    find "$SCRIPT_DIR" -mindepth 1 -name '*.tar.gz.gpg' -print0 | 
    while IFS= read -r -d '' line
    do
        item="$line"
        echo ''
    	echo "decrypting and unarchiving..."
    	echo "$item"
    	echo to "$SCRIPT_DIR"/
    	cat "$item" | pv -s $(gdu -scb "$item" | tail -1 | awk '{print $1}' | grep -o "[0-9]\+") | gpg --batch --passphrase="$GPG_PASSWORD" --quiet -d - | unpigz -dc - | sudo gtar --same-owner -C "$SCRIPT_DIR" -xpf - >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m"
    done
        
    stop_sudo
}

#decrypt_and_unarchive_parallel
decrypt_and_unarchive_sequential

echo ''
echo 'done ;)'
echo ''
  
exit