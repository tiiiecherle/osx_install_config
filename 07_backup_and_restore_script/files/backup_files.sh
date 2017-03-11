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
    
    # solution 1
    # only working for sudo commands, not for commands that need a password and are run without sudo
    # and only works for specified time
    # asking for the administrator password upfront
    #sudo -v
    # keep-alive: update existing 'sudo' time stamp until script is finished
    #while true; do sudo -n true; sleep 600; kill -0 "$$" || exit; done 2>/dev/null &
    
    # solution 2
    # working for all commands that require the password (use sudo -S for sudo commands)
    # working until script is finished or exited
    
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



###
### script trap and backup / restore selection
###


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
    unset SUDOPASSWORD
}

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "unset_variables; printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "unset_variables; kill_subprocesses >/dev/null 2>&1; exit; kill_main_process" EXIT
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


if [ "$SELECTEDUSER" == "tom" ] || [ "$SELECTEDUSER" == "bobby" ];
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
echo "rsync from /Users/$USER/Desktop/"
printf "%-11s" "to" "/Users/$USER/Desktop/desktop/_current/..." && echo
rsync -a -z -v --delete --progress --stats --human-readable --links --exclude files --exclude backup --exclude backup_* --exclude desktop --exclude data --exclude extra --exclude scripts --exclude macintosh_hd /Users/$USER/Desktop/ /Users/$USER/Desktop/desktop/_current/ 1>/dev/null
echo "done ;)"
echo ""

# deleting some files / folders
if [[ $(find "/Users/$USER/Music/iTunes/Mobile Applications/" -type f) != "" ]]
then
    rm "/Users/$USER/Music/iTunes/Mobile Applications/"*
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
            read -r -p "file $SAVEFILE already exists, do you want to overwrite it? [y/N] " response
            response=$(echo $response | tr '[:upper:]' '[:lower:]')   # tolower
            if [[ "$response" =~ (^n.*|n) ]] || [[ "$response" == "" ]]
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
        printf "%-45s" ""$(basename "{}")"... " && builtin printf '$SUDOPASSWORD' | gpg --batch --no-tty --yes --quiet --passphrase-fd 0 -d "{}" | unpigz | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
    else
        :
    fi
' ::: "$(cat "$FILESTARGZLOG")"
wait
#printf "%-45s" ""$(basename "{}")"... " && unpigz -c "{}" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m";


echo ''
echo 'backing up files done ;)'
exit