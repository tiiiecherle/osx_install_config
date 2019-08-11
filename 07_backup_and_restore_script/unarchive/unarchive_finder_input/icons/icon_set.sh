#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### set icon
###

APP_NAME_VERSIONS=(
"decrypt_finder_input_gpg_progress.app"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app"
)
BUILD_DIR="$SCRIPT_DIR_ONE_BACK"
ICON_NAME="gpg.icns"

for APP_NAME in "${APP_NAME_VERSIONS[@]}"
do
    #echo ''
    # setting icons
    chmod 770 "$SCRIPT_DIR"/icon_set_python3.py
    #sudo pip install pyobjc
    pip3 install pyobjc-framework-Cocoa | grep -v "already satisfied"
    python3 "$SCRIPT_DIR"/icon_set_python3.py "$SCRIPT_DIR"/"$ICON_NAME" "$BUILD_DIR"/app/"$APP_NAME"
    for i in applet droplet AutomatorApplet
	do
		if [[ -e "$BUILD_DIR"/app/"$APP_NAME".app/Contents/Resources/"$i".icns ]]; then cp -a "$BUILD_DIR"/icons/"$ICON_NAME".icns "$BUILD_DIR"/app/"$APP_NAME".app/Contents/Resources/"$i".icns; else :; fi
	done
    cp -a "$SCRIPT_DIR"/document.icns "$BUILD_DIR"/app/"$APP_NAME"/Contents/Resources/document.icns
done

echo ''
echo "done ;)"
echo ''
