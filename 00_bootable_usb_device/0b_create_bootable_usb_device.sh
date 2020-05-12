#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

env_enter_sudo_password



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
echo ''
# path to macos installer
#INSTALLERPATH=""$PATH_TO_APPS"/Install macOS High Sierra.app"
#INSTALLERPATH=""$PATH_TO_APPS"/Install macOS Mojave.app"
NUMBER_OF_AVAILABLE_INSTALLERS=$(find "$PATH_TO_APPS" -mindepth 1 -maxdepth 1 -name "Install*macOS*" | wc -l | awk '{print $1}')
if [[ "$NUMBER_OF_AVAILABLE_INSTALLERS" -le "1" ]]
then
    INSTALLERPATH="$(find "$PATH_TO_APPS" -mindepth 1 -maxdepth 1 -name "Install*macOS*")"
else
    installer=()
    while IFS= read -r line; do installer+=("$line"); done <<< "$(find "$PATH_TO_APPS" -mindepth 1 -maxdepth 1 -name "Install*macOS*")"
    COLUMNS_DEFAULT="$COLUMNS"
    PS3="Please select installer to use: "
    COLUMNS=1
    select INSTALLERPATH in "${installer[@]}"
    do
        #echo "you selected "$INSTALLERPATH"..."
        #echo ''
        COLUMNS="$COLUMNS_DEFAULT"
        break
    done
fi
echo "the path to the installer is "$INSTALLERPATH"..."
VOLUMENAME="Untitled"
VOLUMEPATH="/Volumes/$VOLUMENAME"

# checking if VOLUMEPATH is on USB_DEVICE
if [[ $(diskutil list $USB_DEVICE | grep "$VOLUMENAME") == "" ]]
then
	echo ''
	echo "there is no partition named "$VOLUMENAME" on "$USB_DEVICE", exiting..."
	echo ''
	exit
else
    :
fi

# checking if available
if [[ ! -e "$INSTALLERPATH" ]] || [[ "$INSTALLERPATH" == "" ]]
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

VERSION_TO_CHECK_AGAINST=10.13
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.13
    sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --applicationpath "$INSTALLERPATH" --nointeraction
else
    # macos versions 10.14 and up
    #sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --nointeraction
    sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --nointeraction --downloadassets
fi
    
    
### deleting efi partition to make the exfat data partition usable on windows
# the exfat volume is only usable on linux and mac if you do not delete the efi partiton
# as of 2018-06 is seems like windows can only read / write to first partition on a gpt foramtted device

echo ''
VARIABLE_TO_CHECK="$DELETE_EFI"
QUESTION_TO_ASK="do you want to delete the efi partition on the usb storage device to make the exfat data partition usable on windows? (Y/n) "
env_ask_for_variable
DELETE_EFI="$VARIABLE_TO_CHECK"

echo ''
diskutil umountDisk $USB_DEVICE
sleep 3
if [[ $(mount | awk '{print $1}' | grep "$USB_DEVICE") != "" ]]
then
    diskutil umountDisk force $USB_DEVICE
else
    :
fi

if [[ "$DELETE_EFI" =~ ^(yes|y)$ ]]
then
	echo ''
    EFI_PARTITION_NUMBER=$(diskutil list $USB_DEVICE | grep "EFI.*EFI" | awk '{print ($0+0)}')
    if [[ $EFI_PARTITION_NUMBER =~ ^[0-9]+$ ]] && [[ $EFI_PARTITION_NUMBER -lt 9 ]]
    then
    	# echo "number smaller than 9"
        sudo gpt remove -i $EFI_PARTITION_NUMBER $USB_DEVICE
        sleep 2
    else
    	# echo "no number or bigger than 9"
    	echo "no valid efi partition selected to delete, exiting..."
    fi
else
    :
fi
echo ''

diskutil list $USB_DEVICE

echo ''
echo 'done ;)'
echo ''


###
### unsetting password
###

unset SUDOPASSWORD
