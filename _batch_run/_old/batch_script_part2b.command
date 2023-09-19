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
        RUN_FROM_BATCH_SCRIPT_ONE="yes"
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


	### hosts file generator
	printf "\n${bold_text}###\nhosts file generator...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/root/1_hosts_file/install_hosts_file_generator_and_launchdservice.sh
	env_active_source_app		
	
	### local ssl certificate
    if [[ "$MACOS_VERSION_MAJOR" != 10.15 ]]
    then
        # macos versions other than 10.15
        # more complicated and risky on 11 and newer due to signed system volume (ssv)
        :
    else
        # macos versions 10.15
    	printf "\n${bold_text}###\nlocal ssl certificate...\n###\n${default_text}"
    	env_create_tmp_batch_script_fifo
    	"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/root/2_cert_install_update/install_cert_install_update_launchdservice.sh
    	env_active_source_app
    fi
    
    
	### network locations
	printf "\n${bold_text}###\nnetwork locations...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/root/3_network_select/install_network_select_and_launchdservice.sh
	env_active_source_app
	# waiting until online
	ONLINE_STATUS=""
	NUM=0
	while [[ "$ONLINE_STATUS" != "online" ]] && [[ "$NUM" -le 60 ]]
	do
		env_check_if_online &> /dev/null
		sleep 5
		NUM=$((NUM+10))
	done
	
	
	### screen resolution	
	if [[ "$INSTALL_SCREEN_RESOLUTION_LAUNCHD" == "yes" ]]
	then
		printf "\n${bold_text}###\nscreen resolution...\n###\n${default_text}"
		"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/user/1_screen_resolution/install_screen_resolution_user_launchdservice.sh
		env_active_source_app
	else
		:
	fi
	
	
	### reminders
	printf "\n${bold_text}###\nreminders...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/user/2_reminders/install_reminders_user_launchdservice.sh
	env_active_source_app
	
	
	### logout hook
	printf "\n${bold_text}###\nlogout hook...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/09_launchd/9c_run_on_logout/install_run_on_logout_hook.sh
	
	
	### login hook
	printf "\n${bold_text}###\nlogin hook...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/09_launchd/9d_run_on_login/system/install_run_on_login_hook.sh
	
		
	### special autostart apps
	for AUTOSTART_APP in whatsapp signal virusscannerplus
	do
	    AUTOSTART_APP_UPPER=$(echo "$AUTOSTART_APP" | tr '[:lower:]' '[:upper:]')
	    AUTOSTART_APP_LOWER=$(echo "$AUTOSTART_APP" | tr '[:upper:]' '[:lower:]')
        AUTOSTART_VARIABLE_TO_CHECK=INSTALL_RUN_ON_LOGIN_$AUTOSTART_APP_UPPER
        if [[ $(eval "echo \"\$$AUTOSTART_VARIABLE_TO_CHECK\"") == "yes" ]]
        then
        	printf "\n${bold_text}###\nspecial autostart app $AUTOSTART_APP_LOWER...\n###\n${default_text}"
        	. "$SCRIPTS_FINAL_DIR"/09_launchd/9d_run_on_login/autostart_apps/install_run_on_login_"$AUTOSTART_APP_LOWER".sh	
        	echo ''
        else
        	:
        fi
	done
	
	
	### dock
	printf "\n${bold_text}###\ndock...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/10_dock/10_dock.sh
	
	
	### privacy database entries
	printf "\n${bold_text}###\nprivacy database entries...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11a_system_preferences_privacy_sqlite_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
	
	
	### safari
	printf "\n${bold_text}###\nsafari...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11b_safari_extensions_cookies.sh
	env_active_source_app
	
	
	### third party app preferences
	printf "\n${bold_text}###\nthird party app preferences...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11k_third_party_app_preferences.sh
	
	
	### macos and app preferences
	printf "\n${bold_text}###\nmacos and app preferences...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11c_macos_preferences_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
	
	
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
sed -i '' '/YES (0)/d' "$COMBINED_ERROR_LOG"
sed -i '' '/YES (0)/d' "$COMBINED_ERROR_LOG"
sed -i '' '/Von https\:\/\/github\.com/d' "$COMBINED_ERROR_LOG"
sed -i '' '/From https\:\/\/github\.com/d' "$COMBINED_ERROR_LOG"
sed -i '' '/\* branch.*FETCH_HEAD/d' "$COMBINED_ERROR_LOG"
sed -i '' '/DEPRECATION: Configuring installation scheme with distutils config files is deprecated.*Homebrew\/homebrew-core\/issues\/76621/d' "$COMBINED_ERROR_LOG"
#awk '/./ { e=0 } /^$/ { e += 1 } e <= 2' "$COMBINED_ERROR_LOG" > /tmp/errorlog.txt
#cat /tmp/errorlog.txt > "$COMBINED_ERROR_LOG"
#rm -f /tmp/errorlog.txt
perl -i -ane '$n=(@F==0) ? $n+1 : 0; print if $n<=2' "$COMBINED_ERROR_LOG"


### done
echo ''
echo "done ;)"
#echo ''


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
#echo ''

if [[ "$RUN_FROM_BATCH_SCRIPT_ONE" == "yes" ]]
then
	:
else
	REBOOT_NOW="yes"
	# keep terminal(s) open (error logs are on the desktop)
	# reopen all windows after next login
	# false = disable, true = enable
	defaults write com.apple.loginwindow TALLogoutSavesState -bool true
	ask_for_reboot
fi

if [[ -e "/tmp/batch_script_in_progress" ]]; then rm -f "/tmp/batch_script_in_progress"; else :; fi

