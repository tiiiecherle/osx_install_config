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
	    local VERSION_NUMBER=""
		local APP_NAME="XtraFinder"
		local APP_NAME_LOWERED=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
		local AUTOMATION_APP_NAME="$APP_NAME".app
		local APP_INSTALLER="/Users/"$USER"/Desktop/"$APP_NAME".dmg"
		#local MANUAL_INSTALL_SOURCE="/Volumes/"$APP_NAME"/For OS X 10.13 - 10.6"
		local MANUAL_INSTALL_SOURCE="/Volumes/"$APP_NAME"/For OS X "$MACOS_VERSION_MAJOR" "$MACOS_MARKETING_NAME"/Manual Installation"
		local BUNDLE_PATH_SOURCE=""$MANUAL_INSTALL_SOURCE"/"$APP_NAME"Plugins.bundle"
		local BUNDLE_PATH_DESTINATION="/System/Library/PrivateFrameworks/FileProvider.framework/OverrideBundles/"$APP_NAME"Plugins.bundle"
		
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
	    VERSION_TO_CHECK_AGAINST=10.15
	    if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
        then
		    # macos versions 10.15
	        # in 10.15 /System default gets mounted read-only
	        # can only be mounted read/write with according SIP settings
	        sudo mount -uw /
	        # stays mounted rw until next reboot
	        sleep 0.5 
		else
		    # macos versions other than 10.15
			echo ''
		    echo "this script is only compatible with macos 10.15 and newer, exiting..."
		    echo ''
		    exit
		fi
		
		# as "$APP_NAME" is no longer installable by cask let`s install it that way ;)
	    #if [[ "$RUN_FROM_CASKS_SCRIPT" == "yes" ]]; then :; else echo ''; fi
		echo "downloading "$APP_NAME_LOWERED"..."
		curl https://www.trankynam.com/"$APP_NAME_LOWERED"/downloads/"$APP_NAME".dmg -o "$APP_INSTALLER" --progress-bar
		echo "mounting image..."
		yes | hdiutil attach "$APP_INSTALLER" 1>/dev/null
		sleep 5
		# uninstall before xtrafinder 1.5.1
		#if [[ -e "$PATH_TO_APPS"/XtraFinder.app ]]
		#then
		#	echo "uninstalling application..."
		#	env_use_password | sudo "$MANUAL_INSTALL_SOURCE"/Extra/Uninstall.app/Contents/MacOS/Uninstall 2>&1 | grep -v "Failed to connect (window) outlet"
		#	sleep 10
		#else
		#	:
		#fi
		# additional uninstall steps xtrafinder 1.5.1 and newer
		echo "uninstalling..."
		COMPONENTS_TO_UNINSTALL=(
		"/System/Library/PrivateFrameworks/FileProvider.framework/OverrideBundles/"$APP_NAME"Plugins.bundle"
		"/System/Library/ScriptingAdditions/"$APP_NAME"Injector.osax"
		"/"$PATH_TO_APPS"/"$APP_NAME".app"
		)
		for i in "${COMPONENTS_TO_UNINSTALL[@]}"
		do
			if [[ -e "$i" ]]
			then
				env_use_password | sudo rm -rf "$i"
			else
				:
			fi
		done
		echo "installing application..."
		# install xtrafinder
		#env_use_password | sudo installer -pkg "$MANUAL_INSTALL_SOURCE"/"$APP_NAME".pkg -target /
		# additional install steps xtrafinder 1.5.1 and newer
		echo "installing..."
		env_use_password | sudo cp -a "$BUNDLE_PATH_SOURCE" "$BUNDLE_PATH_DESTINATION"
		env_use_password | sudo chown -R root:wheel "$BUNDLE_PATH_DESTINATION"
		env_use_password | sudo cp -a ""$MANUAL_INSTALL_SOURCE"/"$APP_NAME"Loader.app" ""$PATH_TO_APPS"/"$APP_NAME".app"
		env_use_password | sudo chown -R root:admin ""$PATH_TO_APPS"/"$APP_NAME".app"
		sleep 1
		echo "unmounting and removing installer..."
		hdiutil detach /Volumes/"$APP_NAME" -quiet
		if [[ -e "$APP_INSTALLER" ]]; then rm "$APP_INSTALLER"; else :; fi
		
		
		### automation
	    # macos versions 10.14 and up
	    AUTOMATION_APPS=(
	    # source app name							automated app name											allowed (1=yes, 0=no)
	    "$APP_NAME                       			Finder                  									1"
	    )
	    PRINT_AUTOMATING_PERMISSIONS_ENTRIES="no" env_set_apps_automation_permissions
		
		
		### preferences
		if [[ -e ""$PATH_TO_APPS"/"$APP_NAME".app" ]]
	    then
	
	    	echo "setting "$APP_NAME_LOWERED" preferences..."
	    	
	    	# automatically check for updates
	    	defaults write com.apple.finder XFAutomaticChecksForUpdate -bool true
	    	
	    	# enable copy / cut - paste
	    	defaults write com.apple.finder XtraFinder_XFCutAndPastePlugin -bool true
	    	
	    	# disable xtrafinder tabs
	    	defaults write com.apple.finder XtraFinder_XFTabPlugin -bool false
	    	
	    	# # disable xtrafinder menu bar icon
	    	#defaults write com.apple.finder XtraFinder_ShowStatusBarIcon -bool false
	    	
	    	
	    	### right click finder plugins
	    	
	    	# show copy path
	    	#defaults write com.apple.finder XtraFinder_XFCopyPathMenuPlugin -bool true
	    	
	    	# path type options
	    	# 0 = path, 3 = hfs path, 4 = terminal path
	    	defaults write com.apple.finder XtraFinder_XFCopyPathMenuPlugin_Default -integer 0
	    	
	    	# show make symbolic link
	    	defaults write com.apple.finder XtraFinder_XFMakeSymbolicLinkActionPlugin -bool false
	    	
	    	# show open in new window
	    	defaults write com.apple.finder XtraFinder_XFOpenInNewWindowPlugin -bool true
			
			# autostart
			AUTOSTART_ITEMS=(
		    # name													                  start hidden
		    ""$APP_NAME"                                                              false"                   
		    )
		    env_add_startup_items
	
	    else
	    	:
	    fi

		echo "please logout or reboot before starting "$APP_NAME"..."
		
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
