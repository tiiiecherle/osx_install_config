#!/bin/zsh

###
### config file
###

sh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"


###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### variables
###

SCRIPTS_FINAL_DIR="$SCRIPT_DIR_ONE_BACK"
env_identify_terminal



###
### config file 1
###

# installing again if local file is different from online file
printf "\n${bold_text}###\nconfig file...\n###\n${default_text}"
"$SCRIPTS_FINAL_DIR"/_config_file/install_config_file.sh

# re-sourcing config file
if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

printf "\n${bold_text}###\nsudo password...\n###\n${default_text}"
echo ''
echo "please enter sudo password..."
env_enter_sudo_password
#env_start_sudo

# env_delete_tmp_batch_script_fifo and env_delete_tmp_batch_script_gpg_fifo are part of config file



###
### functions
###

create_tmp_batch_script_fifo() {
    env_delete_tmp_batch_script_fifo
    mkfifo -m 600 "/tmp/tmp_batch_script_fifo"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_batch_script_fifo" &
    #echo "$SUDOPASSWORD" > "/tmp/tmp_sudo_cask_script_fifo" &
}

create_tmp_batch_script_gpg_fifo() {
    env_delete_tmp_batch_script_gpg_fifo
    mkfifo -m 600 "/tmp/tmp_batch_script_gpg_fifo"
    builtin printf "$GPG_PASSWORD\n" > "/tmp/tmp_batch_script_gpg_fifo" &
    #echo "$GPG_PASSWORD" > "/tmp/tmp_sudo_cask_script_fifo" &
}



###
### trap
###

trap_function_exit_middle() { env_delete_tmp_batch_script_fifo; env_delete_tmp_batch_script_gpg_fifo; unset SUDOPASSWORD; unset USE_PASSWORD; env_deactivating_keepingyouawake; rm -f "/tmp/batch_script_in_progress" }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"



###
### batch script part 2
###


### in addition to showing them in terminal write errors to logfile when run from batch script
touch "/tmp/batch_script_in_progress"
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi


### security permissions
echo ''
printf "\n${bold_text}###\nsecurity permissions...\n###\n${default_text}"
echo ''
env_databases_apps_security_permissions
env_identify_terminal

