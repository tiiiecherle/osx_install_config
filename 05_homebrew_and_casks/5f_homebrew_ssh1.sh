#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



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

function get_running_subprocesses()
{
    SUBPROCESSES_PID_TEXT=$(pgrep -lg $(ps -o pgid= $$) | grep -v $$ | grep -v grep)
    SCRIPT_COMMAND=$(ps -o comm= $$)
	PARENT_SCRIPT_COMMAND=$(ps -o comm= $PPID)
	if [[ $PARENT_SCRIPT_COMMAND == "bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "-bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "" ]]
	then
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | awk '{print $1}')
    else
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | grep -v "$PARENT_SCRIPT_COMMAND" | awk '{print $1}')
    fi
}

function kill_subprocesses() 
{
    # kills only subprocesses of the current process
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    #echo "killing processes..."
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # giving subprocesses the chance to terminate cleanly kill -15
    get_running_subprocesses
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -15 $RUNNING_SUBPROCESSES
        # do not wait here if a process can not terminate cleanly
        #wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # waiting for clean subprocess termination
    TIME_OUT=0
    while [[ $RUNNING_SUBPROCESSES != "" ]] && [[ $TIME_OUT -lt 3 ]]
    do
        get_running_subprocesses
        sleep 1
        TIME_OUT=$((TIME_OUT+1))
    done
    # killing the rest of the processes kill -9
    get_running_subprocesses
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -9 $RUNNING_SUBPROCESSES
        wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # unsetting variable
    unset RUNNING_SUBPROCESSES
}

function kill_main_process() 
{
    # kills processes itself
    #kill $$
    kill -13 $$
}

function unset_variables() {
    unset SUDOPASSWORD
    unset SUDO_PID
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

function activating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
	echo "activating keepingyouawake..."
    #echo ''
	open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///activate
else
        :
fi
}

function deactivating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
    echo "deactivating keepingyouawake..."
    open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///deactivate
else
    :
fi
}

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")

# trap
trap "stop_sudo; printf '\n'; stty sane; pkill ruby; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
trap "stop_sudo; stty sane; kill_subprocesses >/dev/null 2>&1; deactivating_keepingyouawake >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
#set -e

    
###
### starting installation
###
    
# install or uninstall
read -p "do you want to install or uninstall ssh compatible with version ssh1 (i/u)? " CONT_SSH_BREW
CONT_SSH_BREW="$(echo "$CONT_SSH_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower

# checking if online
echo ''
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "we are online, running script..."
    echo ''
    
    if [[ "$CONT_SSH_BREW" == "i" || "$CONT1_BREW" == "install" ]]
    then
        ### install
        # https://apple.stackexchange.com/questions/255621/how-to-enable-ssh-v1-in-macos-sierra
                
        # activating keepingyouawake
        if [ -e /Applications/KeepingYouAwake.app ]
        then
            :
        else
            echo ''
            echo "installing keepingyouawake..."
            builtin printf '"$SUDOPASSWORD\n"' | brew cask install --force keepingyouawake 2> /dev/null | grep "successfully installed"
        fi
        activating_keepingyouawake
        
        # updating homebrew
        echo ''
        echo "updating homebrew..."
        brew update
        #brew upgrade
        # forcing homebrew update to revert any local patch
        echo ''
        echo "forcing homebrew update to revert any local patch..."
        brew update --force > /dev/null 2>&1
        
        # uninstalling patched ssh versions and dependencies including all installed versions
        echo ''
        echo "uninstalling patch and older openssh version that is compatible with ssh1..."
        #brew uninstall formula_name --force
        brew uninstall openssh --force
        brew uninstall openssl --force
        #brew uninstall openssl@1.1 --force 2> /dev/null
        
        # installing patch and older openssh version that is compatible with ssh1
        echo ''
        echo "installing patch and older openssh version that is compatible with ssh1..."
        curl -fsSL https://raw.githubusercontent.com/boltomli/MyMacScripts/master/homebrew/homebrew-core.openssh.diff | patch /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/openssh.rb
        echo ''
        brew install openssh --with-ssh1
        
        # commenting out ssh1 incompatible ssh config entry
        # open trolCommander or Commander One
        # /Users/$USER/.ssh/config
        # comment out the following line
        #UseKeychain yes
        # save
        
        echo ''
        echo "disabling incompatible ssh1 entries in ssh config file..."
        sed -i '' '/UseKeychain/s/^/#/g' /Users/$USER/.ssh/config
        
        # deactivating keepingyouawake
        echo ''
        deactivating_keepingyouawake
        
        # checking openssh version and ssh1 compatibility
        echo ''
        echo "checking openssh version and ssh1 compatibility..."
        echo "should be /usr/local/bin/ssh to be ssh1 compatible..."
        which ssh
        $(which ssh) -1 -V
            
        # using ssh1
        #/usr/local/bin/ssh -1 ADDRESS -L PORT:IP:PORT
        
    elif [[ "$CONT_SSH_BREW" == "u" || "$CONT1_BREW" == "uninstall" ]]
    then
        ### uninstall
        # brew cleanup <formula>
        # or
        brew cleanup
        
        # uninstalling patched ssh versions and dependencies including all installed versions
        #echo ''
        echo "uninstalling patch and older openssh version that is compatible with ssh1..."
        #brew uninstall formula_name --force
        brew uninstall openssh --force
        brew uninstall openssl --force
        #brew uninstall openssl@1.1 --force 2> /dev/null
        
        # forcing homebrew update to revert any local patch
        echo ''
        echo "forcing homebrew update to revert any local patch..."
        brew update --force > /dev/null 2>&1
        
        # installing latest versions of openssl and openssh
        #echo ''
        #echo "installing latest versions of openssl and openssh..."
        #brew install openssl
        #brew install openssh
        #brew install openssl@1.1
        
        # checking openssh version
        echo ''
        echo "checking openssh version..."
        echo "should be /usr/bin/ssh..."
        which ssh
        $(which ssh) -V

        # uncommenting ssh1 incompatible ssh config entry
        echo ''
        echo "enabling incompatible ssh1 entries in ssh config file..."
        # removes one # at the beginning of a line matching the pattern
        #sed -i '' '/UseKeychain/s/^#//g' /Users/$USER/.ssh/config
        # removes all # at the beginning of a line matching the pattern
        sed -i '' '/UseKeychain/s/^#*//g' /Users/$USER/.ssh/config
    else
        echo "no valid input, exiting script..."
        exit
    fi
    
else
    echo "not online, exiting script..."
    echo ''
    exit
fi
 
# done
echo ''
echo "done ;)"
echo ''

###
### unsetting password
###

unset SUDOPASSWORD
