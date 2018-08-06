#!/bin/bash

###
### updates and installations to all macs running the script
###

SCRIPT_DIR_MACOS=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
SCRIPT_DIR_BACKUP=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    ( while true; do ${USE_PASSWORD} | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID1="$!"
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID1) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID1 > /dev/null
        then
            sudo kill -9 $SUDO_PID1 &> /dev/null
            wait $SUDO_PID1 2>/dev/null
            #wait "$SUDO_PID1"
        else
            :
        fi
    fi
    unset SUDO_PID1
    sudo -k
}

echo "installing some apps and updating preferences..."


###
### 2017-03-09
###

function 2017_03_09_update () {
    
    # installing gnupg2
    ${USE_PASSWORD} | brew install gnupg2
    
    # installing gpgtools
    start_sudo
    brew update
    ${USE_PASSWORD} | brew cask install --force eaglefiler
    ${USE_PASSWORD} | brew cask install --force gpgtools
    stop_sudo
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

function 2017_03_24_update () {
    
    # uninstalling gpgtools
    if [[ $(brew cask info gpgtools | grep "Not installed") == "" ]]
    then
        start_sudo
        ${USE_PASSWORD} | brew cask zap gpgtools
        ${USE_PASSWORD} | brew cask zap textwrangler
        sudo rm -rf /Users/$USER/.gnupg
        stop_sudo
    else
        :
    fi
        
    # installing own gpg apps
    cp -a "$SCRIPT_DIR_BACKUP"/unarchive/unarchive_finder_input/decrypt_finder_input_gpg_progress.app /Applications/decrypt_finder_input_gpg_progress.app
    chmod 755 /Applications/decrypt_finder_input_gpg_progress.app
    chown 501:admin /Applications/decrypt_finder_input_gpg_progress.app
    
    cp -a "$SCRIPT_DIR_BACKUP"/unarchive/unarchive_finder_input/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app /Applications/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app
    chmod 755 /Applications/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app
    chown 501:admin /Applications/unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress.app
    
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

function 2017-04-07_update () {
    
    set +e
    
    # unistalling gnupg2 (formula was dropped)
    ${USE_PASSWORD} | brew uninstall gnupg2
    
    # installing gnupg2
    ${USE_PASSWORD} | brew install gnupg
    brew link --overwrite gnupg
    
    # preferences notification center
    start_sudo
    "$SCRIPT_DIR_MACOS"/11h_notification_center.sh
    stop_sudo
    
    # libreoffice language pack
    start_sudo
    brew update
    ${USE_PASSWORD} | brew cask install --force libreoffice-language-pack
    stop_sudo
    
    set -e

}
#2017-04-07_update


###
### 2017-05-19
###

function 2017-05-19_update () {
    
    set +e
    
    start_sudo
    brew update
    ${USE_PASSWORD} | brew cask zap adobe-reader
    ${USE_PASSWORD} | brew cask install --force adobe-acrobat-reader
    stop_sudo
    
    set -e

}
#2017-05-19_update


###
### 2017-10-09
###

function 2017-10-09_update () {
    
    set +e
    
    start_sudo
    # installing onyx for high sierra
    echo ''
    brew update
    ${USE_PASSWORD} | brew cask install --force onyx
    echo ''
    stop_sudo
    
    set -e

}
#2017-10-09_update


###
### 2018-01-10
###

function 2018-01-10_update () {
    
    set +e
    
    # htop is not compatible with macos high sierra
    brew uninstall --force htop
    brew install glances
    
    set -e

}
#2018-01-10_update


###
### 2018-02-15
###

function 2018-02-15_update () {
    
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
    set -e

}
#2018-02-15_update


###
### 2018-02-15
###

function 2018-02-15_update () {
    
    set +e
    echo ''
    
    # resetting homebrew path 
    echo 'export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"' > /Users/$(logname)/.bash_profile
    source /Users/$(logname)/.bash_profile
    
    echo ''
    set -e

}
#2018-02-15_update


###
### 2018-06-20
###

function 2018-06-20_update () {
    
    set +e
    echo ''
    
    # ask if changes of documents shall be confirmed when closing
    # false = off, true = on
    defaults write -g NSCloseAlwaysConfirmsChanges -bool true
    
    echo ''
    set -e

}
#2018-06-20_update


