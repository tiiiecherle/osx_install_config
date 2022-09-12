#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



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
### functions
###

### variables
env_identify_terminal

ask_for_restore_dir_files() {
    if [[ $(echo "$RESTORE_DIR_FILES") == "" ]] && [[ "$ASK_FOR_RESTORE_DIRS" != "no" ]]
    then
        echo ''
        echo "please select restore directory for files..."
        RESTORE_DIR_FILES=$(sudo -H -u "$loggedInUser" osascript "$SCRIPT_DIR"/restore_ask_dir_files.scpt 2> /dev/null | sed s'/\/$//')
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
        if [[ "$RESTORE_VBOX_FILES" == "yes" ]]
        then
            echo "please select restore directory for virtualbox..."
            RESTORE_DIR_VBOX=$(sudo -H -u "$loggedInUser" osascript "$SCRIPT_DIR"/restore_ask_dir_vbox.scpt 2> /dev/null | sed s'/\/$//')
            sleep 0.5
            osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
            #osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
            sleep 0.5
            if [[ "$RESTORE_DIR_VBOX" != "" ]]; then RESTORE_VBOX="yes"; else :; fi
        else
            :
        fi
    else
        :
    fi
}

ask_for_restore_dir_utm() {
    if [[ $(echo "$RESTORE_DIR_UTM") == "" ]] && [[ "$ASK_FOR_RESTORE_DIRS" != "no" ]]
    then
        if [[ "$RESTORE_UTM_FILES" == "yes" ]]
        then
            echo "please select restore directory for utm..."
            RESTORE_DIR_UTM=$(sudo -H -u "$loggedInUser" osascript "$SCRIPT_DIR"/restore_ask_dir_utm.scpt 2> /dev/null | sed s'/\/$//')
            sleep 0.5
            osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
            #osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
            sleep 0.5
            if [[ "$RESTORE_DIR_UTM" != "" ]]; then RESTORE_UTM="yes"; else :; fi
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
ask_for_restore_dir_utm

if [[ "$RESTORE_FILES_OPTION" == "ask_for_restore_directories" ]]
then
    return
    exit
else
    :
fi

if [[ "$RESTORE_FILES_OPTION" == "unarchive" ]]
then
    cp "$BACKUP_RESTORE_SCRIPTS_DIR"/unarchive/unarchive_tar_gz_gpg_perms_progress_all_in_folder.command "$RESTORE_DIR_FILES"/
    #"$RESTORE_DIR_FILES"/unarchive_tar_gz_gpg_perms_progress_all_in_folder.command &
    open ""$RESTORE_DIR_FILES"/unarchive_tar_gz_gpg_perms_progress_all_in_folder.command"
    sleep 3
    if [[ "$RESTORE_DIR_VBOX" != "" ]]
    then
        cp "$BACKUP_RESTORE_SCRIPTS_DIR"/unarchive/unarchive_tar_gz_progress_all_in_folder.command "$RESTORE_DIR_VBOX"/
        #"$RESTORE_DIR_VBOX"/unarchive_tar_gz_progress_all_in_folder.command &
        open ""$RESTORE_DIR_VBOX"/unarchive_tar_gz_progress_all_in_folder.command"
    else
        :
    fi
    sleep 3
    if [[ "$RESTORE_DIR_UTM" != "" ]]
    then
        cp "$BACKUP_RESTORE_SCRIPTS_DIR"/unarchive/unarchive_tar_gz_progress_all_in_folder.command "$RESTORE_DIR_UTM"/
        #"$RESTORE_DIR_VBOX"/unarchive_tar_gz_progress_all_in_folder.command &
        open ""$RESTORE_DIR_UTM"/unarchive_tar_gz_progress_all_in_folder.command"
    else
        :
    fi
    
    echo ''
    echo "waiting for unarchiving to finish..."
    sleep 3
    WAIT_PIDS=()
    WAIT_PIDS+=$(ps -A | grep -v grep | grep /unarchive_tar_gz_gpg_perms_progress_all_in_folder.command | awk '{print $1}')
    WAIT_PIDS+=$(ps -A | grep -v grep | grep /unarchive_tar_gz_progress_all_in_folder.command | awk '{print $1}')
    # older version gives waring during batch install "awk: newline in string [...]"
    #WAIT_PIDS+=$(ps aux | grep /unarchive_tar_gz_gpg_perms_progress_all_in_folder.command | grep -v grep | awk '{print $2;}')
    #WAIT_PIDS+=$(ps aux | grep /unarchive_tar_gz_progress_all_in_folder.command | grep -v grep | awk '{print $2;}')
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
    trap_function_exit_middle() { env_deactivating_caffeinate; }
fi
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

env_activating_caffeinate


### backup/restore files and directories
# can be set here or in user config file

#BACKUPDIRS=(
#"/Users/"$USER"/Pictures"
#)
    
#BACKUPDIR_VBOX=(
#"/Users/"$USER"/vbox_dir_name/vbox_name"
#)

#BACKUPDIR_UTM=(
#"/Users/"$USER"/Library/Containers/com.utmapp.UTM/Data/Documents/utm_box_name.utm"
#)


### restore files function
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
        	if [[ -e "$line" ]] && [[ -e "$RESTORE_TO_DIR"/"$BASENAME_LINE" ]] && [[ $(find "$RESTORE_TO_DIR"/"$BASENAME_LINE" -mindepth 1 -maxdepth 1 ! -name ".localized" ! -name ".DS_Store") != "" ]]
        	then
        		echo "restoring "$line"..."
        		#if find "$line" -mindepth 1 -maxdepth 1 ! -name ".localized" ! -name ".DS_Store" | read
        		if [[ $(find "$line" -mindepth 1 -maxdepth 1 ! -name ".localized" ! -name ".DS_Store") != "" ]]
                then
                    # not empy
                    rm -rf "$line"/*
                else
                    # empty
                    :
                fi
                mv -f /"$RESTORE_TO_DIR"/"$BASENAME_LINE"/* "$line"/
        		#cp -a /"$RESTORE_TO_DIR"/"$BASENAME_LINE"/* "$line"/
        	else
        		echo "for "$line" source or destination does not exist, skipping..." >&2
        	fi
        fi
    	# cleaning up
        if [[ -e "$RESTORE_TO_DIR"/"$BASENAME_LINE" ]]
    	then
    	    echo "cleaning up "$RESTORE_TO_DIR"/"$BASENAME_LINE"..."
    	    rm -rf "$RESTORE_TO_DIR"/"$BASENAME_LINE"
    	else
    	    :
    	fi
        echo ''
    done <<< "$(printf "%s\n" "${RESTORE_DIRS[@]}")"
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
    
    RESTORE_TO_DIR="$RESTORE_DIR_FILES"
    unset RESTORE_DIRS
    # do not restore macos to desktop as it could already be there and this script could be run from there on a (batch) restore
    RESTORE_DIRS="$(printf "%s\n" "${BACKUPDIRS[@]}" | grep -v 'Desktop/macos')"
    if [[ "$RESTORE_DIRS" != "" ]]
    then
        restore_files
    else
        :
    fi
fi


### restoring utm machines
if [[ "$RESTORE_UTM" == "yes" ]]
then
    if [[ ! -L ~/Library/Containers/com.utmapp.UTM/Data/Documents ]]
    then
        echo "RESTORE_DIR_UTM is "$RESTORE_DIR_UTM"..."
        if [[ $(echo "$RESTORE_DIR_UTM") == "" ]]
        then
            #echo ''
            echo "restoredir for utm restore is empty, skipping..."
            echo ''
        else
            #echo ''
            echo "restoredir for utm restore is "$RESTORE_DIR_UTM"..."
            echo ''
            RESTORE_TO_DIR="$RESTORE_DIR_UTM"
            unset RESTORE_DIRS
            RESTORE_DIRS="$(printf "%s\n" "${BACKUPDIR_UTM[@]}")"
            if [[ "$RESTORE_DIRS" != "" ]]
            then
                restore_files
            else
                :
            fi
        fi
    else
        :
    fi
    
else
    :
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
                #echo ''
                echo "restoredir for virtualbox restore is empty, skipping..."
                echo ''
            else
                #echo ''
                echo "restoredir for virtualbox restore is "$RESTORE_DIR_VBOX"..."
                echo ''
                
                RESTORE_TO_DIR="$RESTORE_DIR_VBOX"
                unset RESTORE_DIRS
                RESTORE_DIRS="$(printf "%s\n" "${BACKUPDIR_VBOX[@]}")"
                if [[ "$RESTORE_DIRS" != "" ]]
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


