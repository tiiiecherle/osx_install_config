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
    yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    #env_stop_sudo
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
#	sudo chown -R 501:"$BREWGROUP" "$BREWPATH"
#	sudo find "$BREWPATH" -type f -print0 | sudo xargs -0 chmod g+rw
#	sudo find "$BREWPATH" -type d -print0 | sudo xargs -0 chmod g+rwx
#else
#	:
#fi

#echo ''


### including homebrew commands in PATH
# path documentation
# see 2d_login_shell_customization.sh

# setting path
echo ''
echo "setting PATH..."

# default value of variable is set in .shellscriptsrc, can be overwritten here, e.g.
# PATH_TO_SET='/usr/local/bin:$PATH'

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


### updating homebrew
echo ''
echo "updating and checking homebrew..."
# checking installation and updating homebrew
brew analytics on
#cd /usr/local/Library && git stash && git clean -d -f
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


### installing homebrew cask
echo ''
echo "installing homebrew cask..."

brew tap homebrew/cask


### installing keepingyouawake
#if [[ -e "$PATH_TO_APPS"/KeepingYouAwake.app ]]
if [[ $(brew cask list | grep "^keepingyouawake$") != "" ]]
then
    :
else
    echo ''
    echo "installing keepingyouawake..."
    env_use_password | brew cask install --force keepingyouawake 2> /dev/null | grep "successfully installed"
    sleep 1
fi


### activating keepingyouawake
env_activating_keepingyouawake


### installing cask repair to contribute to homebrew casks
#echo ''
echo "installing cask-repair..."
brew install vitorgalvao/tiny-scripts/cask-repair
#cask-repair --help
# fixing red dots before confirming commit that prevent the commit from being made
# https://github.com/vitorgalvao/tiny-scripts/issues/88
# gem uninstall -ax rubocop rubocop-cask
# brew cask style
# if this is not working try with sudo
# sudo gem uninstall -ax rubocop rubocop-cask
# brew cask style
# if this is not working remove the version of gem which brew cask style complains about, e.g.
# rm -rf /Users/"$USER"/.gem/ruby/2.6.0/
# brew cask style


### installing parallel as dependency for the other scripts
if command -v parallel &> /dev/null
then
    # installed
    :
else
    # not installed
    echo ''
    echo "installing parallel..."
    brew install parallel
    #echo ''
fi


### cleaning up
echo ''
echo "cleaning up..."

env_cleanup_all_homebrew
    

### stopping sudo
# done in trap
#env_stop_sudo


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
