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
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}



###
### starting installation
###

echo ''
echo "updating homebrew, formulas and casks..."

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

# will exclude these apps from updating
# pass in params to fit your needs
# use the exact brew/cask name and separate names with a pipe |
BREW_EXCLUDES="${1:-}"
CASK_EXCLUDES="${2:-}"


homebrew-update() {
    echo ''
    echo "updating homebrew..."
    brew analytics off 1> /dev/null && brew update 1> /dev/null && brew prune 1> /dev/null && brew doctor 1> /dev/null
    echo 'updating homebrew finished ;)'
}

cleanup-all() {
    echo ''
    echo "cleaning up..."
    brew cleanup && brew cask cleanup 1> /dev/null
    echo 'cleaning finished ;)'
}

# upgrading all homebrew formulas
brew-upgrade() {
    echo "updating brew formulas..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "BREW NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'
    
    TMP_DIR=/tmp/brew_updates
    if [ -e "$TMP_DIR" ]
    then
        if [ "$(ls -A $TMP_DIR/)" ]
        then
            rm "$TMP_DIR"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p $TMP_DIR/
    DATE_LIST_FILE=$(echo "brew_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    touch "$TMP_DIR"/"$DATE_LIST_FILE"

    for item in $(brew list); do
        local BREW_INFO=$(brew info $item)
        local BREW_NAME="$item"
        local NEW_VERSION=$(echo "$BREW_INFO" | grep -e "$BREW_NAME: .*" | cut -d" " -f3 | sed 's/,//g')
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$BREW_INFO" | grep -q ".*/Cellar/$BREW_NAME/$NEW_VERSION.*" 2>&1 && echo -e '\033[1;32mtrue\033[0m' || echo -e '\033[1;31mfalse\033[0m' )

        printf "%-35s | %-20s | %-15s\n" "$BREW_NAME" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"
        
        # installing if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == "$(echo -e '\033[1;31mfalse\033[0m')" ]] && [[ ${CASK_EXCLUDES} != *"$BREW_NAME"* ]]
        then
            echo "$BREW_NAME" >> "$TMP_DIR"/"$DATE_LIST_FILE"
        fi

        BREW_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done
    
    echo ''
    
    while IFS='' read -r line || [[ -n "$line" ]]
    do
        echo 'updating '"$line"'...'
        ${USE_PASSWORD} | brew upgrade "$line"
        echo 'removing old installed versions of '"$line"'...'
        ${USE_PASSWORD} | brew cleanup "$line"
        echo ''
    done <"$TMP_DIR"/"$DATE_LIST_FILE"
    
    echo 'brew formulas updates finished ;)'
}

# selectively upgrade casks
cask-upgrade() {
    echo "updating casks..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "CASK NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'
    
    TMP_DIR=/tmp/cask_updates
    if [ -e "$TMP_DIR" ]
    then
        if [ "$(ls -A $TMP_DIR/)" ]
        then
            rm "$TMP_DIR"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p $TMP_DIR/
    DATE_LIST_FILE=$(echo "casks_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    DATE_LIST_FILE_LATEST=$(echo "casks_update_latest"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    touch "$TMP_DIR"/"$DATE_LIST_FILE"
    touch "$TMP_DIR"/"$DATE_LIST_FILE_LATEST"
    
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
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$CASK_INFO" | grep -q ".*/Caskroom/$CASK_NAME/$NEW_VERSION.*" 2>&1 && echo -e '\033[1;32mtrue\033[0m' || echo -e '\033[1;31mfalse\033[0m')

        printf "%-35s | %-20s | %-15s\n" "$CASK_NAME" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"
        
        # installing if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == "$(echo -e '\033[1;31mfalse\033[0m')" ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            echo "$CASK_NAME" >> "$TMP_DIR"/"$DATE_LIST_FILE"
        fi
        
        if [[ "$NEW_VERSION" == "latest" ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            echo "$CASK_NAME" >> "$TMP_DIR"/"$DATE_LIST_FILE_LATEST"
        fi

        CASK_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done

    echo ''
    
    while IFS='' read -r line || [[ -n "$line" ]]
    do
        echo 'updating '"$line"'...'
        sudo brew cask uninstall "$line" --force
        sudo brew cask install "$line" --force
        echo ''
    done <"$TMP_DIR"/"$DATE_LIST_FILE"
    
    #read -p 'do you want to update all installed casks that show "latest" as version (y/N)? ' CONT_LATEST
    CONT_LATEST="N"
    CONT_LATEST="$(echo "$CONT_LATEST" | tr '[:upper:]' '[:lower:]')"    # tolower
	if [[ "$CONT_LATEST" == "y" || "$CONT_LATEST" == "yes" ]]
    then
        echo 'updating all installed casks that show "latest" as version...'
        echo ''
        while IFS='' read -r line || [[ -n "$line" ]]
        do
            echo 'updating '"$line"'...'
            sudo brew cask uninstall "$line" --force
            sudo brew cask install "$line" --force
            echo ''
        done <"$TMP_DIR"/"$DATE_LIST_FILE_LATEST"
    else
        echo 'skipping all installed casks that show "latest" as version...'
        echo ''
    fi

    echo 'casks updates finished ;)'
}

homebrew-update
echo ''
brew-upgrade
echo ''
cask-upgrade

cleanup-all


# done
echo ''
echo "script done ;)"
echo ''



###
### unsetting password
###

unset SUDOPASSWORD
