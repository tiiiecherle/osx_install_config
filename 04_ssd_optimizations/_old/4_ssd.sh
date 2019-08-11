#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



setting_ssd_preferences() {

	###
	### asking password upfront
	###
	
	env_enter_sudo_password
	
	
	
	###
	### ssd optimizations
	###
	
	VARIABLE_TO_CHECK="$DISK_IS_SSD"
	QUESTION_TO_ASK="Is your disk an ssd, otherwise it is not recommended to run this script (y/N)? "
	env_ask_for_variable
	DISK_IS_SSD="$VARIABLE_TO_CHECK"
	
	if [[ "$DISK_IS_SSD" =~ ^(yes|y)$ ]]
	then
		echo "continuing script..."
	
		###
		### SSD
		###
		
		echo "SSD"
		
		echo 'disabling deep sleep / hibernation...'
		
		# disable hibernation (speeds up entering sleep mode)
		sudo pmset -a hibernatemode 0
		# enable hibernation
		#sudo pmset -a hibernatemode 3
		
		# remove the sleep image file to save disk space
		# only do that with hibernation disabled
		sudo rm -rf /private/var/vm/sleepimage
		
		# create a zero-byte file instead
		sudo touch /private/var/vm/sleepimage
		
		# and make sure it can be rewritten
		sudo chflags uchg /private/var/vm/sleepimage
		
		# checking file size
		du -h /private/var/vm/sleepimage
		
		# preventing going from sleep to deep sleep / hibernate
		# time for waiting from going to deep sleep (autopoweroffdelay) can be found with
		# pmset -g | grep autopower
		sudo pmset -a autopoweroff 0
		# enable going from sleep to deep sleep / hibernate
		#sudo pmset -a autopoweroff 1
		
		# disable the sudden motion sensor as it is not useful for SSDs
		# not included for my macbookpro 2012 in sierra
		# pmset -g | grep sms
		#echo "disabling sudden motion sensor..."
		#sudo pmset -a sms 0
		# enable the sudden motion sensor
		#sudo pmset -a sms 1
		
		# disable local time machine backup
		#echo "disabling local time machine backup..."
		# already done in system preferences script
		#sudo tmutil disablelocal
		
		### noatime
	    echo "creating noatime launchd..."
	    
	    if [[ -e "/Library/LaunchDaemons/com.noatime.plist" ]]
	    then
	    	sudo rm "/Library/LaunchDaemons/com.noatime.plist"
	    else
	    	:
	    fi
	    
	    # closing EOL has to stay unindented
	    sudo "$SCRIPT_INTERPRETER" -c "cat >/Library/LaunchDaemons/com.noatime.plist" <<'EOF'
	    <?xml version="1.0" encoding="UTF-8"?>
	    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
	    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	    <plist version="1.0">
	    <dict>
	    <key>Label</key>
	    <string>com.noatime</string>
	    <key>ProgramArguments</key>
	    <array>
	    <string>mount</string>
	    <string>-uwo</string>
	    <string>noatime</string>
	    <string>/</string>
	    </array>
	    <key>RunAtLoad</key>
	    <true/>
	    </dict>
	    </plist>
EOF
	    
	    sudo chown root:wheel "/Library/LaunchDaemons/com.noatime.plist"
	    sudo chmod 644 "/Library/LaunchDaemons/com.noatime.plist"
	    
	    #ls -la /Library/LaunchDaemons/ | grep noatime.plist
	    #open /Library/LaunchDaemons/com.noatime.plist
	    
	    # launchd service
	    echo ""
	    echo "enabling launchd service..."
	    if [[ $(sudo launchctl list | grep com.noatime) != "" ]];
	    then
	        sudo launchctl unload "/Library/LaunchDaemons/com.noatime.plist"
	    else
	        :
	    fi
	    sudo launchctl load "/Library/LaunchDaemons/com.noatime.plist"
	    echo "waiting before checking if launchd is enabled..."
	    sleep 10
	    echo "checking if launchd service is enabled..."
	    sudo launchctl list | grep com.noatime
	    
	    echo ''
	    if [[ $(mount | grep " / " | grep noatime) == "" ]]
	    then
	    	echo "noatime is not enabled..."
	    else
	    	echo "noatime is enabled..."
	    fi
	    
	    # undo changes
	    # sudo launchctl unload "/Library/LaunchDaemons/com.noatime.plist"
	    # sudo rm "/Library/LaunchDaemons/com.noatime.plist"
		
		echo "done"
		
		echo "a few changes need a reboot or logout to take effect"
	    echo "initializing reboot"
	    
	    osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
	    #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
	    #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout
	
	else
		echo "this script is for ssds only... exiting..."
	fi
}
#setting_ssd_preferences
echo ''
echo "this script is deprecated, no changes have been made, exiting..."
echo ''

###
### unsetting password
###

unset SUDOPASSWORD
