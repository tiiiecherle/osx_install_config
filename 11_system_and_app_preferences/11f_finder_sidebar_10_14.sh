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
### compatibility
###

# specific macos version only
if [[ "$MACOS_VERSION_MAJOR" != "10.14" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.14, exiting..."
    echo ''
    exit
else
    :
fi



###
### security permissions
###

echo ''    
env_databases_apps_security_permissions
env_identify_terminal


echo "setting security and automation permissions..."
### automation
# macos versions 10.14 and up
AUTOMATION_APPS=(
# source app name							automated app name										    allowed (1=yes, 0=no)
"$SOURCE_APP_NAME                           System Events                                               1"
"$SOURCE_APP_NAME                           Finder		                                                1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions


### sfltool
# sfltool restore|add-item|save-lists|test|archive|enable-modern|dump-server-state|clear|disable-modern|dump-storage|list-info [options]


### alternative to mysides
# https://github.com/robperc/FinderSidebarEditor


### mysides
# BREW_PATH_PREFIX=$(brew --prefix)
# installs to "$BREW_PATH_PREFIX"/bin/mysides
# -rwxr-xr-x    1 root  wheel  47724 14 Apr 02:07 mysides
# https://github.com/mosen/mysides
# newer version here
# https://github.com/Tatsh/mysides
MYSIDESVERSION="1.0.1"
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    :
else
    echo ''
fi
VARIABLE_TO_CHECK="$INSTALL_UPDATE_MYSIDES"
QUESTION_TO_ASK="do you want to install / update to mysides "$MYSIDESVERSION"? (y/N) "
env_ask_for_variable
INSTALL_UPDATE_MYSIDES="$VARIABLE_TO_CHECK"

if [[ "$INSTALL_UPDATE_MYSIDES" =~ ^(yes|y)$ ]]
then
	echo "downloading and installing mysides..."
	MYSIDESINSTALLER="/Users/$USER/Desktop/mysides-"$MYSIDESVERSION".pkg"
	#wget https://github.com/mosen/mysides/releases/download/v"$MYSIDESVERSION"/mysides-"$MYSIDESVERSION".pkg -O "$MYSIDESINSTALLER"
	curl https://github.com/mosen/mysides/releases/download/v"$MYSIDESVERSION"/mysides-"$MYSIDESVERSION".pkg -o "$MYSIDESINSTALLER" --progress-bar
	open "$MYSIDESINSTALLER"
	echo "waiting for installer to finish..."
	while ps aux | grep 'Installer.app.*Installer' | grep -v grep > /dev/null; do sleep 1; done
	echo "removing installer file..."
	if [ -e "$MYSIDESINSTALLER" ]; then rm "$MYSIDESINSTALLER"; else :; fi
	echo "continuing setting finder sidebar entries..."
	sleep 2
else
    :
fi

echo ''
echo "clearing and setting finder sidebar items..."

# clearing out settings and removes icloud
#sfltool clear
# if everything is cleared with this command, block three (device, external drives, cds, dvds and ipods) would need a second reboot and applying settings again to work after first reboot
#sleep 5

# currently only working with latest git version, not with 1.0.0
# disable sip
# BREW_PATH_PREFIX=$(brew --prefix)
# copy build file to "$BREW_PATH_PREFIX"/bin/mysides
# sudo chown root:wheel ""$BREW_PATH_PREFIX"/bin/mysides"
# sudo chmod 755 ""$BREW_PATH_PREFIX"/bin/mysides"
#mysides remove all
#
#mysides remove "Alle meine Dateien"
#mysides remove myDocuments.cannedSearch
#mysides remove iCloud
#mysides add domain-AirDrop nwnode://domain-AirDrop
mysides remove domain-AirDrop >/dev/null 2>&1
mysides add Applications file://"$PATH_TO_APPS"
mysides add Desktop file:///Users/"$USER"/Desktop
mysides add Documents file:///Users/"$USER"/Documents
mysides add Downloads file:///Users/"$USER"/Downloads
mysides add Movies file:///Users/"$USER"/Movies
mysides add Music file:///Users/"$USER"/Music
mysides add Pictures file:///Users/"$USER"/Pictures
mysides add "$USER" file:///Users/"$USER"

# user specific customization
SCRIPT_NAME="finder_sidebar_$USER"
SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
SCRIPT_DIR_INPUT_KEEP="$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep
if [[ -e "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh ]]
then
    echo ''
    echo "user specific sidebar customization script found..."
    USER_ID=`id -u`
    chown "$USER_ID":staff "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    chmod 700 "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
    . "$SCRIPT_DIR_INPUT_KEEP"/"$SCRIPT_NAME".sh
else
    echo ''
    echo "user specific sidebar customization script not found......"
fi
echo ''

#touch ~/Library/Preferences/com.apple.sidebarlists.plist
#if [[ -e ~/Library/Preferences/com.apple.sidebarlists.plist ]]
#then
#	rm ~/Library/Preferences/com.apple.sidebarlists.plist
#else
#	:
#fi


### run applescript to set sidebar preferences
#open /"$SCRIPT_DIR"/11f_script_finder_sidebar/11f_finder_sidebar.app

enable_disable_finder_sidebar_items() {
#osascript 2>/dev/null <<EOF
osascript <<EOF

tell application "System Events"
	
	set frontApp to first application process whose frontmost is true
	set frontAppName to name of frontApp
	
	tell process "Finder"
		set frontmost to true
		#click menu item "Einstellungen …" of menu "Finder" of menu bar item "Finder" of menu bar 1
		keystroke "," using {command down}
		delay 1
		#click button "Seitenleiste" of toolbar 1 of window "Finder-Einstellungen"
		click button 3 of toolbar 1 of window 1
		delay 1
		# zugang zu meinem mac
		#set theCheckbox to checkbox "iCloud Drive" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 11 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# computer
		set host_name to (do shell script "echo $HOSTNAME")
		--return host_name
		# last used
		#set theCheckbox to checkbox host_name of window "Finder-Einstellungen"
		set theCheckbox to checkbox 1 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# airdrop
		#set theCheckbox to checkbox host_name of window "Finder-Einstellungen"
		set theCheckbox to checkbox 2 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# my computer
		#set theCheckbox to checkbox host_name of window "Finder-Einstellungen"
		set theCheckbox to checkbox 12 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# festplatten
		#set theCheckbox to checkbox "Festplatten" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 13 of window 1
		click theCheckbox
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# externe festplatten
		#set theCheckbox to checkbox "Externe Festplatten" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 14 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# cds, dvds, ios-devices
		#set theCheckbox to checkbox "CDs, DVDs und iPods" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 15 of window 1
		click theCheckbox
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# bonjour
		#set theCheckbox to checkbox "Bonjour-Computer" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 16 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# verbundene server
		#set theCheckbox to checkbox "Verbundene Server" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 17 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# tags
		#set theCheckbox to checkbox "Benutzte Tags" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 18 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		#
		delay 1
		#tell application "Finder" to close window "Finder-Einstellungen"
		tell application "Finder" to close window 1
		
	end tell
	
	tell process frontAppName
		set frontmost to true
	end tell
	
end tell

EOF
}
enable_disable_finder_sidebar_items

# do not show icloud drive in drives
defaults write com.apple.finder SidebarShowingiCloudDesktop -bool false
defaults write com.apple.finder SidebarShowingSignedIntoiCloud -bool false

# show tags
defaults write com.apple.finder ShowRecentTags -bool false

# settings are in 
# ~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteVolumes.sfl2
# and
# ~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl2


### restarting finder
killall cfprefsd
killall Finder
sleep 5

enable_disable_finder_sidebar_items2() {
#osascript 2>/dev/null <<EOF
osascript <<EOF

tell application "System Events"
	
	set frontApp to first application process whose frontmost is true
	set frontAppName to name of frontApp
	
	tell process "Finder"
		set frontmost to true
		#click menu item "Einstellungen …" of menu "Finder" of menu bar item "Finder" of menu bar 1
		keystroke "," using {command down}
		delay 1
		#click button "Seitenleiste" of toolbar 1 of window "Finder-Einstellungen"
		click button 3 of toolbar 1 of window 1
		delay 1
		# icloud drive
		#set theCheckbox to checkbox "iCloud Drive" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 11 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		#
		delay 1
		#tell application "Finder" to close window "Finder-Einstellungen"
		tell application "Finder" to close window 1
		
	end tell
	
	tell process frontAppName
		set frontmost to true
	end tell
	
end tell

EOF
}
enable_disable_finder_sidebar_items2


### restarting finder
killall cfprefsd
killall Finder
sleep 5


### removing security permissions
#remove_apps_security_permissions_stop


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


#echo ''
echo "done ;)"
echo ''
