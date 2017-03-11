#!/bin/bash

###
### updates and installations to all macs running the script
###

SCRIPT_DIR_MACOS=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")

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
