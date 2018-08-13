#!/bin/bash

###
### backup / restore script v41
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
### functions
###

# kill can only be silenced when 
# wrapped into function >/dev/null 2>&1 
# or with wait 
# or with kill -13

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
    unset OPTION
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

function databases_apps_security_permissions() {
    DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_SYSTEM"
    DATABASE_USER=""$HOMEFOLDER"/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_USER"
}

function give_apps_security_permissions() {
    databases_apps_security_permissions
    if [[ $(defaults read loginwindow SystemVersionStampAsString | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
        # all gui app backups in one script
        # accessibility entry for reminders backup
        sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,NULL,NULL);"
        # reminders
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceReminders','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,NULL,NULL);"
        # contacts
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,NULL,NULL);"
        # calendar
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,NULL,NULL);"
        
    else
        # macos versions 10.14 and up
        # accessibility
        sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,?);"
        # reminders
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceReminders','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
        # contacts
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
        # calendar
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
        # automation gui backup app
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.gui-apps-backup',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
        # automation files
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.Terminal',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.Terminal',0,1,1,?,NULL,0,'com.apple.Terminal',?,NULL,?);"
        # automation vbox backup app
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.virtualbox-backup',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
        sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.apple.ScriptEditor.id.virtualbox-backup',0,1,1,?,NULL,0,'com.apple.Terminal',?,NULL,?);"
    fi
    sleep 1
}

