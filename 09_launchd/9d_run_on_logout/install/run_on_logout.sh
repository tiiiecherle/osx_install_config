#!/bin/bash

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

run_on_logout_parallel () {
	
	# cleaning caches
	rm -rf /Library/Caches/* &
	rm -rf /System/Library/Caches/* &
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Caches/* &
	
	# cleaning dnscaches
	dns_caches () {
	dscacheutil -flushcache
	killall -HUP mDNSResponder
	}
	dns_caches &
	
	# cleaning safari
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/History.db* &
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/LastSession.plist &
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/Downloads.plist &
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/KnownSitesUsingPlugIns.plist &
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/Downloads.plist &
	sudo -u $loggedInUser rm -f /Users/$loggedInUser/Library/Safari/TopSites.plist &
	#sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Safari/LocalStorage
	find /Users/$loggedInUser/Library/Safari/LocalStorage/* -type f -not -name "*.nba.*" -print0 | xargs -0 rm -f &
	sudo -u $loggedInUser rm -rf /Users/$loggedInUser/Library/Safari/Databases &
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Favicon Cache" &
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Template Icons" &
	sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Safari/Touch Icons Cache" &
	# rest is already deleted from /Users/$loggedInUser/Library/Caches/*
	
	# cleaning firefox storage
	FIREFOX_PROFILES="/Users/$loggedInUser/Library/Application Support/Firefox/Profiles"
	if [[ -e "$FIREFOX_PROFILES" ]]
	then 
		sudo -u $loggedInUser rm -rf "$FIREFOX_PROFILES"/*.default/storage/* &
	else
		:
	fi
	
	# cleaning progressive downloader
	PSD_INSTALLATION="/Applications/Progressive Downloader.app"
	if [[ -e "$PSD_INSTALLATION" ]]
	then
		sudo -u $loggedInUser rm -rf "/Users/$loggedInUser/Library/Application Support/Progressive Downloader Data" &
		# has to be run as user (sudo -u $loggedInUser) or permissions would change and file would no longer work
		sudo -u $loggedInUser defaults delete /Users/$loggedInUser/Library/Preferences/com.PS.PSD.plist psDownloadedBytes &
	else
		:
	fi

}

run_on_logout () {
	
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
		sudo -u $loggedInUser defaults delete /Users/$loggedInUser/Library/Preferences/com.PS.PSD.plist psDownloadedBytes
	else
		:
	fi

}

run_on_logout_parallel
#run_on_logout
sleep 0.5

#TIME_OUT=0
#while [[ $TIME_OUT -lt 4 ]]
#do
#    sleep 1
#    TIME_OUT=$((TIME_OUT+1))
#done
# wait

# testing - does not help on hangs during shutdown
#pkill -u $loggedInUser
#sudo pkill -u root
#sudo kill -9 $(ps A | awk '{print $1}' | tail -n +2)

# do not use this here as it prevents reboots
# I haven`t found a way yet to check on shutdown if the shutdown cause is a reboot or real shutdown
# until then this stays disabled
# shutdown
#sudo shutdown -h now


