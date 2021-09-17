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
"utm_backup.app"
)
BUILD_DIR="$SCRIPT_DIR_ONE_BACK"
ICON_NAME="utm_backup.icns"

PATH_TO_ICON="$SCRIPT_DIR"/"$ICON_NAME"
#PATH_TO_OBJECT_TO_SET_ICON_FOR="$BUILD_DIR"/app/"$APP_NAME"

for APP_NAME in "${APP_NAME_VERSIONS[@]}"
do
    PATH_TO_OBJECT_TO_SET_ICON_FOR="$BUILD_DIR"/app/"$APP_NAME"
    echo ''
    echo "$APP_NAME"
    # setting icons
    env_set_custom_icon
done

echo ''
echo "done ;)"
echo ''
