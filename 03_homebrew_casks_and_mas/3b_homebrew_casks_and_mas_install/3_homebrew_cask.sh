#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### script frame
###

if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
then
    . "$SCRIPT_DIR"/1_script_frame.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi



###
### homebrew cask
###


### command line tools
env_command_line_tools_install_shell


### starting sudo
env_start_sudo

# use xcode if installed
if [[ -e "/Applications/Xcode-beta.app" ]]
then
    echo ''
    echo "changing to xcode command line tools..."
    sudo rm -rf /Library/Developer/CommandLineTools
    sudo xcode-select --switch /Applications/Xcode-beta.app
    sudo xcodebuild -license accept
    sudo xcodebuild -runFirstLaunch
else
    :
fi


### including homebrew commands in PATH
# path documentation
# see 2d_login_shell_customization.sh

# setting path
echo ''
echo "setting PATH..."

# default value of variable is set in .shellscriptsrc, can be overwritten here, e.g.
# BREW_PATH_PREFIX=$(brew --prefix)
# PATH_TO_SET='"$BREW_PATH_PREFIX"/bin:$PATH'

# setting default paths in /etc/paths
#env_start_sudo			# already started above
#env_set_default_paths
#env_stop_sudo			# done in trap

# setting paths for bash
SHELL_TO_CHECK="/bin/bash"
SHELL_CONFIG="/Users/$(logname)/.bashrc"
env_set_path_for_shell

# setting paths for zsh
SHELL_TO_CHECK="/bin/zsh"
SHELL_CONFIG="/Users/$(logname)/.zshrc"
env_set_path_for_shell

# setting/unsetting path via launchctl
#env_start_sudo			# already started above
sudo launchctl config user path ''
sudo launchctl config system path ''
#env_stop_sudo			# done in trap


### installing homebrew without pressing enter or entering the password again
echo ''
if command -v brew &> /dev/null
then
    # installed
    echo "homebrew already installed, skipping..."   
else
    # not installed
    echo "installing homebrew..."
    # homebrew installation
    #env_start_sudo
    # ruby homebrew installer is deprecated
    #yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    # rewritten in bash
    yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)" 2>&1
    #env_stop_sudo
fi

# use xcode if installed
if [[ -e "/Applications/Xcode-beta.app" ]]
then
	echo ''
	echo "changing to xcode command line tools..."
	sudo rm -rf /Library/Developer/CommandLineTools
    sudo xcode-select --switch /Applications/Xcode-beta.app
	sudo xcodebuild -license accept
	sudo xcodebuild -runFirstLaunch
else
	:
fi


### homebrew permissions
# homebrew cache
#sudo chown -R "$USER":staff $(brew --cache)
sudo chown -R "$USER" $(brew --cache)

#if [ -e "$(brew --prefix)" ] 
#then
#	echo "setting ownerships and permissions for homebrew..."
#	BREWGROUP="admin"
#	BREWPATH=$(brew --prefix)
#	sudo chown -R $(id -u "$USER"):"$BREWGROUP" "$BREWPATH"
#	sudo find "$BREWPATH" -type f -print0 | sudo xargs -0 chmod g+rw
#	sudo find "$BREWPATH" -type d -print0 | sudo xargs -0 chmod g+rwx
#else
#	:
#fi

#echo ''


### updating homebrew
echo ''
echo "updating and checking homebrew..."
# checking installation and updating homebrew
brew analytics on
#brew analytics off
#BREW_PATH_PREFIX=$(brew --prefix)
#cd "$BREW_PATH_PREFIX"/Library && git stash && git clean -d -f
brew update
brew upgrade
# temporarily updating to the latest git status / commits, git update / upgrade will update to latest stable version when released
#cd "$(brew --repository)" && git checkout master && git pull origin master && cd -
# brew prune deprecated as of 2019-01, using brew cleanup instead
brew cleanup 1> /dev/null
brew doctor


### cleaning up
echo ''
echo "cleaning up..."

env_cleanup_all_homebrew


### installing homebrew cask (as of 2023-03 the homebrew/cask tap is unnecessary)
# Warning: You have an unnecessary local Cask tap.
# This can cause problems installing up-to-date casks.
# Please remove it by running:
# brew untap homebrew/cask
#echo ''
#echo "installing homebrew cask..."
#
#brew tap homebrew/cask 2>&1


### installing keepingyouawake
#if [[ -e "$PATH_TO_APPS"/KeepingYouAwake.app ]]
if [[ $(brew list --cask | grep "^keepingyouawake$") != "" ]]
then
    :
else
    echo ''
    echo "installing keepingyouawake..."
    #env_use_password | brew install --cask --force keepingyouawake 2> /dev/null | grep "successfully installed"
    env_use_password | brew install --cask --force keepingyouawake
    sleep 1
    APP_NAME="KeepingYouAwake"
    env_set_open_on_first_run_permissions
    sleep 1
fi


### activating caffeinate
env_activating_caffeinate


### installing cask repair to contribute to homebrew casks
# deprecated as of 2021-01, use brew bump-cask-pr instead
#echo ''
#echo "installing cask-repair..."
#brew tap vitorgalvao/tiny-scripts 2>&1
#brew install cask-repair
#cask-repair --help
# fixing red dots before confirming commit that prevent the commit from being made
# https://github.com/vitorgalvao/tiny-scripts/issues/88
# gem uninstall -ax rubocop rubocop-cask
# brew style
# if this is not working try with sudo
# sudo gem uninstall -ax rubocop rubocop-cask
# brew style
# if this is not working remove the version of gem which brew style complains about, e.g.
# rm -rf /Users/"$USER"/.gem/ruby/2.6.0/
# brew style


### installing dependenies for the other scripts
echo ''
echo "installing script dependencies..."
HOMEBREW_SCRIPT_DEPENDENCIES_LIST=(
parallel
jq
)
HOMEBREW_SCRIPT_DEPENDENCIES=$(printf "%s\n" "${HOMEBREW_SCRIPT_DEPENDENCIES_LIST[@]}")

while IFS= read -r line || [[ -n "$line" ]] 
do
    if [[ "$line" == "" ]]; then continue; fi
    i="$line"
    if command -v "$i" &> /dev/null
    then
        # installed
        :
    else
        # not installed
        echo ''
        echo "installing "$i"..."
        brew install --formula "$i"
        #echo ''
    fi
done <<< "$(printf "%s\n" "${HOMEBREW_SCRIPT_DEPENDENCIES[@]}")"

### cleaning up
echo ''
echo "cleaning up..."

env_cleanup_all_homebrew
    

### stopping sudo
# done in trap
#env_stop_sudo


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
