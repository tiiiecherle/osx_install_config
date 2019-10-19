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

reset_safari_download_location () {

    sudo -H -u "$loggedInUser" defaults write com.apple.Safari AlwaysPromptForDownloadFolder -bool false

    if [[  -d "/Users/"$loggedInUser"/Desktop/files" ]]
    then
        #sudo -H -u "$loggedInUser" mkdir -p "/Users/$loggedInUser/Desktop/files"
        #mkdir -p "~/Desktop/files"
        sudo -H -u "$loggedInUser" defaults write com.apple.Safari DownloadsPath -string "~/Desktop/files"
        #defaults write com.apple.Safari DownloadsPath -string "~/Desktop/files"
    else
        sudo -H -u "$loggedInUser" defaults write com.apple.Safari DownloadsPath -string "~/Downloads"
    fi
    
    # testing
    #echo "$loggedInUser" > /Users/"$loggedInUser"/Desktop/login_script.txt
        
}
#reset_safari_download_location


# workaround for macos bug that prevents /etc/fstab entries to work for encrypted apfs volumes
unmount_test_partition() {
    MACOS_CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | awk '{print $3}')
    if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "macintosh_hd" ]]
    then
        sleep 15
        #if [[ -e "/Volumes/macintosh_hd2" ]]; then sudo diskutil unmount /Volumes/macintosh_hd2; fi
        #if [[ -e "/Volumes/macintosh_hd2 - Daten" ]]; then sudo diskutil unmount "/Volumes/macintosh_hd2 - Daten"; fi
        if [[ -e "/Volumes/macintosh_hd2" ]]; then sudo umount -f /Volumes/macintosh_hd2; fi
        if [[ -e "/Volumes/macintosh_hd2 - Daten" ]]; then sudo umount -f "/Volumes/macintosh_hd2 - Daten"; fi
    else
        :
    fi
}
unmount_test_partition &


###

# run command as root
# echo 1

# run command as user
# sudo -H -u "$loggedInUser" echo 1
