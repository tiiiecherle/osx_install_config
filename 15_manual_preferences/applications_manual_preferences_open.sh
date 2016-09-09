#!/bin/bash

# opening apps for applying manual preferences
echo "opening apps for applying preferences manually..."

applications_to_open=(
"/Applications/Safari.app"
"/Applications/Firefox.app"
"/Applications/Adobe Acrobat Reader DC.app"
"/Applications/Adobe Acrobat X Pro/Adobe Acrobat Pro.app"
"/Applications/AppCleaner.app"
#"/Applications/Bartender 2.app"
"/Applications/FaceTime.app"
"/Applications/GitHub Desktop.app"
"/Applications/iStat Menus.app"
"/Applications/iTunes.app"
"/Applications/Calendar.app"
"/Applications/Contacts.app"
"/Applications/Mail.app"
"/Applications/Microsoft Excel.app"
"/Applications/Microsoft Word.app"
"/Applications/Microsoft Office 2011/Microsoft Excel.app"
"/Applications/Microsoft Office 2011/Microsoft Word.app"
"/Applications/Messages.app"
"/Applications/The Unarchiver.app"
"/Applications/Xcode.app"
"/Applications/iphone/iMazing.app"
)

for i in "${applications_to_open[@]}"
do
	if [ -e "$i" ]
	then
	    echo "opening $(basename "$i")"
		open "$i"
	else
		:
	fi
done

# opening system preferences for the monitor
function open_system_prefs_monitor() {
#osascript 2>/dev/null <<EOF
osascript <<EOF

tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.displays"
	set tabnames to (get the name of every anchor of pane id "com.apple.preference.displays")
	#display dialog tabnames
	#get the name of every anchor of pane id "com.apple.preference.displays"
	reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
end tell

delay 2

EOF
}
open_system_prefs_monitor

echo "done ;)"
