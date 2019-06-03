#!/usr/bin/env bash

###
### asking password upfront
###

# function for reading secret string (POSIX compliant)
enter_password_secret()
{
    # read -s is not POSIX compliant
    #read -s -p "Password: " SUDOPASSWORD
    #echo ''
    
    # this is POSIX compliant
    # disabling echo, this will prevent showing output
    stty -echo
    # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
    trap 'stty echo' EXIT
    # asking for password
    printf "Password: "
    # reading secret
    read -r "$@" SUDOPASSWORD
    # reanabling echo
    stty echo
    trap - EXIT
    # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
    printf "\n"
    # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
    # has to be part of the function or it wouldn`t be updated during the maximum three tries
    #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
}

# unset the password if the variable was already set
unset SUDOPASSWORD

# making sure no variables are exported
set +a

# asking for the SUDOPASSWORD upfront
# typing and reading SUDOPASSWORD from command line without displaying it and
# checking if entered password is the sudo password with a set maximum of tries
NUMBER_OF_TRIES=0
MAX_TRIES=3
while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
do
    NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
    #echo "$NUMBER_OF_TRIES"
    if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    then
        enter_password_secret
        ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
        if [ $? -eq 0 ]
        then 
            break
        else
            echo "Sorry, try again."
        fi
    else
        echo ""$MAX_TRIES" incorrect password attempts"
        exit
    fi
done

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}


###
### functions
###



###
### variables
###

MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)



###
### setting some non apple third party app preferences
###


### totalfinder

if [[ -e "/Applications/TotalFinder.app" ]]
then
	
	echo ''
	echo "totalfinder"
	
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
	:
fi


### xtrafinder

if [ -e "/Applications/XtraFinder.app" ]
then

	echo ''
    echo "xtrafinder"
	
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
	:
fi


### iterm 2                                                      

if [[ -e "/Applications/iTerm.app" ]]
then
    
    echo ''
    echo "iterm 2"

    # make terminal font sf mono available in other apps
    cp -a /Applications/Utilities/Terminal.app/Contents/Resources/Fonts/* /Users/$USER/Library/Fonts/
    
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
	:
fi


### GPGMail 2

# disable signing emails by default
#defaults write ~/Library/Preferences/org.gpgtools.gpgmail SignNewEmailsByDefault -bool false


### office 2016 & 2019

if [[ $(find "/Applications/" -mindepth 1 -maxdepth 1 -name "Microsoft *.app") != "" ]]
then
    
    echo ''
    echo "office"
    
    # https://github.com/erikberglund/ProfileManifests/blob/master/Resources/ManifestsGenerated/Microsoft/Archive/Office%202016%20for%20Mac%20Preference%20Keys%20-%20Prefs-2018-09-19.csv

    # user name and initials
    defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/MeContact.plist" Name "`finger $USER | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //'`"
    defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/MeContact.plist" Initials "`finger $USER | awk -F: '{ print $3 }' | head -n1 | sed 's/^ //' | cut -c1-1`"
    #defaults read "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/MeContact.plist"
    
    # set default save location to local
    #defaults write ~/Library/Preferences/com.microsoft.office DefaultsToLocalOpenSave -bool true
    defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/com.microsoft.officeprefs.plist" DefaultsToLocalOpenSave -bool true
    chown $USER:staff "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/com.microsoft.officeprefs.plist"
    # set theme
    # 1 = light
    # 2 = dark
    defaults write ~/Library/Preferences/com.microsoft.office kCUIThemePreferencesThemeKeyPath -integer 1
    # do not show documents popup on launch
    defaults write ~/Library/Preferences/com.microsoft.office ShowDocStageOnLaunch -bool false
    # do not send telemetry data and crash reports
    defaults write ~/Library/Preferences/com.microsoft.autoupdate2.plist SendAllTelemetryEnabled -bool false
    defaults write ~/Library/Preferences/com.microsoft.autoupdate2.plist SendCrashReportsEvenWithTelemetryDisabled -bool false
    defaults write ~/Library/Preferences/com.microsoft.autoupdate.fba.plist SendAllTelemetryEnabled -bool false
    defaults write ~/Library/Preferences/com.microsoft.autoupdate.fba.plist SendCrashReportsEvenWithTelemetryDisabled -bool false
    defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.plist" SendAllTelemetryEnabled -bool false
    #defaults write "/Users/$USER/Library/Group Containers/UBF8T346G9.Office/com.microsoft.Office365V2.plist" SendCrashReportsEvenWithTelemetryDisabled -bool false
    
    # app specific settings
    for OFFICE_APP in Word Excel onenote.mac Outlook Powerpoint
    do 
        if [[ -e ~/Library/Containers/com.microsoft.$OFFICE_APP ]]
        then
            # do not send telemetry data and crash reports
            defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist SendAllTelemetryEnabled -bool false
            defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist SendCrashReportsEvenWithTelemetryDisabled -bool false
            # show ribbons
            defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist kOUIRibbonDefaultCollapse -bool false
            # skip first run popups
            defaults write ~/Library/Containers/com.microsoft.$OFFICE_APP/Data/Library/Preferences/com.microsoft.$OFFICE_APP.plist kSubUIAppCompletedFirstRunSetup1507 -bool true
        else
            :
        fi
    done
    
else
    :
fi


### libreoffice

if [[ -e "/Applications/LibreOffice.app" ]]
then

    echo ''
    echo "libreoffice"

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
    # open /Applications/LibreOffice.app
    # preferences - libreoffice - advanced - expert - search for settings name, e.g. RecentDocsThumbnail or PickListSize
    # set and apply

else
	:
fi


### avast

if [[ -e "/Applications/Avast.app" ]]
then

    echo ''
    echo "avast"

    #echo "setting preferences..."
    AVAST_DAEMON_CONFIG='/Library/Application Support/Avast/config/com.avast.daemon.conf'
    if [[ $(cat "$AVAST_DAEMON_CONFIG" | grep "^STATISTICS*") == "" ]]
    then
        sudo bash -c "echo '' >> '$AVAST_DAEMON_CONFIG'"
        sudo bash -c "echo 'STATISTICS = 0' >> '$AVAST_DAEMON_CONFIG'"
    else
        :
    fi
    if [[ $(cat "$AVAST_DAEMON_CONFIG" | grep "^HEURISTICS*") == "" ]]
    then
        #sudo bash -c "echo '' >> '$AVAST_DAEMON_CONFIG'"
        sudo bash -c "echo 'HEURISTICS = 0' >> '$AVAST_DAEMON_CONFIG'"
    else
        :
    fi
    
    # files
    AVAST_FILESHIELD_CONFIG='/Library/Application Support/Avast/config/com.avast.fileshield.conf'
    sudo bash -c "cat > '$AVAST_FILESHIELD_CONFIG' << 'EOF'
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
    sudo bash -c "cat > '$AVAST_PROXY_CONFIG' << 'EOF'
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
    AVAST_BACKEND='/Applications/Avast.app/Contents/Backend/hub'
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
	:
fi


###
### unsetting password
###

unset SUDOPASSWORD



echo ''
echo "done ;)"
echo ''

