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
    else
        env_enter_sudo_password
        unset -f sudo
    fi
else
    :
fi

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
# can not be used in untar pipe "| sudo gtar", use start_sudo with env_use_password instead

# getting logged in user and unique id
# done in config file



###
### traps
###

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    trap_function_exit_middle() { env_stop_sudo; unset GPG_PASSWORD; }
else
    trap_function_exit_middle() { env_stop_sudo; unset GPG_PASSWORD; env_deactivating_keepingyouawake; }
fi
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"



###
### checking installation of needed tools
###

echo ''
echo "checking if all needed tools are installed..."

# installing command line tools
if xcode-select --install 2>&1 | grep installed >/dev/null
then
  	echo command line tools are installed...
else
  	echo command line tools are not installed, installing...
  	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
  	#sudo xcodebuild -license accept
fi

# checking homebrew including script dependencies
if command -v brew &> /dev/null
then
	# installed
    echo "homebrew is installed..."
    # checking for missing dependencies
    for formula in gnu-tar pigz pv coreutils parallel gnupg
    do
    	if [[ $(brew list | grep "^$formula$") == '' ]]
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
        echo "at least one needed homebrew tools of gnu-tar, pigz, pv, coreutils, parallel, and gnupg is missing, exiting..."
        exit
    else
        echo "needed homebrew tools are installed..." 
    fi
    unset MISSING_SCRIPT_DEPENDENCY
else
    # not installed
    echo "homebrew is not installed, exiting..."
    exit
fi            


###
### decrypting and unarchiving
###

# this script finds all .tar.gz.gpg files in the folder where the script is located,
# decrypts and unarchives them if they have the same password
# if there are multiple files

# gpg password
if [[ "$GPG_PASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_gpg_fifo ]]
    then
        unset GPG_PASSWORD
        GPG_PASSWORD=$(cat "/tmp/tmp_batch_script_gpg_fifo" | head -n 1)
        USE_GPG_PASSWORD='builtin printf '"$GPG_PASSWORD\n"''
        env_delete_tmp_batch_script_gpg_fifo
    else
        while [[ $GPG_PASSWORD != $GPG_PASSWORD2 ]] || [[ $GPG_PASSWORD == "" ]]; do stty -echo && printf "gpg decryption password: " && read -r "$@" GPG_PASSWORD && printf "\n" && printf "re-enter gpg decryption password: " && read -r "$@" GPG_PASSWORD2 && stty echo && printf "\n" && USE_GPG_PASSWORD='builtin printf '"$GPG_PASSWORD\n"''; done
    fi
else
    :
fi


NUMBER_OF_CORES=$(parallel --number-of-cores)
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
#echo $NUMBER_OF_MAX_JOBS_ROUNDED

env_start_sudo

decrypt_and_unarchive_sequential() {
    
    echo "decrypting and unarchiving is set to sequential mode..."
    #echo ''
     
    while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
        item="$line"
        echo ''
        env_activating_keepingyouawake
    	echo "decrypting and unarchiving..."
    	echo "$item"
    	echo to "$SCRIPT_DIR"/
    	# only needed if password is not passed via --passphrase
    	#export GPG_TTY=$(tty)
    	#export PINENTRY_USER_DATA='USE_CURSES=1'
    	cat "$item" | pv -f -s $(gdu -scb "$item" | tail -1 | awk '{print $1}' | grep -o "[0-9]\+") | gpg --batch --passphrase="$GPG_PASSWORD" --quiet -d - | unpigz -dc - | sudo gtar --same-owner -C "$SCRIPT_DIR" -xpf - >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m" >&2
    done <<< "$(find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -name '*.tar.gz.gpg')"
        
}
decrypt_and_unarchive_sequential


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
#echo ''
  
exit
