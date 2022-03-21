#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
        env_sudo
    else
        env_enter_sudo_password
    fi
else
    :
fi




###
### homebrew uninstall
###

# uninstalling homebrew and all casks
# https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/FAQ.md

###
###
###

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    :
else
    echo ''
fi

# asking for casks zap
VARIABLE_TO_CHECK="$ZAP_CASKS"
QUESTION_TO_ASK="do you want to zap / uninstall all casks including preferences (y/N)? "
env_ask_for_variable
ZAP_CASKS="$VARIABLE_TO_CHECK"

# asking for command line tools uninstall
VARIABLE_TO_CHECK="$UNINSTALL_DEV_TOOLS"
QUESTION_TO_ASK="do you want to uninstall developer tools (Y/n)? "
env_ask_for_variable
UNINSTALL_DEV_TOOLS="$VARIABLE_TO_CHECK"

# asking for homebrew uninstall
VARIABLE_TO_CHECK="$UNINSTALL_HOMEBREW"
QUESTION_TO_ASK="do you want to uninstall homebrew and all formulae (Y/n)? "
env_ask_for_variable
UNINSTALL_HOMEBREW="$VARIABLE_TO_CHECK"


###
###
###

if command -v brew &> /dev/null
then
    # installed
    BREW_PATH_PREFIX=$(brew --prefix)
else
    # not installed
    echo "homebrew is not installed, exiting..."
    echo ''
    exit
fi

# casks zap
if [[ "$ZAP_CASKS" =~ ^(no|n)$ ]]
then
    if [[ -e ""$BREW_PATH_PREFIX"/Caskroom" ]]
    then
        # backing up specifications of latest installed casks
        echo ''
        echo "backing up "$BREW_PATH_PREFIX"/Caskroom/. to /tmp/Caskroom/..."
        #ls -la "$BREW_PATH_PREFIX"/Caskroom/
        mkdir -p /tmp/Caskroom
        cp -a "$BREW_PATH_PREFIX"/Caskroom/. /tmp/Caskroom/
        #ls -la /tmp/Caskroom/
    else
        echo ''
        echo ""$BREW_PATH_PREFIX"/Caskroom/ not found, skipping backup..."
    fi
else
    #env_start_sudo
    echo ''
    echo "uninstalling casks incl. preferences..."
    for caskstouninstall in $(brew list --cask)
    do  
        echo "zapping $caskstouninstall"...
    	env_use_password | brew uninstall --zap --cask --force "$caskstouninstall"
    	echo ''
    done
    if [[ $(brew list --cask) == "" ]]
    then
        echo "all casks uninstalled..."
    else
        echo "the following casks are still installed..."
        brew list --cask
    fi
    #env_stop_sudo
fi

# command line tools uninstall
if [[ "$UNINSTALL_DEV_TOOLS" =~ ^(yes|y)$ ]]
then
    echo ''
    echo "uninstalling developer tools..."
    sudo rm -rf /Library/Developer/CommandLineTools
    #echo ''
else
    :
fi

# homebrew uninstall
if [[ "$UNINSTALL_HOMEBREW" =~ ^(yes|y)$ ]]
then
    echo ''
    echo "uninstalling homebrew and all formulae..."
    # redefining sudo so it is possible to run homebrew without entering the password again
    env_sudo_homebrew
    # uninstalling with homebrew script
    #sudo yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh)"
    # forcing sudo to forget the sudo password (can still be used with env_use_password)
    sudo -K
    # redefining sudo back for the rest of the script
    env_sudo
    #
    cleanup_files_and_folders=(
        "/opt/homebrew-cask"
        ""$BREW_PATH_PREFIX"/Caskroom"
        ""$BREW_PATH_PREFIX"/lib/librtmp.dylib"
        ""$BREW_PATH_PREFIX"/var/homebrew/"
        ""$BREW_PATH_PREFIX"/var/cache/"
        ""$BREW_PATH_PREFIX"/Homebrew/"
    )
    for i in "${cleanup_files_and_folders[@]}"
    do
        if [[ -e "$i" ]]
        then
            sudo rm -rf "$i"
        else
            :
        fi
    done
    sudo chmod 0755 "$BREW_PATH_PREFIX"
    sudo chown root:wheel "$BREW_PATH_PREFIX"
    for CONFIG_FILE in ~/.bash_profile ~/.bashrc ~/.zshrc
    do
        if [[ -e "$CONFIG_FILE" ]]; then :; else continue; fi
        sed -i '' '\|/bin:$PATH|d' "$CONFIG_FILE"
        sed -i '' '\|# homebrew PATH|d' "$CONFIG_FILE"
        sed -i '' '${/^$/d;}' "$CONFIG_FILE"
    done
else
    :
fi

echo ''



###
### unsetting password
###

unset SUDOPASSWORD
