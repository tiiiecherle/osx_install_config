#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



###
### asking password upfront
###

# solution 1
# only working for sudo commands, not for commands that need a password and are run without sudo
# and only works for specified time
# asking for the administrator password upfront
#sudo -v
# keep-alive: update existing 'sudo' time stamp until script is finished
#while true; do sudo -n true; sleep 600; kill -0 "$$" || exit; done 2>/dev/null &

# solution 2
# working for all commands that require the password (use sudo -S for sudo commands)
# working until script is finished or exited

# function for reading secret string (POSIX compliant)
enter_password_secret()
{
    # read -s is not POSIX compliant
    #read -s -p "Password: " SUDOPASSWORD
    #echo ''
    
    # this is POSIX compliant
    # disabling echo, this will prevent showing output
    stty -echo
    # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
    trap 'stty echo' EXIT
    # asking for password
    printf "Password: "
    # reading secret
    read -r "$@" SUDOPASSWORD
    # reanabling echo
    stty echo
    trap - EXIT
    # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
    printf "\n"
    # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
    # has to be part of the function or it wouldn`t be updated during the maximum three tries
    #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
}

# unset the password if the variable was already set
unset SUDOPASSWORD

# making sure no variables are exported
set +a

# asking for the SUDOPASSWORD upfront
# typing and reading SUDOPASSWORD from command line without displaying it and
# checking if entered password is the sudo password with a set maximum of tries
NUMBER_OF_TRIES=0
MAX_TRIES=3
while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
do
    NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
    #echo "$NUMBER_OF_TRIES"
    if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    then
        enter_password_secret
        ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
        if [ $? -eq 0 ]
        then 
            break
        else
            echo "Sorry, try again."
        fi
    else
        echo ""$MAX_TRIES" incorrect password attempts"
        exit
    fi
done

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo --prompt="" -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo --prompt="" -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo --prompt="" -k -S "$@"
}



###
### starting installation
###

echo ''
echo "installing homebrew and homebrew casks..."

echo ''

# creating directory and adjusting permissions
echo "creating directory..."

if [ ! -d /usr/local ]; then
sudo mkdir /usr/local
fi
#sudo chown -R $USER:staff /usr/local
sudo chown -R $(whoami) /usr/local

# installing command line tools
if xcode-select --install 2>&1 | grep installed >/dev/null
then
  	echo command line tools are installed...
else
  	echo command line tools are not installed, installing...
  	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
  	#sudo xcodebuild -license accept
fi

sudo xcode-select --switch /Library/Developer/CommandLineTools

# updating command line tools and system
#echo ""
echo "checking for command line tools update..."
COMMANDLINETOOLUPDATE=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools")
if [ "$COMMANDLINETOOLUPDATE" == "" ]
then
	echo "no update for command line tools available..."
else
	echo "update for command line tools available, updating..."
	softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLUPDATE" | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//')"
fi
#softwareupdate -i --verbose "$(softwareupdate --list | grep "* Command Line" | sed 's/*//' | sed -e 's/^[ \t]*//')"

# Will exclude these apps from updating. Pass in params to fit your needs. Use the exact brew/cask name and separate names with a pipe |
BREW_EXCLUDES="${1:-}"
CASK_EXCLUDES="${2:-}"

cleanup-all() {
    echo -e "Cleaning up..."
    brew analytics off && brew update && brew upgrade && brew prune && brew doctor && brew cleanup && brew cask cleanup
    echo -e "Clean finished.\n\n"
}

# Upgrade all the Homebrew apps
brew-upgrade() {
    log-info "Updating Brew apps..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "BREW NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'


    for item in $(brew list); do
        local BREW_INFO=$(brew info $item)
        local BREW_NAME="$item"
        local NEW_VERSION=$(echo "$BREW_INFO" | grep -e "$BREW_NAME: .*" | cut -d" " -f3 | sed 's/,//g')
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$BREW_INFO" | grep -q ".*/Cellar/$BREW_NAME/$NEW_VERSION.*" 2>&1 && echo true )

        printf "%-35s | %-20s | %-15s\n" "$BREW_NAME" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"

        # Install if not up-to-date and not excluded
        if [[ "$CURRENT_VERSION_INSTALLED" == false ]] && [[ ${BREW_EXCLUDES} != *"$BREW_NAME"* ]]; then
            brew upgrade $item
        fi

        BREW_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done

    log-info "Brew upgrades finished.\n"
}

# Selectively upgrade casks
cask-upgrade() {
    log-info "Updating Cask apps..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "CASK NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'

    for c in $(brew cask list); do
        local CASK_INFO=$(brew cask info $c)
        local CASK_NAME=$(echo "$c" | cut -d ":" -f1 | xargs)
        #if [[ $(brew cask info $c | tail -1 | grep "(app)") != "" ]]
        #then
        #    APPNAME=$(brew cask info $c | tail -1 | awk '{$(NF--)=""; print}' | sed 's/ *$//')
        #else
        #    APPNAME=$(echo $(brew cask info $c | grep -A 1 "==> Name" | tail -1).app)
        #fi
        #local INSTALLED_VERSION=$(plutil -p "/Applications/$APPNAME/Contents/Info.plist" | grep "CFBundleShortVersionString" | awk '{print $NF}' | sed 's/"//g')
        local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//' )
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$CASK_INFO" | grep -q ".*/Caskroom/$CASK_NAME/$NEW_VERSION.*" 2>&1 && echo true )

        printf "%-35s | %-20s | %-15s\n" "$CASK_NAME" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"

        CASK_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done

    echo ""
    
    for c in $(brew cask list); do
        local CASK_INFO=$(brew cask info $c)
        local CASK_NAME=$(echo "$c" | cut -d ":" -f1 | xargs)
        local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//' )
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$CASK_INFO" | grep -q ".*/Caskroom/$CASK_NAME/$NEW_VERSION.*" 2>&1 && echo true )

        # Install if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == false ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            sudo brew cask install "$CASK_NAME" --force
        fi
        
        #if [[ "$NEW_VERSION" == latest ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        #then
        #    sudo brew cask install "$CASK_NAME" --force
        #fi

        CASK_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done


    log-info "Cask upgrades finished.\n"
}

log-info() {
    echo -e "INFO:  $1"
}

cleanup-all

brew-upgrade

cask-upgrade

# done
echo ''
echo "homebrew script done ;)"
echo ''



###
### unsetting password
###

unset SUDOPASSWORD
