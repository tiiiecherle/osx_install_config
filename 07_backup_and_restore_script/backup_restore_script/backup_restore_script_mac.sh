#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
        env_sudo
    else
        env_enter_sudo_password
    fi
else
    :
fi



###
### functions
###

unset_variables() {
    unset OPTION
    #unset RESTOREDIR
    unset RESTOREMASTERDIR
    unset RESTOREUSERDIR
    unset RESTORETODIR
    unset DESTINATION
    unset HOMEFOLDER
    unset MASTERUSER
    unset USERUSER
    unset TERMINALWIDTH
    unset LINENUMBER
    unset DESTINATION
    unset SUDOPASSWORD
    unset VBOXSAVEDIR
    unset UTMSAVEDIR
    unset GUI_APP_TO_BACKUP
}

delete_tmp_backup_script_fifo1() {
    # fifo1 is used for files backup 
    if [[ -e "/tmp/tmp_backup_script_fifo1" ]]
    then
        rm "/tmp/tmp_backup_script_fifo1"
    else
        :
    fi
}

create_tmp_backup_script_fifo1() {
    # fifo1 is used for files backup 
    delete_tmp_backup_script_fifo1
    mkfifo -m 600 "/tmp/tmp_backup_script_fifo1"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_backup_script_fifo1" &
}

delete_tmp_backup_script_fifo2() {
    # fifo2 is used for homebrew update for casks 
    if [[ -e "/tmp/tmp_backup_script_fifo2" ]]
    then
        rm "/tmp/tmp_backup_script_fifo2"
    else
        :
    fi
}

create_tmp_backup_script_fifo2() {
    # fifo2 is used for homebrew update for casks
    delete_tmp_backup_script_fifo2
    mkfifo -m 600 "/tmp/tmp_backup_script_fifo2"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_backup_script_fifo2" &
}

