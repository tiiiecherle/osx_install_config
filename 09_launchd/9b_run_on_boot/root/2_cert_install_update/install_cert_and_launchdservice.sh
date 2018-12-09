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


###
### homebrew and script dependencies
###

echo ''

loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

# checking homebrew and script dependencies
if [[ $(sudo -u $loggedInUser command -v brew) == "" ]]
then
    echo "please install homebrew, then run this installer again..."
    echo "homebrew is not installed, exiting..."
    exit
else
    echo "homebrew is installed..."
fi

# checking if all script dependencies are installed
#echo ''
echo "checking for script dependencies..."
if [[ $(brew list | grep openssl) == '' ]]
then
    echo "not all script dependencies installed, installing..."
    ${USE_PASSWORD} | brew install openssl
else
    echo "all script dependencies installed..."
fi

echo ''

###
### installing and running cert installer / updater
### 

# script directory
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo $SCRIPT_DIR

SCRIPT_DIR_DEFAULTS_WRITE=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && cd .. && cd .. && cd .. && pwd)")
if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh ]]
then
    #"$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh
    CERTIFICATE_NAME_VARIABLE=$(cat "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh | grep "^CERTIFICATE_NAME")
    #echo "CERTIFICATE_NAME_VARIABLE is $CERTIFICATE_NAME_VARIABLE..."
    SERVER_IP_VARIABLE=$(cat "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh | grep "^SERVER_IP")
    #echo "SERVER_IP_VARIABLE is $SERVER_IP_VARIABLE..."
else
    echo "script with variables not found, exiting..."
    exit
fi

# uninstalling possible old files
echo "uninstalling possible old files..."
. "$SCRIPT_DIR"/launchd_and_script/uninstall_cert_and_launchdservice.sh
wait

# cert install / update file
echo "installing cert install/update script..."
sudo mkdir -p /Library/Scripts/custom/
sudo cp "$SCRIPT_DIR"/launchd_and_script/cert_install_update.sh /Library/Scripts/custom/cert_install_update.sh
sudo chown -R root:wheel /Library/Scripts/custom/
sudo chmod -R 755 /Library/Scripts/custom/
sudo sed -i '' 's/^CERTIFICATE_NAME=.*/'"$CERTIFICATE_NAME_VARIABLE"'/' /Library/Scripts/custom/cert_install_update.sh
sudo sed -i '' 's/^SERVER_IP=.*/'"$SERVER_IP_VARIABLE"'/' /Library/Scripts/custom/cert_install_update.sh

# launchd service file
echo "installing launchd service..."
sudo cp "$SCRIPT_DIR"/launchd_and_script/com.cert.install_update.plist /Library/LaunchDaemons/com.cert.install_update.plist
sudo chown root:wheel /Library/LaunchDaemons/com.cert.install_update.plist
sudo chmod 644 /Library/LaunchDaemons/com.cert.install_update.plist

# run installation
echo "running cert install/update script..."

# has to be run as root because sudo cannot write to logfile with root priviliges for the function with sudo tee
# otherwise the privileges of the logfile would have to be changed before running inside the script
# sudo privileges inside the called script will not timeout
# script will run as root later anyway
echo ''
sudo bash -c "/Library/Scripts/custom/cert_install_update.sh" &
wait < <(jobs -p)

# launchd service
echo ""
echo "enabling launchd service..."
if [[ $(sudo launchctl list | grep cert.install_update) != "" ]];
then
    sudo launchctl unload /Library/LaunchDaemons/com.cert.install_update.plist
    sudo launchctl disable system/com.cert.install_update
else
    :
fi
sudo launchctl enable system/com.cert.install_update
sudo launchctl load /Library/LaunchDaemons/com.cert.install_update.plist
echo "checking if launchd service is enabled..."
sudo launchctl list | grep cert.install_update

echo "opening logfile..."
#nano /var/log/cert_update.log
open /var/log/cert_update.log

echo ''
echo 'done ;)'
echo ''

###
### unsetting password
###

unset SUDOPASSWORD

