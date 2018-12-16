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
### installing and running network-select installer
### 

# script directory
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo $SCRIPT_DIR

# variables
SERVICE_NAME=com.network.select
SCRIPT_NAME=network_select

other_launchd_services=(
com.hostsfile.install_update
com.cert.install_update
)

launchd_services=(
"${other_launchd_services[@]}"
"$SERVICE_NAME"
)

# uninstalling possible old files
echo ''
echo "uninstalling possible old files..."
. "$SCRIPT_DIR"/launchd_and_script/uninstall_"$SCRIPT_NAME"_and_launchdservice.sh
wait

# script file
echo "installing network select script..."
sudo mkdir -p /Library/Scripts/custom/
sudo cp "$SCRIPT_DIR"/launchd_and_script/"$SCRIPT_NAME".sh /Library/Scripts/custom/"$SCRIPT_NAME".sh
sudo chown -R root:wheel /Library/Scripts/custom/
sudo chmod -R 755 /Library/Scripts/custom/

# launchd service file
echo "installing launchd service..."
sudo cp "$SCRIPT_DIR"/launchd_and_script/"$SERVICE_NAME".plist /Library/LaunchDaemons/"$SERVICE_NAME".plist
sudo chown root:wheel /Library/LaunchDaemons/"$SERVICE_NAME".plist
sudo chmod 644 /Library/LaunchDaemons/"$SERVICE_NAME".plist

# run installation
echo "running network select install script..."

# has to be run as root because sudo cannot write to logfile with root priviliges for the function with sudo tee
# otherwise the privileges of the logfile would have to be changed before running inside the script
# sudo privileges inside the called script will not timeout
# script will run as root later anyway
#echo ''
sudo bash -c "/Library/Scripts/custom/network_select.sh" &
wait < <(jobs -p)

### unloading and disabling launchdservices launched by network_select
#echo ''
echo "unloading other launchdservices..."
for i in "${other_launchd_services[@]}"
do
    if [[ $(sudo launchctl list | grep "$i") != "" ]];
    then
        echo "unloading "$i"..."
        sudo launchctl unload /Library/LaunchDaemons/"$i".plist
    else
        :
    fi
done

echo ''
echo "disabling other launchdservices..."
for i in "${other_launchd_services[@]}"
do
    if [[ $(sudo launchctl print-disabled system | grep "$i" | grep false) != "" ]];
    then
        echo "disabling "$i"..."
        sudo launchctl disable system/"$i"
    else
        :
    fi
done


# launchd service
echo ""
if [[ $(sudo launchctl list | grep network.select) != "" ]];
then
    sudo launchctl unload /Library/LaunchDaemons/"$SERVICE_NAME".plist
    sudo launchctl disable system/"$SERVICE_NAME"
else
    :
fi
sudo launchctl enable system/"$SERVICE_NAME"
sudo launchctl load /Library/LaunchDaemons/"$SERVICE_NAME".plist

echo "waiting 15s for other launchdservices to load before checking installation..."
sleep 15

# checking installation
echo "checking installation..."
sudo "$SCRIPT_DIR"/launchd_and_script/checking_installation.sh
wait

#echo "opening logfile..."
#nano /var/log/network_select.log
#open /var/log/network_select.log
#open /var/log/"$SCRIPT_NAME".log

#echo ''
echo 'done ;)'
echo ''

###
### unsetting password
###

unset SUDOPASSWORD

