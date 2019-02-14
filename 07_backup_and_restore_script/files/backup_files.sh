#!/bin/bash

#echo "script"
#echo $FILESTARGZSAVEDIR
#echo $FILESAPPLESCRIPTDIR

###
### asking password upfront
###

if [[ -e /tmp/run_from_backup_script1 ]] && [[ $(cat /tmp/run_from_backup_script1) == 1 ]]
then
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
    unset SUDOPASSWORD
    SUDOPASSWORD=$(cat "/tmp/tmp_backup_script_fifo1" | head -n 1)
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    delete_tmp_backup_script_fifo1
    set +a
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

### functions

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}

ask_for_variable () {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}


###
### script trap and backup / restore selection
###


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

### trapping
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_SOURCED="yes" || SCRIPT_SOURCED="no"
[[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"
# a sourced script does not exit, it ends with return, so checking for session master is sufficent
# subprocesses will not be killed on return, only on exit
#if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_SOURCED" == "no" ]]
if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]]
then
    # script is session master and not run from another script (S on mac Ss on linux)
    trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
else
    # script is not session master and run from another script (S+ on mac and linux) 
    trap "printf '\n'; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "unset SUDOPASSWORD; exit" EXIT
fi
#set -e

###

if [ "$SELECTEDUSER" == "" ]
then
    # users on the system without ".localized" and "Shared"
    SYSTEMUSERS=$(ls -1 /Users/ | egrep -v "^[.]" | egrep -v "Shared" | egrep -v "Guest")
    
    # user profile for backup
    export PS3="Please select user profile for file backup by typing the number: "
    select SELECTEDUSER in ""$SYSTEMUSERS""
      do
      echo You selected user "$SELECTEDUSER".
        break
    done
    
    # check1 if a valid user was selected
    USERCHECK=$(find /Users -maxdepth 1 -name "$SELECTEDUSER" -exec basename {} \;)
    if [ "$SELECTEDUSER" != "$USERCHECK" ]; then
        echo "no valid user selected - exiting script because of no real username..."
        exit
    else
        :
    fi
    
    # check2 if a valid user was selected
    if [ "$SELECTEDUSER" == "" ]; then
        echo "no valid user selected - exiting script because of empty username..."
        exit
    else
        :
    fi
else
    :
fi


###


if [ "$SELECTEDUSER" == "tom" ] || [ "$SELECTEDUSER" == "bobby" ] || [ "$SELECTEDUSER" == "wolfgang" ];
then
    :
else
    echo "there is no valid files backup set for the selected user, exiting..."
    exit
fi

if [ "$SELECTEDUSER" == "tom" ];
then

    BACKUPDIRS=(
    "/Users/$USER/Pictures"
    "/Users/$USER/Music"
    "/Users/$USER/Desktop/desktop"
    "/Users/$USER/Desktop/backup"
    "/Users/$USER/github"
    "/Users/$USER/Desktop/files"
    "/Users/$USER/Documents"
    "/Users/$USER/Library/Application Support/MobileSync"
    )

else
    :
fi

if [ "$SELECTEDUSER" == "bobby" ];
then

    BACKUPDIRS=(
    "/Users/$USER/Pictures"
    "/Users/$USER/Music"
    "/Users/$USER/Desktop/desktop"
    "/Users/$USER/_WS_IMAC"
    "/Users/$USER/Eigene_Dateien_wsmac"
    "/Users/$USER/Documents"
    "/Users/$USER/Downloads"
    "/Users/$USER/Library/Application Support/MobileSync"
    )

else
    :
fi

if [ "$SELECTEDUSER" == "wolfgang" ];
then

    BACKUPDIRS=(
    "/Users/$USER/Desktop/desktop"
    )

else
    :
fi


###

DATE=$(date +%F)
FILESTARGZLOG="$FILESTARGZSAVEDIR"/targz_file_log_"$DATE".txt

echo ""
if [[ -f "$FILESTARGZLOG" ]]; then rm "$FILESTARGZLOG"; else :; fi
touch "$FILESTARGZLOG"

#FILE_EXTENSION=tar.gz
FILE_EXTENSION=tar.gz.gpg


function targz_and_progress {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}')
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz && echo
    #echo to "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz > "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz; popd 1> /dev/null
    echo "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz >> "$FILESTARGZLOG"
    echo ""

}

function tar_gz_gpg_and_progress {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}')
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" && echo
    #echo to "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz.gpg
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz | gpg --batch --yes --quiet --passphrase="$SUDOPASSWORD" --symmetric --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-count 65536 --compress-algo 0 -o "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" 1> /dev/null; popd 1> /dev/null
    echo "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" >> "$FILESTARGZLOG"
    echo ""

}


# other commands before starting the actual archiving
mkdir -p /Users/$USER/Desktop/desktop/_current/
echo "rsync from /Users/$USER/Desktop/"
printf "%-11s" "to" "/Users/$USER/Desktop/desktop/_current/..." && echo
rsync -a -z -v --delete --progress --stats --human-readable --links --exclude files --exclude backup --exclude backup_* --exclude desktop --exclude data --exclude extra --exclude scripts --exclude macintosh_hd /Users/$USER/Desktop/ /Users/$USER/Desktop/desktop/_current/ 1>/dev/null
echo "done ;)"
echo ""

# deleting some files / folders
if [[ -e "/Users/$USER/Music/iTunes/Mobile Applications/" ]]
then
    if [[ $(find "/Users/$USER/Music/iTunes/Mobile Applications/" -type f) != "" ]]
    then
        rm "/Users/$USER/Music/iTunes/Mobile Applications/"*
    else
        :
    fi
else
    :
fi

# creating files from SOURCES to selected destination
for DIRS in "${BACKUPDIRS[@]}";
do

    if [[ -d "$DIRS" ]];
    then

        # checking if file exists
        SAVEFILE="$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION"
        if [[ -f "$SAVEFILE" ]];
        then
            # asking for deleting existing file
            # default answer is "" and is defined as no
            VARIABLE_TO_CHECK="$OVERWRITE_EXISTING"
            QUESTION_TO_ASK="file $SAVEFILE already exists, do you want to overwrite it? (y/N) "
            ask_for_variable
            OVERWRITE_EXISTING="$VARIABLE_TO_CHECK"
            
            if [[ "$OVERWRITE_EXISTING" =~ ^(no|n)$ ]]
            then
                #exit 1
                echo skipping "$SAVEFILE"
                echo ""
            else
                rm "$SAVEFILE"
                #targz_and_progress
                tar_gz_gpg_and_progress
            fi
        else
            #targz_and_progress
            tar_gz_gpg_and_progress
        fi

    else
        :
    fi
done


#echo ""
echo "testing integrity of file(s) in "$FILESTARGZSAVEDIR"/..."
echo ""
#
#
NUMBER_OF_CORES=$(parallel --number-of-cores)
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
#echo $NUMBER_OF_MAX_JOBS_ROUNDED
#
parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -q bash -c '
    if [[ -f "{}" ]];
    then
        printf "%-45s" """$(basename "{}")""... " && builtin printf '$SUDOPASSWORD' | gpg --batch --no-tty --yes --quiet --passphrase-fd 0 -d "{}" | unpigz | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
    else
        :
    fi
' ::: "$(cat "$FILESTARGZLOG")"
wait
#printf "%-45s" ""$(basename "{}")"... " && unpigz -c "{}" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m";


echo ''
echo 'backing up files done ;)'
exit