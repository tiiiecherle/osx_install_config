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

# checking if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    #echo ''
    
    
    ### registering xtrafinder
    echo ''
    SCRIPT_DIR_LICENSE="$SCRIPT_DIR_TWO_BACK"
	if [[ -e "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/xtrafinder_register.sh ]]
	then
	    "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/xtrafinder_register.sh
	else
	    echo "script to register xtrafinder not found..."
	fi
    
    
    ### installation 	
	# as xtrafinder is no longer installable by cask let`s install it that way ;)
    echo ''
	echo "downloading xtrafinder..."
	XTRAFINDER_INSTALLER="/Users/$USER/Desktop/XtraFinder.dmg"
	#wget https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -O "$XTRAFINDER_INSTALLER"
	curl https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -o "$XTRAFINDER_INSTALLER" --progress-bar
	#open "$XTRAFINDER_INSTALLER"
	echo "mounting image..."
	yes | hdiutil attach "$XTRAFINDER_INSTALLER" 1>/dev/null
	sleep 5
	# uninstall
	echo "uninstalling application..."
	#env_use_password | sudo /Volumes/XtraFinder/Extra/Uninstall.app/Contents/MacOS/Uninstall 1>/dev/null
	env_use_password | sudo /Volumes/XtraFinder/Extra/Uninstall.app/Contents/MacOS/Uninstall 2>&1 | grep -v "Failed to connect (window) outlet"
	sleep 10
	echo "installing application..."
	env_use_password | sudo installer -pkg /Volumes/XtraFinder/XtraFinder.pkg -target / 1>/dev/null
	#sudo installer -pkg /Volumes/XtraFinder/XtraFinderInstaller.pkg -target / 1>/dev/null
	sleep 1
	#echo "waiting for installer to finish..."
	#while ps aux | grep 'installer' | grep -v grep > /dev/null; do sleep 1; done
	echo "unmounting and removing installer..."
	hdiutil detach /Volumes/XtraFinder -quiet
	if [ -e "$XTRAFINDER_INSTALLER" ]; then rm "$XTRAFINDER_INSTALLER"; else :; fi
	
	
	### automation
    # macos versions 10.14 and up
    AUTOMATION_APPS=(
    # source app name							automated app name											allowed (1=yes, 0=no)
    "XtraFinder                                 Finder                  									1"
    )
    PRINT_AUTOMATING_PERMISSIONS_ENTRYS="no" env_set_apps_automation_permissions
	
	
	### preferences
	if [ -e "/Applications/XtraFinder.app" ]
    then
    
    	echo "setting xtrafinder preferences..."
    	
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
    	osascript -e 'tell application "System Events" to make login item at end with properties {name:"XtraFinder", path:"/Applications/XtraFinder.app", hidden:false}'
    	
    else
    	:
    fi

    	
else
    # offline
    echo "skipping installation..."
    #echo ''
fi

echo ''
echo "done ;)"
echo ''

###
### unsetting password
###

unset SUDOPASSWORD
