#!/bin/zsh

add_finder_favorites() {
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
		
		set value of text field "Serveradresse:" of window "Mit Server verbinden" to "smb://172.16.1.200"
		
		delay 1
		click button 1 of window "Mit Server verbinden"
		delay 1
		
	end tell
	
end tell

#tell application "Finder" to close front window
tell application "Finder" to close window "Mit Server verbinden"

EOF
}
add_finder_favorites

echo "done ;)"
