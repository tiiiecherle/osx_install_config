#!/bin/zsh

###
### script dir
###

if [[ -n "$BASH_SOURCE" ]]
then
	SCRIPT_PATH="$BASH_SOURCE"
elif [[ -n "$ZSH_VERSION" ]]
then
	SCRIPT_PATH="${(%):-%x}"
fi
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
SCRIPT_DIR_ONE_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && pwd)"
SCRIPTS_FINAL_DIR="$SCRIPT_DIR_ONE_BACK"



###
### config file
###

if [[ -e "$SCRIPTS_FINAL_DIR"/_config_file/install_config_file.sh ]]
then
	# installing again if local file is different from online file
	printf "\n${bold_text}###\nconfig file...\n###\n${default_text}"
	ENABLE_SELF_UPDATE="no" "$SCRIPTS_FINAL_DIR"/_config_file/install_config_file.sh
	# re-sourcing config file
	if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
	eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"
	
	if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
	eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
fi



###
### variables
###

SCRIPTS_FINAL_DIR="$SCRIPT_DIR_ONE_BACK"
env_identify_terminal



###
### user config profile
###

echo ''
printf "\n${bold_text}###\nuser profile...\n###\n${default_text}"
echo ''
SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile



###
### asking password upfront
###

echo ''
printf "\n${bold_text}###\nsudo password...\n###\n${default_text}"
echo ''
echo "please enter sudo password..."
env_enter_sudo_password
#env_start_sudo

# env_delete_tmp_batch_script_fifo and env_delete_tmp_batch_script_gpg_fifo are part of config file


###
### app store password
###
echo ''
printf "\n${bold_text}###\napp store password...\n###\n${default_text}"
echo ''
echo "please enter app store password..."
while [[ $MAS_APPSTORE_PASSWORD != $MAS_APPSTORE_PASSWORD2 ]] || [[ $MAS_APPSTORE_PASSWORD == "" ]]; do stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && printf "re-enter appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD2 && stty echo && printf "\n" && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''; done



###
### functions
###

# fifo funtions are part of config file



###
### caffeinate
###

echo ''
printf "\n${bold_text}###\ncaffeinate...\n###\n${default_text}"
#echo ''
env_activating_caffeinate



###
### trap
###

trap_function_exit_middle() { env_delete_tmp_batch_script_fifo; env_delete_tmp_batch_script_gpg_fifo; env_delete_tmp_sudo_mas_script_fifo; env_delete_tmp_appstore_mas_script_fifo; unset SUDOPASSWORD; unset USE_PASSWORD; env_deactivating_caffeinate; rm -f "/tmp/batch_script_in_progress" }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"



###
### batch script part 1
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_force_start_error


### security permissions
#echo ''
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
"$SOURCE_APP_NAME                           $SYSTEM_GUI_SETTINGS_APP                                    1"
"$SOURCE_APP_NAME                           Finder                                                      1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions
echo ''