function remove_apps_security_permissions_start_script() {
    databases_apps_security_permissions
    if [[ $(defaults read loginwindow SystemVersionStampAsString | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
        sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where client='com.apple.ScriptEditor.id.gui-apps-backup';"
        sudo sqlite3 "$DATABASE_USER" "delete from access where client='com.apple.ScriptEditor.id.gui-apps-backup';"
    else
        # macos versions 10.14 and up
        # gui backup app
        sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where client='com.apple.ScriptEditor.id.gui-apps-backup';"
        sudo sqlite3 "$DATABASE_USER" "delete from access where client='com.apple.ScriptEditor.id.gui-apps-backup';"
        # automation files
        sudo sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.systemevents');"
        sudo sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.Terminal');"
        # vbox backup app
        sudo sqlite3 "$DATABASE_USER" "delete from access where client='com.apple.ScriptEditor.id.virtualbox-backup';"
    fi
    sleep 1
}

function remove_apps_security_permissions_stop_script() {
    databases_apps_security_permissions
    if [[ $(defaults read loginwindow SystemVersionStampAsString | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
        :
    else
        # macos versions 10.14 and up
        # automation files
        sudo sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.systemevents');"
        sudo sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.Terminal');"
    fi
    #sleep 1
}


### trapping
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_SOURCED="yes" || SCRIPT_SOURCED="no"
[[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"
# a sourced script does not exit, it ends with return, so checking for session master is sufficent
# subprocesses will not be killed on return, only on exit
#if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_SOURCED" == "no" ]]
if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]]
then
    # script is session master and not run from another script (S on mac Ss on linux)
    trap "delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; delete_tmp_backup_script_fifo3; remove_apps_security_permissions_stop_script; open -g keepingyouawake:///deactivate; printf '\n'; stty sane; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; delete_tmp_backup_script_fifo3; remove_apps_security_permissions_stop_script; open -g keepingyouawake:///deactivate; stty sane; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
else
    # script is not session master and run from another script (S+ on mac and linux)
    trap "delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; delete_tmp_backup_script_fifo3; remove_apps_security_permissions_stop_script; open -g keepingyouawake:///deactivate; printf '\n'; stty sane; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; delete_tmp_backup_script_fifo3; remove_apps_security_permissions_stop_script; open -g keepingyouawake:///deactivate; stty sane; unset SUDOPASSWORD; exit" EXIT
fi
set -e

echo ''

if [ "$OPTION" == "" ]
then
    # choosing the backup and defining $BACKUP variable
    PS3="Please select option by typing the number: "
    select OPTION in BACKUP RESTORE
    do
        echo You selected option $OPTION.
        echo ''
        break
    done
else
    echo "script is run with option $OPTION..."
    echo ''
fi

# check if a valid option was selected
if [[ "$OPTION" == "" ]] || [[ "$OPTION" != "BACKUP" ]] && [[ "$OPTION" != "RESTORE" ]]
then
    echo "no valid option selected - exiting script..."
    exit
else
    :
fi

###
### backup / restore function
###

# starting a function to tee a record to a logfile
function backup_restore {
    
    # backupdate
    DATE=$(date +%F)
    
    # users on the system without ".localized" and "Shared"
    #SYSTEMUSERS=$(pushd /Users/ >/dev/null 2>&1; printf "%s " * | egrep -v "^[.]" | egrep -v "Guest"; popd >/dev/null 2>&1)
    SYSTEMUSERS=$(ls -1 /Users/ | egrep -v "^[.]" | egrep -v "Shared" | egrep -v "Guest")
    
    # getting logged in user
    #echo "LOGNAME is $(logname)..."
    #/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
    #stat -f%Su /dev/console
    #defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
    # recommended way
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    #echo "loggedInUser is $loggedInUser..."

    if [[ $(echo "$SYSTEMUSERS" | wc -l | sed 's/ //g') == "1" ]]
    then
        SELECTEDUSER="$SYSTEMUSERS"
        if [ "$OPTION" == "BACKUP" ]
        then
            echo "only one user account on the system, backing up user ""$SELECTEDUSER""..."
        elif [ "$OPTION" == "RESTORE" ]
        then
            echo "only one user account on the system, restoring to user ""$SELECTEDUSER""..."
        else
            :
        fi
        echo ''
    else
        if [ "$OPTION" == "BACKUP" ]
        then
            PS3="Please select user to backup by typing the number: "
        elif [ "$OPTION" == "RESTORE" ]
        then
            PS3="Please select user to restore to by typing the number: "
        else
            :
        fi
        
        select SELECTEDUSER in ""$SYSTEMUSERS""
        do
            echo You selected user "$SELECTEDUSER".
            echo ""
            break
        done
    fi
    
    # check1 if a valid user was selected
    USERCHECK=$(find /Users -maxdepth 1 -name "$SELECTEDUSER" -exec basename {} \;)
    if [ "$SELECTEDUSER" != "$USERCHECK" ]
    then
        echo "no valid user selected - exiting script because of no real username..."
        echo ''
        exit
    else
        :
    fi
    
    # check2 if a valid user was selected
    if [ "$SELECTEDUSER" == "" ]
    then
        echo "no valid user selected - exiting script because of empty username..."
        exit
    else
        :
    fi
    
    # confirm run
    read -p "do you want to run the script with option ""$OPTION"" and for user ""$SELECTEDUSER"" (Y/n)? " CONT_SCRIPT
    CONT_SCRIPT="$(echo "$CONT_SCRIPT" | tr '[:upper:]' '[:lower:]')"    # tolower
    echo $CONT_SCRIPT
    sleep 0.1
    #
    if [[ "$CONT_SCRIPT" == "" || "$CONT_SCRIPT" == "y" || "$CONT_SCRIPT" == "yes" ]]
    then
        :
    else
        echo ''
        echo "exiting..."
        echo ''
        exit
    fi
    
    ###
    ### variables and list syntax check
    ###
    
    # user home folder
    HOMEFOLDER=/Users/"$SELECTEDUSER"
    echo HOMEFOLDER is "$HOMEFOLDER"
    
    # checking if user directory exists
    if [ -d "$HOMEFOLDER" ]
    then
        echo "user home directory exists - running script..."
        echo ''
    
        # path to current working directory
        CURRENT_DIR="$(pwd)"
        echo current directory is "$CURRENT_DIR"
        
        # path to running script directory
        #SCRIPT_DIR="$(dirname $0)"
        #SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
        echo script directory is "$SCRIPT_DIR"
        
        # checking syntax of backup / restore list
        BACKUP_RESTORE_LIST="$SCRIPT_DIR"/list/backup_restore_list.txt
        echo ""
        SYNTAXERRORS=0
        LINENUMBER=0
        while IFS='' read -r line || [[ -n "$line" ]]
        do
            LINENUMBER=$(($LINENUMBER+1))
        	if [ ! "$line" == "" ] && [[ ! $line =~ ^[\#] ]] && [[ ! $line =~ ^m[[:blank:]] ]] && [[ ! $line =~ ^u[[:blank:]] ]] && [[ ! $line =~ ^echo[[:blank:]] ]]
        	then
                echo "wrong syntax for entry in line "$LINENUMBER": "$line""
                SYNTAXERRORS=$(($SYNTAXERRORS+1))
            else
            	:
                #echo "correct entry"
            fi
        	    
        done <"$BACKUP_RESTORE_LIST"
        
        #echo "$SYNTAXERRORS"
        if [ "$SYNTAXERRORS" -gt "0" ]
        then
            echo "there are syntax errors in the backup / restore list, please correct the entries and rerun the script..."
            exit
        else
        	echo "syntax of backup / restore list o.k., continuing..."
        	echo ""
        fi
        
        ###
        ### updates and installations to all macs running the script
        ###
        
        if [[ -e "$SCRIPT_DIR"/update_macos/updates_macos.sh ]]
        then
            . "$SCRIPT_DIR"/update_macos/updates_macos.sh
            wait
        else
            echo """$SCRIPT_DIR""/update_macos/updates_macos.sh not found, skipping..."
        fi
        
        ###
        ### checking installation of needed tools
        ###
        
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
            if [[ "$OPTION" == "BACKUP" ]]; 
            then
                # checking for missing dependencies
                for formula in gnu-tar pigz pv coreutils parallel gnupg cliclick
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
                    echo at least one needed homebrew tools of gnu-tar, pigz, pv, coreutils, parallel, gnupg and cliclick is missing, exiting...
                    exit
                else
                    echo needed homebrew tools are installed...     
                fi
                unset MISSING_SCRIPT_DEPENDENCY
            else
                # checking for missing dependencies
                for formula in coreutils parallel
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
                    echo at least one needed homebrew tools of coreutils and parallel is missing, exiting...
                    exit
                else
                    echo needed homebrew tools are installed...     
                fi
                unset MISSING_SCRIPT_DEPENDENCY
            fi
        fi
        
        #echo ''
        
        ###
        ### backup
        ###
        
        # activating keepingyouawake
        if [ -e /Applications/KeepingYouAwake.app ]
        then
            echo ''
            echo "activating keepingyouawake..."
            echo ''
            open -g keepingyouawake:///activate
        else
            :
        fi
        
        # checking if backup option was selected
        if [[ "$OPTION" == "BACKUP" ]]; 
            then
            echo "running backup..."
            sleep 1
            
            echo ''
            echo "resetting security permissions for backup apps..."
            remove_apps_security_permissions_start_script
            give_apps_security_permissions
            
            # opening applescript which will ask for saving location of compressed file
            echo ''
            echo "asking for directory to save the backup to..."
            TARGZSAVEDIR=$(sudo -u "$loggedInUser" osascript "$SCRIPT_DIR"/backup_restore_script/ask_save_to.scpt 2> /dev/null | sed s'/\/$//')
            sleep 0.5

            #echo ''
            # checking if valid path for backup was selected
            if [ -e "$TARGZSAVEDIR" ]
            then
                echo "backup will be saved to "$TARGZSAVEDIR""
                sleep 0.1
            else
                echo "no valid path for saving the backup selected, exiting script..."
                exit
            fi
            printf '\n'
            sleep 0.1
            
            ### asking for backups
            # virtualbox backup
            if [ "$SELECTEDUSER" == tom ]
            then
                read -p "do you want to backup virtualbox images (y/N)? " CONT1
                CONT1="$(echo "$CONT1" | tr '[:upper:]' '[:lower:]')"    # tolower
                sleep 0.1
                #
                if [[ "$CONT1" == "y" || "$CONT1" == "yes" ]]
                then
                    # opening applescript which will ask for saving location of compressed file
                    echo "asking for directory to save the vbox backup to..."
                    VBOXSAVEDIR=$(sudo -u "$loggedInUser" osascript "$SCRIPT_DIR"/vbox_backup/ask_save_to_vbox.scpt 2> /dev/null | sed s'/\/$//')
                    sleep 0.5
                    #echo ''
                    # checking if valid path for backup was selected
                    if [ -e "$VBOXSAVEDIR" ]
                    then
                        echo "vbox backup will be saved to "$VBOXSAVEDIR""
                        sleep 0.1
                        printf '\n'
                        sleep 0.1
                    else
                        echo "no valid path for saving the vbox backup selected, exiting script..."
                        exit
                    fi
                else
                    :
                fi
            else
                :
            fi
            
            # files backup
            read -p "do you want to backup local files (y/N)? " CONT2
            CONT2="$(echo "$CONT2" | tr '[:upper:]' '[:lower:]')"    # tolower
            sleep 0.1
            
            # reminders backup
            read -p "do you want to run a reminders backup (y/N)? " CONT3
            CONT3="$(echo "$CONT3" | tr '[:upper:]' '[:lower:]')"    # tolower
            sleep 0.1
        
            # running contacts backup applescript
            read -p "do you want to run a contacts backup (y/N)? " CONT4
            CONT4="$(echo "$CONT4" | tr '[:upper:]' '[:lower:]')"    # tolower
            sleep 0.1
        
            # running calendars backup applescript
            read -p "do you want to run an calendars backup (y/N)? " CONT5
            CONT5="$(echo "$CONT5" | tr '[:upper:]' '[:lower:]')"    # tolower
            sleep 0.1

            if [[ "$CONT3" == "y" || "$CONT3" == "yes" || "$CONT4" == "y" || "$CONT4" == "yes" || "$CONT5" == "y" || "$CONT5" == "yes" ]]
            then
                echo ''
            else
                :
            fi
            
            ### running backups
            # reminders
            if [[ "$CONT3" == "y" || "$CONT3" == "yes" ]]
            then
                echo "running reminders backup... please do not touch the computer until the app quits..."
                # cleaning up old backups (only keeping the latest 4)
                find "$HOMEFOLDER"/Documents/backup/reminders -type d -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d | while read -r REMINDERSBACKUPS
                do
                    rm -rf "$HOMEFOLDER"/Documents/backup/reminders/"$REMINDERSBACKUPS"
                done
                             
                # running contacts backup
                GUI_APP_TO_BACKUP=Reminders
                export GUI_APP_TO_BACKUP
                open "$SCRIPT_DIR"/gui_apps/gui_apps_backup.app
                #PID=$(ps aux | grep gui_apps_backup | grep -v grep | awk "{ print \$2 }")
                #echo $PID
                # waiting for the process to finish
                while ps aux | grep gui_apps_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                osascript -e 'tell application "Terminal" to activate'
            else
                :
            fi
            
            # contacts
            if [[ "$CONT4" == "y" || "$CONT4" == "yes" ]]
            then
                echo "running contacts backup... please do not touch the computer until the app quits..."
                # cleaning up old backups (only keeping the latest 4)
                find "$HOMEFOLDER"/Documents/backup/contacts -type d -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d | while read -r CONTACTSBACKUPS
                do
                    rm -rf "$HOMEFOLDER"/Documents/backup/contacts/"$CONTACTSBACKUPS"
                done
                
                # running contacts backup
                GUI_APP_TO_BACKUP=Contacts
                export GUI_APP_TO_BACKUP
                open "$SCRIPT_DIR"/gui_apps/gui_apps_backup.app
                #PID=$(ps aux | grep gui_apps_backup | grep -v grep | awk "{ print \$2 }")
                #echo $PID
                # waiting for the process to finish
                while ps aux | grep gui_apps_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                osascript -e 'tell application "Terminal" to activate'
                
                # old working
                # service entry for for contacts backup
                #sudo sqlite3 ""$HOMEFOLDER"/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceAddressBook','com.apple.ScriptEditor.id.contacts-backup',0,1,1,NULL,NULL);"
                #sleep 2
                # running contacts backup
                #open "$SCRIPT_DIR"/gui_apps/contacts/contacts_backup.app
                #PID=$(ps aux | grep contacts_backup | grep -v grep | awk "{ print \$2 }")
                #echo $PID
                # waiting for the process to finish
                #while ps aux | grep contacts_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                #osascript -e 'tell application "Terminal" to activate'
            else
                :
            fi
            
            # calendar
            if [[ "$CONT5" == "y" || "$CONT5" == "yes" ]]
            then
                echo "running calendars backup... please do not touch the computer until the app quits..."
                # cleaning up old backups (only keeping the latest 4)
                find "$HOMEFOLDER"/Documents/backup/calendar -type d -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d | while read -r CALENDARSBACKUPS
                do
                    rm -rf "$HOMEFOLDER"/Documents/backup/calendar/"$CALENDARSBACKUPS"
                done
                
                # running calendar backup
                GUI_APP_TO_BACKUP=Calendar
                export GUI_APP_TO_BACKUP
                open "$SCRIPT_DIR"/gui_apps/gui_apps_backup.app
                #PID=$(ps aux | grep gui_apps_backup | grep -v grep | awk "{ print \$2 }")
                #echo $PID
                # waiting for the process to finish
                while ps aux | grep gui_apps_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                osascript -e 'tell application "Terminal" to activate'
                 
                # old working
                # accessibility entry for calendar backup
                #sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);"
                # service entry for for calendar backup
                #sudo sqlite3 ""$HOMEFOLDER"/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceCalendar','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);"
                #sleep 2
                # running calendar backup                
                #open "$SCRIPT_DIR"/gui_apps/contacts/calendars_backup.app
                #PID=$(ps aux | grep calendars_backup | grep -v grep | awk "{ print \$2 }")
                #echo $PID
                # waiting for the process to finish
                #while ps aux | grep calendars_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                #osascript -e 'tell application "Terminal" to activate'
            else
                :
            fi
            
            # files
            if [[ "$CONT2" == "y" || "$CONT2" == "yes" ]]
            then
                FILESTARGZSAVEDIR="$TARGZSAVEDIR"
                FILESAPPLESCRIPTDIR="$APPLESCRIPTDIR"
                echo "running local files backup..."
                create_tmp_backup_script_fifo1
                . "$SCRIPT_DIR"/files/run_files_backup.sh
            else
                :
            fi
            
            # virtualbox
            if [[ "$CONT1" == "y" || "$CONT1" == "yes" ]]
            then
                echo "running virtualbox backup..."
                export VBOXSAVEDIR
                open "$SCRIPT_DIR"/vbox_backup/virtualbox_backup.app
            else
                :
            fi
        
            # backup destination
            DESTINATION="$HOMEFOLDER"/Desktop/backup_"$SELECTEDUSER"_"$DATE"
            mkdir -p "$DESTINATION"
            
            # backup
            #
            echo ""
            echo "starting backup..."
            #    
            BACKUP_RESTORE_LIST="$SCRIPT_DIR"/list/backup_restore_list.txt
            #STTY_ORIG=$(stty -g)
            #TERMINALWIDTH=$(echo $COLUMNS)
            #TERMINALWIDTH=$(stty size | awk '{print $2}')
            TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
            LINENUMBER=0
            
            function backup_data () {
                # using with parallel
                # comment out the while, do done lines
                # uncomment this line
                line="$1"
                #echo "$line"
                
                #while IFS='' read -r line || [[ -n "$line" ]]
                #do
                
                	LINENUMBER=$(($LINENUMBER+1))
                	
                    # if starting with one # and whitespace / tab
                	#if [[ $line =~ ^[\#][[:blank:]] ]]
                	
                	# if starting with more than one #
                	#if [[ $line =~ ^[\#]{2,} ]]
                
                	# if line is empty
                	#if [ -z "$line" ]
                	if [ "$line" == "" ]
                	then
                        :
                    else
                        :
                    fi
                	
                	# if starting with #
                	if [[ $line =~ ^[\#] ]]
                	then
                        :
                    else
                        :
                    fi
                    
                    # if starting with echo and whitespace / tab
                	if [[ $line =~ ^echo[[:blank:]] ]]
                	then
                        OUTPUT=$(echo "$line" | sed 's/^echo*//' | sed -e 's/^[ \t]*//')
                		TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
                        echo "$OUTPUT" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                    else
                        :
                    fi   
                     	
                	# if starting with m and space / tab
                	if [[ $line =~ ^m[[:blank:]] ]]
                	then
                        ENTRY=$(echo "$line" | cut -f2 | sed 's|~|'"$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
                        #echo "$ENTRY"
                        DIRNAME_ENTRY=$(dirname "$ENTRY")
                        #echo "$DIRNAME_ENTRY"
                        BASENAME_ENTRY=$(basename "$ENTRY")
                        #echo "$BASENAME_ENTRY"
                        if [ -e "$ENTRY" ]
                        then
                            cd "$DIRNAME_ENTRY"
                            mkdir -p "$DESTINATION$DIRNAME_ENTRY"
                            sudo rsync -a "$BASENAME_ENTRY" "$DESTINATION$DIRNAME_ENTRY"
                        else
                			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-8))
                            #echo "        ""$ENTRY" does not exist, skipping...
                            echo "$BASENAME_ENTRY" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ \ \ \ /g"
                        fi
                    else
                        :
                    fi
                    
                    # if starting with u and space / tab
                	if [[ $line =~ ^u[[:blank:]] ]]
                	then
                        ENTRY=$(echo "$line" | cut -f2 | sed 's|~|'"$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
                        #echo "$ENTRY"
                        DIRNAME_ENTRY=$(dirname "$ENTRY")
                        #echo "$DIRNAME_ENTRY"
                        BASENAME_ENTRY=$(basename "$ENTRY")
                        #echo "$BASENAME_ENTRY"
                        if [ -e "$ENTRY" ]
                        then
                            cd "$DIRNAME_ENTRY"
                            mkdir -p "$DESTINATION$DIRNAME_ENTRY"
                            sudo rsync -a "$BASENAME_ENTRY" "$DESTINATION$DIRNAME_ENTRY"
                        else
                			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-8))
                            #echo "        ""$ENTRY" does not exist, skipping...
                            echo "$BASENAME_ENTRY" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ \ \ \ /g"
                        fi
                    else
                        :
                    fi
                                    
                #done <"$BACKUP_RESTORE_LIST"
            }
            
            # without parallel
            # comment out the whole following parallel block
            # uncomment the while read, done lines in the script and run the function
            # backup_data
            
            # with parallel
            # comment out the whole without parallel block
            # comment out the while read, done lines in the script and run
            export DESTINATION
            export TERMINALWIDTH
            export HOMEFOLDER
            export LINENUMBER
            #
            mkdir -p /tmp/backup_restore
            TMP_BACKUP_FUNCTION_SCRIPT="/tmp/backup_restore/backup_data.sh"
            touch "$TMP_BACKUP_FUNCTION_SCRIPT"
            chmod +x "$TMP_BACKUP_FUNCTION_SCRIPT"
            echo "#!/bin/bash" > "$TMP_BACKUP_FUNCTION_SCRIPT"
            echo $(declare -f backup_data) >> "$TMP_BACKUP_FUNCTION_SCRIPT"
            #sed -i '' "s/backup_data () {//" "$TMP_BACKUP_FUNCTION_SCRIPT"
            sed -i '' "s/^.*() {//" "$TMP_BACKUP_FUNCTION_SCRIPT"
            sed -i '' "s/\(.*\)}/\1 /" "$TMP_BACKUP_FUNCTION_SCRIPT"
            #
            NUMBER_OF_CORES=$(parallel --number-of-cores)
            NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
            #echo $NUMBER_OF_MAX_JOBS
            NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
            #echo $NUMBER_OF_MAX_JOBS_ROUNDED
            #
            ulimit -n 4096
            sudo -E parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k "$TMP_BACKUP_FUNCTION_SCRIPT" ::: "$(cat "$BACKUP_RESTORE_LIST")"
            wait
            #
                     
            # resetting terminal settings or further input will not work
            #reset
            #stty "$STTY_ORIG"
            stty sane
        
            echo ''            
            echo 'copying backup data to '"$DESTINATION"'/ done ;)'
            echo ''
            # opening app for archiving
            #osascript -e 'tell application "Keka.app" to activate'
            
            #open -g -a "$SCRIPT_DIR"/archive/archive_tar_gz.app
            #osascript -e 'display dialog "backup finished, starting archiving..."'
            #osascript -e 'tell application "'"$SCRIPT_DIR"'/archive/archive_tar_gz.app" to activate'
            
            # homebrew updates
            # done in seperate script now
        	
            # moving log to backup directory
            mv "$HOMEFOLDER"/Desktop/backup_restore_log.txt "$DESTINATION"/_backup_restore_log.txt
        
            # compressing and moving backup
            #echo ''
            echo "compressing and moving backup..."
        
            # checking and defining some variables
        	#echo "TARGZSAVEDIR is "$TARGZSAVEDIR""
            #echo "APPLESCRIPTDIR is "$APPLESCRIPTDIR""
            DESKTOPBACKUPFOLDER="$DESTINATION"
            #echo "DESKTOPBACKUPFOLDER is "$DESKTOPBACKUPFOLDER""
            
            #export DESKTOPBACKUPFOLDER
            #export TARGZSAVEDIR
            #sudo -E bash -c ''"$SCRIPT_DIR"'/backup_restore_script/compress_and_move_backup.sh'
            
            . "$SCRIPT_DIR"/backup_restore_script/compress_and_move_backup.sh
            wait
            
            # deleting backup folder on desktop
            echo ''
            echo "deleting backup folder on desktop..."
            if [ -e "$DESTINATION" ]
            then
                #:
                sudo rm -rf "$DESTINATION"
            else
                :
            fi
            
            # waiting for all scripts to finish before starting update script
            echo ''
            echo "waiting for running backup scripts to finish..."
            
            if [[ "$CONT1" == "y" || "$CONT1" == "yes" ]]
            then
                while ps aux | grep /compress_and_move_vbox_backup.sh | grep -v grep > /dev/null; do sleep 1; done
            else
                :
            fi
    
            if [[ "$CONT2" == "y" || "$CONT2" == "yes" ]]
            then
                while ps aux | grep /backup_files.sh | grep -v grep > /dev/null; do sleep 1; done
            else
                :
            fi
            
            # done
            echo ''
            echo 'backup finished ;)'
            osascript -e 'display notification "complete ;)" with title "Backup Script"'
            echo ''
            
            # installing homebrew update script
            echo "updating homebrew formulas and casks..."
        	BREW_CASKS_UPDATE_APP="brew_casks_update"
            if [ -e /Applications/"$BREW_CASKS_UPDATE_APP".app ]
            then
            	rm -rf /Applications/"$BREW_CASKS_UPDATE_APP".app
            else
            	:
            fi
            cp -a "$SCRIPT_DIR"/update_homebrew/"$BREW_CASKS_UPDATE_APP".app /Applications/
            chown 501:admin /Applications/"$BREW_CASKS_UPDATE_APP".app
            chown -R 501:admin /Applications/"$BREW_CASKS_UPDATE_APP".app/custom_files/
            chmod 755 /Applications/"$BREW_CASKS_UPDATE_APP".app
            chmod 770 /Applications/"$BREW_CASKS_UPDATE_APP".app/custom_files/"$BREW_CASKS_UPDATE_APP".sh
            xattr -dr com.apple.quarantine /Applications/"$BREW_CASKS_UPDATE_APP".app
            # running homebrew update script
            create_tmp_backup_script_fifo2
        	open /Applications/"$BREW_CASKS_UPDATE_APP".app
        	
        	# waiting for the process to finish
        	echo "waiting for updating homebrew formulas and casks..."
        	#sleep 5
            while ps aux | grep ''"$BREW_CASKS_UPDATE_APP"'.app/Contents' | grep -v grep > /dev/null; do sleep 1; done
            while ps aux | grep /brew_casks_update.sh | grep -v grep > /dev/null; do sleep 1; done
            
            echo ''
            echo "updating homebrew formulas and casks finished ;)"
            osascript -e 'display notification "complete ;)" with title "Update Script"'
            
            ###
            ### additional settings and commands
            ###
            
            # disabling siri analytics
            # already done in system preferences script before but some apps seam to appear here later
            for i in $(/usr/libexec/PlistBuddy -c "Print CSReceiverBundleIdentifierState" /Users/$USER/Library/Preferences/com.apple.corespotlightui.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
            do
                #echo $i
            	/usr/libexec/PlistBuddy -c "Set CSReceiverBundleIdentifierState:$i false" /Users/$USER/Library/Preferences/com.apple.corespotlightui.plist
            done
            
            # disabling local time machine backups and cleaning up possible old ones
            sudo tmutil disable
            # sudo tmutil enable
            
            # force local time machine backup
            #tmutil localsnapshot
            # stop local time machine backup
            #tmutil stopbackup
            # show status of tmutil
            #tmutil status
            
            # list localsnapshots
            #tmutil listlocalsnapshots / | cut -d'.' -f4-
            #tmutil listlocalsnapshots / | rev | cut -d'.' -f1 | rev
            #tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]'
            
            if [[ $(tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]') == "" ]]
            then
                # no local time machine backups found
                :
            else
                echo ''
                echo "local time machine backups found, deleting..."
                for i in $(tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]')
                do
                	tmutil deletelocalsnapshots "$i"
                done
                echo ''
            fi
            
            # deactivating keepingyouawake
            if [ -e /Applications/KeepingYouAwake.app ]
            then
                echo "deactivating keepingyouawake..."
                open -g keepingyouawake:///deactivate
            else
                :
            fi
            
            echo ''
            echo "script done ;)"
            
            exit
        
        else
            :
        fi
        
        ###
        ### restore
        ###
        
        # place the files from the backup in two folders
        # /Users/USERNAME/Desktop/restore/master/backup_directories (Applications, Library, User)
        # /Users/USERNAME/Desktop/restore/user/backup_directories (Applications, Library, User)
                
        # restore dir
        # restore master dir
        echo "please select restore master directory..."
        RESTOREMASTERDIR=$(sudo -u "$loggedInUser" osascript "$SCRIPT_DIR"/backup_restore_script/ask_restore_master_dir.scpt 2> /dev/null | sed s'/\/$//')
        if [[ $(echo "$RESTOREMASTERDIR") == "" ]]
        then
            echo ''
            echo "restoremasterdir is empty - exiting script..."
            echo ''
            exit
        else
            echo ''
            echo 'restoremasterdir for restore is '"$RESTOREMASTERDIR"''
            echo ''
        fi

        # restore user dir
        echo "please select restore user directory..."
        RESTOREUSERDIR=$(sudo -u "$loggedInUser" osascript "$SCRIPT_DIR"/backup_restore_script/ask_restore_user_dir.scpt 2> /dev/null | sed s'/\/$//')
        if [[ $(echo "$RESTOREUSERDIR") == "" ]]
        then
            echo ''
            read -p "restoreuserdir is empty, do you want to set it to the same directory as the restoremasterdir (Y/n)? " CONT5
            CONT5="$(echo "$CONT5" | tr '[:upper:]' '[:lower:]')"    # tolower
            if [[ "$CONT5" == "y" || "$CONT5" == "yes" || "$CONT5" == "" ]]
            then
                RESTOREUSERDIR="$RESTOREMASTERDIR"
                echo ''
                echo 'restoreuserdir for restore is '"$RESTOREUSERDIR"''
                echo ''
            else
                echo ''
                echo "restoreuserdir is empty - exiting script..."
                echo ''
                exit
            fi
        else
            echo ''
            echo 'restoreuserdir for restore is '"$RESTOREUSERDIR"''
            echo ''
        fi
        
        #echo ''
        #echo restoredir for restore is "$RESTOREDIR"
        
        #RESTORETODIR="$HOMEFOLDER"/Desktop/testrestore
        #mkdir -p "$RESTORETODIR"
        RESTORETODIR=""
        
        # checking if restore option was selected
        if [[ "$OPTION" == "RESTORE" ]]; 
            then
            echo "running restore..."
        
            # master user restore directory
            MASTERUSER=$(ls "$RESTOREMASTERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared" | head -n 1 )
            echo masteruser for restore is "$MASTERUSER"
        
            # user from restore directory
            USERUSER=$(ls "$RESTOREUSERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared" | head -n 1 )
            echo useruser for restore is "$USERUSER"
        
            # user to restore to
            echo user to restore to is "$SELECTEDUSER"
            #echo ''
            
            # casks install
            printf '\n'           
            read -p "do you want to install casks after restoring the backup (Y/n)? " CONT1
            CONT1="$(echo "$CONT1" | tr '[:upper:]' '[:lower:]')"    # tolower
            #echo ''
            
            # stopping services and backing up files
            sudo launchctl stop org.cups.cupsd
        
            ### running restore
            BACKUP_RESTORE_LIST="$SCRIPT_DIR"/list/backup_restore_list.txt
            #STTY_ORIG=$(stty -g)
            #TERMINALWIDTH=$(echo $COLUMNS)
            #TERMINALWIDTH=$(stty size | awk '{print $2}')
            TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
            LINENUMBER=0
            
            function restore_data () {
                
                # using with parallel
                # comment out the while, do done lines
                # uncomment this line
                line="$1"
                #echo "$line"
                
                #while IFS='' read -r line || [[ -n "$line" ]]
                #do
                
                LINENUMBER=$(($LINENUMBER+1))
            	
                # if starting with one # and whitespace / tab
            	#if [[ $line =~ ^[\#][[:blank:]] ]]
            	
            	# if starting with more than one #
            	#if [[ $line =~ ^[\#]{2,} ]]
            
            	# if line is empty
            	#if [ -z "$line" ]
            	if [ "$line" == "" ]
            	then
                    :
                else
                    :
                fi
            	
            	# if starting with #
            	if [[ $line =~ ^[\#] ]]
            	then
                    :
                else
                    :
                fi
                
                # if starting with echo and whitespace / tab
            	if [[ $line =~ ^echo[[:blank:]] ]]
            	then
                    OUTPUT=$(echo "$line" | sed 's/^echo*//' | sed -e 's/^[ \t]*//')
        			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
                    echo "$OUTPUT" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                else
                    :
                fi
                    	
            	# if starting with m and space / tab
            	if [[ $line =~ ^m[[:blank:]] ]]
            	then
            	    LOWERCASESECTION=master
                    SECTIONUSER="$MASTERUSER"
                    RESTORESECTIONDIR="$RESTOREMASTERDIR"
                    #
                    ENTRY_TO=$(echo "$line" | cut -f2 | sed 's|~|'"$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
                    ENTRY_FROM=$(echo "$line" | cut -f2 | sed 's|~|'"/Users/$SECTIONUSER"'|' | sed -e 's/[ /]\{2,\}/\//')
                    #
                    RESTORE_FROM=$(echo "$RESTORESECTIONDIR$ENTRY_FROM" | sed -e 's/[ /]\{2,\}/\//')
                    RESTORE_TO=$(echo "$RESTORETODIR$ENTRY_TO" | sed -e 's/[ /]\{2,\}/\//')
                    #
                    DIRNAME_RESTORE_FROM=$(dirname "$RESTORE_FROM")
                    #echo "$DIRNAME_RESTORE_FROM"
                    BASENAME_RESTORE_FROM=$(basename "$RESTORE_FROM")
                    #echo "$DIRNAME_RESTORE_FROM"
                    DIRNAME_RESTORE_TO=$(dirname "$RESTORE_TO")
                    #echo "$DIRNAME_RESTORE_TO"
                    BASENAME_RESTORE_TO=$(basename "$RESTORE_TO")
                    #
                    TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
                    #
                    sudo mkdir -p "$DIRNAME_RESTORE_TO"
                    if [ -e "$DIRNAME_RESTORE_TO" ]
                    then
                        if [ -e "$RESTORE_FROM" ]
                        then
                            #sudo mkdir -p "$DIRNAME_RESTORE_TO"
                            if [ -e "$RESTORE_TO" ]
                            then
                                cd "$DIRNAME_RESTORE_TO"
                                sudo rm -rf "$BASENAME_RESTORE_TO"
                            else
                                :
                            fi
                            cd "$DIRNAME_RESTORE_FROM"
                            echo "$RESTORE_FROM" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo "to ""$RESTORE_TO" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo '     '
                            sudo rsync -a "$BASENAME_RESTORE_FROM" "$DIRNAME_RESTORE_TO"
                        else
                            echo "no "$ENTRY_FROM" in "$LOWERCASESECTION" backup - skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo ''
                        fi
                    else
                        echo "$DIRNAME_RESTORE_TO" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                    fi
                else
                    :
                fi
                
                # if starting with u and space / tab
            	if [[ $line =~ ^u[[:blank:]] ]]
            	then
            	    LOWERCASESECTION=user
                    SECTIONUSER="$USERUSER"
                    RESTORESECTIONDIR="$RESTOREUSERDIR"
                    #
                    ENTRY_TO=$(echo "$line" | cut -f2 | sed 's|~|'"$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
                    ENTRY_FROM=$(echo "$line" | cut -f2 | sed 's|~|'"/Users/$SECTIONUSER"'|' | sed -e 's/[ /]\{2,\}/\//')
                    #
                    RESTORE_FROM=$(echo "$RESTORESECTIONDIR$ENTRY_FROM" | sed -e 's/[ /]\{2,\}/\//')
                    RESTORE_TO=$(echo "$RESTORETODIR$ENTRY_TO" | sed -e 's/[ /]\{2,\}/\//')
                    #
                    DIRNAME_RESTORE_FROM=$(dirname "$RESTORE_FROM")
                    #echo "$DIRNAME_RESTORE_FROM"
                    BASENAME_RESTORE_FROM=$(basename "$RESTORE_FROM")
                    #echo "$DIRNAME_RESTORE_FROM"
                    DIRNAME_RESTORE_TO=$(dirname "$RESTORE_TO")
                    #echo "$DIRNAME_RESTORE_TO"
                    BASENAME_RESTORE_TO=$(basename "$RESTORE_TO")
                    #
                    TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
                    #
                    sudo mkdir -p "$DIRNAME_RESTORE_TO"
                    if [ -e "$DIRNAME_RESTORE_TO" ]
                    then
                        if [ -e "$RESTORE_FROM" ]
                        then
                            #sudo mkdir -p "$DIRNAME_RESTORE_TO"
                            if [ -e "$RESTORE_TO" ]
                            then
                                cd "$DIRNAME_RESTORE_TO"
                                sudo rm -rf "$BASENAME_RESTORE_TO"
                            else
                                :
                            fi
                            cd "$DIRNAME_RESTORE_FROM"
                            echo "$RESTORE_FROM" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo "to ""$RESTORE_TO" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo '     '
                            sudo rsync -a "$BASENAME_RESTORE_FROM" "$DIRNAME_RESTORE_TO"
                        else
                            echo "no "$ENTRY_FROM" in "$LOWERCASESECTION" backup - skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo ''
                        fi
                    else
                        echo "$DIRNAME_RESTORE_TO" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                    fi
                else
                    :
                fi
                
            #done <"$BACKUP_RESTORE_LIST"
                
            }
            
            # without parallel
            # comment out the whole following parallel block
            # uncomment the while read, done lines in the script and run the function
            # restore_data
            
            # with parallel
            # comment out the whole without parallel block
            # comment out the while read, done lines in the script and run
            #export RESTOREDIR
            export RESTOREMASTERDIR
            export RESTOREUSERDIR
            export RESTORETODIR
            export DESTINATION
            export HOMEFOLDER
            export MASTERUSER
            export USERUSER
            export TERMINALWIDTH
            export LINENUMBER
            #
            mkdir -p /tmp/backup_restore
            TMP_RESTORE_FUNCTION_SCRIPT="/tmp/backup_restore/restore_data.sh"
            touch "$TMP_RESTORE_FUNCTION_SCRIPT"
            chmod +x "$TMP_RESTORE_FUNCTION_SCRIPT"
            echo "#!/bin/bash" > "$TMP_RESTORE_FUNCTION_SCRIPT"
            echo $(declare -f restore_data) >> "$TMP_RESTORE_FUNCTION_SCRIPT"
            #sed -i '' "s/backup_data () {//" "$TMP_RESTORE_FUNCTION_SCRIPT"
            sed -i '' "s/^.*() {//" "$TMP_RESTORE_FUNCTION_SCRIPT"
            sed -i '' "s/\(.*\)}/\1 /" "$TMP_RESTORE_FUNCTION_SCRIPT"
            #
            NUMBER_OF_CORES=$(parallel --number-of-cores)
            NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
            #echo $NUMBER_OF_MAX_JOBS
            NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
            #echo $NUMBER_OF_MAX_JOBS_ROUNDED
            #
            ulimit -n 4096
            sudo -E parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k "$TMP_RESTORE_FUNCTION_SCRIPT" ::: "$(cat "$BACKUP_RESTORE_LIST")"
            wait
            #   
            
            # resetting terminal settings or further input will not work
            #reset
            #stty "$STTY_ORIG"
            stty sane
        
            #echo ""
            echo "restore done ;)"
        
            ### cleaning up old unused files after restore
        
            echo ""
            echo "cleaning up some files..."
        
            # virtualbox extpack
            if [[ -e "$HOMEFOLDER"/Library/VirtualBox ]]
            then
                find "$HOMEFOLDER"/Library/VirtualBox -name "*.vbox-extpack" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r VBOXEXTENSIONS
                do
                    sudo rm "$VBOXEXTENSIONS"
                done
            else
                :
            fi
        
            # virtualbox logs
            if [[ -e "$HOMEFOLDER"/Library/VirtualBox ]]
            then
                find "$HOMEFOLDER"/Library/VirtualBox -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r VBOXLOGS
                do
                    sudo rm "$VBOXLOGS"
                done
            else
                :
            fi
        
            # fonts
            if [[ -e "$HOMEFOLDER"/Library/Fonts ]]
            then
                find "$HOMEFOLDER"/Library/Fonts \( -name "*.dir" -o -name "*.list" -o -name "*.scale" \) -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r FONTSFILES
                do
                    sudo rm "$FONTSFILES"
                done
            else
                :
            fi
        
            # jameica backups
            if [[ -e "$HOMEFOLDER"/Library/jameica ]]
            then
                find "$HOMEFOLDER"/Library/jameica -name "jameica-backup-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r JAMEICABACKUPS
                do
                    sudo rm "$JAMEICABACKUPS"
                done
            else
                :
            fi
                   
            # jameica logs
            if [[ -e "$HOMEFOLDER"/Library/jameica ]]
            then
                find "$HOMEFOLDER"/Library/jameica -name "jameica.log-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r JAMEICALOGS
                do
                    sudo rm "$JAMEICALOGS"
                done
            else
                :
            fi
                    
            # address book migration
            if [[ -e "$HOMEFOLDER"/Library/"Application Support"/AddressBook ]]
            then
                find "$HOMEFOLDER"/Library/"Application Support"/AddressBook -name "Migration*.abbu.tbz" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r ADDRESSBOOKMIGRATION
                do
                    sudo rm "$ADDRESSBOOKMIGRATION"
                done
            else
                :
            fi
                    
            # 2do
            if [[ -e "$HOMEFOLDER"/Library/"Application Support"/Backups ]]
            then
                find "$HOMEFOLDER"/Library/"Application Support"/Backups -name "*.db" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,2d | while read -r TODOBACKUPS
                do
                    sudo rm "$TODOBACKUPS"
                done
            else
                :
            fi
            
            # unified remote
            if [[ -e "$HOMEFOLDER"/Library/"Application Support"/"Unified Remote" ]]
            then
                find "$HOMEFOLDER"/Library/"Application Support"/"Unified Remote" -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r UNIFIEDREMOTELOGS
                do
                    sudo rm "$UNIFIEDREMOTELOGS"
                done
            else
                :
            fi
            
            # whatsapp
            if [[ -e "/Users/$USER/Library/Application Support/WhatsApp/" ]]
            then
                sudo rm -rf "/Users/$USER/Library/Application Support/WhatsApp/main-process.log"*
                sudo rm -rf "/Users/$USER/Library/Application Support/WhatsApp/IndexedDB/"*
                sudo rm -rf "/Users/$USER/Library/Application Support/WhatsApp/Cache/"*
            else
                :
            fi
            
            # telegram
            if [[ -e "/Users/$USER/Library/Application Support/Telegram/" ]]
            then
                rm -rf "/Users/$USER/Library/Application Support/Telegram/exports/"*
                rm -rf "/Users/$USER/Library/Application Support/Telegram/logs/"*
            else
                :
            fi
            # Caches/ru.keepcoder.Telegram/* not included in backup / restore
            # rm -rf "/Users/$USER/Library/Caches/ru.keepcoder.Telegram/"*
            # postbox/media/* not included in backup / restore
            #find "/Users/$USER/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/" -name "media" -type d -print0 | xargs -0 rm -rf
            # after deleting postbox/db/* or accounts-metadata the computer has to be reregistered with phone number
            #rm -rf "/Users/$USER/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/"account-*"/postbox/db/"*
            
            # signal
            if [[ -e "/Users/$USER/Library/Application Support/Signal/" ]]
            then
                #rm -rf "/Users/$USER/Library/Application Support/Signal/attachments.noindex"
                #rm -rf "/Users/$USER/Library/Application Support/Signal/Cache/"
                #rm -rf "/Users/$USER/Library/Application Support/Signal/databases/"
                #rm -rf "/Users/$USER/Library/Application Support/Signal/GPUCache/"
                #rm -rf "/Users/$USER/Library/Application Support/Signal/Local Storage/"
                #rm -rf "/Users/$USER/Library/Application Support/Signal/logs/"
                #rm -rf "/Users/$USER/Library/Application Support/Signal/QuotaManager"*
                #
                rm -rf "/Users/$USER/Library/Application Support/Signal/"* 
            else
                :
            fi
        
            echo "cleaning done ;)"
            
            # post restore operations
            echo ""
            echo "running post restore operations..."
            sudo launchctl start org.cups.cupsd
            /System/Library/CoreServices/pbs -flush
            
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
        
        else
            :
        fi
        #
    else
        echo "user home directory does not exist - exiting script..."
        exit
    fi

}

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
SCRIPT_DIR_FINAL=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && pwd)")
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

