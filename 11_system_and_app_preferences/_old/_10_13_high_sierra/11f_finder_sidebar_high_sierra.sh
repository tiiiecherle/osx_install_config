#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



# sfltool
# sfltool restore|add-item|save-lists|test|archive|enable-modern|dump-server-state|clear|disable-modern|dump-storage|list-info [options]

# mysides
# installs to /usr/local/bin/mysides
# -rwxr-xr-x    1 root  wheel  47724 14 Apr 02:07 mysides
# https://github.com/mosen/mysides
MYSIDESVERSION="1.0.1"
read -r -p "do you want to install / update to mysides "$MYSIDESVERSION"? (y/N) " answer
response="$(echo "$answer" | tr '[:upper:]' '[:lower:]')"    # tolower
#echo $response
# >= bash 4
#if [[ $response =~ ^(yes|y|"")$ ]]
# >= bash 3.2
#if [[ $response =~ ^([yes]|[y]|[""])$ ]]
#
#if [[ $response == "y" || $response == "yes" || $response == "" ]]
if [[ $response == "y" || $response == "yes" ]]
then
	echo "downloading and installing mysides..."
	MYSIDESINSTALLER="/Users/$USER/Desktop/mysides-"$MYSIDESVERSION".pkg"
	wget https://github.com/mosen/mysides/releases/download/v1.0.0/mysides-1.0.0.pkg -O "$MYSIDESINSTALLER"
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
echo "clearing and setting finder sidebare items..."

# clearing out settings and removes icloud
#sfltool clear
# if everything is cleared with this command, block three (device, external drives, cds, dvds and ipods) would need a second reboot and applying settings again to work after first reboot
#sleep 5

# currently only working with latest git version, not with 1.0.0
# disable sip
# copy build file to /usr/local/bin/mysides
# sudo chown root:wheel "/usr/local/bin/mysides"
# sudo chmod 755 "/usr/local/bin/mysides"
#mysides remove all
#
#mysides remove "Alle meine Dateien"
mysides remove myDocuments.cannedSearch
mysides remove iCloud
mysides add domain-AirDrop nwnode://domain-AirDrop
mysides remove domain-AirDrop
mysides add Applications file:///Applications
mysides add Desktop file:///Users/${USER}/Desktop
mysides add Documents file:///Users/${USER}/Documents
mysides add Downloads file:///Users/${USER}/Downloads
mysides add Movies file:///Users/${USER}/Movies
mysides add Music file:///Users/${USER}/Music
mysides add Pictures file:///Users/${USER}/Pictures
mysides add ${USER} file:///Users/${USER}
if [[ $USER == tom ]]
then
	mysides add files file:///Users/${USER}/Desktop/files
	# or
	#/usr/bin/sfltool add-item com.apple.LSSharedFileList.FavoriteItems file:///Users/$USER/Desktop/files && sleep 2
else
	:
fi	
if [[ $USER == wolfgang ]]
then
	echo ''
	read -r -p $'to add entries form a network volume you have to be connected to the volume as the user that uses the links later.\nplease connect to /Volumes/office/ as the respective user.\nare you connected to /Volumes/office/ as the user that uses the links later? (Y/n) ' answer
	response="$(echo "$answer" | tr '[:upper:]' '[:lower:]')"    # tolower
	if [[ $response == "y" || $response == "yes" || $response == "" ]]
	then
		mysides add Aufträge file:///Volumes/office/documents/gep/material/VIII%20Auftra%CC%88ge/
		mysides add Scans file:///Volumes/office/documents/_scan
		mysides add Tabellen file:///Volumes/office/documents/mfs/allg/_tabellen
		mysides add Solarplan file:///Volumes/office/documents/mfs/solarplan
		mysides add Projektordner file:///Volumes/office/documents/mfs/projektordner
		mysides add Überwacchung file:///Volumes/office/documents/mfs/projektordner/ueberwachung
		echo ''
	else
		echo ''
	fi
else
	:
fi	

#touch ~/Library/Preferences/com.apple.sidebarlists.plist
if [[ -e ~/Library/Preferences/com.apple.sidebarlists.plist ]]
then
	rm ~/Library/Preferences/com.apple.sidebarlists.plist
else
	:
fi

# run applescript to set sidebar preferences
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
		#set theCheckbox to checkbox "Zugang zu meinem Mac" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 12 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# verbundene server
		#set theCheckbox to checkbox "Verbundene Server" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 13 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# bonjour
		#set theCheckbox to checkbox "Bonjour-Computer" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 14 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# computer
		set host_name to (do shell script "echo $HOSTNAME")
		--return host_name
		#set theCheckbox to checkbox host_name of window "Finder-Einstellungen"
		set theCheckbox to checkbox 15 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is true then click theCheckbox
		end tell
		delay 0.2
		# festplatten
		#set theCheckbox to checkbox "Festplatten" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 16 of window 1
		click theCheckbox
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# externe festplatten
		#set theCheckbox to checkbox "Externe Festplatten" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 17 of window 1
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# cds, dvds, ipods
		#set theCheckbox to checkbox "CDs, DVDs und iPods" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 18 of window 1
		click theCheckbox
		tell theCheckbox
			set checkboxStatus to value of theCheckbox as boolean
			if checkboxStatus is false then click theCheckbox
		end tell
		delay 0.2
		# tags
		#set theCheckbox to checkbox "Benutzte Tags" of window "Finder-Einstellungen"
		set theCheckbox to checkbox 19 of window 1
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

# show tags
defaults write com.apple.finder ShowRecentTags -bool false

# restart finder
#killall Finder

echo "done ;)"
echo "the changes need a reboot to take effect..."
#echo "initializing reboot"
echo ""

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout
