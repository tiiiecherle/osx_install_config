#!/bin/zsh

###
### config file
###

if [[ -n "$BASH_SOURCE" ]]
then
    # path to script
    SCRIPT_PATH="$BASH_SOURCE"
elif [[ -n "$ZSH_VERSION" ]]
then
    # path to script
    SCRIPT_PATH="${(%):-%x}"
else
    :
fi   

# installing config file if this is a first run and the computer is offline
#printf "\n${bold_text}config file...\n${default_text}"
SCRIPT_DIR_ONE_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && pwd)"
SCRIPTS_FINAL_DIR="$SCRIPT_DIR_ONE_BACK"
if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else "$SCRIPTS_FINAL_DIR"/_config_file/install_config_file.sh; fi

# re-sourcing config file
if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables

#echo ''


###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### check if archive exists
###

if [[ -e "$SCRIPT_DIR_TWO_BACK"/_scripts_input_keep/mobileconfig_macos_"$USER".dmg ]]
then
    MOBILECONFIG_ARCHIV_PATH="$SCRIPT_DIR_TWO_BACK"/_scripts_input_keep/mobileconfig_macos_"$USER".dmg
else
    echo ''
    echo "archive with mobileconfig files does not exist for the current user, exiting..."
    echo ''
    exit
fi



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


### trapping
trap_function_exit_middle() { unset SUDOPASSWORD; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

#printf "\n${bold_text}mobileconfig archive password...\n${default_text}"
#echo "please enter mobileconfig dmg password..."
#while [[ $MOBILECONFIG_ARCHIV != $MOBILECONFIG_ARCHIV2 ]] || [[ $MOBILECONFIG_ARCHIV == "" ]]; do stty -echo && printf "mobileconfig dmg password: " && read -r "$@" MOBILECONFIG_ARCHIV && printf "\n" && printf "re-enter mobileconfig dmg password: " && read -r "$@" MOBILECONFIG_ARCHIV2 && stty echo && printf "\n" && USE_MOBILECONFIG_ARCHIV='builtin printf '"$MOBILECONFIG_ARCHIV\n"''; done


### security and automation
printf "\n${bold_text}security and automation preferences...\n${default_text}"

env_identify_terminal

# security
APPS_SECURITY_ARRAY=(
# app name									security service									     allowed (1=yes, 0=no)
"$SOURCE_APP_NAME                           kTCCServiceAccessibility                             	 1"
)
PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions

# automation
# macos versions 10.14 and up
# source app name							automated app name										 allowed (1=yes, 0=no)
AUTOMATION_APPS=(
"$SOURCE_APP_NAME						    System Events                   		                 1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions


### mounting archive
printf "\n${bold_text}mounting mobileconfig archive...\n${default_text}"
builtin printf "$SUDOPASSWORD" | hdiutil attach -stdinpass "$MOBILECONFIG_ARCHIV_PATH"
sleep 3

printf "\n${bold_text}installing mobileconfigs...\n${default_text}"
#MOBILECONFIG_INPUT_PATH=$(find "/Volumes" -mindepth 1 -maxdepth 1 -type d -name "*_mobileconfig")
MOBILECONFIG_INPUT_PATH="/Volumes/mobileconfig_macos_"$USER""


### cleaning possible old trashes on Volume
if [[ -e "/Volumes/mobileconfig_macos_"$USER"/.Trashes" ]]
then
    builtin printf "$SUDOPASSWORD" | builtin command sudo -p '' -k -S rm -rf "/Volumes/mobileconfig_macos_"$USER"/.Trashes"
else
    :
fi


### installing mobileconfigs
while IFS= read -r line || [[ -n "$line" ]] 
do
    if [[ "$line" == "" ]]; then continue; fi
    i="$line"
    echo "$(basename $i)"

    open "$i"
    
    sleep 3
        
    osascript <<EOF
    
        tell application "System Preferences"
        	activate
        	#set paneids to (get the id of every pane)
        	#display dialog paneids
        	#return paneids
        	#set current pane to pane "com.apple.preferences.configurationprofiles"
        	#get the name of every anchor of pane id "com.apple.preferences.configurationprofiles"
        	#set tabnames to (get the name of every anchor of pane id "com.apple.preferences.configurationprofiles")
        	#display dialog tabnames
        	#return tabnames
        	#reveal anchor "Profile" of pane id "com.apple.preferences.configurationprofiles"
        	try
        		reveal pane id "com.apple.preferences.configurationprofiles"
        		delay 4
        	end try
        end tell
        
        tell application "System Events" to tell process "System Preferences" to set visible to true
        delay 1
        tell application "System Events" to tell process "System Preferences" to set frontmost to true
        delay 1
        
        tell application "System Events"
        	select row 2 of table 1 of scroll area 2 of window "Profile" of process "System Preferences"
        	delay 4
        	tell process "System Preferences"
        		try
        			click button "Installieren …" of scroll area 1 of window "Profile"
        		on error
        		    click button 1 of sheet 1 of window 1
        		end try
        		delay 4
        		try
        			click button "Installieren" of sheet 1 of window "Profile"
        		on error
        		    click button 1 of sheet 1 of window 1    			
        		end try
        		delay 4
        		try
        			tell application "System Events" to keystroke "$SUDOPASSWORD"
        		end try
        		delay 2
        		try
            		tell application "System Events"
            		    try
            			    tell process "SecurityAgent"
            				    click button "OK" of window 1
            			    end tell
            	        end try
            		end tell
            	on error
            		tell application "System Events"
            		    try
            			    tell process "SecurityAgent"
            				    click button 2 of window 1
            			    end tell
            	        end try
            		end tell            	
        		end try
        		delay 4
        		try
        			click button "Installieren" of sheet 1 of window "Profile"
        			delay 4
        		on error
        		    try
        		        click button 1 of sheet 1 of window 1
        		        delay 4
        		    end try
        		end try
        		try
        		    repeat until (exists window "Profile")
		                delay 1
		            end repeat
		        on error
        		    repeat until (exists window 1)
		                delay 1
		            end repeat
		        end try

        	end tell
        end tell
        
        delay 4

        tell application "System Preferences" to quit
        
EOF
    
    #if [[ $(echo "$i" | grep -i "wifi") != "" ]]
    #then
    #    sleep 10
    #else
    #    sleep 5
    #fi
    sleep 4
    
done <<< "$(find "$MOBILECONFIG_INPUT_PATH" -type f -name "*.mobileconfig")"

printf "\n${bold_text}unmounting mobileconfig archive...\n${default_text}"
hdiutil detach "$MOBILECONFIG_INPUT_PATH"

echo ''
echo 'done ;)'
echo ''