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
echo "loggedInUser is $loggedInUser..."
if [[ "$loggedInUser" == "" ]]
then
    WAIT_TIME=$((MAX_NUM*SLEEP_TIME))
    echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
    exit
else
    :
fi

# getting sum of number of reboots and shutdowns since installation
NUM1=$(last reboot | grep reboot | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
#echo $NUM1
NUM2=$(last shutdown | grep shutdown | wc -l | sed 's/ //g')
#echo $NUM2
NUM3=$((NUM1+NUM2))
#echo $NUM3

# cleaning function1
run_cleaning1 () {
	
	echo "running cleaning function 1..."
	
	# cleaning safari
	if [[ $(find /Users/"$loggedInUser"/Library/Safari -mindepth 1 -maxdepth 1 -name "History.db*") != "" ]]
	then
		sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/History.db*
	else
		:
	fi
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/LastSession.plist
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/Downloads.plist
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/KnownSitesUsingPlugIns.plist
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/Downloads.plist
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Safari/TopSites.plist
	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Safari/LocalStorage
	#find /Users/"$loggedInUser"/Library/Safari/LocalStorage/* -type f -not -name "*.nba.*" -print0 | xargs -0 rm -f
	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Safari/Databases
	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Safari/Favicon Cache"
	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Safari/Template Icons"
	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Safari/Touch Icons Cache"
	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Caches
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Cookies/com.apple.Safari.SearchHelper.binarycookies
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/com.apple.Safari.SearchHelper.binarycookies
	
	# cookies moved to run_cleaning2
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Cookies/HSTS.plist
	sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/HSTS.plist
	sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Preferences/Macromedia/Flash Player/"
	
	# cleaning firefox storage
	FIREFOX_PROFILE_PATH=$(find "/Users/""$loggedInUser""/Library/Application Support/Firefox/" -name "*.default*")
	FIREFOX_PREFERENCES="/Users/"$loggedInUser"/Library/Application Support/Firefox/"
	if [[ -e "$FIREFOX_PROFILE_PATH" ]]
	then 		
		cd "$FIREFOX_PROFILE_PATH"/storage
		ls -1 "$FIREFOX_PROFILE_PATH"/storage | \
		grep -v default | \
		xargs sudo -H -u "$loggedInUser" rm -rf
		cd - >/dev/null 2>&1
		
		cd "$FIREFOX_PROFILE_PATH"/storage/default
		ls -1 "$FIREFOX_PROFILE_PATH"/storage/default | \
		grep -v moz-extension+++ | \
		xargs sudo -H -u "$loggedInUser" rm -rf
		cd - >/dev/null 2>&1
	else
		:
	fi
	
	# cleaning progressive downloader
	PSD_INSTALLATION=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin / | grep -i "/Progressive Downloader.app$")
	if [[ "$PSD_INSTALLATION" != "" ]] && [[ -e "$PSD_INSTALLATION" ]]
	then
		sudo -H -u "$loggedInUser" rm -rf "/Users/"$loggedInUser"/Library/Application Support/Progressive Downloader Data"
		# has to be run as user (sudo -H -u "$loggedInUser") or permissions would change and file would no longer work
		if [[ -e /Users/"$loggedInUser"/Library/Preferences/com.PS.PSD.plist ]]
		then
			if [[ $(defaults read /Users/"$loggedInUser"/Library/Preferences/com.PS.PSD.plist | grep psDownloadedBytes) != "" ]]
			then
				#echo "deleting entry..."
				sudo -H -u "$loggedInUser" defaults delete /Users/"$loggedInUser"/Library/Preferences/com.PS.PSD.plist psDownloadedBytes
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
	# do not clean /System/Library/Caches/* as it leads to not opening third party system settings panes
	# can be solved by installing the latest combo update afterwards
	#rm -rf /System/Library/Caches/*
	rm -rf /Library/Caches/*
	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Caches/*
	
	# safari cookies
	#sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Cookies/Cookies.binarycookies
	#sudo -H -u "$loggedInUser" rm -f /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies
	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Cookies/
	sudo -H -u "$loggedInUser" rm -rf /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/*

	# restoring basic cookies
	# deprecated, use super agent browser extension instead
	restore_basic_cookies() {
		if [[ -e /Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies ]]
		then
			sudo -H -u "$loggedInUser" mkdir -p /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/
			sudo -H -u "$loggedInUser" cp -a /Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies
		else
			:
		fi
	}
	#restore_basic_cookies
	
	# cleaning dnscaches
	dns_caches () {
		dscacheutil -flushcache
		killall -HUP mDNSResponder
	}
	dns_caches

}

reset_safari_download_location () {

    sudo -H -u "$loggedInUser" defaults write com.apple.Safari AlwaysPromptForDownloadFolder -bool false
    if [[ -d "/Users/"$loggedInUser"/Desktop/files" ]]
    then
        #sudo -H -u "$loggedInUser" mkdir -p "/Users/"$loggedInUser"/Desktop/files"
        #mkdir -p "~/Desktop/files"
        sudo -H -u "$loggedInUser" defaults write com.apple.Safari DownloadsPath -string "/Users/"$loggedInUser"/Desktop/files"
        #defaults write com.apple.Safari DownloadsPath -string "~/Desktop/files"
    else
        sudo -H -u "$loggedInUser" defaults write com.apple.Safari DownloadsPath -string "/Users/"$loggedInUser"/Downloads"
    fi
    
    # testing
    #echo "$loggedInUser" > /Users/"$loggedInUser"/Desktop/login_script.txt
        
}

deactivate_hidden_login_items_workaround () {
# explanation see scripts 11c and 11k

	ACTIVE_LOGIN_ITEMS=(
	com.DigiDNA.iMazing2Mac.Mini.plist
	com.adobe.ARMDCHelper.\*.plist
	com.adobe.ARMDC.Communicator.plist
	com.adobe.ARMDC.SMJobBlessHelper.plist
	com.microsoft.teams.TeamsUpdaterDaemon.plist
	com.google.keystone.agent.plist
	com.google.keystone.xpcservice.plist
	com.google.keystone.daemon.plist
	org.xquartz.startx.plist
	com.teamviewer.Helper.plist
	com.teamviewer.UninstallerHelper.plist
	com.teamviewer.UninstallerWatcher.plist
	org.xquartz.privileged_startx.plist
	)
	ACTIVE_LOGIN_ITEMS_LIST=$(printf "%s\n" "${ACTIVE_LOGIN_ITEMS[@]}")

	LOGIN_ITEMS_DIRECTORIES=(
	/Library/LaunchAgents
	/Library/LaunchDaemons
	/Users/"$loggedInUser"/Library/LaunchAgents
	)
	LOGIN_ITEMS_DIRECTORIES_LIST=$(printf "%s\n" "${LOGIN_ITEMS_DIRECTORIES[@]}")
	
	while IFS= read -r line || [[ -n "$line" ]]
	do
		if [[ "$line" == "" ]]; then continue; fi
		local LOGIN_ITEM="$line"
		
			while IFS= read -r line || [[ -n "$line" ]]
			do
				if [[ "$line" == "" ]]; then continue; fi
				local LOGIN_ITEM_DIRECTORY="$line"
				
				LOGIN_ITEMS_PATH=
				if [[ $(ls -1 "$LOGIN_ITEM_DIRECTORY" | grep "$LOGIN_ITEM") != "" ]]
				then
					LOGIN_ITEM_COMPLETE_PATH="$LOGIN_ITEM_DIRECTORY"/$(ls -1 "$LOGIN_ITEM_DIRECTORY" | grep "$LOGIN_ITEM")
					#echo "$LOGIN_ITEM_COMPLETE_PATH"
					if [[ -e "$LOGIN_ITEM_COMPLETE_PATH" ]]
					then
						echo ""$LOGIN_ITEM_COMPLETE_PATH" exists, deleting..."
						rm -f "$LOGIN_ITEM_COMPLETE_PATH"
					else	
						:
					fi
				else
					:
				fi
			done <<< "$(printf "%s\n" "${LOGIN_ITEMS_DIRECTORIES_LIST[@]}")"
	done <<< "$(printf "%s\n" "${ACTIVE_LOGIN_ITEMS_LIST[@]}")"

}

DIVIDER=10
# every reboot is counted as shutdown, too
# using NUM3 would result in counting +2 on every boot
if (( NUM1 % $DIVIDER == 0 ))
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

deactivate_hidden_login_items_workaround
sleep 0.1

# last reboot | grep reboot | wc -l | sed 's/ //g'
# last shutdown | grep reboot | wc -l | sed 's/ //g'

