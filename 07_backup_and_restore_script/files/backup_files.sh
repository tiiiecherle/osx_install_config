#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### variables
###

#echo "script"
#echo $FILESTARGZSAVEDIR
#echo $FILESAPPLESCRIPTDIR



###
### asking password upfront
###

if [[ -e /tmp/tmp_backup_script_fifo1 ]]
then
    delete_tmp_backup_script_fifo1() {
        if [[ -e "/tmp/tmp_backup_script_fifo1" ]]
        then
            rm "/tmp/tmp_backup_script_fifo1"
        else
            :
        fi
    }
    unset SUDOPASSWORD
    SUDOPASSWORD=$(cat "/tmp/tmp_backup_script_fifo1" | head -n 1)
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    delete_tmp_backup_script_fifo1
    set +a
    env_sudo
else
    env_enter_sudo_password
fi



###
### script
###


### checking for script dependencies
echo ''
echo "checking for script dependencies..."
if command -v parallel &> /dev/null
then
    # installed
    echo "all script dependencies installed..."
else
    echo "not all script dependencies installed, exiting..."
    echo ''
    exit
fi
#echo ''


### trapping
trap_function_exit_middle() { unset SUDOPASSWORD; unset USE_PASSWORD; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"


### user selection
if [[ "$SELECTEDUSER" == "" ]]
then
    echo ''
    # users on the system without ".localized" and "Shared"
    SYSTEMUSERS=$(ls -1 /Users/ | egrep -v "^[.]" | egrep -v "Shared" | egrep -v "Guest")
    
    # user profile for backup
    COLUMNS_DEFAULT="$COLUMNS"
    COLUMNS=1 PS3="Please select user profile for file backup by typing the number: "
    select SELECTEDUSER in ""$SYSTEMUSERS""
    do
        echo "you selected user "$SELECTEDUSER"..."
        #echo ''
        COLUMNS="$COLUMNS_DEFAULT"
        break
    done
    
    # check1 if a valid user was selected
    USERCHECK=$(find /Users -maxdepth 1 -name "$SELECTEDUSER" -exec basename {} \;)
    if [[ "$SELECTEDUSER" != "$USERCHECK" ]]; then
        echo "no valid user selected - exiting script because of no real username..."
        exit
    else
        :
    fi
    
    # check2 if a valid user was selected
    if [[ "$SELECTEDUSER" == "" ]]; then
        echo "no valid user selected - exiting script because of empty username..."
        exit
    else
        :
    fi
else
    :
fi


### user backup files/directories
if [[ "$SELECTEDUSER" == "tom" ]] || [[ "$SELECTEDUSER" == "bobby" ]] || [[ "$SELECTEDUSER" == "wolfgang" ]];
then
    :
else
    echo "there is no valid files backup set for the selected user, exiting..."
    exit
fi

if [[ "$SELECTEDUSER" == "tom" ]];
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

if [[ "$SELECTEDUSER" == "bobby" ]];
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

if [[ "$SELECTEDUSER" == "wolfgang" ]];
then

    BACKUPDIRS=(
    "/Users/$USER/Desktop/desktop"
    )

else
    :
fi


### variables
DATE=$(date +%F)
FILESTARGZLOG="$FILESTARGZSAVEDIR"/targz_file_log_"$DATE".txt

echo ""
if [[ -f "$FILESTARGZLOG" ]]; then rm "$FILESTARGZLOG"; else :; fi
touch "$FILESTARGZLOG"

#FILE_EXTENSION=tar.gz
FILE_EXTENSION=tar.gz.gpg


### functions
targz_and_progress() {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1) ; done)
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz && echo
    #echo to "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz > "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz; popd 1> /dev/null
    echo "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz >> "$FILESTARGZLOG"
    echo ""

}

tar_gz_gpg_and_progress() {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1) ; done)
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" && echo
    #echo to "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")".tar.gz.gpg
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz | gpg --batch --yes --quiet --passphrase="$SUDOPASSWORD" --symmetric --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-count 65536 --compress-algo 0 -o "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" 1> /dev/null; popd 1> /dev/null
    echo "$FILESTARGZSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" >> "$FILESTARGZLOG"
    echo ""

}


### other commands before starting the actual archiving
mkdir -p /Users/$USER/Desktop/desktop/_current/
echo "rsync from /Users/$USER/Desktop/"
printf "%-11s" "to" "/Users/$USER/Desktop/desktop/_current/..." && echo
rsync -a -z -v --delete --progress --stats --human-readable --links --exclude 'files' --exclude 'backup' --exclude 'backup_*' --exclude 'desktop' --exclude 'data' --exclude 'extra' --exclude 'scripts' --exclude 'macintosh_hd' /Users/$USER/Desktop/ /Users/$USER/Desktop/desktop/_current/ 1>/dev/null
echo "done ;)"
echo ''


### deleting some files / folders
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


### creating files from SOURCES to selected destination
for DIRS in "${BACKUPDIRS[@]}"
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
            env_ask_for_variable
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
            unset OVERWRITE_EXISTING
        else
            #targz_and_progress
            tar_gz_gpg_and_progress
        fi
    else
        :
    fi
done


### checking integrity
#echo ''
echo "testing integrity of file(s) in "$FILESTARGZSAVEDIR"/..."
echo ''

NUMBER_OF_CORES=$(parallel --number-of-cores)
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
#echo $NUMBER_OF_MAX_JOBS_ROUNDED

check_files_parallel() {
    file="$1"
    if [[ -f "$file" ]];
    then
        printf "%-45s" ""$(basename "$file")"..." && builtin printf "$SUDOPASSWORD" | gpg --batch --no-tty --yes --quiet --passphrase-fd 0 -d "$file" | unpigz | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
    else
        :
    fi
}

if [[ "$(cat "$FILESTARGZLOG")" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "check_files_parallel {}" ::: "$(cat "$FILESTARGZLOG")"; fi
wait

echo ''
echo 'backing up files done ;)'
echo ''

exit
