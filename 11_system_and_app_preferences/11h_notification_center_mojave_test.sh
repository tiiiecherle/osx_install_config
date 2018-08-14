#!/bin/bash

#launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
#killall NotificationCenter

PLIST_FILE='~/Library/Preferences/com.apple.ncprefs.plist'

# this sets some extended attributes on the file
# without this the changes will be written but restored to the old version by killall usernoted or reboot
#com.apple.lastuseddate#PS
# check with 
#xattr /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
#xattr -l /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
# clean all extended attributes
#xattr -c /Users/$USER/Library/Preferences/com.apple.ncprefs.plist
open $(eval echo "$PLIST_FILE")
sleep 2


IFS=$'\n'

user=`ls -l /dev/console | cut -d " " -f 4`

#Location of the notification center preferences plist for the current user
notificationsPLIST="/Users/$user/Library/Preferences/com.apple.ncprefs.plist"

#List of the name of the bundles that need to be configured. Set to your needs.
#bundlesToConfigure=('com.apple.FaceTime' 'com.apple.iCal' 'com.apple.FaceTime' 'com.apple.gamecenter' 'com.apple.mail' 'com.apple.iChat' 'com.apple.reminders' 'com.apple.Safari' 'com.apple.iTunes')
# Get list of all user manipulatable notification center objects 
bundlesToConfigure=com.bitdefender.virusscannerplus


#Count of the bundles existing in the plist
apps=`/usr/libexec/PlistBuddy -c "Print :apps" "$notificationsPLIST"`
count=$(echo "$apps" | grep "bundle-id"|wc -l)

#Substracting one to run in a for loop
count=$((count - 1))

change=0
for index in $(seq 0 $count); do
    #Getting each bundle id with PlistBuddy
    bundleID=$(/usr/libexec/PlistBuddy -c "Print apps:$index:bundle-id" "$notificationsPLIST");

    #If the name of the current bundle is in our list of bundles to configure
    if [[ "${bundlesToConfigure[*]}" == *"$bundleID"* ]]; then
        flag=`/usr/libexec/PlistBuddy -c "Print apps:$index:flags" "$notificationsPLIST"`
        echo Current value:  $index:$bundleID $flag
            #echo "  Flag is less than 4096.  Adding 4096 to disable notification/preview on lockscreen."
            flag=343
            change=1
            sudo -u $user /usr/libexec/PlistBuddy -c "Set :apps:${index}:flags ${flag}" "$notificationsPLIST"
            #/usr/libexec/PlistBuddy -c "Set :apps:${index}:flags ${flag}" "$notificationsPLIST"
            flag=`/usr/libexec/PlistBuddy -c "Print apps:$index:flags" "$notificationsPLIST"`
            echo New Value: $index:$bundleID $flag
            sleep 1
            flag=`/usr/libexec/PlistBuddy -c "Print apps:$index:flags" "$notificationsPLIST"`
            echo Set Value: $index:$bundleID $flag
            
            #cp -a /Users/$user/Library/Preferences/com.apple.ncprefs.plist /tmp/com.apple.ncprefs.plist
            #if [ $change == 1 ]; then echo "Changes made.  Restarting Notification Center for them to take effect.";killall sighup usernoted;killall sighup NotificationCenter; fi
            #sleep 10
            #cat /tmp/com.apple.ncprefs.plist > /Users/$user/Library/Preferences/com.apple.ncprefs.plist
            #flag=`/usr/libexec/PlistBuddy -c "Print apps:$index:flags" "$notificationsPLIST"`
            #echo Cat Value: $index:$bundleID $flag
            
            loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
            #echo "loggedInUser is $loggedInUser..."
        	# cleaning caches
        	sudo rm -rf /Library/Caches/*
        	sudo rm -rf /System/Library/Caches/*
        	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Caches/*

            rm -rf $(getconf DARWIN_USER_DIR)/com.apple.notificationcenter/db2/db
            #rm -rf db2
            #cd -
            
            sleep 1
            
            #sudo chown root:admin $notificationsPLIST
            #sudo chmod 000 $notificationsPLIST
            #ls -la $notificationsPLIST
            
            if [ $change == 1 ]; 
            then 
                echo "Changes made.  Restarting Notification Center for them to take effect."
                #launchctl load -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist
                #open /System/Library/CoreServices/NotificationCenter.app
                killall sighup usernoted
                killall sighup NotificationCenter
            fi
            sleep 10
            flag=`/usr/libexec/PlistBuddy -c "Print apps:$index:flags" "$notificationsPLIST"`
            echo Effective Value: $index:$bundleID $flag

    fi
done

#sudo sqlite3 $(getconf DARWIN_USER_DIR)/com.apple.notificationcenter/db2/db
#sudo sqlite3 $(getconf DARWIN_USER_DIR)/com.apple.notificationcenter/db2/db "UPDATE app SET flags='343' where app_id='8'"


exit 0