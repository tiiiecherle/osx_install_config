#!/bin/bash

###
### updates and installations to all macs running the script
###

SCRIPT_DIR_MACOS=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")
SCRIPT_DIR_BACKUP=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    #sudo -v
    ( while true; do sudo -v; sleep 60; done; ) &
    SUDO_PID1="$!"
    disown
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID1) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID1 > /dev/null
        then
            sudo kill -9 "$SUDO_PID1"
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
    
    # unistalling gnupg2 (formula was dropped)
    ${USE_PASSWORD} | brew uninstall gnupg2
    
    # installing gnupg2
    ${USE_PASSWORD} | brew install gnupg
    brew link --overwrite gnupg
    
    # preferences notification center
    start_sudo
    "$SCRIPT_DIR_MACOS"/11h_notification_center.sh
    stop_sudo

}
2017-04-07_update
