#!/bin/bash

###
### backup / restore script v38
### last version without parallel was v35
### last version without gpg was v36
###


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
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}



###
### script trap and backup / restore selection
###

# trapping script to kill subprocesses when script is stopped
#trap 'echo "" && kill $(jobs -rp) >/dev/null 2>&1' SIGINT SIGTERM EXIT
#trap "killall background >/dev/null 2>&1; unset SUDOPASSWORD; kill -9 -$(ps -o pgid= $$ | grep -o '[0-9]*') >/dev/null 2>&1; exit" SIGHUP SIGINT SIGTERM EXIT
#trap "echo "" && trap - SIGTERM >/dev/null 2>&1 && kill -- -$$ >/dev/null 2>&1" SIGINT SIGTERM EXIT

# trapping script to kill subprocesses when script is stopped
# kill -9 can only be silenced with >/dev/null 2>&1 when wrappt into function
function kill_subprocesses() 
{
    # kills subprocesses only
    pkill -9 -P $$
}

function kill_main_process() 
{
    # kills subprocesses and process itself
    exec pkill -9 -P $$
}

function unset_variables() {
    #unset RESTOREDIR
    unset RESTOREMASTERDIR
    unset RESTOREUSERDIR
    unset RESTORETODIR
    unset DESTINATION
    unset HOMEFOLDER
    unset MASTERUSER
    unset USERUSER
    unset TERMINALWIDTH
    unset LINENUMBER
    unset DESTINATION
    unset SUDOPASSWORD
}

function delete_tmp_backup_script_fifo1() {
    if [ -e "/tmp/tmp_backup_script_fifo1" ]
    then
        rm "/tmp/tmp_backup_script_fifo1"
    else
        :
    fi
    if [ -e "/tmp/run_from_backup_script1" ]
    then
        rm "/tmp/run_from_backup_script1"
    else
        :
    fi
}

function create_tmp_backup_script_fifo1() {
    delete_tmp_backup_script_fifo1
    touch "/tmp/run_from_backup_script1"
    echo "1" > "/tmp/run_from_backup_script1"
    mkfifo -m 600 "/tmp/tmp_backup_script_fifo1"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_backup_script_fifo1" &
}

function delete_tmp_backup_script_fifo2() {
    if [ -e "/tmp/tmp_backup_script_fifo2" ]
    then
        rm "/tmp/tmp_backup_script_fifo2"
    else
        :
    fi
    if [ -e "/tmp/run_from_backup_script2" ]
    then
        rm "/tmp/run_from_backup_script2"
    else
        :
    fi
}

function create_tmp_backup_script_fifo2() {
    delete_tmp_backup_script_fifo2
    touch "/tmp/run_from_backup_script2"
    echo "1" > "/tmp/run_from_backup_script2"
    mkfifo -m 600 "/tmp/tmp_backup_script_fifo2"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_backup_script_fifo2" &
}

function delete_tmp_backup_script_fifo3() {
    if [ -e "/tmp/tmp_backup_script_fifo3" ]
    then
        rm "/tmp/tmp_backup_script_fifo3"
    else
        :
    fi
    if [ -e "/tmp/run_from_backup_script3" ]
    then
        rm "/tmp/run_from_backup_script3"
    else
        :
    fi
}

function create_tmp_backup_script_fifo3() {
    delete_tmp_backup_script_fifo3
    touch "/tmp/run_from_backup_script3"
    echo "1" > "/tmp/run_from_backup_script3"
    mkfifo -m 600 "/tmp/tmp_backup_script_fifo3"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_backup_script_fifo3" &
}

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; delete_tmp_backup_script_fifo3; unset_variables; open -g keepingyouawake:///deactivate; printf '\n'; stty sane; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; delete_tmp_backup_script_fifo3; unset_variables; open -g keepingyouawake:///deactivate; stty sane; kill_subprocesses >/dev/null 2>&1; exit; kill_main_process" EXIT
set -e

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
SCRIPT_DIR_FINAL=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && pwd)")
APPLESCRIPTDIR="$SCRIPT_DIR"

        # restore master dir
        echo "please select restore master directory..."
        RESTOREMASTERDIR=$(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c "osascript \"$SCRIPT_DIR\"/backup_restore_script/ask_restore_master_dir.scpt" | sed s'/\/$//')
        if [[ $(echo "$RESTOREMASTERDIR") == "" ]]
        then
            echo ''
            echo "restoremasterdir is empty - exiting script..."
            exit
        else
            echo ''
            echo 'restoremasterdir for restore is '"$RESTOREMASTERDIR"''
            echo ''
        fi

        # restore user dir
        echo "please select restore user directory..."
        RESTOREUSERDIR=$(sudo su $(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser') -c "osascript \"$SCRIPT_DIR\"/backup_restore_script/ask_restore_user_dir.scpt" | sed s'/\/$//')
        if [[ $(echo "$RESTOREUSERDIR") == "" ]]
        then
            echo ''
            echo "restoreuserdir is empty - exiting script..."
            exit
        else
            echo ''
            echo 'restoreuserdir for restore is '"$RESTOREUSERDIR"''
            echo ''
        fi


# unsetting varibales and cleaning bash environment
unset_variables   

# kill all child and grandchild processes and the parent process itself
#ps -o pgid= $$ | grep -o '[0-9]*'
#kill -9 -$(ps -o pgid= $$ | grep -o '[0-9]*') 1> /dev/null

exit

