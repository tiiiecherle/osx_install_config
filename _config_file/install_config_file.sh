#!/bin/zsh

### sourcing config file
if [[ -f ~/.shellscriptsrc ]]
then 
    . ~/.shellscriptsrc
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
    # user config profile
    SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
    env_check_for_user_profile
else
    :
fi


### shell specific script dir
if [[ -n "$BASH_SOURCE" ]]
then
    SCRIPT_PATH="$BASH_SOURCE"
elif [[ -n "$ZSH_VERSION" ]]
then
    SCRIPT_PATH="${(%):-%x}"
fi
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"


### variables
SHELL_SCRIPTS_CONFIG_FILE="shellscriptsrc"
SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH=~/."$SHELL_SCRIPTS_CONFIG_FILE"


### installation
echo ''
if [[ -e "$SCRIPT_DIR"/"$SHELL_SCRIPTS_CONFIG_FILE".sh ]]
then
    echo "installing config file from local directory..."
    #echo ''
    cp "$SCRIPT_DIR"/"$SHELL_SCRIPTS_CONFIG_FILE".sh "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
    if [[ $? -eq 0 ]]; then SUCCESSFULLY_INSTALLED="yes"; else SUCCESSFULLY_INSTALLED="no"; fi
    if [[ "$ENABLE_SELF_UPDATE" == "no" ]]
    then
        # deactivating self-update
        sed -i '' '/env_config_file_self_update$/s/^#*/#/g' "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
    else
        # activating self-update
        sed -i '' '/env_config_file_self_update$/s/^#*//g' "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
    fi
else
    echo "installing config file from github..."
    echo ''
    curl https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/"$SHELL_SCRIPTS_CONFIG_FILE".sh -o "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
    if [[ $? -eq 0 ]]; then SUCCESSFULLY_INSTALLED="yes"; else SUCCESSFULLY_INSTALLED="no"; fi
fi

# ownership and permissions
chown 501:staff "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
chmod 600 "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"

# checking if installation was successful
echo ''
if [[ -f "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH" ]] && [[ "$SUCCESSFULLY_INSTALLED" == "yes" ]]
then
    printf "config file was \033[1;32msuccessfully\033[0m installed to $SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH...\n"
else
    printf "\033[1;31merror installing config file to $SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH, please install it manually...\033[0m\n"
fi
#echo ''
printf '\n' 
