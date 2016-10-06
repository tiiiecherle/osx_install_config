#!/bin/bash



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

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

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

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo --prompt="" -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo --prompt="" -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo --prompt="" -k -S "$@"
}



###
### java 6
###

# before running download and install the latest version of java jre from www.java.com or through homebrew cask

# restoring functionality of apps that need java 6 without installing apple java
#sudo mkdir -p /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
#sudo ln -s '/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents' /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents
#sudo mkdir -p /System/Library/Java/Support/Deploy.bundle


# to undo this do
#sudo rm -rf /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
#sudo rm -rf /System/Library/Java/Support/Deploy.bundle

echo 'done ;)'



###
### unsetting password
###

unset SUDOPASSWORD
