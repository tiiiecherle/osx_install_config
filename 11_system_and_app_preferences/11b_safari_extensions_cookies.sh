#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### safari extensions
###

### opening safari
# on a clean install (without restoring some data or preferences, e.g. PerSitePreferences.db) Safari has to be opened at least one time before the files will be created
# opening wihtout loading a website does not trigger creating the files, so "run" is not enough, opening and loading a first website is needed
WEBSITE_SAFARI_DATABASE="/Users/"$USER"/Library/Safari/PerSitePreferences.db"
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]] || [[ ! -e "$WEBSITE_SAFARI_DATABASE" ]]
then
	echo ''
    echo "opening and quitting safari..."
    APP_NAME=Safari
    env_get_path_to_app
    open -a "$PATH_TO_APP" "https://google.com"
    osascript <<EOF
		try
    		tell application "Safari"
    			#run
    			delay 5
    			quit
    		end tell
    	end try
EOF
else
	:
fi


### extensions
# as apple changed the format of extensions for 10.14 and up it is no longer necessary to restore the "*.safariextz" files
# "/$HOMEFOLDER/Library/Safari/Extensions/Extensions.plist"
# "/$HOMEFOLDER/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.Extensions.plist"
# are restored by the restore script if they were present at backup

# allow better to start correctly
#echo ''
APP_NAME_FOR_PREFERENCES="Better"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	defaults write better.fyi.mac dontShowMigrationCancelMessageAgain -bool true
	defaults write better.fyi.mac IntroductionComplete -bool true
else
	:
	#echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi

# opening extensions
echo ''
echo "opening safari apps that include extensions..."
# should already be enabled by restoring ~/Library/Containers/com.apple.Safari/Data/Library/WebKit/ContentExtensions
applications_safari=(
Better
GhosteryLite
"AdGuard for Safari"
"Google Analytics Opt Out"
)

for i in "${applications_safari[@]}"
do
	APP_NAME="$i"
	env_get_path_to_app
	if [[ "$PATH_TO_APP" != "" ]]
	then
	    echo "opening $(basename "$PATH_TO_APP")"
		open "$PATH_TO_APP"
		sleep 5
		osascript -e "tell application \"$(basename "$PATH_TO_APP")\" to quit"
	else
		:
	fi
done


### extensions
echo "safari has to be quit before continuing..."
#if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
#then
	sleep 5
    osascript -e "tell application \"Safari\" to quit"
    sleep 1
    for i in "${applications_safari[@]}"
	do
		if [[ -e "$i" ]]
		then
			#BASENAME_APP=$(basename "$i")
		    #echo "opening "$BASENAME_APP""
		    #osascript -e "tell application \"$BASENAME_APP\" to quit"
			osascript -e "tell application \"$i\" to quit"
			sleep 1
		else
			:
		fi
	done
#else
#	:
#fi

while ps aux | grep 'Safari.app/Contents/MacOS/Safari$' | grep -v grep > /dev/null; do sleep 1; done


### restoring basic cookies
# deprecated, use super agent browser extension instead
restoring_basic_cookies() {
	APP_NAME=Safari
	env_get_path_to_app
	if [[ -e /Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies ]]
	then
		sleep 2
		echo ''
		echo "restoring basic cookies..."
		if [[ -e /Users/"$loggedInUser"/Library/Cookies ]]
		then
			#rm -f /Users/"$loggedInUser"/Library/Cookies/Cookies.binarycookies
			rm -rf /Users/"$loggedInUser"/Library/Cookies
		else
			:
		fi
		mkdir -p /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies
		cp -a /Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies /Users/"$loggedInUser"/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies
		if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
		then
			:
		else
			sleep 2
			open -a "$PATH_TO_APP" "https://myaccount.google.com/intro/privacycheckup?utm_source=pp&utm_medium=Promo-in-product&utm_campaign=pp_intro&hl=de"
			sleep 2
		fi
	else
		echo ''
		echo "/Users/"$loggedInUser"/Documents/backup/cookies/Cookies.binarycookies not found, skipping..."
	fi
}
#restoring_basic_cookies


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
echo ''
