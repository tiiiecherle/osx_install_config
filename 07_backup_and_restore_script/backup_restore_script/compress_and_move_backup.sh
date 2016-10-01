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
    PVSIZE=$(gdu -scb "$DESKTOPBACKUPFOLDER" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1.0 | bc | cut -d'.' -f1  ) ; done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$DESKTOPBACKUPFOLDER")"/"$(basename "$DESKTOPBACKUPFOLDER")"/ to "$(echo "$TARGZFILE")""
    pushd "$(dirname "$DESKTOPBACKUPFOLDER")" 1> /dev/null; gtar -cpf - "$(basename "$DESKTOPBACKUPFOLDER")" | pv -s "$PVSIZE" | pigz --best > "$TARGZFILE"; popd 1> /dev/null && echo '' && echo 'testing integrity of file(s)' && echo -n "$(basename "$TARGZFILE")"'... ' && gtar -tzf "$TARGZFILE" >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'
    echo ''

}

if [ -e "$TARGZFILE" ]
then
    read -p "file \"$TARGZFILE\" already exist, overwrite it (y/N)? " CONT_COMP1
    CONT_COMP1="$(echo "$CONT_COMP1" | tr '[:upper:]' '[:lower:]')"    # tolower
	if [[ "$CONT_COMP1" == "y" || "$CONT_COMP1" == "yes" ]]
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
    		CONT_COMP2="$(echo "$CONT_COMP2" | tr '[:upper:]' '[:lower:]')"    # tolower
			if [[ "$CONT_COMP2" == "y" || "$CONT_COMP2" == "yes" ]]            
			then
                rm "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")"
                pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && echo -e "backup file successfully moved... this is \033[1;32mOK\033[0m"

            else
                :
            fi
        else
            pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && echo -e "backup file successfully moved... this is \033[1;32mOK\033[0m"

        fi
    else
        echo ""$TARGZSAVEDIR" does not exist, backup file cannot be moved..."
    fi
fi

# done
#echo ''
#echo 'done ;)'