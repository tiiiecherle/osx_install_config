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
### usb installer
###

### usb storage device if only one is plugged in
USB_DEVICE=$(diskutil list | grep external | awk '{print $1}')
DEVICE_NAME=$(diskutil info $USB_DEVICE | grep "Media Name:" | sed 's/^.*Name: //' | awk '{$1=$1};1')
#echo $DEVICE_NAME

# check if only one usb_device is connected
if [[ $(diskutil list | grep external | awk '{print $1}' | wc -l | awk '{print ($0+0)}') != "1" ]]
then
    echo ''
    echo "there is no or more than one external usb storage device connected..."
    echo "please connect only the external usb storage device that is supposed to be formatted..."
    echo "exiting..."
    echo ''
    exit
else
    :
fi


# format usb drive with guid partition table
# format partition with OS X Extended (Journaled) JHFS+ and name it "Untitled" and leave it mounted
# download installer to some directory and put the POSIX path in the variable
# or just use this script with option 2 
# 0a_format_bootable_usb_device.sh


### variables
# adjust installer path and name and run the following command in terminal and enter admin password
INSTALLERPATH="/Applications/Install macOS Mojave.app"
VOLUMENAME="Untitled"
VOLUMEPATH="/Volumes/$VOLUMENAME"
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)


# checking if VOLUMEPATH is on USB_DEVICE
if [[ $(diskutil list $USB_DEVICE | grep "$VOLUMENAME") == "" ]]
then
	echo ''
	echo """$VOLUMENAME"" does not seem to be on $USB_DEVICE, exiting..."
	echo ''
	exit
else
    :
fi

# checking if available
if [[ ! -e "$INSTALLERPATH" ]]
then
	echo ''
	echo "macos installer not found, exiting..."
	echo ''
	exit
else
    :
fi

# checking if volume is available
if [[ ! -e "$VOLUMEPATH" ]]
then
	echo ''
	echo "$VOLUMEPATH not found, exiting..."
	echo ''
	exit
else
    :
fi

### creating installer   
echo ''
echo "creating installer medium..."

if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13 
    sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --applicationpath "$INSTALLERPATH" --nointeraction
else
    # macos versions 10.14 and up
    sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --nointeraction
fi
    
    
### deleting efi partition to make the exfat data partition usable on windows
# the exfat volume is only usable on linux and mac if you do not delete the efi partiton
# as of 2018-06 is seems like windows can only read / write to first partition on a gpt foramtted device

echo ''
read -r -p "do you want to delete the efi partition on the usb storage device to make the exfat data partition usable on windows? [y/N] " response
response="$(echo "$response" | tr '[:upper:]' '[:lower:]')"    # tolower
if [[ "$response" == "y" || "$response" == "yes" ]]
then
	echo ''
	#:
else
	echo ''
	echo "exiting script..."
	echo ''
	exit
fi

EFI_PARTITION_NUMBER=$(diskutil list $USB_DEVICE | grep "EFI.*EFI" | awk '{print ($0+0)}')
if [[ $EFI_PARTITION_NUMBER =~ ^[0-9]+$ ]] && [[ $EFI_PARTITION_NUMBER -lt 9 ]]
then
	# echo "number smaller than 9"
	:
else
	# echo "no number or bigger than 9"
	echo "no valid efi partition selected to delete, exiting..."
	exit
fi
diskutil umountDisk $USB_DEVICE
echo ''
sudo gpt remove -i $EFI_PARTITION_NUMBER $USB_DEVICE
echo ''
diskutil list $USB_DEVICE
    

echo ''
echo 'done ;)'
echo ''


###
### unsetting password
###

unset SUDOPASSWORD
