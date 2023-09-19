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
    tell application "System Settings"
	quit
	delay 3
end tell
EOF


# open settings by opening preferences pane directly
# defaults read /System/Library/PreferencePanes/Profiles.prefPane/Contents/Info CFBundleIdentifier com.apple.preferences.configurationprofiles
#open /System/Library/PreferencePanes/Profiles.prefPane

# easiest ways to open a specific system settings pane
# https://apple.stackexchange.com/questions/446111/how-to-open-login-items-in-system-settings-programmatically-in-macos-13-ve
# https://gist.github.com/rmcdongit/f66ff91e0dad78d4d6346a75ded4b751?permalink_comment_id=4258811

# url schemes
# list of all url schemes macos 14
# all ids url schemes are listed in /System/Applications/System Settings.app/Contents/Resources/Sidebar.plist
# or here
# https://github.com/piarasj/piarasj.github.io/blob/master/ventura_settings.md#ventura-system-settings
# listing Pane ids to open with url schemes
# or
#for pref in $(strings "/System/Applications/System Settings.app/Contents/MacOS/System Settings" | awk '/^com.apple./ {print $1 }'); do echo "$pref"; done
# usage
#open "x-apple.systempreferences:<PaneID>"

# open with system settings bundle identifier and pane path
# some paths do not open the correct pane in the gui
#open com.apple.systempreferences /path/to/pane

# other possibilities are documented in 
# _mobileconfig/install_mobileconfig_profiles_13.sh
# _mobileconfig/install_profiles_13/14.scpt

open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
sleep 2


osascript <<EOF

# open install dialog 
# installing profile
# open install dialog 
# if run from shell script the path variable does not work, so check if variable is already set in shell
set ScriptDir to quoted form of POSIX path of (do shell script "echo $SCRIPT_DIR" & "/")
# if not set, set from applescript (only works if run as applescript, not from shell)
if ScriptDir is equal to "'/'" then
	set ScriptDir to quoted form of POSIX path of ((path to me as text) & "::")
end if
tell application "System Events"
	tell UI element 1 of row 2 of table 1 of scroll area 1 of group 2 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1 of process "System Settings"
		set {xPosition, yPosition} to position
		set {xSize, ySize} to size
	end tell
	#modify offsets if hot spot is not centered:
	set xClick to xPosition + (xSize div 2)
	set yClick to yPosition + (ySize div 2)
	tell process "Finder"
		set mouseclickBinary to do shell script "echo " & ScriptDir & "mouseclick"
		set mouseclickBinaryExists to ""
		try
			POSIX file mouseclickBinary as alias
			set mouseclickBinaryExists to "true"
		on error
			set mouseclickBinaryExists to "false"
		end try
		
		if mouseclickBinaryExists is equal to "true" then
			delay 1
			do shell script "chmod 770 " & ScriptDir & "mouseclick"
			do shell script "" & ScriptDir & "mouseclick" & " -x " & xClick & " -y " & yClick & ""
			delay 1
		else
			display dialog "mouseclick binary is missing..."
			return
		end if
		
		delay 1
		
		set mouseclick_doubleBinary to do shell script "echo " & ScriptDir & "mouseclick_double"
		set mouseclick_doubleBinaryExists to ""
		try
			POSIX file mouseclick_doubleBinary as alias
			set mouseclick_doubleBinaryExists to "true"
		on error
			set mouseclick_doubleBinaryExists to "false"
		end try
		
		if mouseclick_doubleBinaryExists is equal to "true" then
			do shell script "chmod 770 " & ScriptDir & "mouseclick_double"
			do shell script "" & ScriptDir & "mouseclick_double" & " -x " & xClick & " -y " & yClick & ""
			# make sure it works
			delay 0.5
			do shell script "" & ScriptDir & "mouseclick_double" & " -x " & xClick & " -y " & yClick & ""
			delay 2
			# alternative cliclick
			#do shell script "/opt/homebrew/bin/cliclick dc:" & xClick & "," & yClick & ""
		else
			display dialog "mouseclick_double binary is missing..."
			return
		end if
	end tell
end tell

delay 2

# install profile
tell application "System Events"
	tell process "System Settings"
		try
			click button "Installieren …" of group 1 of sheet 1 of window "Profile"
		on error
			click button 1 of group 1 of sheet 1 of window 1
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
			click button "Installieren …" of sheet 1 of window "Profile"
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

tell application "System Settings" to quit
      
EOF
    
    #if [[ $(echo "$i" | grep -i "wifi") != "" ]]
    #then
    #    sleep 10
    #else
    #    sleep 5
    #fi
    sleep 4
    
done <<< "$(find "$MOBILECONFIG_INPUT_PATH" -type f -name "*.mobileconfig" 2>&1 | grep -v -e 'Permission denied')"

printf "\n${bold_text}unmounting mobileconfig archive...\n${default_text}"
hdiutil detach "$MOBILECONFIG_INPUT_PATH"

echo ''
echo 'done ;)'
echo ''