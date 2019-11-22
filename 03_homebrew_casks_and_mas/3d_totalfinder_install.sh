#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

env_enter_sudo_password



###
### installation
###

install_finder_enhancement() {

	# checking if online
	env_check_if_online
	if [[ "$ONLINE_STATUS" == "online" ]]
	then
	    # online
	    #echo ''
	    
	    
	    ### variables
	    #local VERSION_NUMBER="1.12.2"
	    #local VERSION_NUMBER=$(curl -s https://totalfinder.binaryage.com/ | grep -o "TotalFinder.*.dmg" | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
	    #local VERSION_NUMBER=$(curl -s https://totalfinder.binaryage.com/changelog-beta.txt | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -n1)
	    local VERSION_NUMBER=$(curl -s https://totalfinder.binaryage.com/changelog.txt | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | head -n1)
		local APP_NAME="TotalFinder"
		local APP_NAME_LOWERED=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
		local AUTOMATION_APP_NAME="$APP_NAME".app
		local APP_INSTALLER="/Users/"$USER"/Desktop/"$APP_NAME".dmg"
		
		
		### registering "$APP_NAME"
	    local SCRIPT_DIR_LICENSE="$SCRIPT_DIR_TWO_BACK"
		if [[ -e "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/"$APP_NAME_LOWERED"_register.sh ]]
		then
			echo ''
		    "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/"$APP_NAME_LOWERED"_register.sh
		else
		    echo "script to register "$APP_NAME_LOWERED" not found..."
		fi
	    
	    
	    ### installation
		# as "$APP_NAME" is no longer installable by cask let`s install it that way ;)
	    #if [[ "$RUN_FROM_CASKS_SCRIPT" == "yes" ]]; then :; else echo ''; fi
		echo "downloading "$APP_NAME_LOWERED"..."
		curl https://downloads.binaryage.com/"$APP_NAME"-"$VERSION_NUMBER".dmg -o "$APP_INSTALLER" --progress-bar
		echo "mounting image..."
		yes | hdiutil attach "$APP_INSTALLER" 1>/dev/null
		sleep 5
		# uninstall
		#echo "uninstalling application..."
		#open ""$PATH_TO_APPS"/TotalFinder.app/Contents/Resources/TotalFinder.bundle/Contents/Resources/TotalFinder Uninstaller.app"
		#sleep 10
		echo "installing application..."
		#env_use_password | sudo installer -pkg /Volumes/"$APP_NAME"/"$APP_NAME".pkg -target / 1>/dev/null
		env_use_password | sudo installer -pkg /Volumes/"$APP_NAME"/"$APP_NAME".pkg -target /
		sleep 1
		echo "unmounting and removing installer..."
		hdiutil detach /Volumes/"$APP_NAME" -quiet
		if [[ -e "$APP_INSTALLER" ]]; then rm "$APP_INSTALLER"; else :; fi
		
		
		### automation
	    # macos versions 10.14 and up
	    AUTOMATION_APPS=(
	    # source app name							automated app name											allowed (1=yes, 0=no)
	    "$AUTOMATION_APP_NAME                       Finder                  									1"
	    )
	    PRINT_AUTOMATING_PERMISSIONS_ENTRIES="no" env_set_apps_automation_permissions
		
		
		### preferences
		if [[ -e ""$PATH_TO_APPS"/"$APP_NAME".app" ]]
	    then
	    
	    	echo "setting "$APP_NAME_LOWERED" preferences..."
	
			defaults write com.binaryage.totalfinder TotalFinderDontCustomizeDockIcon -bool true
	
			defaults write com.binaryage.totalfinder TotalFinderTabsDisabled -bool true
			
			# open /Users/"$USER"/Library/Preferences/com.binaryage.totalfinder.plist
			
			# autostart
	    	osascript -e 'tell application "System Events" to make login item at end with properties {name:"'$APP_NAME'", path:"'$PATH_TO_APPS'/'$APP_NAME'.app", hidden:false}'
	
	    else
	    	:
	    fi

	else
	    # offline
	    echo "skipping installation..."
	    #echo ''
	fi
}
install_finder_enhancement


if [[ "$RUN_FROM_CASKS_SCRIPT" == "yes" ]]
then
	:
else
	echo ''
	echo "done ;)"
	echo ''
fi

###
### unsetting password
###

unset SUDOPASSWORD
