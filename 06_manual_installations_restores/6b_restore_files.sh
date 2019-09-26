#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables


###
### functions
###

### variables
SCRIPTS_FINAL_DIR="$SCRIPT_DIR_ONE_BACK"
env_identify_terminal

ask_for_restore_dir_files() {
    if [[ $(echo "$RESTORE_DIR_FILES") == "" ]] && [[ "$ASK_FOR_RESTORE_DIRS" != "no" ]]
    then
        echo ''
        echo "please select restore directory for files..."
        RESTORE_DIR_FILES=$(sudo -H -u "$loggedInUser" osascript "$SCRIPT_DIR"/ask_restore_dir_files.scpt 2> /dev/null | sed s'/\/$//')
        sleep 0.5
        osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
        #osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
        sleep 0.5
    else
        :
    fi
}

ask_for_restore_dir_vbox() {
    if [[ $(echo "$RESTORE_DIR_VBOX") == "" ]] && [[ "$ASK_FOR_RESTORE_DIRS" != "no" ]]
    then
        if [[ "$USER" == "tom" ]] || [[ "$USER" == "wolfgang" ]]
        then
            echo "please select restore directory for virtualbox..."
            RESTORE_DIR_VBOX=$(sudo -H -u "$loggedInUser" osascript "$SCRIPT_DIR"/ask_restore_dir_vbox.scpt 2> /dev/null | sed s'/\/$//')
            sleep 0.5
            osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
            #osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
            sleep 0.5
            RESTORE_VBOX="yes"
        else
            :
        fi
    else
        :
    fi
}


###
### options
###

### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi


ask_for_restore_dir_files
ask_for_restore_dir_vbox

if [[ "$RESTORE_FILES_OPTION" == "ask_for_restore_directories" ]]
then
    return
    exit
else
    :
fi

if [[ "$RESTORE_FILES_OPTION" == "unarchive" ]]
then
    cp "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/unarchive/unarchive_tar_gz_gpg_perms_progress_all_in_folder.command "$RESTORE_DIR_FILES"/
    #"$RESTORE_DIR_FILES"/unarchive_tar_gz_gpg_perms_progress_all_in_folder.command &
    open ""$RESTORE_DIR_FILES"/unarchive_tar_gz_gpg_perms_progress_all_in_folder.command"
    sleep 3
    if [[ "$RESTORE_DIR_VBOX" != "" ]]
    then
        cp "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/unarchive/unarchive_tar_gz_progress_all_in_folder.command "$RESTORE_DIR_VBOX"/
        #"$RESTORE_DIR_VBOX"/unarchive_tar_gz_progress_all_in_folder.command &
        open ""$RESTORE_DIR_VBOX"/unarchive_tar_gz_progress_all_in_folder.command"
    else
        :
    fi
    sleep 3
    WAIT_PIDS=()
    WAIT_PIDS+=$(ps aux | grep /unarchive_tar_gz_gpg_perms_progress_all_in_folder.command | grep -v grep | awk '{print $2;}')
    WAIT_PIDS+=$(ps aux | grep /unarchive_tar_gz_progress_all_in_folder.command | grep -v grep | awk '{print $2;}')
    #echo "$WAIT_PIDS"
    #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
    while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")" 
    sleep 1
else
    :
fi


###
### restoring files
###

### traps
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    #trap_function_exit_middle() { COMMAND1; COMMAND2; }
    :
else
    trap_function_exit_middle() { env_deactivating_keepingyouawake; }
fi
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

env_activating_keepingyouawake

if [[ "$USER" == "tom" ]]
then

    BACKUPDIRS=(
    #"/Users/$USER/Pictures"
    "/Users/$USER/Music"
    "/Users/$USER/Desktop/desktop"
    "/Users/$USER/Desktop/backup"
    "/Users/$USER/github"
    "/Users/$USER/Desktop/files"
    "/Users/$USER/Documents"
    "/Users/$USER/Library/Application Support/MobileSync"
    )
    
    BACKUPDIR_VBOX=(
    "/Users/$USER/virtualbox/arch_64"
    "/Users/$USER/virtualbox/win10_64"
    )

else
    :
fi

if [[ "$USER" == "bobby" ]]
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

