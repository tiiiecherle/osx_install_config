#!/bin/bash

if [ $(id -u) -ne 0 ]
then
    echo "script has to be run as root, exiting..."
    exit
else
    :
fi

# the script is run as root
# that`s why $USER will not work, use the current logged in user instead
# every command that does not have sudo -u $loggedInUser upfront has to be run as root, but sudo is not needed here

# getting logged in user
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
echo "loggedInUser is $loggedInUser..."
#echo "loggedInUser is $loggedInUser" > /Users/$loggedInUser/Desktop/loggedInUser.txt

# getting sum of number of reboots and shutdowns since installation
NUM1=$(last reboot | grep reboot | wc -l | sed 's/ //g')
#echo $NUM1
NUM2=$(last shutdown | grep shutdown | wc -l | sed 's/ //g')
#echo $NUM2
NUM3=$(($NUM1+$NUM2))
#echo $NUM3

# cleaning function1
run_cleaning1 () {
	
	echo "running cleaning function 1..."
	
	# cleaning safari
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/History.db*
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/LastSession.plist
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/Downloads.plist
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/KnownSitesUsingPlugIns.plist
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/Downloads.plist
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/TopSites.plist
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Safari/LocalStorage
	#find /Users/$loggedInUser/Library/Safari/LocalStorage/* -type f -not -name "*.nba.*" -print0 | xargs -0 rm -f
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Safari/Databases
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Favicon Cache"
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Template Icons"
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Touch Icons Cache"
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Containers/com.apple.Safari/Data/Library/Caches
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Cookies/com.apple.Safari.SearchHelper.binarycookies
	# cookies moved to run_cleaning2
	#sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Cookies/Cookies.binarycookies
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Cookies/HSTS.plist
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Preferences/Macromedia/Flash Player/"
	
	# cleaning firefox storage
	FIREFOX_PROFILE_PATH=$(find "/Users/""$loggedInUser""/Library/Application Support/Firefox/" -name "*.default*")
	FIREFOX_PREFERENCES="/Users/$loggedInUser/Library/Application Support/Firefox/"
	if [[ -e "$FIREFOX_PROFILE_PATH" ]]
	then 		
		cd "$FIREFOX_PROFILE_PATH"/storage
		ls -1 "$FIREFOX_PROFILE_PATH"/storage | \
		grep -v default | \
		xargs sudo -u $loggedInUser rm -rf
		cd - >/dev/null 2>&1
		
		cd "$FIREFOX_PROFILE_PATH"/storage/default
		ls -1 "$FIREFOX_PROFILE_PATH"/storage/default | \
		grep -v moz-extension+++ | \
		xargs sudo -u $loggedInUser rm -rf
		cd - >/dev/null 2>&1
	else
		:
	fi
	
	# cleaning progressive downloader
	PSD_INSTALLATION="/Applications/Progressive Downloader.app"
	if [[ -e "$PSD_INSTALLATION" ]]
	then
		sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Application Support/Progressive Downloader Data"
		# has to be run as user (sudo -u $loggedInUser) or permissions would change and file would no longer work
		if [[ -e /Users/$loggedInUser/Library/Preferences/com.PS.PSD.plist ]]
		then
			if [[ $(defaults read /Users/$loggedInUser/Library/Preferences/com.PS.PSD.plist | grep psDownloadedBytes) != "" ]]
			then
				#echo "deleting entry..."
				sudo -u $loggedInUser defaults delete /Users/$loggedInUser/Library/Preferences/com.PS.PSD.plist psDownloadedBytes
			else
				:
			fi
		else
			:
		fi
	else
		:
	fi

}

# cleaning function2
run_cleaning2 () {
	
	echo "running cleaning function 2..."
	
	# cleaning caches
	rm -rf /Library/Caches/*
	rm -rf /System/Library/Caches/*
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Caches/*
	
	# safari cookies
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Cookies/Cookies.binarycookies
	
	# cleaning dnscaches
	dns_caches () {
	dscacheutil -flushcache
	killall -HUP mDNSResponder
	}
	dns_caches

}

reset_safari_download_location () {

    sudo -u $loggedInUser defaults write com.apple.Safari AlwaysPromptForDownloadFolder -bool false
    if [[ "$loggedInUser" == "tom" ]]
    then
        #sudo -u $loggedInUser mkdir -p "/Users/$loggedInUser/Desktop/files"
        #mkdir -p "~/Desktop/files"
        sudo -u $loggedInUser defaults write com.apple.Safari DownloadsPath -string "/Users/$loggedInUser/Desktop/files"
        #defaults write com.apple.Safari DownloadsPath -string "~/Desktop/files"
    else
        sudo -u $loggedInUser defaults write com.apple.Safari DownloadsPath -string "/Users/$loggedInUser/Downloads"
    fi
    
    # testing
    #echo "$loggedInUser" > /Users/"$loggedInUser"/Desktop/login_script.txt
        
}


DIVIDER=10
# every reboot is counted as shutdown, too
# using NUM3 would result in counting +2 on every boot
if (( $NUM1 % $DIVIDER == 0 ))
then
    #echo "number $NUM1 divisible by $DIVIDER"
    run_cleaning1
    run_cleaning2
else
	#echo "number $NUM1 NOT divisible by $DIVIDER"
	run_cleaning1
fi

sleep 0.1

#reset_safari_download_location
#sleep 0.1

# last reboot | grep reboot | wc -l | sed 's/ //g'
# last shutdown | grep reboot | wc -l | sed 's/ //g'

