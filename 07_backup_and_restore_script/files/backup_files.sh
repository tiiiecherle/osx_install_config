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

FILESSAVEDIR="$FILESTARGZSAVEDIR"

if [[ "$FILESSAVEDIR" == "" ]]
then
    echo ''
    echo "FILESSAVEDIR not set, exiting..."
    echo ''
    exit
else
    :
fi



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
### user backup/restore profile
###

BACKUP_RESTORE_SCRIPTS_DIR="$SCRIPT_DIR_ONE_BACK"
if [[ -e "$BACKUP_RESTORE_SCRIPTS_DIR"/profiles/backup_profile_"$loggedInUser".conf ]]
then
    . "$BACKUP_RESTORE_SCRIPTS_DIR"/profiles/backup_profile_"$loggedInUser".conf
else
    :
fi



###
### script
###


### checking for script dependencies
#echo ''
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
    # users on the system without ".localized" and "Shared"
    SYSTEMUSERS=$(ls -1 /Users/ | egrep -v "^[.]" | egrep -v "Shared" | egrep -v "Guest")
    # converting list to array
    while IFS= read -r line || [[ -n "$line" ]] 
    do
	if [[ "$line" == "" ]]; then continue; fi
        SYSTEMUSERS_ARRAY+=( "$line" )
    done <<< "$(printf "%s\n" "${SYSTEMUSERS[@]}")"
    
    if [[ $(echo "$SYSTEMUSERS" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') == "1" ]]
    then
        SELECTEDUSER="$SYSTEMUSERS"
    else
        echo ''
        COLUMNS_DEFAULT="$COLUMNS"
        PS3="Please select user profile for file backup by typing the number: "
        COLUMNS=1
        select SELECTEDUSER in "${SYSTEMUSERS_ARRAY[@]}"
        do
            echo "you selected user "$SELECTEDUSER"..."
            #echo ''
            COLUMNS="$COLUMNS_DEFAULT"
            break
        done
    fi
    
    # check1 if a valid user was selected
    USERCHECK=$(find /Users -maxdepth 1 -name "$SELECTEDUSER" -exec basename {} \;)
    if [[ "$SELECTEDUSER" != "$USERCHECK" ]]
    then
        echo "no valid user selected - exiting script because of no real username..."
        exit
    else
        :
    fi
    
    # check2 if a valid user was selected
    if [[ "$SELECTEDUSER" == "" ]]
    then
        echo "no valid user selected - exiting script because of empty username..."
        exit
    else
        :
    fi
else
    :
fi


### backup/restore files and directories
# can be set here or in user config file

#BACKUPDIRS=(
#"/Users/"$USER"/Pictures"
#)


### user backup files/directories
if [[ "$BACKUPDIRS" == "" ]]
then
    echo "there is no valid files backup set for the selected user, exiting..." >&2
    exit
else
    :
fi


### variables
DATE=$(date +%F)
FILESLOG="$FILESSAVEDIR"/targz_file_log_"$DATE".txt

echo ""
if [[ -f "$FILESLOG" ]]; then rm "$FILESLOG"; else :; fi
touch "$FILESLOG"


### functions
targz_and_progress() {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1) ; done)
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" && echo
    #echo to "$FILESSAVEDIR"/"$(basename "$DIRS")".tar.gz
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz > "$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m" >&2; popd 1> /dev/null
    echo "$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" >> "$FILESLOG"
    echo ""

}

tar_gz_gpg_and_progress() {

    BACKUPSIZE=$(gdu -scb /"$DIRS/" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1) ; done)
    echo archiving "$DIRS" 
    printf "%-10s" "to" "$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" && echo
    #echo to "$FILESSAVEDIR"/"$(basename "$DIRS")".tar.gz.gpg
    pushd "$(dirname "$DIRS")" 1> /dev/null; gtar --exclude='dccrecv' -cpf - "$(basename "$DIRS")" | pv -s "$BACKUPSIZE" | pigz | gpg --batch --yes --quiet --passphrase="$SUDOPASSWORD" --symmetric --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-count 65536 --compress-algo 0 -o "$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" 1> /dev/null && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m" >&2; popd 1> /dev/null
    echo "$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION" >> "$FILESLOG"
    echo ""

}


### other commands before starting the actual archiving
mkdir -p /Users/$USER/Desktop/desktop/_current/
echo "rsync from /Users/$USER/Desktop/"
printf "%-11s" "to" "/Users/$USER/Desktop/desktop/_current/..." && echo
# alternatively to -aH -iW use -a -z -v
rsync -aH -iW --delete --progress --stats --human-readable --safe-links --delete-excluded --exclude '/macos' --exclude '/files' --exclude '/backup' --exclude '/backup_*' --exclude '/desktop' /Users/"$USER"/Desktop/ /Users/"$USER"/Desktop/desktop/_current/ 1> /dev/null

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
    if [[ -d "$DIRS" ]]
    then
        if [[ "$DIRS" == "/Users/"$USER"/Desktop/macos" ]]
        then
            FILE_EXTENSION=tar.gz
            ARCHIVING_FUNCTION=targz_and_progress
        else
            FILE_EXTENSION=tar.gz.gpg
            ARCHIVING_FUNCTION=tar_gz_gpg_and_progress
        fi
        # checking if file exists
        SAVEFILE="$FILESSAVEDIR"/"$(basename "$DIRS")"."$FILE_EXTENSION"
        if [[ -f "$SAVEFILE" ]]
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
                echo "skipping "$SAVEFILE""
                echo ""
            else
                rm "$SAVEFILE"
                "${ARCHIVING_FUNCTION}"
            fi
            unset OVERWRITE_EXISTING
        else
            "${ARCHIVING_FUNCTION}"
        fi
    else
        :
    fi
    unset FILE_EXTENSION
    unset ARCHIVING_FUNCTION
done


### checking integrity
#echo ''
testing_files_integrity() {
    echo "testing integrity of file(s) in "$FILESSAVEDIR"/..."
    echo ''
    
    NUMBER_OF_CORES=$(parallel --number-of-cores)
    NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
    
    check_files_parallel() {
        file="$1"
        if [[ -f "$file" ]]
        then
            if [[ "$file" == *.tar.gz.gpg ]]
            then
                printf "%-45s" ""$(basename "$file")"..." && builtin printf "$SUDOPASSWORD" | gpg --batch --no-tty --yes --quiet --passphrase-fd 0 -d "$file" | unpigz | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
            elif [[ "$file" == *.tar.gz ]]
            then
                printf "%-45s" ""$(basename "$file")"..." && unpigz -c "$file" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
            else
                echo ""$file" does not have a recognized file extension, skipping..."
            fi
        else
            :
        fi
    }
    
    if [[ "$(cat "$FILESLOG")" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "check_files_parallel {}" ::: "$(cat "$FILESLOG")"; fi
    #if [[ "$(find "$FILESSAVEDIR" -mindepth 1 -maxdepth 1 -type f -name '*.tar.gz.gpg' -o -name '*.tar.gz')" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "check_files_parallel {}" ::: "$(find "$FILESSAVEDIR" -mindepth 1 -maxdepth 1 -type f -name '*.tar.gz.gpg' -o -name '*.tar.gz')"; fi
    wait
    echo ''
}
#testing_files_integrity

echo 'backing up files done ;)'
echo ''

exit
