#!/bin/zsh

if [[ $(id -u) -ne 0 ]]
then
    echo "script has to be run as root, exiting..."
    exit
else
    :
fi

# the script is run as root
# that`s why $USER will not work, use the current logged in user instead
# every command that does not have sudo -H -u "$loggedInUser" upfront has to be run as root, but sudo is not needed here


### getting logged in user before running rest of script
# recommended way, but it seems apple deprecated python2 in macOS 12.3.0
# to keep on using the python command, a python module is needed
#pip3 install pyobjc-framework-SystemConfiguration
#loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
NUM=0
MAX_NUM=30
SLEEP_TIME=3
# waiting for loggedInUser to be available
while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
do
    sleep "$SLEEP_TIME"
    NUM=$((NUM+1))
    # recommended way, but it seems apple deprecated python2 in macOS 12.3.0
    # to keep on using the python command, a python module is needed
    #pip3 install pyobjc-framework-SystemConfiguration
    #loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
done
#echo ''
#echo "NUM is $NUM..."
#echo "loggedInUser is $loggedInUser..."
if [[ "$loggedInUser" == "" ]]
then
    WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
    echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
    exit
else
    :
fi


###

# workaround for macos bug that prevents /etc/fstab entries to work for encrypted apfs volumes
# it seems there is another way of preventing macintosh_hd2 to auto-mount by adding apfs role D (data)
# https://apple.stackexchange.com/questions/310574/how-to-prevent-auto-mounting-of-a-volume-in-macos-high-sierra
# DEVICE_IDENTIFIER=$(diskutil info macintosh_hd2 | grep -e "Device Identifier" | awk '{print $NF}')
# DEVICE_IDENTIFIER2=$(diskutil info "macintosh_hd2 - Daten" | grep -e "Device Identifier" | awk '{print $NF}')
# diskutil apfs changeVolumeRole /dev/diskXsX D
# diskutil apfs changeVolumeRole "$DEVICE_IDENTIFIER" D
# check role
# diskutil apfs list | grep "$DEVICE_IDENTIFIER"
# LESS='+/^[[:space:]]*changeVolumeRole' man diskutil
unmount_second_system_partition() {
    #MACOS_CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | awk '{print $3}')
    MACOS_CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | sed 's/^.*Volume Name: //' | awk '{$1=$1};1')
    if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "macintosh_hd" ]]
    then
        sleep 25
        #if [[ -e "/Volumes/macintosh_hd2" ]]; then sudo diskutil unmount /Volumes/macintosh_hd2; fi
        #if [[ -e "/Volumes/macintosh_hd2 - Daten" ]]; then sudo diskutil unmount "/Volumes/macintosh_hd2 - Daten"; fi
        if [[ -e "/Volumes/macintosh_hd2" ]]; then sudo umount -f /Volumes/macintosh_hd2; fi
        if [[ -e "/Volumes/macintosh_hd2 - Daten" ]]; then sudo umount -f "/Volumes/macintosh_hd2 - Daten"; fi
    else
        :
    fi
}
#unmount_second_system_partition &

unmount_update_partition() {
    # see config file
    MACOS_CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | sed 's/^.*Volume Name: //' | awk '{$1=$1};1')
    get_mounted_disks() {
        MACOS_CURRENTLY_BOOTED_DISK_IDENTIFIER_MAJOR=$(diskutil info "$MACOS_CURRENTLY_BOOTED_VOLUME" | grep "Part of Whole:" | sed 's/^.*Part of Whole: //' | awk '{$1=$1};1')
        LIST_OF_ALL_MOUNTED_VOLUMES=$(for i in $(df -Hl | tail -n +2 | awk '{print $1}'); do diskutil info "$i" | grep "Mount Point:" | sed 's/^.*Mount Point: //' | awk '{$1=$1};1'; done)
        LIST_OF_ALL_MOUNTED_VOLUMES_ON_BOOT_VOLUME=$(for i in $(df -Hl | tail -n +2 | awk '{print $1}' | grep "/dev/"$MACOS_CURRENTLY_BOOTED_DISK_IDENTIFIER_MAJOR""); do diskutil info "$i" | grep "Mount Point:" | sed 's/^.*Mount Point: //' | awk '{$1=$1};1'; done)
        LIST_OF_ALL_MOUNTED_VOLUMES_OUTSIDE_OF_BOOT_VOLUME=$(for i in $(df -Hl | tail -n +2 | awk '{print $1}' | grep -v "/dev/"$MACOS_CURRENTLY_BOOTED_DISK_IDENTIFIER_MAJOR""); do diskutil info "$i" | grep "Mount Point:" | sed 's/^.*Mount Point: //' | awk '{$1=$1};1'; done)
    }
    get_mounted_disks
    
    if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "macintosh_hd" ]]
    then
        if [[ $(echo "$LIST_OF_ALL_MOUNTED_VOLUMES_OUTSIDE_OF_BOOT_VOLUME" | grep '/Update$') != "" ]]
        then
            sleep 25
            if [[ -e "/Volumes/Update" ]]; then sudo umount -f /Volumes/Update; fi
        else
            :
        fi
    else
        :
    fi
}
#unmount_update_partition &


###

# run command as root
# echo 1

# run command as user
# sudo -H -u "$loggedInUser" echo 1
