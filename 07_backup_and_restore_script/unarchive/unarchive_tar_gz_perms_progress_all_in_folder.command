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
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}



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
if [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'which brew') != "" ]]
then
    echo homebrew is installed...
    
    if [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep gnu-tar) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep pigz) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep pv) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep coreutils) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep parallel) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c 'brew list' | grep gnupg) == '' ]]
    then
        echo at least one needed homebrew tool of gnu-tar, pigz, pv, coreutils, parallel and gnupg2 is missing, exiting...
        exit
    else
        echo needed homebrew tools are installed...     
    fi
else
    echo homebrew is not installed, exiting...
    exit
fi



###
### decrypting and unarchiving
###

# this script finds all .tar.gz.gpg files in the folder where the script is located,
# decrypts and unarchives them if they have the same password
# if there are multiple files

function kill_subprocesses() 
{
    # kills only subprocesses of the current process
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # option 1
    RUNNING_SUBPROCESSES=$(pgrep -g $(ps -o pgid= $$))
    kill -15 $RUNNING_SUBPROCESSES
    wait $RUNNING_SUBPROCESSES 2>/dev/null
    # option 2
    #{ kill -15 $RUNNING_SUBPROCESSES && wait $RUNNING_SUBPROCESSES; } >/dev/null 2>&1
    # option 3
    #kill -13 $RUNNING_SUBPROCESSES
    unset RUNNING_SUBPROCESSES
}

function kill_main_process() 
{
    # kills processes itself
    #kill $$
    kill -13 $$
}

function start_sudo() {
    #${USE_PASSWORD} | builtin command sudo -p '' -S -v
    sudo -v
    ( while true; do sudo -v; sleep 60; done; ) &
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

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "printf '\n'; stop_sudo; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "stop_sudo; kill_subprocesses >/dev/null 2>&1; exit" EXIT
#set -e

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")

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
    
    parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" -q bash -c '
    
        item="{}"
        echo ""
    	echo "decrypting and unarchiving..."
    	echo "$item"
    	echo to '"$SCRIPT_DIR"'/"$(basename $item | rev | cut -d"." -f4- | rev )"
    	cat "$item" | pv -s $(gdu -scb "$item" | tail -1 | awk "{print $1}" | grep -o "[0-9]\+") | gpg --batch --passphrase='"$GPG_PASSWORD"' --quiet -d - | unpigz -dc - | sudo gtar --same-owner -C '"$SCRIPT_DIR"' -xpf - >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m"
    ' ::: "$(find "$SCRIPT_DIR" -mindepth 1 -name '*.tar.gz.gpg')"
    
    stop_sudo
}

decrypt_and_unarchive_sequential () {
    start_sudo
    
    for item in $(find "$SCRIPT_DIR" -mindepth 1 -name '*.tar.gz.gpg')
    do
        echo ""
    	echo "decrypting and unarchiving..."
    	echo "$item"
    	echo to "$SCRIPT_DIR"/"$(basename $item | rev | cut -d"." -f4- | rev )"
    	bash -c 'cat '"$item"' | pv -s $(gdu -scb '"$item"' | tail -1 | awk "{print $1}" | grep -o "[0-9]\+") | gpg --batch --passphrase='"$GPG_PASSWORD"' --quiet -d - | unpigz -dc - | sudo gtar --same-owner -C '"$SCRIPT_DIR"' -xpf - >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m"'
    done
        
    stop_sudo
}

decrypt_and_unarchive_parallel
#decrypt_and_unarchive_sequential

echo ''
echo 'done ;)'
echo ''
  
exit