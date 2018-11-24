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
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/Downloads.plist &
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/KnownSitesUsingPlugIns.plist
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/Downloads.plist
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/TopSites.plist
	#sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Safari/LocalStorage
	find /Users/$loggedInUser/Library/Safari/LocalStorage/* -type f -not -name "*.nba.*" -print0 | xargs -0 rm -f
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Safari/Databases
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Favicon Cache"
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Template Icons"
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Touch Icons Cache"
	# rest is already deleted from /Users/$loggedInUser/Library/Caches/*
	
	# cleaning firefox storage
	FIREFOX_PROFILES="/Users/$loggedInUser/Library/Application Support/Firefox/Profiles"
	if [[ -e "$FIREFOX_PROFILES" ]]
	then 
		sudo -u $loggedInUser rm -rf "$FIREFOX_PROFILES"/*.default/storage/*
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
	
	# cleaning dnscaches
	dns_caches () {
	dscacheutil -flushcache
	killall -HUP mDNSResponder
	}
	dns_caches

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

# last reboot | grep reboot | wc -l | sed 's/ //g'
# last shutdown | grep reboot | wc -l | sed 's/ //g'

