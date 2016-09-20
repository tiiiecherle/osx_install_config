#!/bin/bash

# checking and defining some variables
#echo ''
#echo "TARGZSAVEDIR is "$TARGZSAVEDIR""
#echo "APPLESCRIPTDIR is "$APPLESCRIPTDIR""
#echo "DESKTOPBACKUPFOLDER is "$DESKTOPBACKUPFOLDER""
#TARGZFILE="$TARGZSAVEDIR"/"$(basename "$DESKTOPBACKUPFOLDER")".tar.gz
TARGZFILE="$DESKTOPBACKUPFOLDER".tar.gz
#echo "TARGZFILE is "$TARGZFILE""

# trapping script to kill subprocesses when script is stopped
#trap "echo "" && trap - SIGTERM >/dev/null 2>&1 && kill -- -$$ >/dev/null 2>&1" SIGINT SIGTERM EXIT
trap "echo "" && killall background >/dev/null 2>&1" EXIT
set -e

# compressing and checking integrity of backup folder on desktop
function archiving_tar_gz {
    
    # calculating backup folder size
    PVSIZE=$(/usr/local/bin/gdu -scb "$DESKTOPBACKUPFOLDER" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1.0 | bc | cut -d'.' -f1  ) ; done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$DESKTOPBACKUPFOLDER")"/"$(basename "$DESKTOPBACKUPFOLDER")"/ to "$(echo "$TARGZFILE")""
    pushd "$(dirname "$DESKTOPBACKUPFOLDER")" >/dev/null; tar -cpf - "$(basename "$DESKTOPBACKUPFOLDER")" | pv -s "$PVSIZE" | /usr/local/bin/pigz --best > "$TARGZFILE"; popd >/dev/null && echo '' && echo 'testing integrity of file(s)' && echo -n "$(basename "$TARGZFILE")"'... ' && /usr/local/bin/gtar -tzf "$TARGZFILE" >/dev/null 2>&1 && echo file is OK || echo file is INVALID
    echo ''

}

if [ -e "$TARGZFILE" ]
then
    read -p "file \"$TARGZFILE\" already exist, overwrite it (y/N)? " CONT_COMP1
    if [ "$CONT_COMP1" == "y" ]
    then
        rm "$TARGZFILE"
        archiving_tar_gz
    else
        :
    fi
else
    archiving_tar_gz
fi

# moving compressed backup from desktop to selected destination
echo "moving backup file from "$TARGZFILE""
echo "to "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")"..."
if [ "$TARGZFILE" == "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" ]
then
    echo "backup und save directory are identical, moving not required..."
else
    if [ -d "$TARGZSAVEDIR" ]
    then
        if [ -e "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" ]
        then
            read -p "file \"$TARGZSAVEDIR"/"$(basename "$TARGZFILE")\" already exist, overwrite it (y/N)? " CONT_COMP2
            if [ "$CONT_COMP2" == "y" ]
            then
                rm "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")"
                pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && echo "backup file successfully moved... this is OK"
            else
                :
            fi
        else
            pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && echo "backup file successfully moved... this is OK"
        fi
    else
        echo ""$TARGZSAVEDIR" does not exist, backup file cannot be moved..."
    fi
fi

# done
#echo ''
#echo 'done ;)'