#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### updates and installations to all macs running the script
###

SCRIPT_DIR_MACOS="$SCRIPT_DIR"
SCRIPT_DIR_BACKUP="$SCRIPT_DIR_ONE_BACK"

echo "installing some apps and updating preferences..."


###
### 2017-03-09
###

2017_03_09_update() {
    
    # installing gnupg2
    env_use_password | brew install gnupg2
    
    # installing gpgtools
    env_start_sudo
    brew update
    env_use_password | brew install --cask --force eaglefiler
    env_use_password | brew install --cask --force gpgtools
    env_stop_sudo
    if [[ $(cat ~/.gnupg/gpg-agent.conf | grep max-cache-ttl) == "" ]]
    then
    	echo "max-cache-ttl 0" >> ~/.gnupg/gpg-agent.conf
    else
    	:
    fi
    
    # updating defaults open with
    if [ -e "$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist" ]
    then
        rm "$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
    else
        :
    fi
    sleep 2
    "$SCRIPT_DIR_MACOS"/11e_defaults_open_with.sh

}
#2017_03_09_update


###
### 2017-03-24
###

2017_03_24_update() {
    
    # uninstalling gpgtools
    if [[ $(brew info --casks gpgtools | grep "Not installed") == "" ]]
    then
        env_start_sudo
        env_use_password | brew uninstall --cask --zap gpgtools
        env_use_password | brew uninstall --cask --zap textwrangler
        sudo rm -rf /Users/$USER/.gnupg
        env_stop_sudo
    else
        :
    fi
        
    # installing own gpg apps
    cp -a "$SCRIPT_DIR_BACKUP"/unarchive/unarchive_finder_input/decrypt_finder_input_gpg_progress.app "$PATH_TO_APPS"/decrypt_finder_input_gpg_progress.app
    chmod 755 "$PATH_TO_APPS"/decrypt_finder_input_gpg_progress.app
    chown $(id -u "$USER"):admin "$PATH_TO_APPS"/decrypt_finder_input_gpg_progress.app
    
    cp -a "$SCRIPT_DIR_BACKUP"/unarchive/unarchive_finder_input/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app "$PATH_TO_APPS"/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app
    chmod 755 "$PATH_TO_APPS"/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app
    chown $(id -u "$USER"):admin "$PATH_TO_APPS"/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app
    
    # updating defaults open with
    if [ -e "$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist" ]
    then
        rm "$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
    else
        :
    fi
    sleep 2
    "$SCRIPT_DIR_MACOS"/11e_defaults_open_with.sh
    
    osascript -e 'tell app "System Events" to display dialog "the default \"open with\" associations have been set, 
please reboot after finishing the script - thanks ;)" buttons "OK"'

}
#2017_03_24_update


###
### 2017-04-07
###

2017-04-07_update() {
    
    set +e
    
    # unistalling gnupg2 (formula was dropped)
    env_use_password | brew uninstall gnupg2
    
    # installing gnupg2
    env_use_password | brew install gnupg
    brew link --overwrite gnupg
    
    # preferences notification center
    env_start_sudo
    "$SCRIPT_DIR_MACOS"/11h_notification_center.sh
    env_stop_sudo
    
    # libreoffice language pack
    env_start_sudo
    brew update
    env_use_password | brew install --cask --force libreoffice-language-pack
    env_stop_sudo
    
}
#2017-04-07_update


###
### 2017-05-19
###

2017-05-19_update() {
    
    set +e
    
    env_start_sudo
    brew update
    env_use_password | brew uninstall --cask --zap adobe-reader
    env_use_password | brew install --cask --force adobe-acrobat-reader
    env_stop_sudo
    
}
#2017-05-19_update


###
### 2017-10-09
###

2017-10-09_update() {
    
    set +e
    
    env_start_sudo
    # installing onyx for high sierra
    echo ''brew update
    env_use_password | brew install --cask --force onyx
    echo ''env_stop_sudo
    
}
#2017-10-09_update


###
### 2018-01-10
###

2018-01-10_update() {
    
    set +e
    
    # htop is not compatible with macos high sierra
    brew uninstall --force htop
    brew install glances
    
}
#2018-01-10_update


###
### 2018-02-15
###

2018-02-15_update() {
    
    set +e
    echo ''
    # additional dependency for backup script
    brew install cliclick
    
    # copy / paste of a lot of commands does only work in iterm2 when editing / lowering default paste speed
    defaults write com.googlecode.iterm2 QuickPasteBytesPerCall -int 126
    defaults write com.googlecode.iterm2 QuickPasteDelayBetweenCalls -float 0.05323399
    # lower values in steps to try if working by clicking edit - paste special - paste slower
    # check values in preferences advanced - search for paste 
    # defaults		
    # dealy in seconds between chunks when pasting normally			0.01530456
    # number of bytes to paste in each chunk when pasting normally		667
    
    echo ''

}
#2018-02-15_update


###
### 2018-02-15
###

2018-02-15_update() {
    
    set +e
    echo ''
    # resetting homebrew path 
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
    echo 'export PATH="'"$BREW_PATH_PREFIX"'/bin:'"$BREW_PATH_PREFIX"'/sbin:~/bin:$PATH"' > /Users/$(logname)/.bash_profile
    source /Users/$(logname)/.bash_profile
    
    echo ''

}
#2018-02-15_update


###
### 2018-06-20
###

2018-06-20_update() {
    
    set +e
    echo ''
    # ask if changes of documents shall be confirmed when closing
    # false = off, true = on
    defaults write -g NSCloseAlwaysConfirmsChanges -bool true
    
    echo ''

}
#2018-06-20_update



###
### 2018-06-20
###

2020-07-08_update() {
    
    set +e
    echo ''
    brew install python
    
    echo ''

}
#2020-07-08_update


