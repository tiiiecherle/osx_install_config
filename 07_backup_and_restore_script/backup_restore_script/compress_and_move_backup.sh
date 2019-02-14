#!/bin/bash

# checking and defining some variables
#echo ''
#echo "TARGZSAVEDIR is "$TARGZSAVEDIR""
#echo "DESKTOPBACKUPFOLDER is "$DESKTOPBACKUPFOLDER""
#TARGZFILE="$TARGZSAVEDIR"/"$(basename "$DESKTOPBACKUPFOLDER")".tar.gz
#TARGZFILE="$DESKTOPBACKUPFOLDER".tar.gz
TARGZFILE="$DESKTOPBACKUPFOLDER".tar.gz.gpg
#echo "TARGZFILE is "$TARGZFILE""

#set -e

### functions
# compressing and checking integrity of backup folder on desktop
function archiving_tar_gz {
    
    # calculating backup folder size
    PVSIZE=$(gdu -scb "$DESKTOPBACKUPFOLDER" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1.0 | bc | cut -d'.' -f1); done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$DESKTOPBACKUPFOLDER")"/"$(basename "$DESKTOPBACKUPFOLDER")"/"
    printf "%-10s" "to" "$TARGZFILE" && echo
    #echo "to "$(echo "$TARGZFILE")""
    pushd "$(dirname "$DESKTOPBACKUPFOLDER")" 1> /dev/null; sudo gtar -cpf - "$(basename "$DESKTOPBACKUPFOLDER")" | pv -s "$PVSIZE" | pigz > "$TARGZFILE"; popd 1> /dev/null && echo '' && echo 'testing integrity of file(s)' && printf "%-45s" "$(basename "$TARGZFILE")... " && unpigz -c "$TARGZFILE" | gtar -tvv >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'
    echo ''

}

function archiving_tar_gz_gpg {
    
    # calculating backup folder size
    PVSIZE=$(gdu -scb "$DESKTOPBACKUPFOLDER" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1.0 | bc | cut -d'.' -f1); done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$DESKTOPBACKUPFOLDER")"/"$(basename "$DESKTOPBACKUPFOLDER")"/"
    printf "%-10s" "to" "$TARGZFILE" && echo
    #echo "to "$(echo "$TARGZFILE")""
    pushd "$(dirname "$DESKTOPBACKUPFOLDER")" 1> /dev/null; sudo gtar -cpf - "$(basename "$DESKTOPBACKUPFOLDER")" | pv -s "$PVSIZE" | pigz | gpg --batch --yes --quiet --passphrase="$SUDOPASSWORD" --symmetric --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-count 65536 --compress-algo 0 -o "$TARGZFILE" 1> /dev/null; popd 1> /dev/null && echo '' && echo 'testing integrity of file(s)' && printf "%-45s" "$(basename "$TARGZFILE")... " && ${USE_PASSWORD} | gpg --batch --no-tty --yes --quiet --passphrase-fd 0 -d "$TARGZFILE" | unpigz | gtar -tvv >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'
    echo ''

}

ask_for_variable() {
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

if [[ -e "$TARGZFILE" ]]
then
    VARIABLE_TO_CHECK="$OVERWRITE_LOCAL_FILE"
    QUESTION_TO_ASK="file \"$TARGZFILE\" already exist, overwrite it (y/N)? "
    ask_for_variable
    OVERWRITE_LOCAL_FILE="$VARIABLE_TO_CHECK"
    
    if [[ "$OVERWRITE_LOCAL_FILE" =~ ^(yes|y)$ ]]
    then
        rm "$TARGZFILE"
        #archiving_tar_gz
        archiving_tar_gz_gpg
    else
        :
    fi
else
    #archiving_tar_gz
    archiving_tar_gz_gpg
fi

# moving compressed backup from desktop to selected destination
echo "moving "$TARGZFILE""
printf "%-7s" "to" "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && echo
#echo "to "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")"..."
if [[ "$TARGZFILE" == "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" ]]
then
    echo "backup und save directory are identical, moving not required..."
else
    if [[ -d "$TARGZSAVEDIR" ]]
    then
        if [[ -e "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" ]]
        then
            VARIABLE_TO_CHECK="$OVERWRITE_DESTINATION_FILE"
            QUESTION_TO_ASK="file \"$TARGZSAVEDIR"/"$(basename "$TARGZFILE")\" already exist, overwrite it (y/N)? "
            ask_for_variable
            OVERWRITE_DESTINATION_FILE="$VARIABLE_TO_CHECK"
            
            if [[ "$OVERWRITE_DESTINATION_FILE" =~ ^(yes|y)$ ]]         
			then
                rm "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")"
                pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && printf "%-45s" "backup file successfully moved... " && echo -e "this is \033[1;32mOK\033[0m"
            else
                :
            fi
        else
            #pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && echo -e "backup file successfully moved... this is \033[1;32mOK\033[0m"
            pv "$TARGZFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZFILE")" && rm "$TARGZFILE" && printf "%-45s" "backup file successfully moved... " && echo -e "this is \033[1;32mOK\033[0m"
        fi
    else
        echo ""$TARGZSAVEDIR" does not exist, backup file cannot be moved..."
    fi
fi

#exit

# done
#echo ''
#echo 'done ;)'