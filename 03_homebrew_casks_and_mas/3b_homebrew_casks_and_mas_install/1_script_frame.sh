#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" != "" ]]
then
    #USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    :
else
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
    elif [[ -e /tmp/tmp_sudo_mas_script_fifo ]]
    then
        :
    elif [[ -e /tmp/tmp_sudo_cask_script_fifo ]]
    then
        :
    else
        env_enter_sudo_password
    fi
fi


# redefining sudo so it is possible to run homebrew install without entering the password again
env_sudo_homebrew


###
### functions
###

unset_variables() {
    unset FIRST_RUN_DONE
    unset SUDOPASSWORD
    unset SUDO_PID
    unset CHECK_IF_CASKS_INSTALLED
    unset CHECK_IF_FORMULAE_INSTALLED
    unset CHECK_IF_MASAPPS_INSTALLED
    unset INSTALLATION_METHOD
    unset KEEPINGYOUAWAKE
}

# fifo functions are part of config file



###
### script
###

### trapping
if [[ "$RUN_FROM_RUN_ALL_SCRIPT" == "yes" ]] || [[ "$SCRIPT_IS_SESSION_MASTER" == "no" ]]
then
    # do not stop keeping you awake in the scripts executed by run_all in separate tabs
    #echo "no stopping of keepingyouawake..."
    # script is not session master and run from another script (S+ on mac and linux)
    # deleting of fifos added in the separate scripts
    # do not kill ruby here as formulae, caks and mas run parallel if using run_all
    trap_function_exit_middle() { env_stop_sudo; stty sane; unset SUDOPASSWORD; unset USE_PASSWORD; }
    trap_function_exit_end() { :; }
else
    # script is session master and not run from another script (S on mac Ss on linux)
    trap_function_exit_middle() { env_stop_sudo; stty sane; unset SUDOPASSWORD; unset USE_PASSWORD; env_deactivating_caffeinate >/dev/null 2>&1; }
    #trap_function_exit_middle() { env_stop_sudo; stty sane; pkill ruby; unset SUDOPASSWORD; env_deactivating_caffeinate >/dev/null 2>&1; }
    #trap_function_exit_end() { :; }
fi
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"


### security permissions
#echo ''
if [[ "$RUN_FROM_RUN_ALL_SCRIPT" == "yes" ]] || [[ "$SCRIPT_IS_SESSION_MASTER" == "no" ]]
then
    :
else
    echo ''
    env_databases_apps_security_permissions
    env_identify_terminal
    
    echo "setting security and automation permissions..."
    
    ### security permissions
	APPS_SECURITY_ARRAY=(
    # app name									security service										    allowed (1=yes, 0=no)
	"$SOURCE_APP_NAME                           kTCCServiceAccessibility                             	    1"
	"$SOURCE_APP_NAME                           kTCCServiceSystemPolicyAllFiles                             1"
	)
	PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions
    
    
    ### automation
    # macos versions 10.14 and up
    AUTOMATION_APPS=(
    # source app name							automated app name										    allowed (1=yes, 0=no)
    "$SOURCE_APP_NAME                           System Events                                               1"
    "$SOURCE_APP_NAME                           Finder                                                      1"
    "$SOURCE_APP_NAME                           $SYSTEM_GUI_SETTINGS_APP                                    1"
    )
    PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions
    #echo ''
fi


### checking if online
#echo ''
if [[ "$RUN_FROM_RUN_ALL_SCRIPT" == "yes" ]] || [[ "$SCRIPT_IS_SESSION_MASTER" == "no" ]]
then
    :
else
    env_check_if_online
    if [[ "$ONLINE_STATUS" == "online" ]]
    then
        # online
        :
    else
        # offline
        echo "exiting..."
        echo ''
        exit
    fi
    #echo ''
fi

### more variables
# keeping hombrew from updating each time brew install is used
HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_AUTO_UPDATE
# number of max parallel processes
NUMBER_OF_CORES=$(sysctl hw.ncpu | awk '{print $NF}')
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
#NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
# due to connection issues with too many downloads at the same time limiting the maximum number of jobs for now
NUMBER_OF_MAX_JOBS_ROUNDED=6
#echo $NUMBER_OF_MAX_JOBS_ROUNDED


### checking if homebrew is installed
checking_homebrew() {
    if command -v brew &> /dev/null
    then
        # installed
        :
    else
        # not installed      
        if [[ -e "$SCRIPT_DIR"/3_homebrew_cask.sh ]]
        then
            . "$SCRIPT_DIR"/3_homebrew_cask.sh
        else
            echo ''
            echo "homebrew and install script are missing, exiting..."
            echo ''
            exit
        fi
    fi
}
# done in scripts
#checking_homebrew
