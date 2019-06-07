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


### functions

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo() {
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

ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}

###
### homebrew uninstall
###

# uninstalling homebrew and all casks
# https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/FAQ.md

###
###
###

echo ''

# asking for casks zap
VARIABLE_TO_CHECK="$ZAP_CASKS"
QUESTION_TO_ASK="do you want to zap / uninstall all casks including preferences (y/N)? "
ask_for_variable
ZAP_CASKS="$VARIABLE_TO_CHECK"

# asking for command line tools uninstall
VARIABLE_TO_CHECK="$UNINSTALL_DEV_TOOLS"
QUESTION_TO_ASK="do you want to uninstall developer tools (Y/n)? "
ask_for_variable
UNINSTALL_DEV_TOOLS="$VARIABLE_TO_CHECK"

# asking for homebrew uninstall
VARIABLE_TO_CHECK="$UNINSTALL_HOMEBREW"
QUESTION_TO_ASK="do you want to uninstall homebrew and all formulae (Y/n)? "
ask_for_variable
UNINSTALL_HOMEBREW="$VARIABLE_TO_CHECK"


###
###
###

# casks zap
if [[ "$ZAP_CASKS" =~ ^(no|n)$ ]]
then
    if [[ -e "/usr/local/Caskroom" ]]
    then
        # backing up specifications of latest installed casks
        echo ''
        echo "backing up /usr/local/Caskroom/. to /tmp/Caskroom/..."
        #ls -la /usr/local/Caskroom/
        mkdir -p /tmp/Caskroom
        cp -a /usr/local/Caskroom/. /tmp/Caskroom/
        #ls -la /tmp/Caskroom/
    else
        echo ''
        echo "/usr/local/Caskroom/ not found, skipping backup..."
    fi
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
if [[ "$UNINSTALL_DEV_TOOLS" =~ ^(yes|y)$ ]]
then
    echo ''
    echo "uninstalling developer tools..."
    sudo rm -rf /Library/Developer/CommandLineTools
    #echo ''
else
    :
fi

# homebrew uninstall
if [[ "$UNINSTALL_HOMEBREW" =~ ^(yes|y)$ ]]
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
    for CONFIG_FILE in ~/.bash_profile ~/.bashrc ~/.zshrc
    do
        sed -i '' '\|/usr/local/sbin:$PATH|d' "$CONFIG_FILE"
        sed -i '' '\|# setting PATH|d' "$CONFIG_FILE"
        sed -i '' '${/^$/d;}' "$CONFIG_FILE"
    done
else
    :
fi

echo ''



###
### unsetting password
###

unset SUDOPASSWORD
