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

ask_for_variable () {
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
### usb storage device
###


### usb storage device if only one is plugged in
USB_DEVICE=$(diskutil list | grep external | awk '{print $1}')
DEVICE_NAME=$(diskutil info $USB_DEVICE | grep "Media Name:" | sed 's/^.*Name: //' | awk '{$1=$1};1')
#echo $DEVICE_NAME

### formats
WIN_PARTITION_FORMAT=ExFAT
MAC_PARTITION_FORMAT=JHFS+

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

# check if usb_device was found
if [[ $USB_DEVICE == "" ]] || [[ $DEVICE_NAME == "" ]]
then
	echo ''
	echo "usb storage device does not seem to be connected, exiting..."
	echo ''
	exit
else
	:
fi

### selecting kind of formating usb storage device
echo ''
PS3="Please select how to format usb storage device: "
select OPTION in "mbr, windows compatible, one $WIN_PARTITION_FORMAT partition" "gpt, one $WIN_PARTITION_FORMAT and one $MAC_PARTITION_FORMAT partition with option of windows compatibility"
do
    echo You selected option $OPTION.
    #echo ""
    break
done

if [[ "$OPTION" == "mbr, windows compatible, one $WIN_PARTITION_FORMAT partition" ]]; then OPTION="mbr"; fi
if [[ "$OPTION" == "gpt, one $WIN_PARTITION_FORMAT and one $MAC_PARTITION_FORMAT partition with option of windows compatibility" ]]; then OPTION="gpt"; fi
#echo "$OPTION"

if [[ "$OPTION" == "" ]] || [[ "$OPTION" != "mbr" ]] && [[ "$OPTION" != "gpt" ]]
then
    echo ''
    echo "no valid option selected, exiting..."
    echo ''
    exit
else
    #echo "valid option selected, running script..."
    :
fi

### size for calculating b, kb, mb, gb
KILOBYTE_SIZE=1000


### setting values to make calculations work with dots as separators
LC_NUMERIC=C LC_COLLATE=C


### size of usb storage device
DISKSIZE_IN_B=$(diskutil info $USB_DEVICE | grep "Disk Size:" | grep -Eio '[0-9]{10,}')
DISKSIZE_IN_GB="$(echo "scale=2 ; $DISKSIZE_IN_B / $KILOBYTE_SIZE / $KILOBYTE_SIZE / $KILOBYTE_SIZE" | bc -l)"


### option mbr
if [[ "$OPTION" == "mbr" ]]
then

    ### partition sizes
    echo ''
    echo "current usb storage device partitions..."
    diskutil list $USB_DEVICE

    echo ''
    echo "new usb storage device partitions after formating..."
    printf "%-35s %+15s\n" "usb storage device" "$USB_DEVICE"
    printf "%-35s %+15s\n" "usb storage device name" "$DEVICE_NAME"
    #printf "%-35s %+15s\n" "usb storage device size" "$DISKSIZE_IN_GB GB"
    #printf "%-35s %+15s\n" "data size" "$DATASIZE_IN_GB GB"
    #printf "%-35s %+15s\n" "installer size" "$INSTALLER_SIZE_IN_GB GB"
    printf "%-35s %+15s\n" "usb storage device size" "$DISKSIZE_IN_GB GB"
    printf "%-35s %+15s\n" "data partition size ($WIN_PARTITION_FORMAT)" "$DISKSIZE_IN_GB GB"
    echo ''
    
    echo "all data on the usb storage device will be lost..."
    
    VARIABLE_TO_CHECK="$FORMAT_USB_MBR"
    QUESTION_TO_ASK="is it the right usb storage device and do really want to format it like that? (y/N) "
    ask_for_variable
    FORMAT_USB_MBR="$VARIABLE_TO_CHECK"
    
    if [[ "$FORMAT_USB_MBR" =~ ^(yes|y)$ ]]
    then
    	echo ''
    	#:
    else
    	echo ''
    	echo "exiting script..."
    	echo ''
    	exit
    fi
    
    ### formating device
    # the exfat volume is usable on win, linux and mac
    diskutil partitionDisk $USB_DEVICE MBR $WIN_PARTITION_FORMAT USB_DATA R

else
    :
fi

### option mbr
if [[ "$OPTION" == "gpt" ]]
then

    ### path to macos installer
    #INSTALLERPATH="/Applications/Install macOS High Sierra.app"
    INSTALLERPATH="/Applications/Install macOS Mojave.app"
    if [[ ! -e "$INSTALLERPATH" ]]
    then
    	echo ''
    	echo "macos installer not found, assuming 10 gb for hfs+ partition..."
    	# only set to one gb less as one gb is added for security reasons later
    	INSTALLER_SIZE_IN_B=9000000000
    else
    	# size of macos installer
    	INSTALLER_SIZE_IN_B="$(echo $(($(du -s "$INSTALLERPATH" | cut -f1) * 512)))"
    	#echo $INSTALLER_SIZE_IN_B
    	INSTALLER_SIZE_IN_GB="$(echo "scale=2 ; $INSTALLER_SIZE_IN_B / $KILOBYTE_SIZE / $KILOBYTE_SIZE / $KILOBYTE_SIZE" | bc -l)"
    	#echo $INSTALLER_SIZE_IN_GB
    	#INSTALLER_SIZE_IN_GB_ROUNDED=$(printf "%.0f" $INSTALLER_SIZE_IN_GB)
    	#INSTALLER_SIZE_IN_GB_ROUNDED_PLUS_ONE="$(echo "scale=0 ; $INSTALLER_SIZE_IN_GB_ROUNDED + 1" | bc)"
    	#echo $INSTALLER_SIZE_IN_GB_ROUNDED
    	#echo $INSTALLER_SIZE_IN_GB_ROUNDED_PLUS_ONE
    fi
    
    
    ### checking usb storage device size
    #echo $DISKSIZE_IN_B
    if [[ "$INSTALLER_SIZE_IN_B" -gt "$DISKSIZE_IN_B" ]]
    then
    	echo ''
    	echo "usb storage device is smaller than installer, exiting..."
    	echo ''
    	exit
    else
    	:
    fi
    
    ### size for data partition
    DATASIZE_IN_B="$(($DISKSIZE_IN_B-$INSTALLER_SIZE_IN_B))"
    DATASIZE_IN_GB="$(echo "scale=2 ; $DATASIZE_IN_B / $KILOBYTE_SIZE / $KILOBYTE_SIZE / $KILOBYTE_SIZE" | bc)"
    DATASIZE_IN_GB_ROUNDED=$(printf "%.0f" $DATASIZE_IN_GB)
    DATASIZE_IN_GB_ROUNDED_MINUS_ONE="$(printf "%.2f" $(echo "scale=0 ; $DATASIZE_IN_GB_ROUNDED - 1" | bc))"
    DATASIZE_IN_GB_ROUNDED_FORMAT="$(printf "%.0f" $(echo "scale=0 ; $DATASIZE_IN_GB_ROUNDED_MINUS_ONE" | bc))"
    #echo $DATASIZE_IN_B
    #echo $DATASIZE_IN_GB
    #echo $DATASIZE_IN_GB_ROUNDED
    #echo $DATASIZE_IN_GB_ROUNDED_MINUS_ONE
    EFI_DISK_SPACE_IN_GB=0.3
    INSTALLER_PARTITION_SIZE="$(echo "scale=2 ; $DISKSIZE_IN_GB-$DATASIZE_IN_GB_ROUNDED_MINUS_ONE-$EFI_DISK_SPACE_IN_GB" | bc)"
    
    ### partition sizes
    echo ''
    echo "current usb storage device partitions..."
    diskutil list $USB_DEVICE
    
    echo ''
    echo "new usb storage device partitions after formating..."
    printf "%-35s %+15s\n" "usb storage device" "$USB_DEVICE"
    printf "%-35s %+15s\n" "usb storage device name" "$DEVICE_NAME"
    #printf "%-35s %+15s\n" "usb storage device size" "$DISKSIZE_IN_GB GB"
    #printf "%-35s %+15s\n" "data size" "$DATASIZE_IN_GB GB"
    #printf "%-35s %+15s\n" "installer size" "$INSTALLER_SIZE_IN_GB GB"
    printf "%-35s %+15s\n" "usb storage device size" "$DISKSIZE_IN_GB GB"
    printf "%-35s %+15s\n" "efi or free disk space" "$EFI_DISK_SPACE_IN_GB GB"
    printf "%-35s %+15s\n" "data partition size ($WIN_PARTITION_FORMAT)" "$DATASIZE_IN_GB_ROUNDED_MINUS_ONE GB"
    printf "%-35s %+15s\n" "installer partition size ($MAC_PARTITION_FORMAT)" "$INSTALLER_PARTITION_SIZE GB"
    echo ''
    
    echo "all data on the usb storage device will be lost..."
    
    VARIABLE_TO_CHECK="$FORMAT_USB_GPT"
    QUESTION_TO_ASK="is it the right usb storage device and do really want to format it like that? (y/N) "
    ask_for_variable
    FORMAT_USB_GPT="$VARIABLE_TO_CHECK"
    
    if [[ "$FORMAT_USB_GPT" =~ ^(yes|y)$ ]]
    then
    	echo ''
    	#:
    else
    	echo ''
    	echo "exiting script..."
    	echo ''
    	exit
    fi
    
    
    ### formating device
    # format usb storage device as preparation for usb macos installer
    # percent instead of numbers or R is also allowed
    diskutil partitionDisk $USB_DEVICE GPT $WIN_PARTITION_FORMAT USB_DATA "$DATASIZE_IN_GB_ROUNDED_FORMAT"GB $MAC_PARTITION_FORMAT Untitled R
        
    #echo ''
    #echo "creating installer medium..."
    
    # format usb drive with guid partition table
    # format partition with OS X Extended (Journaled) and name it "Untitled" and leave it mounted
    # download installer to some directory and put the POSIX path in the variable
    # adjust installer path and name and run the following command in terminal and enter admin password
    
    #VOLUMEPATH="/Volumes/Untitled"
    
    #sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --applicationpath "$INSTALLERPATH" --nointeraction
    
    
    ### deleting efi partition to make the exfat data partition usable on windows
    # the exfat volume is only usable on linux and mac if you do not delete the efi partiton
    # as of 2018-06 is seems like windows can only read / write to first partition on a gpt foramtted device
    
    echo ''
    VARIABLE_TO_CHECK="$DELETE_EFI"
    QUESTION_TO_ASK="do you want to delete the efi partition on the usb storage device to make the exfat data partition usable on windows? (y/N) "
    ask_for_variable
    DELETE_EFI="$VARIABLE_TO_CHECK"
    
    if [[ "$DELETE_EFI" =~ ^(yes|y)$ ]]
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

else
    :
fi

echo ''
echo 'done ;)'
echo ''


###
### unsetting password
###

unset SUDOPASSWORD
