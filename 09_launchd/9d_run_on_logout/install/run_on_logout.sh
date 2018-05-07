#!/bin/bash

# the script is run as root
# that`s why $USER will not work, use $(logname) for the current logged in user instead
# every command that does not have sudo -u $(logname) upfront has to be run as root, but sudo is not needed here

run_on_logout () {
	
	# cleaning caches
	rm -rf /Library/Caches/* &
	rm -rf /System/Library/Caches/* &
	sudo -u $(logname) rm -rf /Users/$(logname)/Library/Caches/* &
	
	# cleaning dnscaches
	dns_caches () {
	dscacheutil -flushcache
	killall -HUP mDNSResponder
	}
	dns_caches &
	
	# cleaning safari
	sudo -u $(logname) rm -f /Users/$(logname)/Library/Safari/History.db* &
	sudo -u $(logname) rm -f /Users/$(logname)/Library/Safari/LastSession.plist &
	sudo -u $(logname) rm -f /Users/$(logname)/Library/Safari/Downloads.plist &
	sudo -u $(logname) rm -f /Users/$(logname)/Library/Safari/KnownSitesUsingPlugIns.plist &
	sudo -u $(logname) rm -f /Users/$(logname)/Library/Safari/Downloads.plist &
	sudo -u $(logname) rm -f /Users/$(logname)/Library/Safari/TopSites.plist &
	#sudo -u $(logname) rm -rf /Users/$(logname)/Library/Safari/LocalStorage
	find /Users/$(logname)/Library/Safari/LocalStorage/* -type f -not -name "*.nba.*" -print0 | xargs -0 rm -f &
	sudo -u $(logname) rm -rf /Users/$(logname)/Library/Safari/Databases &
	sudo -u $(logname) rm -rf "/Users/$(logname)/Library/Safari/Favicon Cache" &
	sudo -u $(logname) rm -rf "/Users/$(logname)/Library/Safari/Template Icons" &
	sudo -u $(logname) rm -rf "/Users/$(logname)/Library/Safari/Touch Icons Cache" &
	# rest is already deleted from /Users/$(logname)/Library/Caches/*
	
	# cleaning firefox storage
	FIREFOX_PROFILES="/Users/$(logname)/Library/Application Support/Firefox/Profiles"
	if [[ -e "$FIREFOX_PROFILES" ]]
	then 
		sudo -u $(logname) rm -rf "$FIREFOX_PROFILES"/*.default/storage/* &
	else
		:
	fi
	
	# cleaning progressive downloader
	PSD_INSTALLATION="/Applications/Progressive Downloader.app"
	if [[ -e "$PSD_INSTALLATION" ]]
	then
		sudo -u $(logname) rm -rf "/Users/$(logname)/Library/Application Support/Progressive Downloader Data" &
		# has to be run as user (sudo -u $(logname)) or permissions would change and file would no longer work
		sudo -u $(logname) defaults delete /Users/$(logname)/Library/Preferences/com.PS.PSD.plist psDownloadedBytes &
	else
		:
	fi

}

run_on_logout
wait