install_update_dependency_apps() {
    ### gui apps backup
    #echo ''
    echo "updating gui backup app..."    
    APP_TO_INSTALL="gui_apps_backup"
    if [[ -e "$PATH_TO_APPS"/"$APP_TO_INSTALL".app ]]
    then
    	rm -rf "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
    	:
    fi
    cp -a "$WORKING_DIR"/gui_apps/"$APP_TO_INSTALL".app "$PATH_TO_APPS"/
    chown $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chmod 755 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    if [[ $(xattr -l "$PATH_TO_APPS"/"$APP_TO_INSTALL".app | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
        :
    fi
    
    ### vbox backup app
    #echo ''
    echo "updating vbox backup app..."    
    APP_TO_INSTALL="virtualbox_backup"
    if [[ -e "$PATH_TO_APPS"/"$APP_TO_INSTALL".app ]]
    then
    	rm -rf "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
    	:
    fi
    cp -a "$WORKING_DIR"/vbox_backup/"$APP_TO_INSTALL".app "$PATH_TO_APPS"/
    chown $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chown -R $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app/Contents/custom_files/
    chmod 755 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chmod 770 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app/Contents/custom_files/"$APP_TO_INSTALL".sh
    if [[ $(xattr -l "$PATH_TO_APPS"/"$APP_TO_INSTALL".app | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
        :
    fi
    
    ### utm backup app
    #echo ''
    echo "updating utm backup app..."    
    APP_TO_INSTALL="utm_backup"
    if [[ -e "$PATH_TO_APPS"/"$APP_TO_INSTALL".app ]]
    then
    	rm -rf "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
    	:
    fi
    cp -a "$WORKING_DIR"/utm_backup/"$APP_TO_INSTALL".app "$PATH_TO_APPS"/
    chown $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chown -R $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app/Contents/custom_files/
    chmod 755 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chmod 770 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app/Contents/custom_files/"$APP_TO_INSTALL".sh
    if [[ $(xattr -l "$PATH_TO_APPS"/"$APP_TO_INSTALL".app | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
        :
    fi
        
    ### installing / updating homebrew update script
    #echo ''
    echo "updating homebrew formulae and casks app..."
	APP_TO_INSTALL="brew_casks_update"
    if [[ -e "$PATH_TO_APPS"/"$APP_TO_INSTALL".app ]]
    then
    	rm -rf "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
    	:
    fi
    cp -a "$WORKING_DIR"/update_homebrew/"$APP_TO_INSTALL".app "$PATH_TO_APPS"/
    chown $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chown -R $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_TO_INSTALL".app/Contents/custom_files/
    chmod 755 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    chmod 770 "$PATH_TO_APPS"/"$APP_TO_INSTALL".app/Contents/custom_files/"$APP_TO_INSTALL".sh
    if [[ $(xattr -l "$PATH_TO_APPS"/"$APP_TO_INSTALL".app | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_TO_INSTALL".app
    else
        :
    fi
        
    ### updating hosts script
	if [[ -e "$WORKING_DIR"/update_hosts/hosts_file_generator.sh ]]
	then
        #echo ''
        echo "updating hosts update script..."
        sudo mkdir -p /Library/Scripts/custom/
        sudo cp "$WORKING_DIR"/update_hosts/hosts_file_generator.sh /Library/Scripts/custom/hosts_file_generator.sh
        sudo chown -R root:wheel /Library/Scripts/custom/
        sudo chmod -R 755 /Library/Scripts/custom/
    else
        echo ""$WORKING_DIR"/update_hosts/hosts_file_generator.sh not found, skipping updating hosts script..."
    fi
}

give_apps_security_permissions() {
    
    ### security permissions
	APPS_SECURITY_ARRAY=(
    # app name									security service										allowed (1=yes, 0=no)
	"Script Editor                              kTCCServiceAccessibility                             	1"
	"brew_casks_update                          kTCCServiceAccessibility                                1"
	"gui_apps_backup                            kTCCServiceAccessibility                             	1"
	"gui_apps_backup                            kTCCServiceReminders                             	    1"
	"gui_apps_backup                            kTCCServiceAddressBook                             	    1"
	"gui_apps_backup                            kTCCServiceCalendar                             	    1"
	"virtualbox_backup                          kTCCServiceAccessibility                             	1"
	"utm_backup                                 kTCCServiceAccessibility                             	1"
	)
	PRINT_SECURITY_PERMISSIONS_ENTRIES="no" env_set_apps_security_permissions
    
    
    ### automation
    # macos versions 10.14 and up
    # source app name							automated app name										allowed (1=yes, 0=no)
	AUTOMATION_APPS=(
	"$SOURCE_APP_NAME						    System Events                   						1"
	"$SOURCE_APP_NAME						    Finder                   						        1"
	"gui_apps_backup							System Events                   						1"
	"brew_casks_update							System Events                   						1"
	"brew_casks_update							Terminal                   						        1"
	"virtualbox_backup							System Events                   						1"
	"virtualbox_backup							Terminal                   						        1"
	"utm_backup							        System Events                   						1"
	"utm_backup							        Terminal                   						        1"
	)
	PRINT_AUTOMATING_PERMISSIONS_ENTRIES="no" env_set_apps_automation_permissions
    
}

number_of_max_processes() {
    if [[ $(brew list --formula | grep "^parallel$") == '' ]]
	then
		#echo parallel is NOT installed..."
		#NUMBER_OF_MAX_JOBS_ROUNDED=1
		:
	else
        NUMBER_OF_CORES=$(parallel --number-of-cores)
        NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
        #echo $NUMBER_OF_MAX_JOBS
        NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
        #echo $NUMBER_OF_MAX_JOBS_ROUNDED
	fi

}


### variables
env_databases_apps_security_permissions
env_identify_terminal

WORKING_DIR="$SCRIPT_DIR_ONE_BACK"
SCRIPT_DIR_FINAL="$SCRIPT_DIR_TWO_BACK"
APPLESCRIPTDIR="$WORKING_DIR"


### trapping
trap_function_exit_middle() { delete_tmp_backup_script_fifo1; delete_tmp_backup_script_fifo2; open -g keepingyouawake:///deactivate; stty sane; unset SUDOPASSWORD; unset USE_PASSWORD; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

echo ''

if [[ "$OPTION" == "" ]]
then
    # choosing the backup and defining $BACKUP variable
    COLUMNS_DEFAULT="$COLUMNS"
    PS3="Please select option by typing the number: "
    COLUMNS=1 
    select OPTION in BACKUP RESTORE
    do
        echo "you selected option "$OPTION"..."
        echo ''
        COLUMNS="$COLUMNS_DEFAULT"
        break
    done
else
    echo "script is run with option $OPTION..."
    echo ''
fi

# check if a valid option was selected
if [[ "$OPTION" == "" ]] || [[ "$OPTION" != "BACKUP" ]] && [[ "$OPTION" != "RESTORE" ]]
then
    echo "no valid option selected - exiting script..."
    exit
else
    :
fi

###
### backup / restore function
###

# starting a function to tee a record to a logfile
backup_restore() {
    
    # backupdate
    DATE=$(date +%F)
    
    # users on the system without ".localized" and "Shared"
    #SYSTEMUSERS=$(pushd /Users/ >/dev/null 2>&1; printf "%s " * | egrep -v "^[.]" | egrep -v "Guest"; popd >/dev/null 2>&1)
    SYSTEMUSERS=$(ls -1 /Users/ | egrep -v "^[.]" | egrep -v "Shared" | egrep -v "Guest")
    # converting list to array
    while IFS= read -r line || [[ -n "$line" ]] 
    do
	if [[ "$line" == "" ]]; then continue; fi
        SYSTEMUSERS_ARRAY+=( "$line" )
    done <<< "$(printf "%s\n" "${SYSTEMUSERS[@]}")"
    
    # getting logged in user and unique id
    # done in config script

    if [[ $(echo "$SYSTEMUSERS" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') == "1" ]]
    then
        SELECTEDUSER="$SYSTEMUSERS"
        if [[ "$OPTION" == "BACKUP" ]]
        then
            echo "only one user account on the system, backing up user ""$SELECTEDUSER""..."
        elif [[ "$OPTION" == "RESTORE" ]]
        then
            echo "only one user account on the system, restoring to user ""$SELECTEDUSER""..."
        else
            :
        fi
        echo ''
    else
        if [[ "$OPTION" == "BACKUP" ]]
        then
            COLUMNS_DEFAULT="$COLUMNS"
            PS3="Please select user to backup by typing the number: "
        elif [[ "$OPTION" == "RESTORE" ]]
        then
            COLUMNS_DEFAULT="$COLUMNS"
            PS3="Please select user to restore to by typing the number: "
        else
            :
        fi
        
        COLUMNS=1
        select SELECTEDUSER in "${SYSTEMUSERS_ARRAY[@]}"
        do
            echo "you selected user "$SELECTEDUSER"..."
            echo ''
            COLUMNS="$COLUMNS_DEFAULT"
            break
        done
    fi

    # check1 if a valid user was selected
    USERCHECK=$(find /Users -maxdepth 1 -name "$SELECTEDUSER" -exec basename {} \;)
    if [[ "$SELECTEDUSER" != "$USERCHECK" ]]
    then
        echo "no valid user selected - exiting script because of no real username..."
        echo ''
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
    
    # confirm run
    VARIABLE_TO_CHECK="$RUN_SCRIPT"
    QUESTION_TO_ASK="do you want to run the script with option ""$OPTION"" and for user ""$SELECTEDUSER"" (Y/n)? "
    env_ask_for_variable
    RUN_SCRIPT="$VARIABLE_TO_CHECK"
    sleep 0.1
    
    if [[ "$RUN_SCRIPT" =~ ^(yes|y)$ ]]
    then
        :
    else
        echo ''
        echo "exiting..."
        echo ''
        exit
    fi
    
    ###
    ### variables and list syntax check
    ###
    
    # user home folder
    HOMEFOLDER=/Users/"$SELECTEDUSER"
    echo "HOMEFOLDER is "$HOMEFOLDER""
    
    # checking if user directory exists
    if [[ -d "$HOMEFOLDER" ]]
    then
        echo "user home directory exists - running script..."
        echo ''
    
        # path to current working directory
        CURRENT_DIR="$(pwd)"
        echo "current directory is "$CURRENT_DIR"..."
        
        # path to running script directory
        echo "script directory is "$WORKING_DIR"..."
        
        # checking syntax of backup / restore list
        BACKUP_RESTORE_LIST="$WORKING_DIR"/list/backup_restore_list.txt
        echo ""
        SYNTAXERRORS=0
        LINENUMBER=0
        while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
            LINENUMBER=$((LINENUMBER+1))
        	if [[ ! "$line" == "" ]] && [[ ! $line =~ ^[\#] ]] && [[ ! $line =~ ^m[[:blank:]] ]] && [[ ! $line =~ ^u[[:blank:]] ]] && [[ ! $line =~ ^echo[[:blank:]] ]]
        	then
                echo "wrong syntax for entry in line "$LINENUMBER": "$line""
                SYNTAXERRORS=$((SYNTAXERRORS+1))
            else
            	:
                #echo "correct entry"
            fi
        done <<< "$(cat "$BACKUP_RESTORE_LIST")"
        
        #echo "$SYNTAXERRORS"
        if [[ "$SYNTAXERRORS" -gt "0" ]]
        then
            echo "there are syntax errors in the backup / restore list, please correct the entries and rerun the script..."
            exit
        else
        	echo "syntax of backup / restore list o.k., continuing..."
        	echo ""
        fi
        
        ###
        ### updates and installations to all macs running the script
        ###
        
        if [[ -e "$WORKING_DIR"/update_macos/updates_macos.sh ]]
        then
            . "$WORKING_DIR"/update_macos/updates_macos.sh
            wait
        else
            echo ""$WORKING_DIR"/update_macos/updates_macos.sh not found, skipping..."
        fi
        
        ###
        ### checking installation of needed tools
        ###
        
        echo "checking if all needed tools are installed"...
        
        # installing command line tools
        env_command_line_tools_install_shell
        
        # checking homebrew including script dependencies
        if command -v brew &> /dev/null
        then
        	# installed
            echo "homebrew is installed..."
            if [[ "$OPTION" == "BACKUP" ]]; 
            then
                # checking for missing dependencies
                for formula in gnu-tar pigz pv coreutils gnupg cliclick
                do
                	if [[ $(brew list --formula | grep "^$formula$") == '' ]]
                	then
                		#echo """$formula"" is NOT installed..."
                		MISSING_SCRIPT_DEPENDENCY="yes"
                	else
                		#echo """$formula"" is installed..."
                		:
                	fi
                done
                if [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
                then
                    echo at least one needed homebrew tools of gnu-tar, pigz, pv, coreutils, gnupg and cliclick is missing, exiting...
                    exit
                else
                    echo needed homebrew tools are installed...     
                fi
                unset MISSING_SCRIPT_DEPENDENCY
            else
                # checking for missing dependencies
                for formula in coreutils parallel
                do
                	if [[ $(brew list --formula | grep "^$formula$") == '' ]]
                	then
                		#echo """$formula"" is NOT installed..."
                		MISSING_SCRIPT_DEPENDENCY="yes"
                	else
                		#echo """$formula"" is installed..."
                		:
                	fi
                done
                if [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
                then
                    echo at least one needed homebrew tools of coreutils and parallel is missing, exiting...
                    exit
                else
                    echo needed homebrew tools are installed...     
                fi
                unset MISSING_SCRIPT_DEPENDENCY
            fi
        else
            # not installed
            echo "homebrew is not installed, exiting..."
            exit
        fi
        
        #echo ''
        
        ###
        ### backup
        ###
        
        # activating caffeinate
        env_activating_caffeinate
        
        # checking and installing dependencies
        install_update_dependency_apps
        echo ''
        
        echo "resetting security permissions for backup apps..."
        give_apps_security_permissions
        echo ''
        
        # checking if backup option was selected
        if [[ "$OPTION" == "BACKUP" ]]; 
        then
            echo "running backup..."
            sleep 1
            
            # opening applescript which will ask for saving location of compressed file
            echo ''
            echo "asking for directory to save the backup to..."
            TARGZGPGZSAVEDIR=$(sudo -H -u "$loggedInUser" osascript "$WORKING_DIR"/backup_restore_script/ask_save_to.scpt 2> /dev/null | sed s'/\/$//')
            sleep 0.5

            #echo ''
            # checking if valid path for backup was selected
            if [[ -e "$TARGZGPGZSAVEDIR" ]]
            then
                echo "backup will be saved to "$TARGZGPGZSAVEDIR""
                sleep 0.1
            else
                echo "no valid path for saving the backup selected, exiting script..."
                exit
            fi
            printf '\n'
            sleep 0.1
            
            ### asking for backups
            if [[ -e "$WORKING_DIR"/profiles/backup_profile_"$loggedInUser".conf ]]
            then
                echo "backup profile found..."
                #echo ''
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
				    #if [[ $(echo "$line" | grep '.*=".*"') == "" ]]; then continue; fi
				    VERSION_TO_CHECK_AGAINST=10.15
                    if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
                    then
                        # macos 10.15 and newer
                        if [[ $(echo "$line" | grep "REMINDERS_BACKUP") != "" ]]; then continue; fi
                    fi
                    if [[ $(echo "$line" | grep "^#") != "" ]]
                    then
                        :
                    else
                        PROFILE_VARIABLE=$(echo "$line" | cut -d= -f 1)
                        # | awk -F'=' '{print $1}'
                        VARIABLE_VALUE=$(echo "$line" | cut -d= -f 2 | tr -d '"')
                        printf "%-25s %-10s\n" "$PROFILE_VARIABLE" "$VARIABLE_VALUE"
                    fi
                done <<< "$(cat ""$WORKING_DIR"/profiles/backup_profile_"$loggedInUser".conf" | sed '/^[[:space:]]*$/q')"
                
                echo ''
                VARIABLE_TO_CHECK="$RUN_WITH_PROFILE"
                QUESTION_TO_ASK="do you want to use these settings (Y/n)? "
                env_ask_for_variable
                RUN_WITH_PROFILE="$VARIABLE_TO_CHECK"
                sleep 0.1
                
                if [[ "$RUN_WITH_PROFILE" =~ ^(yes|y)$ ]]
                then
                    echo ''
                    . "$WORKING_DIR"/profiles/backup_profile_"$loggedInUser".conf
                    VERSION_TO_CHECK_AGAINST=10.15
                    if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
                    then
                        # macos 10.15 and newer
                        REMINDERS_BACKUP="no"
                    fi
                else
                    echo ''
                fi
            else
                :
            fi            
            
            # virtualbox backup
            if [[ "$BACKUP_VBOX" == "no" ]]
            then
                :
            elif [[ -e /Users/"$loggedInUser"/virtualbox ]] || [[ "$BACKUP_VBOX" == "yes" ]]
            then
                VARIABLE_TO_CHECK="$BACKUP_VBOX"
                QUESTION_TO_ASK="do you want to backup virtualbox images (y/N)? "
                env_ask_for_variable
                BACKUP_VBOX="$VARIABLE_TO_CHECK"
                sleep 0.1
                #
                if [[ "$BACKUP_VBOX" =~ ^(yes|y)$ ]]
                then
                    # opening applescript which will ask for saving location of compressed file
                    echo "asking for directory to save the vbox backup to..."
                    VBOXSAVEDIR=$(sudo -H -u "$loggedInUser" osascript "$WORKING_DIR"/vbox_backup/ask_save_to_vbox.scpt 2> /dev/null | sed s'/\/$//')
                    sleep 0.5
                    #echo ''
                    # checking if valid path for backup was selected
                    if [[ -e "$VBOXSAVEDIR" ]]
                    then
                        echo "vbox backup will be saved to "$VBOXSAVEDIR""
                        sleep 0.1
                        #printf '\n'
                        #sleep 0.1
                    else
                        echo "no valid path for saving the vbox backup selected, exiting script..."
                        exit
                    fi
                else
                    :
                fi
            else
                :
            fi
            
            # utm backup
            if [[ "$BACKUP_UTM" == "no" ]]
            then
                :
            elif [[ -e /Users/"$USER"/Library/Containers/com.utmapp.UTM/Data/Documents ]] || [[ "$BACKUP_UTM" == "yes" ]]
            then
                VARIABLE_TO_CHECK="$BACKUP_UTM"
                QUESTION_TO_ASK="do you want to backup utm images (y/N)? "
                env_ask_for_variable
                BACKUP_UTM="$VARIABLE_TO_CHECK"
                sleep 0.1
                #
                if [[ "$BACKUP_UTM" =~ ^(yes|y)$ ]]
                then
                    # opening applescript which will ask for saving location of compressed file
                    echo "asking for directory to save the utm backup to..."
                    UTMSAVEDIR=$(sudo -H -u "$loggedInUser" osascript "$WORKING_DIR"/utm_backup/ask_save_to_utm.scpt 2> /dev/null | sed s'/\/$//')
                    sleep 0.5
                    #echo ''
                    # checking if valid path for backup was selected
                    if [[ -e "$UTMSAVEDIR" ]]
                    then
                        echo "utm backup will be saved to "$UTMSAVEDIR""
                        sleep 0.1
                        #printf '\n'
                        #sleep 0.1
                    else
                        echo "no valid path for saving the utm backup selected, exiting script..."
                        exit
                    fi
                else
                    :
                fi
            else
                :
            fi
            
            # files backup
            VARIABLE_TO_CHECK="$FILES_BACKUP"
            QUESTION_TO_ASK="do you want to backup local files (y/N)? "
            env_ask_for_variable
            FILES_BACKUP="$VARIABLE_TO_CHECK"
            sleep 0.1
            
            # reminders backup
    	    VERSION_TO_CHECK_AGAINST=10.14
            if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
            then
                # macos versions until and including 10.14
                VARIABLE_TO_CHECK="$REMINDERS_BACKUP"
                QUESTION_TO_ASK="do you want to run a reminders backup (y/N)? "
                env_ask_for_variable
                REMINDERS_BACKUP="$VARIABLE_TO_CHECK"
                sleep 0.1
            else
                # macos 10.15 and up
                :
            fi
        
            # running contacts backup applescript
            VARIABLE_TO_CHECK="$CONTACTS_BACKUP"
            QUESTION_TO_ASK="do you want to run a contacts backup (y/N)? "
            env_ask_for_variable
            CONTACTS_BACKUP="$VARIABLE_TO_CHECK"
            sleep 0.1
              
            # running calendars backup applescript
            VARIABLE_TO_CHECK="$CALENDARS_BACKUP"
            QUESTION_TO_ASK="do you want to run a calendar backup (y/N)? "
            env_ask_for_variable
            CALENDARS_BACKUP="$VARIABLE_TO_CHECK"
            sleep 0.1

            echo ''
            
            ### running backups
            run_gui_backups() {
                # reminders
                if [[ "$REMINDERS_BACKUP" =~ ^(yes|y)$ ]]
                then
                    if [[ "$RUN_WITH_NO_OUTPUT_ON_START" == "yes" ]]; then :; else echo "running reminders backup... please do not touch the computer until the app quits..."; fi
                    # cleaning up old backups (only keeping the latest 4)
                    while IFS= read -r line || [[ -n "$line" ]]
    				do
    				    if [[ "$line" == "" ]]; then continue; fi
                    	REMINDERSBACKUPS="$line"
                    	#echo "$REMINDERSBACKUPS"
                        rm -rf "$HOMEFOLDER"/Documents/backup/reminders/"$REMINDERSBACKUPS"
                    done <<< "$(find "$HOMEFOLDER"/Documents/backup/reminders -type d -mindepth 0 -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d)"
                                 
                    # running contacts backup
                    GUI_APP_TO_BACKUP=Reminders
                    export GUI_APP_TO_BACKUP
                    #open "$WORKING_DIR"/gui_apps/gui_apps_backup.app
                    open "$PATH_TO_APPS"/gui_apps_backup.app
                    sleep 2
                    # waiting for the process to finish
                    #while ps aux | grep gui_apps_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                    # or
                    #WAIT_PIDS=$(ps -A | grep -m1 gui_apps_backup | awk '{print $1}')
                    WAIT_PIDS=$(ps aux | grep gui_apps_backup.app/Contents | grep -v grep | awk '{print $2;}')
                    #echo "$WAIT_PIDS"
                    #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
                    while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
                    #osascript -e 'tell application "Terminal" to activate'
                else
                    :
                fi
                
                # contacts
                if [[ "$CONTACTS_BACKUP" =~ ^(yes|y)$ ]]
                then
                    if [[ "$RUN_WITH_NO_OUTPUT_ON_START" == "yes" ]]; then :; else echo "running contacts backup... please do not touch the computer until the app quits..."; fi
                    # cleaning up old backups (only keeping the latest 4)
                    while IFS= read -r line || [[ -n "$line" ]]
    				do
    				    if [[ "$line" == "" ]]; then continue; fi
                    	CONTACTSBACKUPS="$line"
                    	#echo "$CONTACTSBACKUPS"
                        rm -rf "$HOMEFOLDER"/Documents/backup/contacts/"$CONTACTSBACKUPS"
                    done <<< "$(find "$HOMEFOLDER"/Documents/backup/contacts -type d -mindepth 0 -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d)"
                    
                    # running contacts backup
                    GUI_APP_TO_BACKUP=Contacts
                    export GUI_APP_TO_BACKUP
                    #open "$WORKING_DIR"/gui_apps/gui_apps_backup.app
                    open "$PATH_TO_APPS"/gui_apps_backup.app
                    sleep 2
                    # waiting for the process to finish
                    #while ps aux | grep gui_apps_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                    # or
                    #WAIT_PIDS=$(ps -A | grep -m1 gui_apps_backup | awk '{print $1}')
                    WAIT_PIDS=$(ps aux | grep gui_apps_backup.app/Contents | grep -v grep | awk '{print $2;}')
                    #echo "$WAIT_PIDS"
                    #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
                    while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"                    
                    #osascript -e 'tell application "Terminal" to activate'
                else
                    :
                fi
            
                # calendar
                if [[ "$CALENDARS_BACKUP" =~ ^(yes|y)$ ]]
                then
                    if [[ "$RUN_WITH_NO_OUTPUT_ON_START" == "yes" ]]; then :; else echo "running calendars backup... please do not touch the computer until the app quits..."; fi
                    # cleaning up old backups (only keeping the latest 4)
                    while IFS= read -r line || [[ -n "$line" ]]
    				do
    				    if [[ "$line" == "" ]]; then continue; fi
                    	CALENDARSBACKUPS="$line"
                    	#echo "$CALENDARSBACKUPS"
                        rm -rf "$HOMEFOLDER"/Documents/backup/calendar/"$CALENDARSBACKUPS"
                    done <<< "$(find "$HOMEFOLDER"/Documents/backup/calendar -type d -mindepth 0 -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d)"
                    
                    # making sure calendar is not running
                    #echo "quitting calendar..."
                	osascript <<EOF
                	
                		try
                			tell application "Calendar"
                				quit
                			end tell
                			delay 1
                		end try
	
EOF
                    
                    # un-collapsing all elements in the sidebar
                    PATH_TO_CALENDARS="/Users/"$USER"/Library/Calendars"
                    CALENDAR_PREFERENCES_PLIST=/Users/"$USER"/Library/Preferences/com.apple.iCal.plist
                    /usr/libexec/PlistBuddy -c 'Delete CollapsedTopLevelNodes' "$CALENDAR_PREFERENCES_PLIST" 2>&1 | grep -v "Does Not Exist$"
                    sleep 2
                    
                    # running calendar backup
                    GUI_APP_TO_BACKUP=Calendar
                    export GUI_APP_TO_BACKUP
                    #open "$WORKING_DIR"/gui_apps/gui_apps_backup.app
                    open "$PATH_TO_APPS"/gui_apps_backup.app
                    sleep 2
                    # waiting for the process to finish
                    #while ps aux | grep gui_apps_backup.app/Contents | grep -v grep > /dev/null; do sleep 1; done
                    # or
                    #WAIT_PIDS=$(ps -A | grep -m1 gui_apps_backup | awk '{print $1}')
                    WAIT_PIDS=$(ps aux | grep gui_apps_backup.app/Contents | grep -v grep | awk '{print $2;}')
                    #echo "$WAIT_PIDS"
                    #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
                    while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
                    
                    # collapsing all elements in the sidebar
                    sleep 2
                    env_collapsing_elements_in_calendar_sidebar
        			                   
                else
                    :
                fi
                osascript -e 'tell application "Terminal" to activate'
            }
            
            run_files_backup() {
                # files
                if [[ "$FILES_BACKUP" =~ ^(yes|y)$ ]]            
                then
                    FILESTARGZSAVEDIR="$TARGZGPGZSAVEDIR"
                    FILESAPPLESCRIPTDIR="$APPLESCRIPTDIR"
                    if [[ "$RUN_WITH_NO_OUTPUT_ON_START" == "yes" ]]; then :; else echo "running local files backup..."; fi
                    create_tmp_backup_script_fifo1
                    . "$WORKING_DIR"/files/backup_files_run_script.sh
                else
                    :
                fi
            }

            run_vbox_backup() {
                # virtualbox
                if [[ "$BACKUP_VBOX" =~ ^(yes|y)$ ]]
                then
                    if [[ "$RUN_WITH_NO_OUTPUT_ON_START" == "yes" ]]; then :; else echo "running virtualbox backup..."; fi
                    export VBOXSAVEDIR
                    #open "$WORKING_DIR"/vbox_backup/virtualbox_backup.app
                    open "$PATH_TO_APPS"/virtualbox_backup.app
                else
                    :
                fi
            }
            
            run_utm_backup() {
                # utm
                if [[ "$BACKUP_UTM" =~ ^(yes|y)$ ]]
                then
                    if [[ "$RUN_WITH_NO_OUTPUT_ON_START" == "yes" ]]; then :; else echo "running utm backup..."; fi
                    export UTMSAVEDIR
                    #open "$WORKING_DIR"/utm_backup/utm_backup.app
                    open "$PATH_TO_APPS"/utm_backup.app
                else
                    :
                fi
            }
        
            # backup destination
            DESTINATION="$HOMEFOLDER"/Desktop/backup_"$SELECTEDUSER"_"$DATE"
            #DESTINATION="$TARGZGPGZSAVEDIR"/backup_"$SELECTEDUSER"_"$DATE"
            TARGZGPGFILE="$TARGZGPGZSAVEDIR"/backup_"$SELECTEDUSER"_"$DATE".tar.gz.gpg
            mkdir -p "$DESTINATION"
            
            # backup macos system
            echo "$MACOS_VERSION" > "$DESTINATION"/_backup_macos_version.txt
            
            # backup
            #
            #echo ""
            echo "starting backup..."
            #    
            BACKUP_RESTORE_LIST="$WORKING_DIR"/list/backup_restore_list.txt
            #STTY_ORIG=$(stty -g)
            #TERMINALWIDTH=$(echo $COLUMNS)
            #TERMINALWIDTH=$(stty size | awk '{print $2}')
            TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
            LINENUMBER=0
            
            backup_data() {
                
                if [[ "$USE_PARALLELS" == "yes" ]]
                then
                    line="$1"
                    #echo "$line"
                else
                    :
                fi
                
            	LINENUMBER=$((LINENUMBER+1))
            	
                # if starting with one # and whitespace / tab
            	#if [[ $line =~ ^[\#][[:blank:]] ]]
            	
            	# if starting with more than one #
            	#if [[ $line =~ ^[\#]{2,} ]]
            
            	# if line is empty
            	#if [ -z "$line" ]
            	
            	if [[ "$line" == "" ]]
            	then
                    :
                else
                    :
                fi
            	
            	# if starting with #
            	if [[ "$line" =~ ^[\#] ]]
            	then
                    :
                else
                    :
                fi
                
                # if starting with echo and whitespace / tab
            	if [[ "$line" =~ ^echo[[:blank:]] ]]
            	then
                    OUTPUT=$(echo "$line" | sed 's/^echo*//' | sed -e 's/^[ \t]*//')
            		TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-5))
                    echo "$OUTPUT" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                else
                    :
                fi 
                 	
            	# if starting with m and space / tab or with u and space / tab
            	if [[ "$line" =~ ^m[[:blank:]] ]] || [[ "$line" =~ ^u[[:blank:]] ]]
            	then
                    ENTRY=$(echo "$line" | cut -f2 | sed 's|~|'"$HOMEFOLDER"'|' | sed 's|"$PATH_TO_APPS"|'"$PATH_TO_APPS"'|' | sed -e 's/[ /]\{2,\}/\//')
                    #echo "$ENTRY"
                    DIRNAME_ENTRY=$(dirname "$ENTRY")
                    #echo DIRNAME_ENTRY is "$DIRNAME_ENTRY"
                    BASENAME_ENTRY=$(basename "$ENTRY")
                    #echo BASENAME_ENTRY is "$BASENAME_ENTRY"
                    if [[ "$ENTRY" =~ [*] ]]
                    # or
                    #if [[ $(echo "$ENTRY" | egrep '[*]') != "" ]]		# working
			        #if [[ $(echo "$ENTRY" | grep '[*]') != "" ]]		# working
                    then
                        ENTRY_WITH_ASTERISK="$ENTRY"
                        if [[ "$DIRNAME_ENTRY" =~ [*] ]]
                        then
                            ROOTDIR_PATH=$(echo "$DIRNAME_ENTRY" | cut -d "/" -f2)
                            #echo ROOTDIR_PATH is "$ROOTDIR_PATH"
                            ENTRY="$(find "/$ROOTDIR_PATH" -path "$DIRNAME_ENTRY" -name "$BASENAME_ENTRY" 2> /dev/null)"
                        else
                            ENTRY="$(find "$DIRNAME_ENTRY" -name "$BASENAME_ENTRY" 2> /dev/null)"
                        fi
                        if [[ $(echo "$ENTRY" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') -gt 1 ]]
                        then
                            TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-8))
                            echo "`tput setaf 1``tput bold`"$ENTRY_WITH_ASTERISK" gave multiple results, please be more specific with the entry, only using first line of results...`tput sgr0`" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ \ \ \ /g"
                            ENTRY=$(echo "$ENTRY" | head -n 1)
                        else
                            :
                        fi
                        DIRNAME_ENTRY=$(dirname "$ENTRY")
                        BASENAME_ENTRY=$(basename "$ENTRY")
                        if [[ "$ENTRY" == "" ]]
                        then
                            ENTRY="$ENTRY_WITH_ASTERISK"
                            DIRNAME_ENTRY=$(dirname "$ENTRY")
                            BASENAME_ENTRY=$(basename "$ENTRY")
                        else
                            :
                        fi
                    else
                        :
                    fi
                    #echo ENTRY is "$ENTRY"
                    #echo DIRNAME_ENTRY is "$DIRNAME_ENTRY"
                    #echo BASENAME_ENTRY is "$BASENAME_ENTRY"
                    if [[ -e "$ENTRY" ]]
                    then
                        cd "$DIRNAME_ENTRY"
                        mkdir -p "$DESTINATION$DIRNAME_ENTRY"
                        sudo rsync -a "$BASENAME_ENTRY" "$DESTINATION$DIRNAME_ENTRY"
                    else
            			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-8))
                        #echo "        ""$ENTRY" does not exist, skipping...
                        echo ""$BASENAME_ENTRY" does not exist, skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ \ \ \ /g"
                    fi
                else
                    :
                fi
                            
            }

            backup_data_parallel() {         
                # when using env_parallel variables do not have to be exported
                #export DESTINATION
                #export TERMINALWIDTH
                #export HOMEFOLDER
                #export LINENUMBER
                USE_PARALLELS="yes"
                if [[ "$(cat "$BACKUP_RESTORE_LIST")" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "backup_data {}" ::: "$(cat "$BACKUP_RESTORE_LIST")"; fi
                wait
            }
            
            backup_data_sequential() {
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                    backup_data 
                done <<< "$(cat "$BACKUP_RESTORE_LIST")"
            }
            
            run_backup_data() {
                number_of_max_processes
            
                ulimit -n 4096
                
                if [[ $(sysctl hw.model | grep "iMac11,2") != "" ]] || [[ $(sysctl hw.model | grep "iMac12,1") != "" ]] || [[ $(sysctl hw.model | grep "iMac13,1") != "" ]]
            	then
            		backup_data_sequential
            	elif command -v parallel &> /dev/null
            	then
            	    # installed
            	    backup_data_parallel
            	else
            		# not installed
            		backup_data_sequential
            	fi
                
                # resetting terminal settings or further input will not work
                #reset
                #stty "$STTY_ORIG"
                #stty sane
            
                echo ''            
                echo 'copying backup data to '"$DESTINATION"'/ done ;)'
                echo ''
            	
                # moving log to backup directory
                mv "$HOMEFOLDER"/Desktop/backup_restore_log.txt "$DESTINATION"/_backup_restore_log.txt
            
                # compressing and moving backup
                #echo ''
                echo "compressing backup..."
            
                # checking and defining some variables
            	#echo "TARGZSAVEDIR is "$TARGZGPGZSAVEDIR""
                #echo "APPLESCRIPTDIR is "$APPLESCRIPTDIR""
                DESKTOPBACKUPFOLDER="$DESTINATION"
                #echo "DESKTOPBACKUPFOLDER is "$DESKTOPBACKUPFOLDER""
                
                . "$WORKING_DIR"/backup_restore_script/compress_and_move_backup.sh
                wait
                
                # deleting backup folder on desktop
                echo ''
                echo "deleting backup folder on desktop..."
                if [[ -e "$DESTINATION" ]]
                then
                    #:
                    sudo rm -rf "$DESTINATION"
                else
                    :
                fi
                
                WAIT_PIDS=$(ps aux | grep gui_apps_backup.app/Contents | grep -v grep | awk '{print $2;}')
                if [[ "$WAIT_PIDS" == "" ]]; then :; else echo '' && echo "waiting for gui backups to finish..."; fi

            }
            
            
            ### running backups
            run_backups() {
                run_backup_data &
            	sleep 5
            	RUN_WITH_NO_OUTPUT_ON_START="yes"
            	run_files_backup
            	if [[ "$FILES_BACKUP" =~ ^(yes|y)$ ]]; then sleep 15; else :; fi
            	run_vbox_backup
            	if [[ "$BACKUP_VBOX" =~ ^(yes|y)$ ]]; then sleep 15; else :; fi
            	run_utm_backup
            	if [[ "$BACKUP_UTM" =~ ^(yes|y)$ ]]; then sleep 15; else :; fi
            	run_gui_backups
            	wait
            	#if [[ "$CALENDARS_BACKUP" =~ ^(yes|y)$ ]]; then env_collapsing_elements_in_calendar_sidebar; else :; fi
        	}
        	run_backups
        	
        	run_backups_with_gui_first() {
        	    run_gui_backups
        	    #if [[ "$CALENDARS_BACKUP" =~ ^(yes|y)$ ]]; then env_collapsing_elements_in_calendar_sidebar; else :; fi
        	    run_files_backup
            	run_vbox_backup
            	run_utm_backup
                run_backup_data
        	}
        	#run_backups_with_gui_first
            
            
            ### waiting for all scripts to finish before starting update script
            echo ''
            echo "waiting for running backup scripts to finish..."
            
            if [[ "$BACKUP_VBOX" =~ ^(yes|y)$ ]]
            then
                WAIT_PIDS=$(ps aux | grep /virtualbox_backup.sh | grep -v grep | awk '{print $2;}')
                #echo "$WAIT_PIDS"
                #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
                while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"            
            else
                :
            fi
            
            if [[ "$BACKUP_UTM" =~ ^(yes|y)$ ]]
            then
                WAIT_PIDS=$(ps aux | grep /utm_backup.sh | grep -v grep | awk '{print $2;}')
                #echo "$WAIT_PIDS"
                #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
                while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"            
            else
                :
            fi
    
            if [[ "$FILES_BACKUP" =~ ^(yes|y)$ ]]
            then
                #while ps aux | grep /backup_files.sh | grep -v grep > /dev/null; do sleep 1; done
                # or
                #WAIT_PIDS=$(ps -A | grep -m1 /backup_files.sh | awk '{print $1}')
                WAIT_PIDS=$(ps aux | grep /backup_files.sh | grep -v grep | awk '{print $2;}')
                #echo "$WAIT_PIDS"
                #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
                while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
            else
                :
            fi
            
            # done
            #echo ''
            echo 'backup finished ;)'
            osascript -e 'display notification "complete ;)" with title "Backup Script"'
            echo ''


            ### running homebrew update script
            create_tmp_backup_script_fifo2
            echo "updating homebrew formulae and casks..."
        	open "$PATH_TO_APPS"/brew_casks_update.app
        	sleep 2
        	

        	### installing / updating hosts script
        	echo "waiting for updating hosts file, homebrew formulae and casks..."
        	if [[ -e /Library/Scripts/custom/hosts_file_generator.sh ]]
        	then
                # forcing update on next run by setting last modification time of /etc/hosts earlier
                sudo touch -mt 201512010000 /etc/hosts
                sudo /Library/Scripts/custom/hosts_file_generator.sh 2>&1 | grep 'updating hosts file SUCCESSFULL\|FAILED...' &
            else
                echo "/Library/Scripts/custom/hosts_file_generator.sh not found, skipping updating hosts script..."
            fi
        	
        	
        	### waiting for processes to finish
        	#echo ''
        	sleep 2
            #while ps aux | grep brew_casks_update.app/Contents | grep -v grep > /dev/null; do sleep 1; done
            #while ps aux | grep /brew_casks_update.sh | grep -v grep > /dev/null; do sleep 1; done
            #while ps aux | grep /hosts_file_generator.sh | grep -v grep > /dev/null; do sleep 1; done
            WAIT_PIDS=()
            WAIT_PIDS+=$(ps aux | grep brew_casks_update.app/Contents | grep -v grep | awk '{print $2;}')
            WAIT_PIDS+=$(ps aux | grep /brew_casks_update.sh | grep -v grep | awk '{print $2;}')
            #echo "$WAIT_PIDS"
            #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
            while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"   
            WAIT_PIDS=()
            WAIT_PIDS+=$(ps aux | grep /hosts_file_generator.sh | grep -v grep | awk '{print $2;}')
            #echo "$WAIT_PIDS"
            #if [[ "$WAIT_PIDS" == "" ]]; then :; else sudo lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
            while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; sudo lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
            
            #echo ''
            echo "updating hosts file, homebrew formulae and casks finished ;)"
            osascript -e 'display notification "complete ;)" with title "Update Script"'
            echo ''
            
            ###
            ### additional settings and commands
            ###
            
            # disabling siri analytics
            # already done in system settings script before but some apps seam to appear here later
            for i in $(/usr/libexec/PlistBuddy -c "Print CSReceiverBundleIdentifierState" /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
            do
                #echo $i
            	/usr/libexec/PlistBuddy -c "Set CSReceiverBundleIdentifierState:$i false" /Users/"$USER"/Library/Preferences/com.apple.corespotlightui.plist
            done
            
            # disabling local time machine backups and cleaning up possible old ones
            sudo tmutil disable
            # sudo tmutil enable
            
            # force local time machine backup
            #tmutil localsnapshot
            # stop local time machine backup
            #tmutil stopbackup
            # show status of tmutil
            #tmutil status
            
            # list localsnapshots
            #tmutil listlocalsnapshots / | cut -d'.' -f4-
            #tmutil listlocalsnapshots / | rev | cut -d'.' -f1 | rev
            #tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]'
            
            if [[ $(tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]') == "" ]]
            then
                # no local time machine backups found
                :
            else
                #echo ''
                echo "local time machine backups found, deleting..."
                for i in $(tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]')
                do
                	tmutil deletelocalsnapshots "$i"
                done
                echo ''
            fi
            
            # deactivating caffeinate
			env_deactivating_caffeinate
            
            echo ''
            echo "done ;)"
            echo ''
            
            exit
        
        else
            :
        fi
        
        ###
        ### restore
        ###
        
        # place the files from the backup in two folders
        # /Users/USERNAME/Desktop/restore/master/backup_directories (Applications, Library, User)
        # /Users/USERNAME/Desktop/restore/user/backup_directories (Applications, Library, User)
                
        # restore dir
        # restore master dir
        #echo "please select restore master directory..."
        #RESTOREMASTERDIR=$(sudo -H -u "$loggedInUser" osascript "$WORKING_DIR"/backup_restore_script/ask_restore_master_dir.scpt 2> /dev/null | sed s'/\/$//')
        #if [[ $(echo "$RESTOREMASTERDIR") == "" ]]
        #then
        #    echo ''
        #    echo "restoremasterdir is empty - exiting script..."
        #    echo ''
        #    exit
        #else
        #    echo ''
        #    echo 'restoremasterdir for restore is '"$RESTOREMASTERDIR"''
        #    echo ''
        #fi

        # restore user dir
        if [[ "$RESTOREUSERDIR" == "" ]]
        then
            echo "please select restore user directory..."
            RESTOREUSERDIR=$(sudo -H -u "$loggedInUser" osascript "$WORKING_DIR"/backup_restore_script/ask_restore_user_dir.scpt 2> /dev/null | sed s'/\/$//')
            if [[ $(echo "$RESTOREUSERDIR") == "" ]]
            then
                echo ''
                echo "restoreuserdir is empty - exiting script..."
                echo ''
                exit
            else
                echo ''
                echo 'restoreuserdir for restore is '"$RESTOREUSERDIR"''
                echo ''
            fi
        else
            :
        fi
        
        #echo ''
        #echo restoredir for restore is "$RESTOREDIR"
        
        #RESTORETODIR="$HOMEFOLDER"/Desktop/testrestore
        #mkdir -p "$RESTORETODIR"
        RESTORETODIR=""
        
        # checking if restore option was selected
        if [[ "$OPTION" == "RESTORE" ]]; 
            then
            echo "running restore..."
        
            # master user restore directory
            MASTERUSER=$(ls "$RESTOREMASTERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared" | head -n 1 )
            echo masteruser for restore is "$MASTERUSER"
        
            # user from restore directory
            USERUSER=$(ls "$RESTOREUSERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared" | head -n 1 )
            echo useruser for restore is "$USERUSER"
        
            # user to restore to
            echo user to restore to is "$SELECTEDUSER"
            #echo ''
            
            # casks install
            #VARIABLE_TO_CHECK="$INSTALL_CASKS"
            #QUESTION_TO_ASK="do you want to backup virtualbox images (y/N)? "
            #env_ask_for_variable
            #INSTALL_CASKS="$VARIABLE_TO_CHECK"
            #sleep 0.1
            
            # stopping services and backing up files
            STOP_CALENDAR_REMINDER_SERVICES="yes" STOP_ACCOUNTSD="yes" STOP_CUPSD="yes" env_stopping_services
            echo ''
            
            
            ### running restore
            echo "restoring..."
            echo ''
            
            BACKUP_RESTORE_LIST="$WORKING_DIR"/list/backup_restore_list.txt
            #STTY_ORIG=$(stty -g)
            #TERMINALWIDTH=$(echo $COLUMNS)
            #TERMINALWIDTH=$(stty size | awk '{print $2}')
            TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
            LINENUMBER=0
            
            ### paths to applications
            MACOS_VERSION_MAJOR_BACKUP_SYSTEM=$(cat "$RESTOREUSERDIR"/_backup_macos_version.txt | cut -f1,2 -d'.')
            VERSION_TO_CHECK_AGAINST=10.14
            if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR_BACKUP_SYSTEM") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
            then
                # macos versions until and including 10.14
                PATH_TO_APPS_BACKUP_SYSTEM="/Applications"
            else
                # macos versions 10.15 and up
                PATH_TO_APPS_BACKUP_SYSTEM="/System/Volumes/Data/Applications"
            fi
            #echo "PATH_TO_APPS_BACKUP_SYSTEM is "$PATH_TO_APPS_BACKUP_SYSTEM""
            #echo "PATH_TO_APPS is "$PATH_TO_APPS""
                        
            restore_data() {
                
                if [[ "$USE_PARALLELS" == "yes" ]]
                then
                    line="$1"
                    #echo "$line"
                else
                    :
                fi
                
                LINENUMBER=$((LINENUMBER+1))
            	
                # if starting with one # and whitespace / tab
            	#if [[ $line =~ ^[\#][[:blank:]] ]]
            	
            	# if starting with more than one #
            	#if [[ $line =~ ^[\#]{2,} ]]
            
            	# if line is empty
            	#if [ -z "$line" ]
            	
            	if [[ "$line" == "" ]]
            	then
                    :
                else
                    :
                fi
            	
            	# if starting with #
            	if [[ "$line" =~ ^[\#] ]]
            	then
                    :
                else
                    :
                fi
                
                # if starting with echo and whitespace / tab
            	if [[ "$line" =~ ^echo[[:blank:]] ]]
            	then
                    OUTPUT=$(echo "$line" | sed 's/^echo*//' | sed -e 's/^[ \t]*//')
        			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-5))
                    echo "$OUTPUT" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                else
                    :
                fi
                    	
            	# if starting with m and space / tab
            	if [[ "$line" =~ ^m[[:blank:]] ]]
            	then
            	    LOWERCASESECTION=master
                    SECTIONUSER="$MASTERUSER"
                    RESTORESECTIONDIR="$RESTOREMASTERDIR"
                else
                    :
                fi
                
                # if starting with u and space / tab
                if [[ "$line" =~ ^u[[:blank:]] ]]
            	then
            	    LOWERCASESECTION=user
                    SECTIONUSER="$USERUSER"
                    RESTORESECTIONDIR="$RESTOREUSERDIR"
                else
                    :
                fi
                
             	# if starting with m and space / tab or with u and space / tab
            	if [[ "$line" =~ ^m[[:blank:]] ]] || [[ "$line" =~ ^u[[:blank:]] ]]
            	then
                    ENTRY=$(echo "$line" | cut -f2 | sed -e 's/[ /]\{2,\}/\//')
                    if [[ "$ENTRY" =~ [*] ]]
                    # or
                    #if [[ $(echo "$ENTRY" | egrep '[*]') != "" ]]		# working
			        #if [[ $(echo "$ENTRY" | grep '[*]') != "" ]]		# working
                    then
                        ENTRY_WITH_ASTERISK="$ENTRY"
                        ENTRY_FROM=$(echo "$ENTRY" | sed 's|~|'"/Users/$SECTIONUSER"'|' | sed 's|"$PATH_TO_APPS"|'"$PATH_TO_APPS_BACKUP_SYSTEM"'|')
                        RESTORE_FROM=$(echo "$RESTORESECTIONDIR$ENTRY_FROM")
                        DIRNAME_RESTORE_FROM=$(dirname "$RESTORE_FROM")
                        #echo DIRNAME_RESTORE_FROM is "$DIRNAME_RESTORE_FROM"
                        BASENAME_RESTORE_FROM=$(basename "$RESTORE_FROM")
                        #echo BASENAME_RESTORE_FROM is "$BASENAME_RESTORE_FROM"
                        if [[ "$DIRNAME_RESTORE_FROM" =~ [*] ]]
                        then
                            ROOTDIR_PATH="$RESTORESECTIONDIR"
                            #echo ROOTDIR_PATH is "$ROOTDIR_PATH"
                            ENTRY_RESTORE_FROM="$(find "$ROOTDIR_PATH" -path "$DIRNAME_RESTORE_FROM" -name "$BASENAME_RESTORE_FROM" 2> /dev/null)"
                        else
                            ENTRY_RESTORE_FROM="$(find "$DIRNAME_RESTORE_FROM" -mindepth 1 -maxdepth 1 -name "$BASENAME_RESTORE_FROM" 2> /dev/null)"
                        fi
                        if [[ $(echo "$ENTRY_RESTORE_FROM" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') -gt 1 ]]
                        then
                            TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-8))
                            echo -e "\033[1;31m$ENTRY_WITH_ASTERISK gave multiple results, please be more specific with the entry, only using first line of results...\033[0m" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ \ \ \ /g"
                            ENTRY_RESTORE_FROM=$(echo "$ENTRY_RESTORE_FROM" | head -n 1)
                        else
                            :
                        fi
                        ENTRY=$(echo "$ENTRY_RESTORE_FROM" | sed 's|'"^$RESTORESECTIONDIR"'||' | sed 's|'"^/Users/$SECTIONUSER"'|~|' | sed 's|"$PATH_TO_APPS"|'"$PATH_TO_APPS"'|')
                        if [[ "$ENTRY" == "" ]]
                        then
                            ENTRY="$ENTRY_WITH_ASTERISK"
                        else
                            :
                        fi
                    else
                        :
                    fi
                    #echo ENTRY is "$ENTRY"
                    #
                    ENTRY_FROM=$(echo "$ENTRY" | sed 's|~|'"/Users/$SECTIONUSER"'|' | sed 's|"$PATH_TO_APPS"|'"$PATH_TO_APPS_BACKUP_SYSTEM"'|')
                    ENTRY_TO=$(echo "$ENTRY" | sed 's|~|'"$HOMEFOLDER"'|' | sed 's|"$PATH_TO_APPS"|'"$PATH_TO_APPS"'|')
                    #
                    RESTORE_FROM=$(echo "$RESTORESECTIONDIR$ENTRY_FROM")
                    RESTORE_TO=$(echo "$RESTORETODIR$ENTRY_TO")
                    #
                    DIRNAME_RESTORE_FROM=$(dirname "$RESTORE_FROM")
                    #echo "$DIRNAME_RESTORE_FROM"
                    BASENAME_RESTORE_FROM=$(basename "$RESTORE_FROM")
                    #echo "$DIRNAME_RESTORE_FROM"
                    DIRNAME_RESTORE_TO=$(dirname "$RESTORE_TO")
                    #echo "$DIRNAME_RESTORE_TO"
                    BASENAME_RESTORE_TO=$(basename "$RESTORE_TO")
                    #
                    TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-5))
                    #
                    if [[ -e "$RESTORE_FROM" ]]
                    then
                        sudo mkdir -p "$DIRNAME_RESTORE_TO"
                        if [[ -e "$DIRNAME_RESTORE_TO" ]]
                        then
                            if [[ -e "$RESTORE_TO" ]]
                            then
                                cd "$DIRNAME_RESTORE_TO"
                                sudo rm -rf "$BASENAME_RESTORE_TO"
                            else
                                :
                            fi
                            cd "$DIRNAME_RESTORE_FROM"
                            echo "$RESTORE_FROM" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo "to ""$RESTORE_TO" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                            echo '     '
                            sudo rsync -a "$BASENAME_RESTORE_FROM" "$DIRNAME_RESTORE_TO"
                        else
                            echo ""$DIRNAME_RESTORE_TO" does not exist, skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                        fi
                    else
                        echo "no "$ENTRY_FROM" in "$LOWERCASESECTION" backup - skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/\ \ \ \ \ /g"
                        echo ''
                    fi
                else
                    :
                fi
                                
            }
            
            number_of_max_processes
            
            ulimit -n 4096
            
            restore_data_parallel() {
                # when using env_parallel variables do not have to be exported
                #export RESTOREMASTERDIR
                #export RESTOREUSERDIR
                #export RESTORETODIR
                #export DESTINATION
                #export HOMEFOLDER
                #export MASTERUSER
                #export USERUSER
                #export TERMINALWIDTH
                #export LINENUMBER
                USE_PARALLELS="yes"
                if [[ "$(cat "$BACKUP_RESTORE_LIST")" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "restore_data {}" ::: "$(cat "$BACKUP_RESTORE_LIST")"; fi
                wait
            }
            
            restore_data_sequential() {
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                    restore_data 
                done <<< "$(cat "$BACKUP_RESTORE_LIST")"
            }
            
            if [[ $(sysctl hw.model | grep "iMac11,2") != "" ]] || [[ $(sysctl hw.model | grep "iMac12,1") != "" ]] || [[ $(sysctl hw.model | grep "iMac13,1") != "" ]]
        	then
        		restore_data_sequential
        	elif command -v parallel &> /dev/null
        	then
        	    # installed
        	    restore_data_parallel
        	else
        		# not installed
        		restore_data_sequential
        	fi

            # resetting terminal settings or further input will not work
            #reset
            #stty "$STTY_ORIG"
            stty sane
        
            #echo ""
            echo "restore done ;)"
        
            ### cleaning up old unused files after restore
            echo ''
            echo "cleaning up some files..."
            
            # restore dir
            if [[ -e "$RESTOREUSERDIR" ]]
            then
                sudo rm -rf "$RESTOREUSERDIR"
            else
                :
            fi
        
            # virtualbox extpack
            if [[ -e "$HOMEFOLDER"/Library/VirtualBox ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	VBOXEXTENSIONS="$line"
                	#echo "$VBOXEXTENSIONS"
                    sudo rm "$VBOXEXTENSIONS"
                done <<< "$(find "$HOMEFOLDER"/Library/VirtualBox -name "*.vbox-extpack" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d)"
            else
                :
            fi
        
            # virtualbox logs
            if [[ -e "$HOMEFOLDER"/Library/VirtualBox ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	VBOXLOGS="$line"
                	#echo "$VBOXLOGS"
                    sudo rm "$VBOXLOGS"
                done <<< "$(find "$HOMEFOLDER"/Library/VirtualBox -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat)"
            else
                :
            fi
        
            # fonts
            if [[ -e "$HOMEFOLDER"/Library/Fonts ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	FONTSFILES="$line"
                	#echo "$FONTSFILES"
                    sudo rm "$FONTSFILES"
                done <<< "$(find "$HOMEFOLDER"/Library/Fonts \( -name "*.dir" -o -name "*.list" -o -name "*.scale" \) -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat)"
            else
                :
            fi
        
            # jameica backups
            if [[ -e "$HOMEFOLDER"/Library/jameica ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	JAMEICABACKUPS="$line"
                	#echo "$JAMEICABACKUPS"
                    sudo rm "$JAMEICABACKUPS"
                done <<< "$(find "$HOMEFOLDER"/Library/jameica -name "jameica-backup-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d)"
            else
                :
            fi
                   
            # jameica logs
            if [[ -e "$HOMEFOLDER"/Library/jameica ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	JAMEICALOGS="$line"
                	#echo "$JAMEICALOGS"
                    sudo rm "$JAMEICALOGS"
                done <<< "$(find "$HOMEFOLDER"/Library/jameica -name "jameica.log-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d)"
            else
                :
            fi
                    
            # address book migration
            if [[ -e "$HOMEFOLDER"/Library/"Application Support"/AddressBook ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	ADDRESSBOOKMIGRATION="$line"
                	#echo "$ADDRESSBOOKMIGRATION"
                    sudo rm "$ADDRESSBOOKMIGRATION"
                done <<< "$(find "$HOMEFOLDER"/Library/"Application Support"/AddressBook -name "Migration*.abbu.tbz" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat)"
            else
                :
            fi
                    
            # 2do
            if [[ -e "$HOMEFOLDER"/Library/"Application Support"/Backups ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	TODOBACKUPS="$line"
                	#echo "$TODOBACKUPS"
                    sudo rm "$TODOBACKUPS"
                done <<< "$(find "$HOMEFOLDER"/Library/"Application Support"/Backups -name "*.db" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,2d)"
            else
                :
            fi
            
            # unified remote
            if [[ -e "$HOMEFOLDER"/Library/"Application Support"/"Unified Remote" ]]
            then
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                	UNIFIEDREMOTELOGS="$line"
                	#echo "$UNIFIEDREMOTELOGS"
                    sudo rm "$UNIFIEDREMOTELOGS"
                done <<< "$(find "$HOMEFOLDER"/Library/"Application Support"/"Unified Remote" -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat)"
            else
                :
            fi
            
            # whatsapp
            WHATSAPP_DIR="/Users/"$USER"/Library/Application Support/WhatsApp/"
            if [[ -e "$WHATSAPP_DIR" ]]
            then
                #:
                #find ""$WHATSAPP_DIR"/" -name "main-process.log*" -print0 | xargs -0 rm -rf
                #sudo rm -rf ""$WHATSAPP_DIR"/WhatsApp/Cache/"
                sudo rm -rf "$WHATSAPP_DIR"
            else
                :
            fi
            
            # telegram
            if [[ -e "/Users/"$USER"/Library/Application Support/Telegram/" ]]
            then
                rm -rf "/Users/"$USER"/Library/Application Support/Telegram/exports/"
                rm -rf "/Users/"$USER"/Library/Application Support/Telegram/logs/"
            else
                :
            fi
            # Caches/ru.keepcoder.Telegram/* not included in backup / restore
            # rm -rf "/Users/"$USER"/Library/Caches/ru.keepcoder.Telegram/"
            # postbox/media/* not included in backup / restore
            #find "/Users/"$USER"/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/" -name "media" -type d -print0 | xargs -0 rm -rf
            # after deleting postbox/db/* or accounts-metadata the computer has to be reregistered with phone number
            #rm -rf "/Users/"$USER"/Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/"account-*"/postbox/db/"
            
            # signal
            if [[ -e "/Users/"$USER"/Library/Application Support/Signal/" ]]
            then
                if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "macintosh_hd2" ]]
                then
                    # remove everything and start clean as of 2023-09 signal does not have a sync or backup/restore function for the signal desktop app
                    # data is stored in
                    # ~/Library/Application Support/Signal/sql/db.sqlite
                    # access to database
                    # sqlcipher ~"/Library/Application Support/Signal/sql/db.sqlite"
                    # .tables results in file is not a database
                    # decrypt database
                    # PRAGMA key = "x'<key from config.json>'";
                    # .tables (or other commands)
                    rm -rf "/Users/"$USER"/Library/Application Support/Signal/"
                else
                    rm -rf "/Users/"$USER"/Library/Application Support/Signal/logs/"
                fi
                
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/__update__"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/attachments.noindex"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/Cache/"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/databases/"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/GPUCache/"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/IndexedDB/"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/Local Storage/"
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/logs/"
                #find "/Users/"$USER"/Library/Application Support/Signal/" -name "QuotaManager*" -print0 | xargs -0 rm -rf
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/sql/"
                #
                #rm -rf "/Users/"$USER"/Library/Application Support/Signal/"
                #
                #find "/Users/"$USER"/Library/Application Support/Signal/" ! -name "IndexedDB" ! -name "sql" ! -name "config.json" ! -name "ephemeral.json" ! -name "attachments.noindex" -print0 -mindepth 1 -maxdepth 1 | xargs -0 rm -rf
                #
                # not needed if no files are deleted above
                #if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
                #then
                #    :
                #else
                #    osascript -e 'tell app "System Events" to display dialog "please unlink all devices from signal on ios before opening the macos desktop app..."' &
                #fi
            else
                :
            fi
        
            echo "cleaning done ;)"
            
            # post restore operations
            echo ''
            echo "running post restore operations..."
            
            # update services menu entries in all apps
            /System/Library/CoreServices/pbs -flush
            
            # enabling services
            START_ACCOUNTSD="yes" START_CUPSD="yes" env_starting_services
            # accountsd needs to run before re-enabling the calendar services in order for all calendars to appear
            # env_starting_services includes an additional a 5s waiting time
            sleep 5
            START_CALENDAR_REMINDER_SERVICES="yes" env_starting_services
            # giving macos time to convert calendars to new format
            if [[ "$MACOS_VERSION_MAJOR" == "13" ]]
            then
                WAITING_TIME=60
            	NUM1=0
            	#echo ''
            	echo ''
            	while [[ "$NUM1" -le "$WAITING_TIME" ]]
            	do 
            		NUM1=$((NUM1+1))
            		if [[ "$NUM1" -le "$WAITING_TIME" ]]
            		then
            			#echo "$NUM1"
            			sleep 1
            			tput cuu 1 && tput el
            			echo "waiting $((WAITING_TIME-NUM1)) to give macos time to convert calendars to new format..."
            		else
            			:
            		fi
            	done
            else
                :
            fi
            echo ''
            
            ### casks install
            if [[ "$INSTALL_CASKS" =~ ^(yes|y)$ ]]
            then
                echo ""
                echo "installing casks..."
                create_tmp_homebrew_script_fifo
                # this has to run in a new shell due to variables, functions, etc.
                # so do not source this script
                # tee does not capture the output format, so e.g. you can not see the download progress of casks, use scripts command to keep output formats
                #"$SCRIPT_INTERPRETER" -c """$WORKING_DIR_FINAL""/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/5_casks.sh"
                # parentheses put script in subshell - this works with subprocess killing functions
                # exec and "$SCRIPT_INTERPRETER" -c output terminations of sleep 60 from start sudo at the end
                ( "$WORKING_DIR_FINAL"/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/5_casks.sh )
                wait
            else
                :
            fi

            ### ownership and permissions
            #echo ''
            echo "setting ownerships and permissions..."
            export RESTOREMASTERDIR
            export RESTOREUSERDIR
            . "$WORKING_DIR"/permissions/ownerships_and_permissions_restore.sh
            #wait
            
            echo ''
            echo "done ;)"
            
            if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
            then
                tput cuu 2
            else
                echo '' 
                osascript -e 'tell app "loginwindow" to «event aevtrrst»'           # reboot
                #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'          # shutdown
                #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'          # logout
            fi
        else
            :
        fi
        #
    else
        echo "user home directory does not exist - exiting script..."
        exit
    fi

}


if [[ "$OPTION" == "BACKUP" ]]
then
    # script is run with
	# export OPTION=RESTORE; time "$WORKING_DIR"/backup_restore_script/backup_restore_script_mac.sh
    # tee does not capture the output format, so e.g. you couldn`t see the download progress of casks
    backup_restore | tee "$HOME"/Desktop/backup_restore_log.txt
elif [[ "$OPTION" == "RESTORE" ]]
then
    # script is run with
    # export OPTION=RESTORE; time script -q ~/Desktop/backup_restore_log.txt "$WORKING_DIR"/backup_restore_script/backup_restore_script_mac.sh
    # to read the output file including formats do
    # cat ~/Desktop/backup_restore_log.txt
    backup_restore
else
    :
fi

###
### unsetting password
###

# unsetting varibales and cleaning bash environment
unset_variables   

# kill all child and grandchild processes and the parent process itself
#ps -o pgid= $$ | grep -o '[0-9]*'
#kill -9 -$(ps -o pgid= $$ | grep -o '[0-9]*') 1> /dev/null


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


exit