DIRECTORY_TO_SEARCH_FOR_QUARANTINE="$SCRIPT_DIR_ONE_BACK"
env_remove_quarantine_attribute


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
    	env_create_tmp_batch_script_fifo
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
	    if [[ "$GPG_SUDO_PASSWORD" =~ ^(yes|y)$ ]]
	    then
	    	GPG_PASSWORD="$SUDOPASSWORD"
	    else
	    	echo ''
	    	while [[ $GPG_PASSWORD != $GPG_PASSWORD2 ]] || [[ $GPG_PASSWORD == "" ]]; do stty -echo && printf "gpg decryption password: " && read -r "$@" GPG_PASSWORD && printf "\n" && printf "re-enter gpg decryption password: " && read -r "$@" GPG_PASSWORD2 && stty echo && printf "\n" && USE_GPG_PASSWORD='builtin printf '"$GPG_PASSWORD\n"''; done
	    fi
	fi
	if [[ "$RESTORE_DIR_VBOX" == "" ]]
	then
		echo "no directory for restoring vbox selected, respective scripts will be skipped..."
	else
		:
	fi
	if [[ "$RESTORE_DIR_UTM" == "" ]]
	then
		echo "no directory for restoring utm selected, respective scripts will be skipped..."
	else
		:
	fi
	echo ''
	
	
	### mobileconfig	
	if [[ "$INSTALL_MOBILECONFIG" == "yes" ]]
	then
		printf "\n${bold_text}###\nmobile config...\n###\n${default_text}"
		env_create_tmp_batch_script_fifo
		"$SCRIPTS_FINAL_DIR"/_mobileconfig/install_mobileconfig_profiles_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
		env_active_source_app
	else
		:
	fi
	env_activating_caffeinate
	env_force_start_error
    
    
    ### login shell customization
	printf "\n${bold_text}###\nlogin shell customization...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/02_preparations/2d_login_shell_customization.sh

	
	### homebrew and cask install
	printf "\n${bold_text}###\nhomebrew cask...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	env_create_tmp_mas_script_fifo
	open -a Terminal "$SCRIPTS_FINAL_DIR"/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/0_run_all.command
	sleep 3
	
	# waiting for respective homebrew formulae before starting to unarchive the backup files
	echo ''
	echo "waiting for respective homebrew formulae before starting to unarchive the backup files..."
	echo ''
	checking_dependencies() {
	    MISSING_SCRIPT_DEPENDENCY=""
		if command -v brew &> /dev/null
		then
			# installed
		    # checking for missing dependencies
		    for formula in gnu-tar pigz pv coreutils parallel gnupg
		    do
		    	if [[ $(brew list --formula | grep "^$formula$") == '' ]]
		    	then
		    		#echo ""$formula" is NOT installed..."
		    		MISSING_SCRIPT_DEPENDENCY="yes"
		    	else
		    		#echo ""$formula" is installed..."
		    		:
		    	fi
		    done
		    # wait until command is available, e.g. if building from source
		    for command_to_test in gtar pigz pv gdu parallel gpg
		    do
		   		if command -v "$command_to_test" &> /dev/null
		    	then
		    		#echo ""$command_to_test" is installed..."
					:
		    	else
		    		#echo ""$command_to_test" is NOT installed..."
		    		MISSING_SCRIPT_DEPENDENCY="yes"
		    	fi
		    done
		else
		    # not installed
		    MISSING_SCRIPT_DEPENDENCY="yes"
		fi
		#echo "MISSING_SCRIPT_DEPENDENCY is "$MISSING_SCRIPT_DEPENDENCY""
	}

	setting_config() {
	    #echo ''
	    ### sourcing .$SHELLrc or setting PATH
	    # as the script is run from a launchd it would not detect the binary commands and would fail checking if binaries are installed
	    # needed if binary is installed in a special directory
	    if [[ -n "$BASH_SOURCE" ]] && [[ -e /Users/"$USER"/.bashrc ]] && [[ $(cat /Users/"$USER"/.bashrc | grep 'export PATH=.*:$PATH"') != "" ]]
	    then
	        echo "sourcing .bashrc..."
	        #. /Users/"$USER"/.bashrc
	        # avoiding oh-my-zsh errors for root by only sourcing export PATH
	        source <(sed -n '/^export\ PATH\=/p' /Users/"$USER"/.bashrc)
	    elif [[ -n "$ZSH_VERSION" ]] && [[ -e /Users/"$USER"/.zshrc ]] && [[ $(cat /Users/"$USER"/.zshrc | grep 'export PATH=.*:$PATH"') != "" ]]
	    then
	        echo "sourcing .zshrc..."
	        ZSH_DISABLE_COMPFIX="true"
	        #. /Users/"$USER"/.zshrc
	        # avoiding oh-my-zsh errors for root by only sourcing export PATH
	        source <(sed -n '/^export\ PATH\=/p' /Users/"$USER"/.zshrc)
	    else
	        echo "PATH was not set continuing with default value..."
	    fi
	    echo "using PATH..." 
	    echo "$PATH"
	    echo ''
	}
	setting_config
		
	MISSING_SCRIPT_DEPENDENCY=""
	checking_dependencies
	while [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
	do
		sleep 30
		checking_dependencies
	done
	echo "no missing dependencies, continuing..."
	
	
	### creating symlinks
	printf "\n${bold_text}###\ncreating symlinks...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/02_preparations/symbolic_links_testvolume_macos_beta.sh
	
	
	### unarchiving and restoring files
	if [[ "$RESTORE_DIR_FILES" == "" ]]
	then
		:
	else
		printf "\n${bold_text}###\nunarchiving and restoring files...\n###\n${default_text}"
		env_create_tmp_batch_script_fifo
		env_create_tmp_batch_script_gpg_fifo
		#time ASK_FOR_RESTORE_DIRS="no" RESTORE_FILES_OPTION="unarchive" RESTORE_DIR_FILES="$RESTORE_DIR_FILES" RESTORE_DIR_VBOX="$RESTORE_DIR_VBOX" RESTORE_VBOX="$RESTORE_VBOX" "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/files/restore_files.sh
		ASK_FOR_RESTORE_DIRS="no" RESTORE_FILES_OPTION="unarchive" RESTORE_DIR_FILES="$RESTORE_DIR_FILES" RESTORE_DIR_VBOX="$RESTORE_DIR_VBOX" RESTORE_VBOX="$RESTORE_VBOX" RESTORE_DIR_UTM="$RESTORE_DIR_UTM" RESTORE_UTM="$RESTORE_UTM" "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/files/restore_files.sh
		unset RESTORE_FILES_OPTION
		sleep 1
		env_active_source_app
		tput cuu 1
		env_activating_caffeinate
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
	env_activating_caffeinate
	
	
	### nvram
	printf "\n${bold_text}###\nnvram...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/01_recovery_settings_and_nvram/1b_nvram.sh
	
	
	### system update
	#printf "\n${bold_text}###\nsystem update...\n###\n${default_text}"
	#"$SCRIPTS_FINAL_DIR"/02_preparations/2a_system_update.sh
	
	
	### run before shutdown
	# important: script can not delay shutdown and is killed by macos on shutdown
	# more documentation can be found in the script
	# moved to batchs script 1 to execute after the next reboot (after batch script 2)
	printf "\n${bold_text}###\nrun before shutdown launchd...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/09_launchd/9e_run_on_shutdown/install_script_run_on_shutdown_launchdservice.sh
	env_active_source_app
	
	
	### network configuration
	printf "\n${bold_text}###\nnetwork configuration...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
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
		env_create_tmp_batch_script_fifo
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
        env_create_tmp_batch_script_fifo
	    open -a Terminal "$SCRIPTS_FINAL_DIR"/_batch_run/batch_script_part2.command
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
	sleep 1
	echo ''
	printf "\n${bold_text}###\nbatch script done...\n###\n${default_text}"
	echo ''
	
}

