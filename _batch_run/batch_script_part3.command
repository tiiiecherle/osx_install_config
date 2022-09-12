#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



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

env_active_source_app() {
	sleep 0.5
	osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
	#osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
	sleep 0.5
}



###
### variables
###

SCRIPTS_FINAL_DIR="$SCRIPT_DIR_ONE_BACK"
env_identify_terminal



###
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile



###
### trap
###

trap_function_exit_middle() { env_delete_tmp_batch_script_fifo; unset SUDOPASSWORD; unset USE_PASSWORD; env_deactivating_caffeinate; rm -f "/tmp/batch_script_in_progress" }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"



###
### batch script part 2
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_force_start_error


### security permissions
#echo ''
printf "\n${bold_text}###\nsecurity permissions...\n###\n${default_text}"
echo ''

DIRECTORY_TO_SEARCH_FOR_QUARANTINE="$SCRIPT_DIR_ONE_BACK"
env_remove_quarantine_attribute


### batch run all function
batch_run_all() {


	### silencing sounds
	osascript -e "set Volume 0"


	### activating caffeinate
	env_activating_caffeinate
	
	
	### reset mail index
	printf "\n${bold_text}###\nreset mail index...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/13_apple_mail_and_accounts/13b_reset_mail_index.sh
	env_active_source_app
	

	### manual app preferences
	printf "\n${bold_text}###\nmanual app preferences...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/15_finalizations/15a_applications_manual_preferences_open.sh
	

	### siri analytics and learning
	printf "\n${bold_text}###\nsiri analytics and learning...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/15_finalizations/15c_disable_siri_analytics_and_learning_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
	
	
	### batch script done
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
sleep 1

### checking output and rebooting
ask_for_reboot() {
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
REBOOT_NOW="no"
# reopen all windows after next login
# false = disable, true = enable
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
ask_for_reboot

if [[ -e "/tmp/batch_script_in_progress" ]]; then rm -f "/tmp/batch_script_in_progress"; else :; fi

exit &> /dev/null

