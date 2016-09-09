#!/bin/bash

#echo "script"
#echo $TARGZSAVEDIR
#echo $APPLESCRIPTDIR


###


# users on the system without ".localized" and "Shared"
SYSTEMUSERS=$(ls /Users | egrep -v "^[.]" | egrep -v "Shared")

# user profile for backup
export PS3="Please select user profile for file backup by typing the number: "
select SELECTEDUSER in "$SYSTEMUSERS"
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


###


if [ "$SELECTEDUSER" == "tom" ] || [ "$SELECTEDUSER" == "bobby" ];
then
    :
else
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
TARGZLOG="$TARGZSAVEDIR"/targz_file_log_"$DATE".txt

echo ""
if [[ -f "$TARGZLOG" ]]; then rm "$TARGZLOG"; else :; fi
touch "$TARGZLOG"


function targz_and_progress {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}')
    echo archiving "$DIRS" to "$TARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz
    pushd "$(dirname "$DIRS")"; tar --exclude='dccrecv' -cf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz --best > "$TARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz; popd
    echo "$TARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz >> "$TARGZLOG"
    echo ""

}


# other commands before starting the actual .tar.gz
echo "rsync from /Users/$USER/Desktop/ to /Users/$USER/Desktop/desktop/_current/..."
rsync -a -z -v --delete --progress --stats --human-readable --links --exclude files --exclude backup --exclude backup_* --exclude desktop --exclude data --exclude extra --exclude scripts --exclude macintosh_hd /Users/$USER/Desktop/ /Users/$USER/Desktop/desktop/_current/ 1>/dev/null
echo "done ;)"
echo ""


# creating .tar.gz files from SOURCES to selected destination
for DIRS in "${BACKUPDIRS[@]}";
do

    if [[ -d "$DIRS" ]];
    then

        # checking if file exists
        SAVEFILE="$TARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz
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
echo "testing integrity of file(s) in "$TARGZSAVEDIR"/..."
echo ""
#
IFS=$'\n'
for TOCHECK in $(cat "$TARGZLOG");
do
#echo $TOCHECK

    if [[ -f "$TOCHECK" ]];
    then

        #echo -n "$(basename "$TOCHECK")"'... ' && tar -tzf "$TOCHECK" >/dev/null 2>&1 && echo file is OK || echo file is INVALID
        echo -n "$(basename "$TOCHECK")"'... ' && gtar -tzf "$TOCHECK" >/dev/null 2>&1 && echo file is OK || echo file is INVALID

    else
        :
    fi
done
unset IFS
echo ""