if [[ "$USER" == "wolfgang" ]]
then

    BACKUPDIR_VBOX=(
    "/Users/$USER/virtualbox/win10_64"
    )

else
    :
fi

restore_files() {
    while IFS= read -r line || [[ -n "$line" ]]
    do
        LINENUMBER=$((LINENUMBER+1))
        if [[ "$line" == "" ]]; then continue; fi
        line="$line"
        #echo "$line"
        DIRNAME_LINE=$(dirname "$line")
        #echo DIRNAME_LINE is "$DIRNAME_LINE"
        BASENAME_LINE=$(basename "$line")
        #echo BASENAME_LINE is "$BASENAME_LINE"
        echo "$BASENAME_LINE"
        if [[ -L "$line" ]]
        then
        	# is symlink
        	echo ""$line" is a symlink, skipping restore..."
        else
        	# not a symlink
        	mkdir -p "$line"
        	if [[ -e "$line" ]] && [[ -e "$RESTORE_DIR"/"$BASENAME_LINE" ]]
        	then
        		echo "restoring "$line"..."
        		if find "$line" -mindepth 1 -maxdepth 1 ! -name ".localized" ! -name ".DS_Store" | read
                then
                    # not empy
                    rm -rf "$line"/*
                else
                    # empty
                    :
                fi
        		mv -f /"$RESTORE_DIR"/"$BASENAME_LINE"/* "$line"/
        		#cp -a /"$RESTORE_DIR"/"$BASENAME_LINE"/* "$line"/
        	else
        		echo "source or destination does not exist, skipping..."
        	fi
        fi
    	# cleaning up
        if [[ -e "$RESTORE_DIR"/"$BASENAME_LINE" ]]
    	then
    	    echo "cleaning up "$RESTORE_DIR"/"$BASENAME_LINE"..."
    	    rm -rf "$RESTORE_DIR"/"$BASENAME_LINE"
    	else
    	    :
    	fi
        echo ''
    done <<< "$(printf "%s\n" "${BACKUP_DIRS[@]}")"
}


### restoring files
if [[ $(echo "$RESTORE_DIR_FILES") == "" ]]
then
    if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then :; else echo ''; fi
    echo "restoredir for files is empty, skipping..."
    echo ''
else
    if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then :; else echo ''; fi
    echo 'restoredir for files restore is '"$RESTORE_DIR_FILES"''
    echo ''
    
    RESTORE_DIR="$RESTORE_DIR_FILES"
    BACKUP_DIRS="$(printf "%s\n" "${BACKUPDIRS[@]}")"
    if [[ "$BACKUP_DIRS" != "" ]]
    then
        restore_files
    else
        :
    fi
fi


### restoring virtualbox machines
if [[ "$RESTORE_VBOX" == "yes" ]]
then
    if [[ ! -L ~/virtualbox ]]
    then
        if [[ -e /Volumes/data_local/virtualbox ]]
        then
            echo "linking to /Volumes/data_local/virtualbox..."
            ln -s /Volumes/data_local/virtualbox ~/
        else
            if [[ $(echo "$RESTORE_DIR_VBOX") == "" ]]
            then
                echo ''
                echo "restoredir for virtualbox restore is empty, skipping..."
                echo ''
            else
                echo ''
                echo "restoredir for virtualbox restore is "$RESTORE_DIR_VBOX"..."
                echo ''
                
                RESTORE_DIR="$RESTORE_DIR_VBOX"
                BACKUP_DIRS="$(printf "%s\n" "${BACKUPDIR_VBOX[@]}")"
                if [[ "$BACKUP_DIRS" != "" ]]
                then
                    restore_files
                else
                    :
                fi
            fi
        fi
    else
        :
    fi
    
else
    :
fi

# moving old desktop
if [[ -e "/Users/"$USER"/Desktop/desktop/_current" ]]
then
    if [[ -e "/Users/"$USER"/Desktop/desktop_old" ]]; then rm -rf "/Users/"$USER"/Desktop/desktop_old"; fi
    mv "/Users/"$USER"/Desktop/desktop/_current" "/Users/"$USER"/Desktop/desktop_old"
else
    :
fi

# opening user folder in finder for other manual restores
open ~/ 

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    env_active_source_app
else
    :
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


#echo ''
echo "done ;)"
echo ''


