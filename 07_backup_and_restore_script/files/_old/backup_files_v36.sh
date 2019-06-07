#!/bin/bash

#echo "script"
#echo $FILESTARGZSAVEDIR
#echo $FILESAPPLESCRIPTDIR

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

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "kill_subprocesses >/dev/null 2>&1; exit; kill_main_process" EXIT
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


function targz_and_progress {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}')
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz && echo
    #echo to "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz > "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz; popd 1> /dev/null
    echo "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz >> "$FILESTARGZLOG"
    echo ""

}


# other commands before starting the actual .tar.gz
echo "rsync from /Users/$USER/Desktop/"
printf "%-11s" "to" "/Users/$USER/Desktop/desktop/_current/..." && echo
rsync -a -z -v --delete --progress --stats --human-readable --links --exclude files --exclude backup --exclude backup_* --exclude desktop --exclude data --exclude extra --exclude scripts --exclude macintosh_hd /Users/$USER/Desktop/ /Users/$USER/Desktop/desktop/_current/ 1>/dev/null
echo "done ;)"
echo ""


# creating .tar.gz files from SOURCES to selected destination
for DIRS in "${BACKUPDIRS[@]}";
do

    if [[ -d "$DIRS" ]];
    then

        # checking if file exists
        SAVEFILE="$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz
        if [[ -f "$SAVEFILE" ]];
        then
            # asking for deleting existing file
            # default answer is "" and is defined as no
            read -r -p "file $SAVEFILE already exists, do you want to overwrite it? (y/N) " response
            response=$(echo $response | tr '[:upper:]' '[:lower:]')   # tolower
            if [[ "$response" =~ (^n.*|n) ]] || [[ "$response" == "" ]]
            then
                #exit 1
                echo skipping "$SAVEFILE"
                echo ""
            else
                rm "$SAVEFILE"
                targz_and_progress
            fi
        else
            targz_and_progress
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
parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k -q "$SHELL" -c '
    if [[ -f "{}" ]];
    then
        printf "%-45s" ""$(basename "{}")"... " && unpigz -c "{}" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
    else
        :
    fi
' ::: "$(cat "$FILESTARGZLOG")"
wait

echo ''
echo 'backing up files done ;)'
exit