#!/bin/bash

###
### asking password upfront
###

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

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    ( while true; do ${USE_PASSWORD} | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID="$!"
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then
            sudo kill -9 $SUDO_PID &> /dev/null
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}

###
### homebrew uninstall
###

# uninstalling homebrew and all casks
# https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/FAQ.md

###
###
###

# asking for casks zap
read -p "do you want to zap / uninstall all casks including preferences (y/N)? " CONT2_BREW
CONT2_BREW="$(echo "$CONT2_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower


# asking for command line tools uninstall
read -p "do you want to uninstall developer tools (Y/n)? " CONT0_BREW
CONT0_BREW="$(echo "$CONT0_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower


# asking for homebrew uninstall
read -p "do you want to uninstall homebrew and all formulae (Y/n)? " CONT1_BREW
CONT1_BREW="$(echo "$CONT1_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower


###
###
###

# casks zap
if [[ "$CONT2_BREW" == "n" || "$CONT2_BREW" == "no" || "$CONT2_BREW" == "" ]]
then
    :
else
    #start_sudo
    echo ''
    echo "uninstalling casks incl. preferences..."
    for caskstouninstall in $(brew cask list)
    do  
        echo "zapping $caskstouninstall"...
    	${USE_PASSWORD} | brew cask zap --force "$caskstouninstall"
    	echo ''
    done
    if [[ $(brew cask list) == "" ]]
    then
        echo "all casks uninstalled..."
    else
        echo "the following casks are still installed..."
        brew cask list
    fi
    #stop_sudo
fi

# command line tools uninstall
if [[ "$CONT0_BREW" == "y" || "$CONT0_BREW" == "yes" || "$CONT0_BREW" == "" ]]
then
    echo ''
    echo "uninstalling developer tools..."
    sudo rm -rf /Library/Developer/CommandLineTools
    echo ''
else
    :
fi

# homebrew uninstall
if [[ "$CONT1_BREW" == "y" || "$CONT1_BREW" == "yes" || "$CONT1_BREW" == "" ]]
then
    echo ''
    echo "uninstalling homebrew and all formulae..."
    # redefining sudo so it is possible to run homebrew without entering the password again
    sudo()
    {
        ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
    }
    # uninstalling with homebrew script
    sudo yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
    # forcing sudo to forget the sudo password (can still be used with ${USE_PASSWORD})
    sudo -K
    # redefining sudo back for the rest of the script
    sudo()
    {
        ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    }
    #
    sudo rm -rf /opt/homebrew-cask
    sudo rm -rf /usr/local/Caskroom
    sudo rm -rf /usr/local/lib/librtmp.dylib
    sudo rm -rf /usr/local/var/homebrew/
    sudo rm -rf /usr/local/var/cache/
    sudo rm -rf /usr/local/Homebrew/
    sudo chmod 0755 /usr/local
    sudo chown root:wheel /usr/local
    sed -i '' '\|/usr/local/sbin:$PATH|d' ~/.bash_profile
else
    :
fi

echo ''



###
### unsetting password
###

unset SUDOPASSWORD
