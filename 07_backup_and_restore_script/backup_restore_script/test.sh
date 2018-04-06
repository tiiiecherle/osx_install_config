#!/bin/bash

###
### backup / restore script v39
### last version without parallel was v35
### last version without gpg was v36
### last version with separate backup scripts for calendar and contact backup scripts was v38
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
    unset VBOXSAVEDIR
    unset GUI_APP_TO_BACKUP
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

###
### backup / restore function
###

# starting a function to tee a record to a logfile
function backup_restore {
                
            ### casks install
            if [[ "$CONT1" == "y" || "$CONT1" == "yes" || "$CONT1" == "" ]]
            then
                echo ""
                echo "installing casks..."
                create_tmp_backup_script_fifo3
                # this has to run in a new shell due to variables, functions, etc.
                # so do not source this script
                #bash -c """$SCRIPT_DIR_FINAL""/05_homebrew_and_casks/5b_homebrew_cask/5_casks.sh"
                bash "$SCRIPT_DIR_FINAL"/05_homebrew_and_casks/5b_homebrew_cask/5_casks.sh
                wait
                echo RUN_FROM_RESTORE_SCRIPT is $RUN_FROM_RESTORE_SCRIPT
                echo SCRIPT_DIR is $SCRIPT_DIR
            else
                :
            fi

            ### ownership and permissions
            echo ""
            echo "setting ownerships and permissions..."
            export RESTOREMASTERDIR
            export RESTOREUSERDIR
            . "$SCRIPT_DIR"/permissions/ownerships_and_permissions_restore.sh
            wait
            
            ### safari extensions settings restore
            # this can not be included in the restore script if the keychain is restored
            # a reboot is needed after restoring the keychain before running the safari extensions restore script
            # or the changes to safari would not be kept
            #echo ""
            #echo "restoring safari extensions and their settings..."
            #export SELECTEDUSER
            #export MASTERUSER
            #export RESTOREMASTERDIR
            #export HOMEFOLDER
            #bash -c "export SELECTEDUSER=\"$SELECTEDUSER\"; export MASTERUSER=\"$MASTERUSER\"; export RESTOREMASTERDIR=\"$RESTOREMASTERDIR\"; export HOMEFOLDER=\"$HOMEFOLDER\"; "$SCRIPT_DIR"/safari_extensions/safari_extensions_settings_restore.sh"
            #bash "$SCRIPT_DIR"/safari_extensions/safari_extensions_settings_restore.sh
            #wait
            
            echo ""
            echo "script done ;)"
            
            osascript -e 'tell app "loginwindow" to «event aevtrrst»'           # reboot
            #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'          # shutdown
            #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'          # logout

}

getting_scriptdir () {
    SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
}
getting_scriptdir
SCRIPT_DIR_FINAL=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && pwd)")
APPLESCRIPTDIR="$SCRIPT_DIR"

#FUNC=$(declare -f backup_restore)
#time bash -c "OPTION=\"$OPTION\"; SCRIPT_DIR=\"$SCRIPT_DIR\"; APPLESCRIPTDIR=\"$APPLESCRIPTDIR\"; $FUNC; backup_restore | tee "$HOME"/Desktop/backup_restore_log.txt"

backup_restore | tee "$HOME"/Desktop/backup_restore_log.txt
#echo ''

###
### unsetting password
###

# unsetting varibales and cleaning bash environment
unset_variables   

# kill all child and grandchild processes and the parent process itself
#ps -o pgid= $$ | grep -o '[0-9]*'
#kill -9 -$(ps -o pgid= $$ | grep -o '[0-9]*') 1> /dev/null

exit

