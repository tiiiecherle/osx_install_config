#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### compatibility
###

# macos 10.14 and newer
VERSION_TO_CHECK_AGAINST=10.13
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.13
    echo ''
    echo "this script is only compatible with macos 10.14 mojave and newer, exiting..."
    echo ''
    exit
else
    :
fi



###
### finder favorites variables
###

SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/finder_favorites_data.sh ]]
then
	. "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/finder_favorites_data.sh
else
    echo ''
    echo "file with variables not found, exiting..."
    exit
fi



###
### finder favorites
###

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
		#keystroke "$FINDER_FAVORITE1"
		
		set value of combo box 1 of window 1 to "$FINDER_FAVORITE1"
		
		delay 1
		click button 1 of group 1 of window 1
		delay 1
		
	end tell
	
end tell

#tell application "Finder" to close front window
tell application "Finder" to close window "Mit Server verbinden"

EOF
}
echo ''
add_finder_favorites

echo ''
echo "done ;)"
echo ''