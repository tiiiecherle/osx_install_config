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
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile



###
### security permissions
###

echo ''    
env_databases_apps_security_permissions
env_identify_terminal


### automation
# macos versions 10.14 and up
echo "setting security and automation permissions..."
AUTOMATION_APPS=(
# source app name							automated app name										    allowed (1=yes, 0=no)
"$SOURCE_APP_NAME                           System Events                                               1"
#"$SOURCE_APP_NAME                           Calendar                                               		1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions
#echo ''



###
### opening apps for applying manual preferences
###

center_frontmost_window() {

	osascript <<EOF
	tell application "System Events"
		set activeApps to name of application processes whose frontmost is true
		set currentApplication to item 1 of activeApps
		-- DEBUG -- currentApplication seems to be the correct application
		-- display notification currentApplication
		-- activate currentApplication
		-- Get the front window and its measurements
		set frontWindow to the first window of application process currentApplication
		set windowSize to size of frontWindow
		set windowPosition to position of frontWindow
	end tell
	
	-- Get the bounds of the screen
	tell application "Finder"
		set screenBounds to bounds of window of desktop
	end tell
	
	--calculate the center of the current window (without menu bar)
	set windowSizeX to item 1 of windowSize
	set windowSizeY to item 2 of windowSize - 30
	set windowCenterX to windowSizeX / 2
	set windowCenterY to windowSizeY / 2
	
	-- calculate the center of the screen
	set screenCenterX to (item 3 of screenBounds) / 2
	set screenCenterY to (item 4 of screenBounds) / 2
	
	--calculate the new window position
	set newWindowPositionX to screenCenterX - windowCenterX
	set newWindowPositionY to screenCenterY - windowCenterY
	
	-- set the new window position
	tell application "System Events"
		set position of frontWindow to {newWindowPositionX, newWindowPositionY}
	end tell

EOF
}

open_applications() {

    while IFS= read -r line || [[ -n "$line" ]] 
	do
	    if [[ "$line" == "" ]]; then continue; fi
        APP_NAME="$line"
        env_get_path_to_app
		if [[ "$PATH_TO_APP" != "" ]]
		then
		    echo "opening $(basename "$PATH_TO_APP")"
			open "$PATH_TO_APP" &
			sleep 5
			if [[ "$APP_NAME" == "Reminders" ]]
			then		
osascript <<EOF
tell application "Reminders"
	launch
	delay 3
	#activate
	#delay 2
end tell

# do not use visible as it makes the window un-clickable
#tell application "System Events" to tell process "Reminders" to set visible to true
#delay 1
tell application "System Events" to tell process "Reminders" to set frontmost to true
delay 1
	
try
	tell application "System Events" 
		tell process "Reminders" 
			click button "Weiter" of window 1
			delay 2
		end tell
	end tell
end try
tell application "System Events" to tell process "Reminders"
	#return position of window 1
	#return size of window 1
    set position of window 1 to {0, 50}
    set size of window 1 to {860, 850}
    delay 2
end tell
EOF
center_frontmost_window

			fi

			if [[ "$APP_NAME" == "Calendar" ]]
			then		
osascript <<EOF
tell application "Calendar"
	launch
	delay 3
	#activate
	#delay 2
end tell

# do not use visible as it makes the window un-clickable
#tell application "System Events" to tell process "Calendar" to set visible to true
#delay 1
tell application "System Events" to tell process "Calendar" to set frontmost to true
delay 1

tell application "System Events" to tell process "Calendar"
	#return position of window 1
	#return size of window 1
    set position of window 1 to {0, 50}
    set size of window 1 to {1650, 950}
    delay 2
end tell
EOF

center_frontmost_window

# disable default holiday calendar
osascript <<EOF
tell application "System Events"
	tell process "Calendar"
		
		set frontmost to true
		
		delay 1
		
		#click menu item "Einstellungen …" of menu "Calendar" of menu bar item "Calendar" of menu bar 1
		keystroke "," using {command down}
		
		delay 1
		
		# general tab
		#click button "Allgemein" of toolbar 1 of window "Allgemein"
		click button 1 of toolbar 1 of window 1
		
		delay 1
		
		#click checkbox "Feiertagskalender einblenden" of window "Allgemein"
		set theCheckbox to checkbox 2 of window 1
		tell theCheckbox
			#click theCheckbox
			#delay 0.2
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		
		delay 1
		
		# notifications tab
		#click button "Hinweise" of toolbar 1 of window "Allgemein"
		click button 3 of toolbar 1 of window 1
		
		delay 1
		
		# notifications for events
		tell pop up button 1 of group 1 of window 1
			perform action "AXShowMenu"
			#click menu item 6 of menu 1
			click menu item "30 Minuten vorher" of menu 1
		end tell
		
		delay 1
		
		# notifications for birthdays
		tell pop up button 1 of window 1
			perform action "AXShowMenu"
			#click menu item 2 of menu 1
			click menu item "Gleicher Tag (9 Uhr)" of menu 1
		end tell
		
		delay 1
		
		#tell application "System Events" to close window 1
		keystroke "w" using command down
		
	end tell
end tell
EOF

			fi

			# contacts
			if [[ "$APP_NAME" == "Contacts" ]]
			then		
				osascript <<EOF
				tell application "Contacts"
					launch
					delay 3
					#activate
					#delay 2
				end tell
				
				# do not use visible as it makes the window un-clickable
				#tell application "System Events" to tell process "Contacts" to set visible to true
				#delay 1
				tell application "System Events" to tell process "Contacts" to set frontmost to true
				delay 1
					
				tell application "System Events" to tell process "Contacts"
					#return position of window 1
					#return size of window 1
				    set position of window 1 to {0, 50}
				    set size of window 1 to {1000, 800}
				    delay 2
				end tell
EOF
				center_frontmost_window
			else
				:
			fi
			
			
			# whatsapp
			if [[ "$APP_NAME" == "WhatsApp" ]]
			then		
				osascript <<EOF
				tell application "WhatsApp"
					launch
					delay 3
					#activate
					#delay 2
				end tell
				
				# do not use visible as it makes the window un-clickable
				#tell application "System Events" to tell process "WhatsApp" to set visible to true
				#delay 1
				tell application "System Events" to tell process "WhatsApp" to set frontmost to true
				delay 1
					
				tell application "System Events" to tell process "WhatsApp"
					#return position of window 1
					#return size of window 1
				    set position of window 1 to {0, 50}
				    set size of window 1 to {1150, 825}
				    delay 2
				end tell
EOF
				center_frontmost_window
			else
				:
			fi
			
			
			# signal
			if [[ "$APP_NAME" == "Signal" ]]
			then		
				osascript <<EOF
				tell application "Signal"
					launch
					delay 3
					#activate
					#delay 2
				end tell
				
				# do not use visible as it makes the window un-clickable
				#tell application "System Events" to tell process "Signal" to set visible to true
				#delay 1
				tell application "System Events" to tell process "Signal" to set frontmost to true
				delay 1
					
				tell application "System Events" to tell process "Signal"
					#return position of window 1
					#return size of window 1
				    set position of window 1 to {0, 50}
				    set size of window 1 to {1150, 825}
				    delay 2
				end tell
EOF
				center_frontmost_window

			else
				:
			fi

			
		else
			echo "$APP_NAME not found, skipping..."
		fi
	done <<< "$(printf "%s\n" "${applications_to_open[@]}")"
	
}

echo ''
echo "opening apps for applying preferences manually..."


VERSION_TO_CHECK_AGAINST=12
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos until and including 12
    
	# confirm kext extensions
	# allowing kext extensions via mobileconfig profile does not work locally, has to be deployed by a trusted mdm server
	osascript <<EOF
	tell application "System Settings"
		reopen
		delay 3
		#activate
		#delay 2	
		#set paneids to (get the id of every pane)
		#display dialog paneids
		#return paneids
		#set current pane to pane "com.apple.preference.security"
		#get the name of every anchor of pane id "com.apple.preference.security"
		#set tabnames to (get the name of every anchor of pane id "com.apple.preference.security")
		#display dialog tabnames
		#return tabnames
		reveal anchor "General" of pane id "com.apple.preference.security"
	end tell
	
	# do not use visible as it makes the window un-clickable
	#tell application "System Events" to tell process "System Settings" to set visible to true
	#delay 1
	tell application "System Events" to tell process "System Settings" to set frontmost to true
	delay 1	
EOF
	sleep 2

else
	# macos versions 13 and up
	:
fi


### opening apps
applications_to_open=(
"FaceTime"
"Messages"
"Calendar"
"Contacts"
"Reminders"
"BresinkSoftwareUpdater"
"Wireguard"
"WhatsApp"
"Signal"
#"Overflow 3"
#"VirusScannerPlus"
#"BetterTouchTool"
)
open_applications

open_more_apps() {
	# no longer needed, but kept for testing
	applications_to_open_test=(
	"Adobe Acrobat Reader DC"
	"AppCleaner"
	"iStat Menus"
	"Microsoft Excel"
	"MacPass"
	"The Unarchiver"
	)
	applications_to_open=$(printf "%s\n" "${applications_to_open_test[@]}")
	open_applications
}
#open_more_apps


### google consent
# deprecated as long as super agent extension is used
# google consent link update
#open -a ""$PATH_TO_APPS"/Safari.app" "https://consent.google.com/d?continue=https://www.google.com/search?client%3Dsafari%26rls%3Den%26q%3Dtest%26ie%3DUTF-8%26oe%3DUTF-8&gl=DE&m=0&pc=srp&uxe=none&hl=de&src=2"
# check here 
# google.de - Datenschutzerklärung - Privatsphärencheck


### open user specific apps
if [[ "$APPLICATIONS_TO_OPEN_USER_SPECIFIC" != "" ]]
then
    applications_to_open=$(printf "%s\n" "${APPLICATIONS_TO_OPEN_USER_SPECIFIC[@]}")
    open_applications
else
    :
fi


### moved to manual install script so that auto reboot after batch_script1 and therefore restoring keychain works
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
	if command -v brew &> /dev/null
	then
	    # installed
	    BREW_PATH_PREFIX=$(brew --prefix)
	else
	    # not installed
	    echo "homebrew is not installed, exiting..."
	    echo ''
	    exit
	fi
	if [[ $(brew list --cask | grep "^libreoffice-language-pack$") != "" ]] 
	then
	    # installung libreoffice language pack
	    LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK=$(ls -1 "$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack | sort -V | head -n 1)
	    SKIP_ENV_GET_PATH_TO_APP="yes"
	    PATH_TO_APP=""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app"
	    env_set_open_on_first_run_permissions
	    PATH_TO_APP=""$PATH_TO_APPS"/LibreOffice.app"
	    env_set_open_on_first_run_permissions
	    open ""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app" &
	    unset SKIP_ENV_GET_PATH_TO_APP
	    sleep 5
	else
		:
	fi
    
    # no longer needed with according cleaning settings in restore script
    #if [[ "$DISPLAY_SIGNAL_DIALOG" == "yes" ]]
	#then
    #	# hint for signal
    #	osascript -e 'display dialog "please unlink all devices from signal on ios before opening the macos desktop app..."' &
    #else
    #	:
    #fi
    
    # no longer needed due to installing wireguard mobileconfig
    #if [[ "$DISPLAY_WIREGUARD_DIALOG" == "yes" ]]
	#then
    #	osascript -e 'display dialog "please add wireguard ondemand settings manually after restoring the profiles..."' &
    #else
    #	:
    #fi
else
	:
fi


VERSION_TO_CHECK_AGAINST=12
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos until and including 12

	### opening system preferences for the monitor
	open_system_prefs_monitor() {
	#osascript 2>/dev/null <<EOF
	osascript <<EOF
	
	tell application "System Preferences"
		reopen
		delay 3
		#activate
		#delay 2
		set current pane to pane "com.apple.preference.displays"
		set tabnames to (get the name of every anchor of pane id "com.apple.preference.displays")
		#display dialog tabnames
		#get the name of every anchor of pane id "com.apple.preference.displays"
		reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
	end tell
	
	# do not use visible as it makes the window un-clickable
	#tell application "System Events" to tell process "System Settings" to set visible to true
	#delay 1
	tell application "System Events" to tell process "System Settings" to set frontmost to true
	delay 1
	
	delay 2
	
EOF
	}
	#open_system_prefs_monitor

else
	# macos versions 13 and up
	:
fi

# opening 
VERSION_TO_CHECK_AGAINST=12
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos until and including 12
    :
else
	# checking allowed in background items
	# opening system settings panes is documented in install_mobileconfig_profiles_xx.sh
	open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
fi


### testing ssh connection
echo ''
SCRIPT_NAME="ssh_connection_test"
SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
SCRIPT_DIR_INPUT_KEEP="$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep
if [[ -e "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh ]]
then
    USER_ID=`id -u`
    chown "$USER_ID":staff "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    chmod 700 "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    . "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
else
    echo "script to test ssh connections not found..."
fi
   
          
### reinstalling textmate
# for some reason textmate breaks on first install, second install fixes installation
echo ''
echo "reinstalling textmate to avoid error on opening..."
brew install --cask --force textmate 2> /dev/null | grep "successfully installed"


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''
