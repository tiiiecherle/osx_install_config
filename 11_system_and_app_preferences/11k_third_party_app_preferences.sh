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
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
        env_sudo
    else
        env_enter_sudo_password
    fi
else
    :
fi


###
### functions
###

# for macos 13 and newer running helper apps on login by using
# launchctl enable gui/"$(id -u "$USER")"/APP_IDENTIFIER
# does no longer work

# it seems an entry in the BackgroundItems file is needed
# readable output
#sfltool dumpbtm /private/var/db/com.apple.backgroundtaskmanagement/BackgroundItems-v8.btm
# delete all data from login-items
#sfltool resetbtm
#
# disabling
# bootout, disbale and remove with launchctl did not work as of 2023-09
#
# deleting and disabling
# to make an item disappear from the list, delete the corresponding files in
# /Library/LaunchAgents			system
# /Library/LaunchDaemons		system
# ~/Library/LaunchAgents		user
# will be reinstalled on every app update of the corresponding app
# workaround included in run_on_shutdown.sh script

# as a workaround a launchagent is working
create_user_launch_agent() {

	if [[ "$USER_LAUNCH_AGENT_NAME" != "" ]] && [[ "$USER_LAUNCH_AGENT_LOGIN_HELPER" != "" ]] && [[ -e "$USER_LAUNCH_AGENT_LOGIN_HELPER" ]]
	then
		cat > "/Users/"$USER"/Library/LaunchAgents/"$USER_LAUNCH_AGENT_NAME".plist" << EOF
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>Label</key>
			<string>$USER_LAUNCH_AGENT_NAME</string>
			<key>ProgramArguments</key>
			<array>
				<string>zsh</string>
				<string>-c</string>
				<string>"$USER_LAUNCH_AGENT_LOGIN_HELPER"</string>
			</array>
			<key>RunAtLoad</key>
			<true/>
		</dict>
		</plist>
EOF
	else
		echo ''
		echo "user launch agent "$USER_LAUNCH_AGENT_NAME" could not be created, skipping..." &>2
		echo ''
	fi
	
}
#USER_LAUNCH_AGENT_NAME="com.APPNAME_login_helper.custom"
#USER_LAUNCH_AGENT_LOGIN_HELPER="PATH_TO_LOGIN_HELPER_SCRIPT_NOT_TO_APP"
#create_user_launch_agent



###
### setting some non apple third party app preferences
###


### totalfinder
totalfinder_settings() {
	echo ''
	APP_NAME_FOR_PREFERENCES="TotalFinder"
	if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
	then
	
		echo "$APP_NAME_FOR_PREFERENCES"
		
		# do not restore windows and tabs after reboot (does not exist in version 1.7.3 and above)
		#defaults write com.apple.finder TotalFinderDontRestoreTabsState -bool yes
		
		# keep original finder icon in dock
		defaults write com.binaryage.totalfinder TotalFinderDontCustomizeDockIcon -bool true
		
		# allow copy of paths in context menu
		#defaults write com.binaryage.totalfinder TotalFinderCopyPathMenuEnabled -bool true
		
		# disable totalfinder tabs
		defaults write com.binaryage.totalfinder TotalFinderTabsDisabled -bool true
		
		# display totalfinder icon in menu bar
		#defaults write com.binaryage.totalfinder TotalFinderShowStatusItem -bool false
		
	else
		echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
	fi
}
# moved to install script
#totalfinder_settings


### xtrafinder

xtrafinder_settings() {
	echo ''
	APP_NAME_FOR_PREFERENCES="XtraFinder"
	if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
	then
		
		echo "$APP_NAME_FOR_PREFERENCES"
		
		# automatically check for updates
		defaults write com.apple.finder XFAutomaticChecksForUpdate -bool true
		
		# enable copy / cut - paste
		defaults write com.apple.finder XtraFinder_XFCutAndPastePlugin -bool true
		
		# disable xtrafinder tabs
		defaults write com.apple.finder XtraFinder_XFTabPlugin -bool false
		
		# # disable xtrafinder menu bar icon
		#defaults write com.apple.finder XtraFinder_ShowStatusBarIcon -bool false
		
		
		### right click finder plugins
		
		# show copy path
		#defaults write com.apple.finder XtraFinder_XFCopyPathMenuPlugin -bool true
		
		# path type options
		# 0 = path, 3 = hfs path, 4 = terminal path
		defaults write com.apple.finder XtraFinder_XFCopyPathMenuPlugin_Default -integer 0
		
		# show make symbolic link
		defaults write com.apple.finder XtraFinder_XFMakeSymbolicLinkActionPlugin -bool false
		
		# show open in new window
		defaults write com.apple.finder XtraFinder_XFOpenInNewWindowPlugin -bool true
	
	else
		echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
	fi
}
# moved to install script
#xtrafinder_settings


