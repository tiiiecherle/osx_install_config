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


### check if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    :
else
	# not online
	echo ''
	echo "not online, exiting..."
	echo ''
fi


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
	
	
	### reset calendar, contacts & reminders
	# move to beginning of script as the local subscrition entries only appear in the sidebar of the calendar after all calendar data is re-dowloaded completetly
	# moved calendar alarms/notification script to end of thsi script as some settings only take effect if the calendars are downloaded completely again
	# otherwise it would need a long wait time (at least 300-500 seconds between the two scripts
	printf "\n${bold_text}###\nreset calendar, contacts & reminders...\n###\n${default_text}"
	CLEAR_LOCAL_DATA="yes" "$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11i_reset_calendar_contacts_reminders_data_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh


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
        # deprecated
    	#printf "\n${bold_text}###\nlocal ssl certificate...\n###\n${default_text}"
    	#env_create_tmp_batch_script_fifo
    	#"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/root/2_cert_install_update/install_cert_install_update_launchdservice.sh
    	#env_active_source_app
    	:
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
	# deprecated
	#printf "\n${bold_text}###\nlogout hook...\n###\n${default_text}"
	#env_create_tmp_batch_script_fifo
	#"$SCRIPTS_FINAL_DIR"/09_launchd/9c_run_on_logout/install_run_on_logout_hook.sh
	
	
	### login hook
	# deprecated
	#printf "\n${bold_text}###\nlogin hook...\n###\n${default_text}"
	#env_create_tmp_batch_script_fifo
	#"$SCRIPTS_FINAL_DIR"/09_launchd/9d_run_on_login/system/install_run_on_login_hook.sh
	
	
	### run on boot
	printf "\n${bold_text}###\nrun on boot launchd...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/09_launchd/9b_run_on_boot/root/5_run_on_boot_general/install_run_on_boot_and_launchdservice.sh
	env_active_source_app
	
	
	### run before shutdown
	# moved to batchs script 1 to execute after the next reboot (after batch script 2)
	
		
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
	
	
	### check if network volume is connected (needed for finder sidebar script)
	# user specific customization
	SCRIPT_NAME="finder_sidebar_"$USER""
	SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
	SCRIPT_DIR_INPUT_KEEP="$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep
	NETWORK_VOLUME_DATA="/Volumes/office"
	if [[ $(uname -m | grep arm) != "" ]]
	then
		# arm mac
		SCRIPT_SUFFIX="py"
	else
		# intel mac
		#SCRIPT_SUFFIX="sh"
		SCRIPT_SUFFIX="py"
	fi	
	
	if [[ -e "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME"."$SCRIPT_SUFFIX" ]]
	then
		if [[ $(cat "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME"."$SCRIPT_SUFFIX" | sed '/^#/ d' | grep "file://"$NETWORK_VOLUME_DATA"") != "" ]]
		then
			printf "\n${bold_text}###\nnetwork connection...\n###\n${default_text}"
			CONNECTION_TIMEOUT=120
			check_if_network_volume_data_is_mounted() {
			    # checking if network volume is mounted
			    #echo ''
			    if mount | grep "$NETWORK_VOLUME_DATA" > /dev/null
			    then
			    	printf '\n'
			        echo "network volume $NETWORK_VOLUME_DATA already mounted, continuing..."
			    else
			    	NUM1=0
			    	printf '\n'
			    	echo "connecting to network volume to add network finder sidebar items later..."
			    	echo "network volume $NETWORK_VOLUME_DATA not mounted, mounting now..."
			    	osascript -e 'tell application "Finder" to activate'
			    	osascript -e 'tell application "System Events" to keystroke "k" using command down'
			    	echo "waiting for network volume to be mounted..."
			    	echo "please connect within "$CONNECTION_TIMEOUT" seconds..."
			    	echo ''
			    	while ! mount | grep "$NETWORK_VOLUME_DATA" > /dev/null
			    	do 
			    		NUM1=$((NUM1+1))
			    		if [[ "$NUM1" -le "$CONNECTION_TIMEOUT" ]]
			    		then
			    			#echo "$NUM1"
			    			sleep 1
			    			if (( NUM1 % 1 == 0 ))
			    			then
			    				tput cuu 1 && tput el
			    				echo "$((CONNECTION_TIMEOUT-NUM1)) seconds left to connect to network volume $NETWORK_VOLUME_DATA..."
			    			else
			    				:
			    			fi
			    		else
			    		    printf '\n'
			    			echo "network volume not mounted in "$NUM1" seconds, skipping network finder sidebar items..." >&2
			    			printf '\n'
			    		fi
			    	done
			    	echo "network volume mounted, continuing..."
			    fi
			    echo ''
			}
			check_if_network_volume_data_is_mounted
		else
			:
		fi
	else
	    #echo ''
	    #echo "user specific sidebar customization script not found......"
	    :
	fi


	### open with
	printf "\n${bold_text}###\nopen with...\n###\n${default_text}"
	CLEAN_SERVICES_CACHE="no" "$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11e_defaults_open_with.sh
	
	
	### finder sidebar
	if mount | grep "$NETWORK_VOLUME_DATA" > /dev/null
    then
		NETWORK_CONNECTED="yes"
	else
		:
	fi
	printf "\n${bold_text}###\nfinder sidebar...\n###\n${default_text}"
	NETWORK_CONNECTED="$NETWORK_CONNECTED" INSTALL_UPDATE_MYSIDES="no" "$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11f_finder_sidebar_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
	env_active_source_app


	### spotlight
	# moved spotlight index behind finder sidebar cus deleting spotlight index led to non working automation permissions until spotlight was reindexed 
	printf "\n${bold_text}###\nspotlight...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11d_system_preferences_spotlight.sh
	env_active_source_app
	

	### finder favorites
	printf "\n${bold_text}###\nfinder favorites...\n###\n${default_text}"
	#echo ''
	# python dependencies
    #pip3 install pyobjc-framework-SystemConfiguration
	#python3 "$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11g_finder_favorites.py
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11g_finder_favorites_python_wrapper.sh
	#echo ''
	
	
	### notification center
	printf "\n${bold_text}###\nnotification center...\n###\n${default_text}"
	INSTALL_UPDATE_MYSIDES="no" "$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11h_notification_center_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
	
	
	### third party app preferences
	# moved to run earlier
	
	
	### migrate internet accounts
	printf "\n${bold_text}###\nmigrate internet accounts...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/13_apple_mail_and_accounts/13a_migrate_internet_accounts.sh


	### samba
	printf "\n${bold_text}###\nsamba...\n###\n${default_text}"
	env_create_tmp_batch_script_fifo
	"$SCRIPTS_FINAL_DIR"/14_samba/14a_samba.sh
	

	### siri analytics and learning
	printf "\n${bold_text}###\nsiri analytics and learning...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/15_finalizations/15c_disable_siri_analytics_and_learning_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh	
	
	
	### firefox hardening
	#printf "\n${bold_text}###\nfirefox hardening...\n###\n${default_text}"
	#CONT1="no" "$SCRIPTS_FINAL_DIR"/15_finalizations/15d_firefox_hardening.sh
	
	
	### calendar notifications and visibility
	printf "\n${bold_text}###\ncalendar alarms and visibility...\n###\n${default_text}"
	"$SCRIPTS_FINAL_DIR"/11_system_and_app_preferences/11j_set_calendar_alarms_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
	
	
	### apple id dock notification
	printf "\n${bold_text}###\napple id dock notification...\n###\n${default_text}"
	CONT1="no" "$SCRIPTS_FINAL_DIR"/15_finalizations/15f_remove_dock_notifications.sh
	
	
	### setting self update for scripts config file
	printf "\n${bold_text}###\nself update for scripts config file...\n###\n${default_text}"
	SHELL_SCRIPTS_CONFIG_FILE="shellscriptsrc"
	SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH=~/."$SHELL_SCRIPTS_CONFIG_FILE"
	# variable is set in user profile and deactivated for batch install scripts in batch_script_part1
	if [[ "$ENABLE_SELF_UPDATE" == "no" ]]
    then
        # deactivating self-update
        echo "deactivating self-update..."
        sed -i '' '/env_config_file_self_update$/s/^#*/#/g' "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
    else
        # activating self-update
        echo "activating self-update..."
        sed -i '' '/env_config_file_self_update$/s/^#*//g' "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
    fi
    echo ''
	
	
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
sed -i '' '/kMDConfigSearchLevelFSSearchOnly/d' "$COMBINED_ERROR_LOG"
sed -i '' '/Internet Accounts Migration starting/d' "$COMBINED_ERROR_LOG"
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
	defaults write com.apple.loginwindow TALLogoutSavesState -bool false
	ask_for_reboot
fi

if [[ -e "/tmp/batch_script_in_progress" ]]; then rm -f "/tmp/batch_script_in_progress"; else :; fi