time ( batch_run_all )
echo ''

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

cleanup_log() {
    sed -i '' '/Klone nach/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/Cloning into/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/^No updates/d' "$COMBINED_ERROR_LOG"
    sed -i '' 's/[[:blank:]]*$//' "$COMBINED_ERROR_LOG"
    sed -i '' 's/[ \t]*$//' "$COMBINED_ERROR_LOG"
    sed -i '' '/^#.*#$/d' "$COMBINED_ERROR_LOG"
    sed -i '' -E '/^#.*[[:space:]]+$/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/^#.*%$/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/.*\.[0-9]%$/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/\[0m.*\[1mTapping homebrew/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/^Tapped.*commands.*\(.*\)$/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/\[new tag\]/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/\[new branch\]/d' "$COMBINED_ERROR_LOG"
    sed -i '' "/Switched to a new branch 'master'/d" "$COMBINED_ERROR_LOG"
    sed -i '' '/\[neuer Branch\]/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/^script -q/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/\[.*\].*\[=.*\].*\%.*ETA/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/\[.*\].*\[=.*\].*100\%/d' "$COMBINED_ERROR_LOG"
    sed -i '' "/Already on 'master'/d" "$COMBINED_ERROR_LOG"
    sed -i '' "/Bereits auf 'master'/d" "$COMBINED_ERROR_LOG"
    sed -i '' '/reinstall.*brew reinstall/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/^To reinstall.*run\:/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/brew reinstall.*/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/Von https\:\/\/github\.com/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/From https\:\/\/github\.com/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/Warning.*already installed/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/Warning.*are using macOS/,/pre-release version\./d' "$COMBINED_ERROR_LOG"
    sed -i '' '/You will encounter build failures/,/pre-release version\./d' "$COMBINED_ERROR_LOG"
    sed -i '' '/Creating client\/daemon connection/d' "$COMBINED_ERROR_LOG"
    sed -i '' '/Please note that these warnings.*Homebrew maintainers/,/just ignore this\. Thanks/d' "$COMBINED_ERROR_LOG"
    sed -i '' "/Already on 'release/d" "$COMBINED_ERROR_LOG"
    sed -i '' '/security\:\ SecKeychainSearchCopyNext\:\ The specified item could not be found in the keychain\./d' "$COMBINED_ERROR_LOG"
    sed -i '' '/It is expected behaviour.*will fail to build/,/may not accept it\./d' "$COMBINED_ERROR_LOG"
    perl -i -ane '$n=(@F==0) ? $n+1 : 0; print if $n<=2' "$COMBINED_ERROR_LOG"
}
sleep 1
cleanup_log


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