### iterm 2
echo ''                                                   
APP_NAME_FOR_PREFERENCES="iTerm"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"

    # make terminal font sf mono available in other apps
    cp -a "$PATH_TO_SYSTEM_APPS"/Utilities/Terminal.app/Contents/Resources/Fonts/* /Users/"$USER"/Library/Fonts/
    
    # set it in iterm2
    /usr/libexec/PlistBuddy ~/Library/Preferences/com.googlecode.iterm2.plist -c 'Set "New Bookmarks":1:"Normal Font" "SFMono-Regular 11"'
    /usr/libexec/PlistBuddy ~/Library/Preferences/com.googlecode.iterm2.plist -c 'Set "New Bookmarks":1:"Horizontal Spacing" 1'
    /usr/libexec/PlistBuddy ~/Library/Preferences/com.googlecode.iterm2.plist -c 'Set "New Bookmarks":1:"Vertical Spacing" 1'
    
    # paste of a lot of commands does only work in iterm2 when editing / lowering default paste speed
    defaults write com.googlecode.iterm2 QuickPasteBytesPerCall -int 83
    defaults write com.googlecode.iterm2 QuickPasteDelayBetweenCalls -float 0.08065756
    # lower values in steps to try if working by clicking edit - paste special - paste slower
    # check values in preferences advanced - search for paste 
    # defaults read com.googlecode.iterm2 | grep Quick
    # defaults
    # number of bytes to paste in each chunk when pasting normally		 667
    # dealy in seconds between chunks when pasting normally			     0.01530456

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### appcleaner
echo ''
APP_NAME_FOR_PREFERENCES="AppCleaner"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
	defaults write net.freemacsoft.AppCleaner SUEnableAutomaticChecks -bool true
	defaults write net.freemacsoft.AppCleaner SUSendProfileInfo -bool false
	
	# smartdelete is activated by adding the smartdelete app to autostart apps
	# see autostart in script 11c_macos_preferences_"$MACOS_VERSION_MAJOR".sh

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### istat menus
echo ''
APP_NAME_FOR_PREFERENCES="iStat Menus"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
	
	# if kill was used to stop the service kickstart is needed to restart it, bootstrap will not work
	
	if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app/Contents/Resources/InstallerBundle.bundle/Contents/Resources/com.bjango.istatmenus.agent.plist" ]]
	then
		cp ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app/Contents/Resources/InstallerBundle.bundle/Contents/Resources/com.bjango.istatmenus.agent.plist" "/Users/"$USER"/Library/LaunchAgents/com.bjango.istatmenus.agent.plist"
	else
		echo "com.bjango.istatmenus.agent.plist not found..." &>2
	fi
	launchctl bootout gui/"$(id -u "$USER")"/com.bjango.istatmenus.agent 2>&1 | grep -v "in progress" | grep -v "No such process"
	#launchctl kill 15 gui/"$(id -u "$USER")"/com.bjango.istatmenus.agent
	sleep 3
	launchctl enable gui/"$(id -u "$USER")"/com.bjango.istatmenus.agent
	launchctl bootstrap gui/"$(id -u "$USER")" "/Users/"$USER"/Library/LaunchAgents/com.bjango.istatmenus.agent.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	sleep 3
	
	if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app/Contents/Resources/InstallerBundle.bundle/Contents/Resources/com.bjango.istatmenus.status.plist" ]]
	then
		cp ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app/Contents/Resources/InstallerBundle.bundle/Contents/Resources/com.bjango.istatmenus.status.plist" "/Users/"$USER"/Library/LaunchAgents/com.bjango.istatmenus.status.plist"
	else
		echo "com.bjango.istatmenus.status.plist not found..." &>2
	fi
	launchctl bootout gui/"$(id -u "$USER")"/com.bjango.istatmenus.status 2>&1 | grep -v "in progress" | grep -v "No such process"
	#launchctl kill 15 gui/"$(id -u "$USER")"/com.bjango.istatmenus.status
	sleep 3
	launchctl enable gui/"$(id -u "$USER")"/com.bjango.istatmenus.status
	launchctl bootstrap gui/"$(id -u "$USER")" "/Users/"$USER"/Library/LaunchAgents/com.bjango.istatmenus.status.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	sleep 3
	
	#launchctl print-disabled system
	#launchctl print system | grep com.bjango.
	sudo launchctl bootout system "/Library/LaunchDaemons/com.bjango.istatmenus.fans.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	#sudo launchctl kill 15 system/com.bjango.istatmenus.fans
	sleep 3
	sudo launchctl enable system/com.bjango.istatmenus.fans
	sudo launchctl bootstrap system "/Library/LaunchDaemons/com.bjango.istatmenus.fans.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	sleep 3
	
	sudo launchctl bootout system "/Library/LaunchDaemons/com.bjango.istatmenus.daemon.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	#sudo launchctl kill 15 system/com.bjango.istatmenus.daemon
	sleep 3
	sudo launchctl enable system/com.bjango.istatmenus.daemon
	sudo launchctl bootstrap system "/Library/LaunchDaemons/com.bjango.istatmenus.daemon.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	sleep 3
	
	#sudo launchctl bootout system "/Library/LaunchDaemons/com.bjango.istatmenus.installerhelper.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	#sudo launchctl kill 15 system/com.bjango.istatmenus.installerhelper
	#sleep 3
	#sudo launchctl enable system com.bjango.istatmenus.installerhelper
	#sudo launchctl bootstrap system "/Library/LaunchDaemons/com.bjango.istatmenus.installerhelper.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	#sleep 3
	
	# permissions are set from restore script

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### bresink software updater
echo ''
APP_NAME_FOR_PREFERENCES="BresinkSoftwareUpdater"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
	
	#launchctl print system | grep Bresink
	
	sudo launchctl bootout system "/Library/LaunchDaemons/BresinkSoftwareUpdater-PrivilegedTool.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	#sudo launchctl kill 15 system/BresinkSoftwareUpdater-PrivilegedTool
	sleep 3
	sudo launchctl enable system/BresinkSoftwareUpdater-PrivilegedTool
	sudo launchctl bootstrap system "/Library/LaunchDaemons/BresinkSoftwareUpdater-PrivilegedTool.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	sleep 3
	
	# permissions are set from restore script

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### the unarchiver
echo ''
APP_NAME_FOR_PREFERENCES="The Unarchiver"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
	defaults write com.macpaw.site.theunarchiver userAgreedToNewTOSAndPrivacy -bool true
	defaults write com.macpaw.site.theunarchiver SUEnableAutomaticChecks -bool true
	defaults write com.macpaw.site.theunarchiver openExtractedFolder -bool true
	
else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### virus scanner plus
echo ''
APP_NAME_FOR_PREFERENCES="VirusScannerPlus"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
    #launchctl kickstart -k gui/"$(id -u "$USER")"/com.bitdefender.VirusScannerHelper
    #sleep 3
  	#launchctl enable gui/"$(id -u "$USER")"/com.bitdefender.VirusScannerHelper
  	#sleep 3
  	
  	USER_LAUNCH_AGENT_NAME="com.bitdefender_virusscanner_login_helper.custom"
	USER_LAUNCH_AGENT_LOGIN_HELPER="/Applications/VirusScannerPlus.app/Contents/Library/LoginItems/VirusScannerHelper.app/Contents/MacOS/VirusScannerHelper"
	create_user_launch_agent
  	
	defaults write com.bitdefender.virusscannerplus continuous_run -bool true
	defaults write com.bitdefender.virusscannerplus upd_automatic -bool true
	defaults write com.bitdefender.virusscannerplus oas_scan -bool true
	defaults write com.bitdefender.virusscannerplus shouldShowTerms -bool false
	defaults write com.bitdefender.virusscannerplus termsOfUse -bool true
	defaults write com.bitdefender.virusscannerplus isForeground -bool false
	
else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### adguard for safari
echo ''
APP_NAME_FOR_PREFERENCES="AdGuard for Safari"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
    #launchctl print gui/$(id -u)
    #launchctl print-disabled "user/$(id -u)"
    #launchctl list | grep -i adguard
	#launchctl enable gui/"$(id -u "$USER")"/com.adguard.safari.AdGuard.login-helper
	#launchctl enable user/"$(id -u "$USER")"/com.adguard.safari.AdGuard.login-helper
	#launchctl start gui/"$(id -u "$USER")"/com.adguard.safari.AdGuard.login-helper
	#launchctl kickstart -k gui/"$(id -u "$USER")"/com.adguard.safari.AdGuard.login-helper
	
	# defaults read /private/var/db/com.apple.xpc.launchd/loginitems.501.plist
	# open /private/var/db/com.apple.xpc.launchd/loginitems.501.plist
	#/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump
	
	#launchctl remove gui/"$(id -u "$USER")"/com.adguard.safari.AdGuard.login-helper
	#launchctl remove gui/"$(id -u "$USER")"/com.adguard.safari.AdGuard
	
	#sleep 3
	
	USER_LAUNCH_AGENT_NAME="com.adguard_login_helper.custom"
	USER_LAUNCH_AGENT_LOGIN_HELPER="/Applications/AdGuard for Safari.app/Contents/Library/LoginItems/AdGuard Login Helper.app/Contents/MacOS/AdGuard Login Helper"
	create_user_launch_agent

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### wireguard
echo ''
APP_NAME_FOR_PREFERENCES="WireGuard"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
	launchctl enable gui/"$(id -u "$USER")"/com.wireguard.macos.login-item-helper
	sleep 3

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### bettertouchtool
echo ''
APP_NAME_FOR_PREFERENCES="BetterTouchTool"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
	defaults write com.hegenberg.BetterTouchTool launchOnStartup -bool true

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### bartender
echo ''
APP_NAME_FOR_PREFERENCES="Bartender 5"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
    #launchctl enable user/"$(id -u "$USER")"/com.surteesstudios.BartenderStartAtLoginHelper
	#launchctl enable gui/"$(id -u "$USER")"/com.surteesstudios.BartenderStartAtLoginHelper
	#sleep 3
	
	USER_LAUNCH_AGENT_NAME="com.bartender_login_helper.custom"
	USER_LAUNCH_AGENT_LOGIN_HELPER="/Applications/"$APP_NAME_FOR_PREFERENCES".app/Contents/Library/LoginItems/BartenderStartAtLoginHelper.app/Contents/MacOS/BartenderStartAtLoginHelper"
	create_user_launch_agent

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### textmate
echo ''
APP_NAME_FOR_PREFERENCES="TextMate"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
	# removing quicklook syntax highlight
	if [[ -e "$PATH_TO_APPS"/TextMate.app/Contents/Library/QuickLook/TextMateQL.qlgenerator ]]
	then
		rm -rf "$PATH_TO_APPS"/TextMate.app/Contents/Library/QuickLook/TextMateQL.qlgenerator
	else
		:
	fi
	# reset quicklook and quicklook cache if neccessary
	#qlmanage -r
	#qlmanage -r cache

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### pvguard
echo ''
APP_NAME_FOR_PREFERENCES="PVGuard"
APP_NAME="$APP_NAME_FOR_PREFERENCES"
if [[ -e "/Users/"$USER"/PVGuardClient/installer/pvdownload.jnlp" ]] && [[ -e "/Applications/OpenWebStart/OpenWebStart javaws.app" ]]
then

	echo "$APP_NAME_FOR_PREFERENCES"
	if [[ -L /Users/"$USER"/Desktop/"$APP_NAME".app ]]; then rm -f /Users/"$USER"/Desktop/"$APP_NAME".app; else :; fi
	if [[ -L "$PATH_TO_APPS"/"$APP_NAME".app ]]; then rm -f "$PATH_TO_APPS"/"$APP_NAME".app; else :; fi

	# installation
	env_get_path_to_app
	if [[ "$PATH_TO_APP" == "" ]]
	then
		if [[ -e /Users/"$USER"/.cache/icedtea-web ]]
		then
			rm -rf /Users/"$USER"/.cache/icedtea-web
		else
			:
		fi
		open -a "/Applications/OpenWebStart/OpenWebStart javaws.app/Contents/MacOS/JavaApplicationStub" "/Users/"$USER"/PVGuardClient/installer/pvdownload.jnlp"
		waiting_for_bundle() {
			WAITING_TIME=180
			NUM1=0
			#echo ''
			echo ''
			while [[ "$NUM1" -le "$WAITING_TIME" ]]
			do 
				NUM1=$((NUM1+1))
				if [[ "$NUM1" -le "$WAITING_TIME" ]]
				then
					#echo "$NUM1"
					sleep 1
					tput cuu 1 && tput el
					echo "waiting $((WAITING_TIME-NUM1)) seconds for downloading and building "$APP_NAME" bundle..."
				else
					:
				fi
			done
		}
		waiting_for_bundle
		#WAIT_PIDS=()
	    #WAIT_PIDS+=$(ps aux | grep /pvdownload.jnlp | grep -v grep | awk '{print $2;}')
	    #while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"  
	else
		echo ""$APP_NAME" already installed..." >&2
	fi
	
	if [[ -e "/Users/"$USER"/.cache/applications/"$APP_NAME".app" ]] && [[ -e "/Users/"$USER"/Applications/"$APP_NAME".app" ]]
	then
		rm -rf "/Users/"$USER"/.cache/applications/"$APP_NAME".app"
	else
		:
	fi
	
	# symlinks
	echo "$PATH_TO_APP"
	APP_NAME="$APP_NAME_FOR_PREFERENCES"
	env_get_path_to_app
	if [[ -e "$PATH_TO_APP" ]] && [[ "$PATH_TO_APP" != "" ]]
	then
	    
	    if [[ -L /Users/"$USER"/Desktop/"$APP_NAME".app ]]; then rm -f /Users/"$USER"/Desktop/"$APP_NAME".app; else :; fi
	    if [[ "$CHECK_FOR_PVGUARD" == "yes" ]]
		then
	    	# symlink to desktop
	    	ln -s "$PATH_TO_APP" /Users/"$USER"/Desktop/"$APP_NAME".app
	    else
			:
		fi
	    
	   	# symlink to applications
	    ln -s "$PATH_TO_APP" "$PATH_TO_APPS"/"$APP_NAME".app
	    
	else
		echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
	fi
	
	# quit app
	pkill -15 java
	
	# notifications
	APPLICATIONS_TO_SET_NOTIFICATIONS=(
	"PVGuard																41943375"
	)
	SET_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications
	CHECK_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications

else
	:
fi


### GPGMail 2

# disable signing emails by default
#defaults write ~/Library/Preferences/org.gpgtools.gpgmail SignNewEmailsByDefault -bool false


### office
echo ''
if [[ $(find ""$PATH_TO_APPS"/" -mindepth 1 -maxdepth 1 -name "Microsoft *.app") != "" ]]
then
    
    echo "office"
    
	# uninstall/reinstall (testing only)
	#cp -a ""$PATH_TO_APPS"/Microsoft Excel.app" "/Users/"$USER"/Desktop/Microsoft Excel.app"
	#brew uninstall --cask --zap --force microsoft-office
	#cp -a "/Users/"$USER"/Desktop/Microsoft Excel.app" ""$PATH_TO_APPS"/Microsoft Excel.app"
	#rm -rf ""$PATH_TO_APPS"/Microsoft Excel.app"
	
	# cleaning old preferences
	rm -f "/Users/"$USER"/Library/Preferences/com.microsoft.office.plist"
	
	# restoring preferences (testing only)
	#cp -a "/Users/"$USER"/Desktop/UBF8T346G9.Office" "/Users/"$USER"/Library/Group Containers/"
	
	# keeping settings and license
	# privacy experience settings have to be set inside of excel or word to write them to the MicrosoftRegistrationDB and can then be preserved or restored
	#if [[ -e "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB" ]]
	#then
	#	# MicrosoftRegistrationDB contains settings
	#	# com.microsoft.Office365.plist contains license
	#	mv "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB" /tmp/MicrosoftRegistrationDB
	#	mv "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365.plist" /tmp/com.microsoft.Office365.plist
	#	mv "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.plist" /tmp/com.microsoft.Office365V2.plist
	#	rm -rf /Users/"$USER"/Library/"Group Containers"/UBF8T346G9.Office/*
	#	mv /tmp/MicrosoftRegistrationDB "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/"
	#	mv /tmp/com.microsoft.Office365.plist "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/"
	#	mv /tmp/com.microsoft.Office365V2.plist "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/"
	#else
	#	:
	#fi
	#killall cfprefsd

    #sleep 5
    # https://github.com/erikberglund/ProfileManifests/blob/master/Resources/ManifestsGenerated/Microsoft/Archive/Office%202016%20for%20Mac%20Preference%20Keys%20-%20Prefs-2018-09-19.csv

    # user name and initials
    defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/MeContact.plist" Name "`finger $USER | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`"
    defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/MeContact.plist" Initials "`finger $USER | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //' | cut -c1-1`"
    #defaults read "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/MeContact.plist"
    
    # set default save location to local
    defaults write ~/Library/Preferences/com.microsoft.office.plist DefaultsToLocalOpenSave -bool false
    # set theme
    # 1 = light
    # 2 = dark
    defaults write ~/Library/Preferences/com.microsoft.office.plist kCUIThemePreferencesThemeKeyPath -integer 1
    # do not show documents popup on launch
    defaults write ~/Library/Preferences/com.microsoft.office.plist ShowDocStageOnLaunch -bool false
    # privacy experience
    # privacy experience settings have to be set inside of excel or word to write them to the MicrosoftRegistrationDB and can then be preserved or restored
    # just changing them here will not have any effect
    defaults write ~/Library/Preferences/com.microsoft.office.plist OptionalConnectedExperiencesPreference -bool false
    defaults write ~/Library/Preferences/com.microsoft.office.plist ConnectedOfficeExperiencesPreference -bool false
    defaults write ~/Library/Preferences/com.microsoft.office.plist OfficeExperiencesAnalyzingContentPreference -bool false
    defaults write ~/Library/Preferences/com.microsoft.office.plist OfficeExperiencesDownloadingContentPreference -bool false
	# telemetry
    defaults write ~/Library/Preferences/com.microsoft.office.plist SendAllTelemetryEnabled -bool false
    # logging
    defaults write ~/Library/Preferences/com.microsoft.office.plist CustomerLoggingEnabled -bool false
    # diagnostics
    defaults write ~/Library/Preferences/com.microsoft.office.plist DiagnosticDataTypePreference -string "ZeroDiagnosticData"
	# terms
    defaults write ~/Library/Preferences/com.microsoft.office.plist TermsAccepted1809 -bool true
    # activation/license
	SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
	if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/office_license.sh ]]
	then
		"$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/office_license.sh  
	    #defaults write ~/Library/Preferences/com.microsoft.office.plist OfficeActivationEmailAddress -string "YOUR_REGISTRATION_EMAIL"
	else
	    echo ''
	    echo "script for setting OfficeActivationEmailAddress not found, skipping..."
	    echo ''
	fi
	# re-linking MicrosoftRegistrationDB.reg
    if [[ -e "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg" ]] || [[ -L "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg" ]]
    then
    	rm -f "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg"
    	sleep 0.5
    else
    	:
    fi
    if [[ -e "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB" ]]
    then
    	OFFICE_REG_FILE=$(find "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB" -name "*.reg" | head -n 1)
    	ln -s "$OFFICE_REG_FILE" "/Users/"$USER"/Library/Group Containers/UBF8T346G9.Office/MicrosoftRegistrationDB.reg"
    else
    	:
   	fi
        
    # merged old preferences
    #defaults write ~/Library/Preferences/com.microsoft.office.plist HaveMergedOldPrefs -bool true
    
    # autoupdate
    #defaults write ~/Library/Preferences/com.microsoft.autoupdate2.plist SendAllTelemetryEnabled -bool false
    #defaults write ~/Library/Preferences/com.microsoft.autoupdate2.plist SendCrashReportsEvenWithTelemetryDisabled -bool false
    #defaults write ~/Library/Preferences/com.microsoft.autoupdate.fba.plist SendAllTelemetryEnabled -bool false
    #defaults write ~/Library/Preferences/com.microsoft.autoupdate.fba.plist SendCrashReportsEvenWithTelemetryDisabled -bool false

    #osascript -e "tell application \"$APP_TEST\" to quit"
    
    # app specific settings
    for OFFICE_APP in Word Excel onenote.mac Outlook Powerpoint
    do 
        # do not send telemetry data and crash reports
        defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist SendAllTelemetryEnabled -bool false
        defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist SendCrashReportsEvenWithTelemetryDisabled -bool false
        # show ribbons
        defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist kOUIRibbonDefaultCollapse -bool false
        # skip first run popups
        defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist kSubUIAppCompletedFirstRunSetup1507 -bool true
    done
    
else
	echo "no microsoft office apps found, skipping setting preferences..." >&2
fi


### libreoffice
echo ''
APP_NAME_FOR_PREFERENCES="LibreOffice"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"

    LIBREOFFICE_CONFIG="/Users/$USER/Library/Application Support/LibreOffice/4/user/registrymodifications.xcu"
    
    # deleting possible old entries and end of file
    sed -i '' '/RecentDocsThumbnail/d' "$LIBREOFFICE_CONFIG"
    sed -i '' '/PickListSize/d' "$LIBREOFFICE_CONFIG"
    sed -i '' '/\<\/oor:items\>/d' "$LIBREOFFICE_CONFIG"
    
    # adding new entries and end of file
    # do not show thumbnails of recent documents in start screen
    echo '<item oor:path="/org.openoffice.Office.Common/History"><prop oor:name="RecentDocsThumbnail" oor:op="fuse"><value>false</value></prop></item>' >> "$LIBREOFFICE_CONFIG"
    # do not show any recent documents in start screen
    echo '<item oor:path="/org.openoffice.Office.Common/History"><prop oor:name="PickListSize" oor:op="fuse"><value>0</value></prop></item>' >> "$LIBREOFFICE_CONFIG"
    # adding end of config file
    echo '</oor:items>' >> "$LIBREOFFICE_CONFIG"
    
    # if checking content of config file after starting the app entries will be sorted alphabetically, not in the last lines
    
    # to set these preferences manually
    # open "$PATH_TO_APPS"/LibreOffice.app
    # preferences - libreoffice - advanced - expert - search for settings name, e.g. RecentDocsThumbnail or PickListSize
    # set and apply

else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


avast_settings() {
	### avast
	echo ''
	APP_NAME_FOR_PREFERENCES="Avast"
	if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
	then
		
		echo "$APP_NAME_FOR_PREFERENCES"
	
	    #echo "setting preferences..."
	    AVAST_DAEMON_CONFIG='/Library/Application Support/Avast/config/com.avast.daemon.conf'
	    if [[ $(cat "$AVAST_DAEMON_CONFIG" | grep "^STATISTICS*") == "" ]]
	    then
	        sudo "$SCRIPT_INTERPRETER" -c "echo '' >> '$AVAST_DAEMON_CONFIG'"
	        sudo "$SCRIPT_INTERPRETER" -c "echo 'STATISTICS = 0' >> '$AVAST_DAEMON_CONFIG'"
	    else
	        :
	    fi
	    if [[ $(cat "$AVAST_DAEMON_CONFIG" | grep "^HEURISTICS*") == "" ]]
	    then
	        #sudo "$SCRIPT_INTERPRETER" -c "echo '' >> '$AVAST_DAEMON_CONFIG'"
	        sudo "$SCRIPT_INTERPRETER" -c "echo 'HEURISTICS = 0' >> '$AVAST_DAEMON_CONFIG'"
	    else
	        :
	    fi
	    
	    # files
	    AVAST_FILESHIELD_CONFIG='/Library/Application Support/Avast/config/com.avast.fileshield.conf'
	    sudo "$SCRIPT_INTERPRETER" -c "cat > '$AVAST_FILESHIELD_CONFIG' << 'EOF'
{
    \"fileshield\" : 
    {
        \"enabled\" : true,
        \"chest\" : true,
        \"scanPup\" : true
    }
}
	
EOF
"
	
	    # mail and web
	    AVAST_PROXY_CONFIG='/Library/Application Support/Avast/config/com.avast.proxy.conf'
	    sudo "$SCRIPT_INTERPRETER" -c "cat > '$AVAST_PROXY_CONFIG' << 'EOF'
{
    \"general\" : 
    {
        \"fsEnabled\" : true
    },
    \"mailshield\" : 
    {
        \"enabled\" : true,
        \"markMailHeaders\" : false,
        \"removeInfectedParts\" : true,
        \"scanIpv6\" : false,
        \"scanPup\" : true,
        \"scanSsl\" : true
    },
    \"webshield\" : 
    {
        \"enabled\" : true,
        \"enabledDownloadScan\" : true,
        \"scanIpv6\" : false,
        \"scanSsl\" : false
    }
}
EOF
"
	
	    # notification durations
	    AVAST_HELPER_CONFIG='/Users/'$USER'/Library/Preferences/com.avast.helper.plist'  
	    defaults write "$AVAST_HELPER_CONFIG" InfoPopupDuration -int 5
	    defaults write "$AVAST_HELPER_CONFIG" UpdatePopupDuration -int 5
	
	    echo "restarting avast services to make the changes take effect..."
	    AVAST_BACKEND=""$PATH_TO_APPS"/Avast.app/Contents/Backend/hub"
	    if [[ -e "$AVAST_BACKEND" ]]
	    then
	        echo "stopping avast services..."
	        sh "$AVAST_BACKEND"/usermodules/010_helper.sh stop >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/010_daemon.sh stop >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/014_fileshield.sh stop >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/020_service.sh stop >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/030_proxy.sh stop >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/060_wifiguard.sh stop >/dev/null 2>&1
	        sleep 1
	        echo "starting avast services..."
	        sh "$AVAST_BACKEND"/usermodules/010_helper.sh start >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/010_daemon.sh start >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/014_fileshield.sh start >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/020_service.sh start >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/030_proxy.sh start >/dev/null 2>&1
	        sudo sh "$AVAST_BACKEND"/modules/060_wifiguard.sh start >/dev/null 2>&1
	    else
	        echo "avast services not found, skipping..."
	    fi
	
	else
		echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
	fi
}
#avast_settings


### eaglefiler
echo ''
APP_NAME_FOR_PREFERENCES="EagleFiler"
if [[ -e ""$PATH_TO_APPS"/"$APP_NAME_FOR_PREFERENCES".app" ]]
then
	
	echo "$APP_NAME_FOR_PREFERENCES"
    
    # index based on the modification date rather than when the file was written to disk
    # this avoids re-indexing when restoring/unpacking from an archive
    # should already be set in the preferences file in backup/restore
	defaults write com.c-command.EagleFiler IndexingUsesAttributeModificationDate -string "NO"
	
	# revert to default (re-index by date when the file was written to disk)
	# leads to re-indexing after unarchiving from backup
	#defaults write com.c-command.EagleFiler IndexingUsesAttributeModificationDate -string "YES"
	# or
	#defaults delete com.c-command.EagleFiler IndexingUsesAttributeModificationDate
	
else
	echo ""$APP_NAME_FOR_PREFERENCES" not found, skipping setting preferences..." >&2
fi


### virtualbox
echo ''
APP_NAME_FOR_PREFERENCES="VirtualBox"
# running macOS 11 with sip (partitally) disabled the following issue occurs
# vbox 6.1.16 and testing versions 6.1.17.x

# sudo kextload -b org.virtualbox.kext.VBoxDrv
#Filesystem error: Invalid directory for executable kext bundle org.virtualbox.kext.VBoxDrv at /Library/Application Support/VirtualBox/VBoxDrv.kext. Should appear in one of:
#	/System/Library/Extensions
#	/Library/Apple/System/Library/Extensions
#	/Library/Extensions
#	/AppleInternal/Library/Extensions
#	/System/AppleInternal/Library/AuxiliaryExtensions
#	/System/AppleInternal/Diagnostics/AuxiliaryExtensions
#	/System/Library/AuxiliaryExtensions
#	/Library/StagedExtensions
#	/private/var/db/KernelExtensionManagement/Staging
#Executing: /usr/bin/kmutil load -b org.virtualbox.kext.VBoxNetFlt
#Validating extension failed: KernelExtension org.virtualbox.kext.VBoxNetFlt v6.1.16 in executable kext bundle org.virtualbox.kext.VBoxNetFlt at /Library/Application Support/VirtualBox/VBoxNetFlt.kext:

# all directories starting with /System do not work with my sip settings
# works
VBOX_KEXT_DESTINATION=/Library/Apple/System/Library/Extensions
# testing
# partially working (VBoxDrv works, rest doesn`t)
#DESTINATION=/Library/Extensions
# symlinks do not work

# vbox_workaround
vbox_workaround() {

	echo "$APP_NAME_FOR_PREFERENCES"

	sudo cp -a "/Library/Application Support/VirtualBox/VBoxDrv.kext" "$VBOX_KEXT_DESTINATION"/VBoxDrv.kext
	sudo cp -a "/Library/Application Support/VirtualBox/VBoxNetFlt.kext" "$VBOX_KEXT_DESTINATION"/VBoxNetFlt.kext
	sudo cp -a "/Library/Application Support/VirtualBox/VBoxNetAdp.kext" "$VBOX_KEXT_DESTINATION"/VBoxNetAdp.kext
	sudo cp -a "/Library/Application Support/VirtualBox/VBoxUSB.kext" "$VBOX_KEXT_DESTINATION"/VBoxUSB.kext
	
	sudo kextload -b org.virtualbox.kext.VBoxDrv
	sudo kextload -b org.virtualbox.kext.VBoxNetFlt
	sudo kextload -b org.virtualbox.kext.VBoxNetAdp
	sudo kextload -b org.virtualbox.kext.VBoxUSB
	
	# open System Settings - Privacy - General
	# accept extensions
	# allowing kext extensions via mobileconfig profile does not work locally, has to be deployed by a trusted mdm server
	osascript <<EOF	
	tell application "System Settings"
		reopen
		delay 3
		#activate
		#delay 2
	end tell
	
	# do not use visible as it makes the window un-clickable
	#tell application "System Events" to tell process "System Settings" to set visible to true
	#delay 1
	tell application "System Events" to tell process "System Settings" to set frontmost to true
	delay 1
EOF

	osascript <<EOF
	tell application "System Events"
		tell process "System Settings"
			#set paneids to (get the id of every pane)
			#display dialog paneids
			#return paneids
			#set current pane to pane "com.apple.preference.security"
			#get the name of every anchor of pane id "com.apple.preference.security"
			#set tabnames to (get the name of every anchor of pane id "com.apple.preference.security")
			#display dialog tabnames
			#return tabnames
			reveal anchor "General" of pane id "com.apple.preference.security"
		end tell
	end tell
EOF
	sleep 3

}
if [[ "$MACOS_VERSION_MAJOR" == "11" ]] && [[ -e "/Users/"$USER"/virtualbox" ]] && [[ -e /Applications/VirtualBox.app ]]
then
	vbox_workaround
else
	:
fi


# undo vbox workaround
undo_vbox_workaround() {
	sudo /usr/bin/kmutil unload -b org.virtualbox.kext.VBoxUSB
	sudo /usr/bin/kmutil unload -b org.virtualbox.kext.VBoxNetFlt
	sudo /usr/bin/kmutil unload -b org.virtualbox.kext.VBoxNetAdp
	sudo /usr/bin/kmutil unload -b org.virtualbox.kext.VBoxUSB
	
	sudo rm -rf "$VBOX_KEXT_DESTINATION"/VBoxDrv.kext
	sudo rm -rf "$VBOX_KEXT_DESTINATION"/VBoxNetFlt.kext
	sudo rm -rf "$VBOX_KEXT_DESTINATION"/VBoxNetAdp.kext
	sudo rm -rf "$VBOX_KEXT_DESTINATION"/VBoxUSB.kext
	
	# reboot and reinstall virtualbox and extension pack
	
	#sudo kextload -b org.virtualbox.kext.VBoxDrv
	#sudo kextload -b org.virtualbox.kext.VBoxNetFlt
	#sudo kextload -b org.virtualbox.kext.VBoxNetAdp
	#sudo kextload -b org.virtualbox.kext.VBoxUSB
	
	# open System Settings - Privacy - General
	# accept extensions
	
	}
#undo_vbox_workaround


### affinity
# link color profiles (needed as of 2021-03)
# no longer needed for V2 apps (as of 2023-01)

color_profile_links_affinity_v1_apps() {
	# publisher
	if [[ -e "$PATH_TO_APPS"/"Affinity Publisher.app" ]]
	then
		echo ''
		APP_NAME_FOR_PREFERENCES="Affinity Publisher"
		echo "$APP_NAME_FOR_PREFERENCES"
		mkdir -p "/Users/$USER/Library/Containers/com.seriflabs.affinitypublisher/Data/Library/Application Support/profiles/"
		if [[ -e /Library/ColorSync/Profiles/eci/ISOcoated_v2_300_eci.icc ]]
		then
			if [[ -e "/Users/$USER/Library/Containers/com.seriflabs.affinitypublisher/Data/Library/Application Support/profiles/ISOcoated_v2_300_eci.icc" ]]
			then
				echo "color profile ISOcoated_v2_300_eci for publisher already exists..."
			else
				ln -s /Library/ColorSync/Profiles/eci/ISOcoated_v2_300_eci.icc "/Users/$USER/Library/Containers/com.seriflabs.affinitypublisher/Data/Library/Application Support/profiles/"
			fi
		else
			echo "color profile ISOcoated_v2_300_eci not found..." >&2
		fi
		if [[ -e /Library/ColorSync/Profiles/eci/eciRGB_v2.icc ]]
		then
			if [[ -e "/Users/$USER/Library/Containers/com.seriflabs.affinitypublisher/Data/Library/Application Support/profiles/eciRGB_v2.icc" ]]
			then
				echo "color profile eciRGB_v2 for publisher already exists..."
			else
				ln -s /Library/ColorSync/Profiles/eci/eciRGB_v2.icc "/Users/$USER/Library/Containers/com.seriflabs.affinitypublisher/Data/Library/Application Support/profiles/"
			fi
		else
			echo "color profile eciRGB_v2 not found..." >&2
		fi
	else
		echo ""$PATH_TO_APPS"/"Affinity Publisher.app" not installed..." >&2
	fi
	
	# photos
	if [[ -e "$PATH_TO_APPS"/"Affinity Photo.app" ]]
	then
		echo ''
		APP_NAME_FOR_PREFERENCES="Affinity Photo"
		echo "$APP_NAME_FOR_PREFERENCES"
		mkdir -p "/Users/$USER/Library/Containers/com.seriflabs.affinityphoto/Data/Library/Application Support/profiles/"
		if [[ -e /Library/ColorSync/Profiles/eci/ISOcoated_v2_300_eci.icc ]]
		then
			if [[ -e "/Users/$USER/Library/Containers/com.seriflabs.affinityphoto/Data/Library/Application Support/profiles/ISOcoated_v2_300_eci.icc" ]]
			then
				echo "color profile ISOcoated_v2_300_eci for photo already exists..."
			else
				ln -s /Library/ColorSync/Profiles/eci/ISOcoated_v2_300_eci.icc "/Users/$USER/Library/Containers/com.seriflabs.affinityphoto/Data/Library/Application Support/profiles/"
			fi
		else
			echo "color profile ISOcoated_v2_300_eci not found..." >&2
		fi
		if [[ -e /Library/ColorSync/Profiles/eci/eciRGB_v2.icc ]]
		then
			if [[ -e "/Users/$USER/Library/Containers/com.seriflabs.affinityphoto/Data/Library/Application Support/profiles/eciRGB_v2.icc" ]]
			then
				echo "color profile eciRGB_v2 for photo already exists..."
			else
				ln -s /Library/ColorSync/Profiles/eci/eciRGB_v2.icc "/Users/$USER/Library/Containers/com.seriflabs.affinityphoto/Data/Library/Application Support/profiles/"
			fi
		else
			echo "color profile eciRGB_v2 not found..." >&2
		fi
	else
		echo ""$PATH_TO_APPS"/"Affinity Photo.app" not installed..." >&2
	fi
	
	# designer
	if [[ -e "$PATH_TO_APPS"/"Affinity Designer.app" ]]
	then
		echo ''
		APP_NAME_FOR_PREFERENCES="Affinity Designer"
		echo "$APP_NAME_FOR_PREFERENCES"
		mkdir -p "/Users/$USER/Library/Containers/com.seriflabs.affinitydesigner/Data/Library/Application Support/profiles/"
		if [[ -e /Library/ColorSync/Profiles/eci/ISOcoated_v2_300_eci.icc ]]
		then
			if [[ -e "/Users/$USER/Library/Containers/com.seriflabs.affinitydesigner/Data/Library/Application Support/profiles/ISOcoated_v2_300_eci.icc" ]]
			then
				echo "color profile ISOcoated_v2_300_eci for designer already exists..."
			else
				ln -s /Library/ColorSync/Profiles/eci/ISOcoated_v2_300_eci.icc "/Users/$USER/Library/Containers/com.seriflabs.affinitydesigner/Data/Library/Application Support/profiles/"
			fi
		else
			echo "color profile ISOcoated_v2_300_eci not found..." >&2
		fi
		if [[ -e /Library/ColorSync/Profiles/eci/eciRGB_v2.icc ]]
		then
			if [[ -e "/Users/$USER/Library/Containers/com.seriflabs.affinitydesigner/Data/Library/Application Support/profiles/eciRGB_v2.icc" ]]
			then
				echo "color profile eciRGB_v2 for designer already exists..."
			else
				ln -s /Library/ColorSync/Profiles/eci/eciRGB_v2.icc "/Users/$USER/Library/Containers/com.seriflabs.affinitydesigner/Data/Library/Application Support/profiles/"
			fi
		else
			echo "color profile eciRGB_v2 not found..." >&2
		fi
	else
		echo ""$PATH_TO_APPS"/"Affinity Designer.app" not installed..." >&2
	fi
}


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


###
### unsetting password
###

unset SUDOPASSWORD



echo ''
echo "done ;)"
echo ''

