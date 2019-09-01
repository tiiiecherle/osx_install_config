#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



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
)
PRINT_AUTOMATING_PERMISSIONS_ENTRYS="yes" env_set_apps_automation_permissions
#echo ''



###
### opening apps for applying manual preferences
###

echo ''
echo "opening apps for applying preferences manually..."

applications_to_open=(
#"/Applications/Safari.app"
#"/Applications/Firefox.app"
""$PATH_TO_APPS"/Adobe Acrobat Reader DC.app"
#""$PATH_TO_APPS"/Adobe Acrobat X Pro/Adobe Acrobat Pro.app"
""$PATH_TO_APPS"/AppCleaner.app"
""$PATH_TO_SYSTEM_APPS"/FaceTime.app"
""$PATH_TO_APPS"/iStat Menus.app"
""$PATH_TO_SYSTEM_APPS"/Calendar.app"
""$PATH_TO_SYSTEM_APPS"/Contacts.app"
""$PATH_TO_SYSTEM_APPS"/Reminders.app"
""$PATH_TO_SYSTEM_APPS"/Mail.app"
""$PATH_TO_APPS"/Microsoft Word.app"
""$PATH_TO_APPS"/Microsoft Excel.app"
""$PATH_TO_SYSTEM_APPS"/Messages.app"
""$PATH_TO_APPS"/The Unarchiver.app"
#"/Applications/Xcode.app"
""$PATH_TO_APPS"/iMazing.app"
""$PATH_TO_APPS"/VirusScannerPlus.app"
#""$PATH_TO_APPS"/Macs Fan Control.app"
#""$PATH_TO_APPS"/Signal.app"
#""$PATH_TO_APPS"/Keka.app"
#""$PATH_TO_APPS"/Overflow 3.app"
""$PATH_TO_APPS"/BresinkSoftwareUpdater.app"
""$PATH_TO_APPS"/MacPass.app"
""$PATH_TO_APPS"/WireGuard.app"
)

for i in "${applications_to_open[@]}"
do
	if [[ -e "$i" ]]
	then
	    echo "opening $(basename "$i")"
		open "$i" &
	else
		:
	fi
done

# google consent
open -a ""$PATH_TO_APPS"/Safari.app" "https://consent.google.com/ui/?continue=https%3A%2F%2Fwww.google.com%2F&origin=https%3A%2F%2Fwww.google.com&m=1&wp=47&gl=DE&hl=de&pc=s&uxe=4133096&ae=1"
open ""$PATH_TO_APPS"/Firefox.app" && sleep 2 && open -a "/Applications/Firefox.app" "https://consent.google.com/ui/?continue=https%3A%2F%2Fwww.google.com%2F&origin=https%3A%2F%2Fwww.google.com&m=1&wp=47&gl=DE&hl=de&pc=s&uxe=4133096&ae=1"

if [[ "$USER" == "wolfgang" ]]
then
    i="/Users/$USER/PVGuardClient/installer/pvdownload.jnlp"
    echo "opening $(basename "$i")"
	open "$i" &
	sleep 1
else
    :
fi

# opening system preferences for the monitor
open_system_prefs_monitor() {
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
#open_system_prefs_monitor

# testing ssh connection
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
             
### removing security permissions
#remove_apps_security_permissions_stop

echo ''
echo "done ;)"
echo ''
