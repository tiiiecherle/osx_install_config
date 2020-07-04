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
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
NUM=0
MAX_NUM=15
SLEEP_TIME=3
# waiting for loggedInUser to be available
while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
do
    sleep "$SLEEP_TIME"
    NUM=$((NUM+1))
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
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

reset_safari_download_location() {

    if sudo -H -u "$loggedInUser" defaults read -app Safari AlwaysPromptForDownloadFolder &>/dev/null
    then
        sudo -H -u "$loggedInUser" defaults delete -app Safari AlwaysPromptForDownloadFolder
    else
        #sudo -H -u "$loggedInUser" defaults write -app Safari AlwaysPromptForDownloadFolder -bool false
        :
    fi

    if [[ -d "/Users/"$loggedInUser"/Desktop/files" ]]
    then
        if [[ $(sudo -H -u "$loggedInUser" defaults read -app Safari DownloadsPath) != "~/Desktop/files" ]]
        then
            #sudo -H -u "$loggedInUser" mkdir -p "/Users/$loggedInUser/Desktop/files"
            #mkdir -p "~/Desktop/files"
            sudo -H -u "$loggedInUser" defaults write -app Safari DownloadsPath -string "~/Desktop/files"
            #sudo -H -u "$loggedInUser" defaults write -app Safari DownloadsPath -string "~/Desktop/files"
            #sudo -H -u "$loggedInUser" defaults write /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist DownloadsPath -string "~/Desktop/files"
            #/usr/libexec/PlistBuddy -c 'Set DownloadsPath "~/Desktop/files"' /Users/"$USER"/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
        else
            :
        fi
    else
        if [[ $(sudo -H -u "$loggedInUser" defaults read -app Safari DownloadsPath) != "~/Downloads" ]]
        then
            sudo -H -u "$loggedInUser" defaults write -app Safari DownloadsPath -string "~/Downloads"
        else
            :
        fi
    fi
    
    # testing
    #echo "$loggedInUser" > /Users/"$loggedInUser"/Desktop/login_script.txt
    
    # activating changes
    #sudo -H -u "$loggedInUser" defaults read com.apple.Safari &>/dev/null
        
}
#reset_safari_download_location


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


###

# run command as root
# echo 1

# run command as user
# sudo -H -u "$loggedInUser" echo 1
