#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### install
###

# variables
APP_NAME="clamav_scan"
DMG_DIR="$SCRIPT_DIR_ONE_BACK"

echo ''
echo "${bold_text}installing "$PATH_TO_APPS"/"$APP_NAME".app...${default_text}"

# remove old installed version
if [[ -e "$PATH_TO_APPS"/"$APP_NAME".app ]]
then
	rm -rf "$PATH_TO_APPS"/"$APP_NAME".app
else
	:
fi

# ownership and permissions
cp -a "$DMG_DIR"/app/"$APP_NAME".app "$PATH_TO_APPS"/
if [[ -e "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$APP_NAME".sh ]]
then
	SCRIPT_NAME="$APP_NAME"
else
	SCRIPT_NAME=$(find "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files -maxdepth 1 -mindepth 1 -type f -name "*.sh")
	if [[ $(echo "$SCRIPT_NAME" | wc -l | awk '{print $1}') != "1" ]]
	then
		echo "SCRIPT_NAME is not set correctly, exiting..."
		exit
	else
		SCRIPT_NAME=$(basename "$SCRIPT_NAME" .sh)
	fi
fi
chown $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_NAME".app
chown -R $(id -u "$USER"):admin "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/
chmod 755 "$PATH_TO_APPS"/"$APP_NAME".app
chmod 770 "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$SCRIPT_NAME".sh

if [[ $(xattr -l "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$SCRIPT_NAME".sh | grep com.apple.quarantine) != "" ]]
then
    xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$SCRIPT_NAME".sh
else
    :
fi
if [[ $(xattr -l "$PATH_TO_APPS"/"$APP_NAME".app | grep com.apple.quarantine) != "" ]]
then
    xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_NAME".app
else
    :
fi


### xattr for included app
#open "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/pdf_shrink_done.app
#open "$PATH_TO_APPS"/"$APP_NAME".app
xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$APP_NAME"_done.app
xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$APP_NAME"_found.app
xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_NAME".app/Contents/custom_files/"$APP_NAME"_stopped.app
xattr -d com.apple.quarantine "$PATH_TO_APPS"/"$APP_NAME".app


### security permissions
echo ''
echo "${bold_text}setting security permissions...${default_text}"
APPS_SECURITY_ARRAY=(
# app name									security service											allowed (1=yes, 0=no)
"$APP_NAME                               	kTCCServiceAccessibility                             		1"
)
PRINT_SECURITY_PERMISSIONS_ENTRIES="no" env_set_apps_security_permissions


### automation
# macos versions 10.14 and up
echo ''
echo "${bold_text}setting automation permissions...${default_text}"
AUTOMATION_APPS=(
# source app name							automated app name											allowed (1=yes, 0=no)
"$APP_NAME									System Events                   							1"
"$APP_NAME									Terminal                   									1"
"$APP_NAME									Finder                   									1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="no" env_set_apps_automation_permissions


### notifications
#echo "setting notification preferences..."
APPLICATIONS_TO_SET_NOTIFICATIONS=(
#"$APP_NAME									310903127"
"clamav_scan_found							310903127"
"clamav_scan_done							310903127"
"clamav_scan_stopped						310903127"
)
SET_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications
CHECK_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications

#open "$PATH_TO_APPS"/"$APP_NAME".app