echo "setting security and automation permissions..."
### automation
# macos versions 10.14 and up
AUTOMATION_APPS=(
# source app name							automated app name										    allowed (1=yes, 0=no)
"$SOURCE_APP_NAME                           System Events                                               1"
"$SOURCE_APP_NAME                           Finder                                                      1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions
echo ''


### homebrew install
if command -v brew &> /dev/null
then
    # installed
    printf "\n${bold_text}###\nhomebrew already installed...\n###\n${default_text}"
    echo ''
    echo "homebrew is already installed..."
    VARIABLE_TO_CHECK="$UNINSTALL_HOMEBREW"
    QUESTION_TO_ASK="do you want to uninstall homebrew and start cleanly? (Y/n)? "
    env_ask_for_variable
    UNINSTALL_HOMEBREW="$VARIABLE_TO_CHECK"
    echo ''
    if [[ "$UNINSTALL_HOMEBREW" =~ ^(yes|y)$ ]]
    then
    	create_tmp_batch_script_fifo
		"$SCRIPTS_FINAL_DIR"/03_homebrew_casks_and_mas/3a_homebrew_casks_and_command_line_tools_uninstall.sh
		#echo ''
    else
    	:
    fi
else
    # not installed
    :
fi

run_batch_one_and_two() {
    ### running batch script 1 & 2 without reboot
    echo ''
    VARIABLE_TO_CHECK="$BATCH_ONE_AND_TWO"
    QUESTION_TO_ASK="do you want to run batch script 1 & 2 at once without reboot? (Y/n)? "
    env_ask_for_variable
    BATCH_ONE_AND_TWO="$VARIABLE_TO_CHECK"
    echo ''
}
# as teh keychain is restored with batch one a reboot is recommended before continuing
#run_batch_one_and_two


### batch run all function
batch_run_all() {

	### silencing sounds
	osascript -e "set Volume 0"
	

	### asking for restore directories
	printf "\n${bold_text}###\nasking restore directories for files...\n###\n${default_text}"
	RESTORE_FILES_OPTION="ask_for_restore_directories"
	. "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/files/restore_files.sh
	unset RESTORE_FILES_OPTION
	if [[ "$RESTORE_DIR_FILES" == "" ]]
	then
		echo "no directory for restoring files selected, respective scripts will be skipped..."
	else
		echo ''
		VARIABLE_TO_CHECK="$GPG_SUDO_PASSWORD"
	    QUESTION_TO_ASK="is your sudo password identical to the backup decryption password? (Y/n)? "
	    env_ask_for_variable
	    GPG_SUDO_PASSWORD="$VARIABLE_TO_CHECK"
	    echo ''
	    if [[ "$GPG_SUDO_PASSWORD" =~ ^(yes|y)$ ]]
	    then
	    	GPG_PASSWORD="$SUDOPASSWORD"
	    else
	    	while [[ $GPG_PASSWORD != $GPG_PASSWORD2 ]] || [[ $GPG_PASSWORD == "" ]]; do stty -echo && printf "gpg decryption password: " && read -r "$@" GPG_PASSWORD && printf "\n" && printf "re-enter gpg decryption password: " && read -r "$@" GPG_PASSWORD2 && stty echo && printf "\n" && USE_GPG_PASSWORD='builtin printf '"$GPG_PASSWORD\n"''; done
	    fi
	fi
	if [[ "$RESTORE_DIR_VBOX" == "" ]]
	then
		echo "no directory for restoring vbox selected, respective scripts will be skipped..."
	else
		:
	fi
	echo ''
	
	
	### homebrew and cask install
	printf "\n${bold_text}###\nhomebrew cask...\n###\n${default_text}"
	create_tmp_batch_script_fifo
	open "$SCRIPTS_FINAL_DIR"/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/0_run_all.command
	sleep 3
	
	# waiting for respective homebrew formulae before starting to unarchive the backup files
	echo ''
	echo "waiting for respective homebrew formulae before starting to unarchive the backup files..."
	echo ''
	checking_dependencies() {
		if command -v brew &> /dev/null
		then
			# installed
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
		else
		    # not installed
		    MISSING_SCRIPT_DEPENDENCY="yes"
		fi
	}
	
	MISSING_SCRIPT_DEPENDENCY=""
	checking_dependencies
	while [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
	do
		MISSING_SCRIPT_DEPENDENCY=""
		sleep 30
		checking_dependencies
	done
	
	
	### creating symlinks
	printf "\n${bold_text}###\ncreating symlinks...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/02_preparations/symbolic_links_testvolume_macos_beta.sh
	
	
	### unarchiving and restoring files
	if [[ "$RESTORE_DIR_FILES" == "" ]]
	then
		:
	else
		printf "\n${bold_text}###\nunarchiving and restoring files...\n###\n${default_text}"
		create_tmp_batch_script_fifo
		create_tmp_batch_script_gpg_fifo
		#time ASK_FOR_RESTORE_DIRS="no" RESTORE_FILES_OPTION="unarchive" RESTORE_DIR_FILES="$RESTORE_DIR_FILES" RESTORE_DIR_VBOX="$RESTORE_DIR_VBOX" RESTORE_VBOX="$RESTORE_VBOX" "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/files/restore_files.sh
		ASK_FOR_RESTORE_DIRS="no" RESTORE_FILES_OPTION="unarchive" RESTORE_DIR_FILES="$RESTORE_DIR_FILES" RESTORE_DIR_VBOX="$RESTORE_DIR_VBOX" RESTORE_VBOX="$RESTORE_VBOX" "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/files/restore_files.sh
		unset RESTORE_FILES_OPTION
		sleep 1
		env_active_source_app
		env_activating_keepingyouawake
	fi
	
	
	### waiting for running processes to finish
	#echo ''
	echo "waiting for running processes to finish..."
	#echo ''
	sleep 3
	WAIT_PIDS=()
	WAIT_PIDS+=$(ps aux | grep /0_run_all.command | grep -v grep | awk '{print $2;}')
	#WAIT_PIDS+=$(ps aux | grep /restore_files.sh | grep -v grep | awk '{print $2;}')
	#echo "$WAIT_PIDS"
	#if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
	while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
	sleep 1
	env_active_source_app
	env_activating_keepingyouawake
	
	
	### login shell customization
	printf "\n${bold_text}###\nlogin shell customization...\n###\n${default_text}"
	create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/02_preparations/2d_login_shell_customization.sh
	
	
	### nvram
	printf "\n${bold_text}###\nnvram...\n###\n${default_text}"
	create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/01_recovery_settings_and_nvram/1b_nvram.sh
	
	
	### system update
	printf "\n${bold_text}###\nsystem update...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/02_preparations/2a_system_update.sh
	
	
	### network configuration
	printf "\n${bold_text}###\nnetwork configuration...\n###\n${default_text}"
	create_tmp_batch_script_fifo
	RUN_WITH_PROFILE="yes" "$SCRIPTS_FINAL_DIR"/05_network_configuration/5_network.sh
	# waiting until online
	ONLINE_STATUS=""
	NUM=0
	while [[ "$ONLINE_STATUS" != "online" ]] && [[ "$NUM" -le 60 ]]
	do
		env_check_if_online &> /dev/null
		sleep 5
		NUM=$((NUM+10))
	done
	
	
	### restoring apps, settings and preferences
	if [[ "$RESTORE_DIR_FILES" == "" ]]
	then
		:
	else
		printf "\n${bold_text}###\nrestoring apps, settings and preferences...\n###\n${default_text}"
		create_tmp_batch_script_fifo
		if [[ "$RESTORE_DIR_FILES" != "" ]]
		then
		    echo ''
			RESTOREUSERDIR=$(find "$RESTORE_DIR_FILES" -mindepth 1 -maxdepth 1 -type d -name "backup_*_[[:digit:]][[:digit:]][[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]-[[:digit:]][[:digit:]]" | sort -n | tail -n 1)
		else
			:
		fi
		echo "restoreuserdir is "$RESTOREUSERDIR"..."
		RUN_SCRIPT="yes" RESTOREUSERDIR="$RESTOREUSERDIR" "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/run_restore_script.command
		sleep 0.5
		#echo ''
	fi
	
	### batch script one and two without reboot
	if [[ "$BATCH_ONE_AND_TWO" =~ ^(yes|y)$ ]]
    then
    	printf "\n${bold_text}###\nbatch scripts...\n###\n${default_text}"
        create_tmp_batch_script_fifo
	    open "$SCRIPTS_FINAL_DIR"/_batch_run/batch_script_part2.command
	    ### waiting for running processes to finish
    	echo ''
    	echo "waiting for batch script 2 to finish..."
    	echo ''
    	sleep 3
    	WAIT_PIDS=()
    	WAIT_PIDS+=$(ps aux | grep /batch_script_part2.command | grep -v grep | awk '{print $2;}')
    	#echo "$WAIT_PIDS"
    	#if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
    	while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"
    else
        :
    fi
	
	### batch script done
	echo ''
	printf "\n${bold_text}###\nbatch script done...\n###\n${default_text}"
	echo ''
	
}

time ( batch_run_all )


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

COMBINED_ERROR_LOG="/Users/"$USER"/Desktop/"$SCRIPT_NAME_WITHOUT_EXTENSION"_errorlog.txt"
if [[ -e "$COMBINED_ERROR_LOG" ]]; then rm -f "$COMBINED_ERROR_LOG"; else :; fi
while IFS= read -r line || [[ -n "$line" ]] 
do
    if [[ "$line" == "" ]]; then continue; fi
    i="$line"
    echo '' >> "$COMBINED_ERROR_LOG"
    echo '' >> "$COMBINED_ERROR_LOG"
	cat "$i" >> "$COMBINED_ERROR_LOG"
done <<< "$(find "$ERROR_LOG_DIR" -mindepth 1 -maxdepth 1 -type f -name "*.txt" | sort -n)"
if [[ -e "$ERROR_LOG_DIR" ]]; then rm -rf "$ERROR_LOG_DIR"; else :; fi

sed -i '' '/Klone nach/d' "$COMBINED_ERROR_LOG"
sed -i '' '/Cloning into/d' "$COMBINED_ERROR_LOG"
sed -i '' '/^No updates/d' "$COMBINED_ERROR_LOG"
#sed -i '' 's/[[:blank:]]*$//' "$COMBINED_ERROR_LOG"
sed -i '' 's/[ \t]*$//' "$COMBINED_ERROR_LOG"
sed -i '' '/^#.*#$/d' "$COMBINED_ERROR_LOG"
sed -i '' '/^#.*%$/d' "$COMBINED_ERROR_LOG"
sed -i '' '/.*\.[0-9]%$/d' "$COMBINED_ERROR_LOG"
sed -i '' '/\[new tag\]/d' "$COMBINED_ERROR_LOG"
sed -i '' '/\[new branch\]/d' "$COMBINED_ERROR_LOG"
sed -i '' '/^script -q/d' "$COMBINED_ERROR_LOG"
sed -i '' '/\[.*\].*\[=.*\].*\%.*ETA/d' "$COMBINED_ERROR_LOG"
sed -i '' '/\[.*\].*\[=.*\].*100\%/d' "$COMBINED_ERROR_LOG"
sed -i '' "/Already on 'master'/d" "$COMBINED_ERROR_LOG"
sed -i '' '/reinstall.*brew reinstall/d' "$COMBINED_ERROR_LOG"
sed -i '' '/Von https\:\/\/github\.com/d' "$COMBINED_ERROR_LOG"
sed -i '' '/From https\:\/\/github\.com/d' "$COMBINED_ERROR_LOG"
sed -i '' '/Warning.*already installed/d' "$COMBINED_ERROR_LOG"
sed -i '' '/\[33mWarning.*are using macOS/,/running this pre-release version/d' "$COMBINED_ERROR_LOG"
#sed -i '' '/\[33mWarning.*Ruby version/,/supported Rubies/d' "$COMBINED_ERROR_LOG"
#awk '/./ { e=0 } /^$/ { e += 1 } e <= 2' "$COMBINED_ERROR_LOG" > /tmp/errorlog.txt
#cat /tmp/errorlog.txt > "$COMBINED_ERROR_LOG"
#rm -f /tmp/errorlog.txt
perl -i -ane '$n=(@F==0) ? $n+1 : 0; print if $n<=2' "$COMBINED_ERROR_LOG"


### done
echo ''
echo "done ;)"
echo ''


### play sound
osascript -e "set Volume 5"
#osascript -e "beep"
#/System/Library/Sounds/
#/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/
SOUND_FILE="/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/AlertTones/Modern/Chord.m4r"
afplay "$SOUND_FILE" && afplay "$SOUND_FILE"
osascript -e "set Volume 3"


### checking output and rebooting
ask_for_reboot() {
	echo ''
	VARIABLE_TO_CHECK="$REBOOT_NOW"
	QUESTION_TO_ASK="${bold_text}please check the complete output before rebooting... reboot now (Y/n)? "
	env_ask_for_variable
	printf "%s" "${default_text}"
	REBOOT_NOW="$VARIABLE_TO_CHECK"
	sleep 0.1
	
	if [[ "$REBOOT_NOW" =~ ^(yes|y)$ ]]
	then
	    #echo ''
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'           # reboot
		#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'          # shutdown
		#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'          # logout
	    #echo ''
	else
		:
	fi
}
# reboot here to avoid problems with the restored keychain
REBOOT_NOW="yes"
# keep terminal(s) open (error logs are on the desktop)
# reopen all windows after next login
# false = disable, true = enable
defaults write com.apple.loginwindow TALLogoutSavesState -bool true
ask_for_reboot

if [[ -e "/tmp/batch_script_in_progress" ]]; then rm -f "/tmp/batch_script_in_progress"; else :; fi


