#!/usr/bin/env bash


### variables
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

# macos 10.14 and higher
#if [[ $(echo $MACOS_VERSION | cut -f1 -d'.') == "10" ]] && [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
# macos 10.14 only
if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.') != "10.14" ]]
then
    #echo "this script is only compatible with macos 10.14 mojave and newer, exiting..."
    echo ''
    echo "this script is only compatible with macos 10.14 mojave, exiting..."
    echo ''
    exit
else
    :
fi


###

function add_finder_favorites() {
#osascript 2>/dev/null <<EOF
osascript <<EOF

tell application "System Events"
	tell process "Finder"
		set frontmost to true
		
		delay 1
		#click menu item "Mit Server verbinden …" of menu "Gehe zu" of menu bar item "Gehe zu" of menu bar 1 of application process "Finder" of application "System Events"
		click menu item "Mit Server verbinden …" of menu "Gehe zu" of menu bar item "Gehe zu" of menu bar 1
		delay 1
		#click text field "Serveradresse:" of window "Mit Server verbinden"
		#delay 1
		#keystroke "smb://172.16.1.200"
		
		set value of combo box 1 of window 1 to "smb://172.16.1.200"
		
		delay 1
		click button 1 of group 1 of window 1
		delay 1
		
	end tell
	
end tell

#tell application "Finder" to close front window
tell application "Finder" to close window "Mit Server verbinden"

EOF
}
add_finder_favorites

echo "done ;)"
