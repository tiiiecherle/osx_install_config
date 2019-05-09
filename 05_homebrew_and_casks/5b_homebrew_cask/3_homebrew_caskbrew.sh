#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")


###
### script frame
###

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
        . "$SCRIPT_DIR"/1_script_frame.sh
    else
        echo ''
        echo "script for functions and prerequisits is missing, exiting..."
        echo ''
        exit
    fi
fi


###
### command line tools
###

checking_command_line_tools


### starting sudo
start_sudo

# installing homebrew without pressing enter or entering the password again
#echo ''
if [[ $(which brew) == "" ]]
then
    echo "installing homebrew..."
    # homebrew installation
    #start_sudo
    yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    #stop_sudo
else
    echo "homebrew already installed, skipping..."
fi

# homebrew permissions
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

# including homebrew commands in PATH
echo 'export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"' > /Users/$(logname)/.bash_profile
source /Users/$(logname)/.bash_profile

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

# cleaning up
echo ''
echo "cleaning up..."

cleanup_all_homebrew


# installing homebrew cask
echo ''
echo "installing homebrew cask..."

brew tap caskroom/cask

# activating keepingyouawake
if [ -e /Applications/KeepingYouAwake.app ]
then
    :
else
    echo ''
    echo "installing keepingyouawake..."
    builtin printf '"$SUDOPASSWORD\n"' | brew cask install --force keepingyouawake 2> /dev/null | grep "successfully installed"
    # avoiding "this dapplication is downloaded from the internet. do you really want to open it?" message on first run
    # must be reset from .xattr file or be reinstalling later
    xattr -p com.apple.quarantine "/Applications/KeepingYouAwake.app" > /tmp/quarantine_keepingyouawake.xattr
    xattr -d com.apple.quarantine "/Applications/KeepingYouAwake.app"
fi
#activating_keepingyouawake

# installing cask repair to contribute to homebrew casks
echo ''
echo "installing cask-repair..."
brew install vitorgalvao/tiny-scripts/cask-repair
#cask-repair --help
# fixing red dots before confirming commit that prevent the commit from being made
# https://github.com/vitorgalvao/tiny-scripts/issues/88
# sudo gem uninstall -ax rubocop rubocop-cask
# brew cask style

# installing parallel as dependency for the other scripts
if [[ "$(which parallel)" == "" ]]
then
    echo ''
    echo "installing parallel..."
    brew install parallel
    #echo ''
else
    :
fi

# cleaning up
echo ''
echo "cleaning up..."

cleanup_all_homebrew
    

### stopping sudo
stop_sudo
