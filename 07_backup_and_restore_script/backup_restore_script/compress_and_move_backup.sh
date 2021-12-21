#!/bin/zsh

# checking and defining some variables
#echo ''
#echo "TARGZSAVEDIR is "$TARGZSAVEDIR""
#echo "DESKTOPBACKUPFOLDER is "$DESKTOPBACKUPFOLDER""
#TARGZFILE="$TARGZSAVEDIR"/"$(basename "$DESKTOPBACKUPFOLDER")".tar.gz
#TARGZFILE="$DESKTOPBACKUPFOLDER".tar.gz
#TARGZGPGFILE="$DESKTOPBACKUPFOLDER".tar.gz.gpg
#echo "TARGZGPGFILE is "$TARGZGPGFILE""


### functions
# compressing and checking integrity of backup folder on desktop
archiving_tar_gz() {
    
    # calculating backup folder size
    PVSIZE=$(gdu -scb "$DESKTOPBACKUPFOLDER" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1); done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$DESKTOPBACKUPFOLDER")"/"$(basename "$DESKTOPBACKUPFOLDER")"/"
    printf "%-10s" "to" "$TARGZFILE" && echo
    #echo "to "$(echo "$TARGZFILE")""
    pushd "$(dirname "$DESKTOPBACKUPFOLDER")" 1> /dev/null; sudo gtar -cpf - "$(basename "$DESKTOPBACKUPFOLDER")" | pv -s "$PVSIZE" | pigz > "$TARGZFILE" && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m" >&2; popd 1> /dev/null
    #echo '' && echo 'testing integrity of file(s)' && printf "%-45s" "$(basename "$TARGZFILE")... " && unpigz -c "$TARGZFILE" | gtar -tvv >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'
    #echo ''

}

archiving_tar_gz_gpg() {
    
    # calculating backup folder size
    PVSIZE=$(gdu -scb "$DESKTOPBACKUPFOLDER" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1); done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$DESKTOPBACKUPFOLDER")"/"$(basename "$DESKTOPBACKUPFOLDER")"/"
    printf "%-10s" "to" "$TARGZGPGFILE" && echo
    #echo "to "$(echo "$TARGZGPGFILE")""
    pushd "$(dirname "$DESKTOPBACKUPFOLDER")" 1> /dev/null; sudo gtar -cpf - "$(basename "$DESKTOPBACKUPFOLDER")" | pv -s "$PVSIZE" | pigz | gpg --batch --yes --quiet --passphrase="$SUDOPASSWORD" --symmetric --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-count 65536 --compress-algo 0 -o "$TARGZGPGFILE" 1> /dev/null && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m" >&2; popd 1> /dev/null
    #echo '' && echo 'testing integrity of file(s)' && printf "%-45s" "$(basename "$TARGZGPGFILE")... " && env_use_password | gpg --batch --no-tty --yes --quiet --passphrase-fd 0 -d "$TARGZGPGFILE" | unpigz | gtar -tvv >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'
    #echo ''

}



###

if [[ -e "$TARGZGPGFILE" ]]
then
    VARIABLE_TO_CHECK="$OVERWRITE_LOCAL_FILE"
    QUESTION_TO_ASK="file \"$TARGZGPGFILE\" already exist, overwrite it (y/N)? "
    env_ask_for_variable
    OVERWRITE_LOCAL_FILE="$VARIABLE_TO_CHECK"
    
    if [[ "$OVERWRITE_LOCAL_FILE" =~ ^(yes|y)$ ]]
    then
        rm "$TARGZGPGFILE"
        #archiving_tar_gz
        archiving_tar_gz_gpg
    else
        :
    fi
else
    #archiving_tar_gz
    archiving_tar_gz_gpg
fi

moving_compressed_backup() {
    # moving compressed backup from desktop to selected destination
    echo "moving "$TARGZGPGFILE""
    printf "%-7s" "to" "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")" && echo
    #echo "to "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")"..."
    if [[ "$TARGZGPGFILE" == "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")" ]]
    then
        echo "backup und save directory are identical, moving not required..."
    else
        if [[ -d "$TARGZSAVEDIR" ]]
        then
            if [[ -e "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")" ]]
            then
                VARIABLE_TO_CHECK="$OVERWRITE_DESTINATION_FILE"
                QUESTION_TO_ASK="file \"$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")\" already exist, overwrite it (y/N)? "
                env_ask_for_variable
                OVERWRITE_DESTINATION_FILE="$VARIABLE_TO_CHECK"
                
                if [[ "$OVERWRITE_DESTINATION_FILE" =~ ^(yes|y)$ ]]         
    			then
                    rm "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")"
                    pv "$TARGZGPGFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")" && rm "$TARGZGPGFILE" && printf "%-45s" "backup file successfully moved... " && echo -e "this is \033[1;32mOK\033[0m"
                else
                    :
                fi
            else
                #pv "$TARGZGPGFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")" && rm "$TARGZGPGFILE" && echo -e "backup file successfully moved... this is \033[1;32mOK\033[0m"
                pv "$TARGZGPGFILE" > "$TARGZSAVEDIR"/"$(basename "$TARGZGPGFILE")" && rm "$TARGZGPGFILE" && printf "%-45s" "backup file successfully moved... " && echo -e "this is \033[1;32mOK\033[0m"
            fi
        else
            echo ""$TARGZSAVEDIR" does not exist, backup file cannot be moved..."
        fi
    fi
}
#moving_compressed_backup

#exit

# done
#echo ''
#echo 'done ;)'
