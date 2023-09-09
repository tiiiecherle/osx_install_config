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
### documentation
###

# reading globaldomain values
# defaults read NSGlobalDomain



###
### compatibility
###

# specific macos version only
if [[ "$MACOS_VERSION_MAJOR" != "12" ]]
then
    echo ''
    echo "this script is only compatible with macos 12, exiting..."
    echo ''
    exit
else
    :
fi



###
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile



###
### script
###


### security permissions
env_databases_apps_security_permissions
env_identify_terminal


echo "setting security and automation permissions..."
### automation
# macos versions 10.14 and up
AUTOMATION_APPS=(
# source app name							automated app name										    allowed (1=yes, 0=no)
"$SOURCE_APP_NAME                           System Events                                               1"
"$SOURCE_APP_NAME                           System Preferences                                          1"
)
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="no" env_set_apps_automation_permissions
echo ''


### uuid

#uuid1=$(system_profiler SPHardwareDataType | grep "Hardware UUID" | awk -F":" '{print $2}' | awk '{gsub(/^[ \t]+|[ \t]+$/, "")}1')
uuid1=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | cut -c22-57)
#uuid1=$(/usr/sbin/system_profiler SPHardwareDataType | grep "Hardware UUID" | awk '{print $3}')

echo "hardware uuid is $uuid1"
#echo ''


### displayid

#displayid=$(/usr/libexec/PlistBuddy -c 'Print com.apple.AmbientDisplay.LUT' ~/Library/Preferences/ByHost/.GlobalPreferences.13C818AE-B18F-56C7-99D0-690513D860A9.plist | tail -n 4 | head -n 1 | awk -F" " '{print $1}')
#displayid=$(sudo defaults read /Library/Preferences/com.apple.windowserver.plist | grep DisplayID | head -n 1 | awk -F"=" '{print $2}' | sed 's/[ \t]//g' | sed 's/;//g')
#displayid1=$(eval echo '"'"$displayid"'"')

#echo "my displayid is $displayid1"


###
### setting preferences
###

setting_preferences() {
    
    ###
    ### preferences - general
    ###
    
    echo "preferences general"
    
    # interface appearance
    # becomes active after logout
    # defaults read -g | grep AppleInterfaceStyle
    # light
    #defaults delete -g AppleInterfaceStyle &> /dev/null
    #defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false
    # dark
    #defaults delete -g AppleInterfaceStyle &> /dev/null
    #defaults write -g AppleInterfaceStyle -string "Dark"
    #defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false
    # automatic
    defaults delete -g AppleInterfaceStyle &> /dev/null
    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true
    
    # immediate change
    #osascript -e '
    #tell application "System Events"
    #    tell appearance preferences
    #        set properties to {dark mode:scheduled}
    #    end tell
    #end tell
    #'
    
    # accent color
    # 0 = red
    # 1 = orange
    # 2 = yellow
    # 3 = green
    # 4 = blue
    # 5 = violet
    # 6 = pink
    # -1 = graphit   
    ##
    defaults write -g AppleAccentColor -int 4
    
    # highlight color
    # example blue
    # defaults write NSGlobalDomain AppleHighlightColor -string "0.698039 0.843137 1.000000 Blue"
    # reset to default (same as accent color)
    defaults delete -g AppleHighlightColor &> /dev/null
    
    # set sidebar icon size
    # 1=small, 2=medium, 3=big
    defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1
    
    # background tinting
    # slightly translucent windows = true
    # not translucent windows = false
    defaults write NSGlobalDomain AppleReduceDesktopTinting -bool false
    
    # show scrollbars
    # possible values: WhenScrolling, Automatic, Always
    defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
    
    # click in the scroll bar to
    # false: jump to the next page
    # true: jump to the spot that's clicked
    defaults write -g AppleScrollerPagingBehavior -bool true
    
    # default web browser
    # see separate script defaults_open_with.sh
    
    # prefer tabs when opening documents
    # always, fullscreen or manual
    defaults write -g AppleWindowTabbingMode -string "always"
    
    # ask if changes of documents shall be confirmed when closing
    # false = off, true = on
    defaults write -g NSCloseAlwaysConfirmsChanges -bool true
    
    # resume apps system-wide (open windows are not restored when closing and re-opening an app)
    # true = off, false = on
    defaults write -g NSQuitAlwaysKeepsWindows -bool false
    
    # recent documents
    ##
    defaults write NSGlobalDomain NSRecentDocumentsLimit 10
    
    # setting handoff
    # false = off, true = on
    ##
    defaults write ByHost/com.apple.coreservices.useractivityd.${uuid1} ActivityAdvertisingAllowed -bool true
    defaults write ByHost/com.apple.coreservices.useractivityd.${uuid1} ActivityReceivingAllowed -bool true
    
    
    
    ###
    ### preferences - screen saver and wallpaper
    ###
    
    echo "preferences wallpaper & screensaver"
    
    # setting desktop wallpaper
    # reading infos
    #osascript -e 'tell application "System Events" to get properties of every desktop'
    
    # sets picture, but does not set the dynamic mode (light, dark, dynamic)
    #osascript -e 'tell application "System Events" to set picture of every desktop to posix file "/System/Library/Desktop Pictures/Big Sur.heic"'
    
    # all credits for the desktop picture section go to
    # https://github.com/tech-otaku/macos-desktop
    
    # desktop picture database
    DESKTOP_DB="/Users/"$USER"/Library/Application Support/Dock/desktoppicture.db"
    
    # sqlite3 "$DESKTOP_DB" ".dump data"
    # big sur dynamic
    VALUE=1
    DESKTOP_FILE="/System/Library/Desktop Pictures/Big Sur.heic"
    
    if [[ $(sqlite3 "$DESKTOP_DB" "SELECT COUNT() FROM displays;") -ge 2 ]] || [[ $(sqlite3 "$DESKTOP_DB" "SELECT COUNT() FROM spaces;") -ge 2 ]]
    then
        osascript -e "tell application \"System Events\" to set picture of every desktop to posix file \"$DESKTOP_FILE\""
        echo "multiple displays or spaces deteced, please select dynamic mode of desktop pictures manually in system preferences..." >&2
    else
        
        # reset desktop wallpaper to make sure to start with a clean database
        if [[ -f "$DESKTOP_DB" ]]; then rm -f "$DESKTOP_DB" && killall Dock && sleep 2; else :; fi
        
        # sqlite3 "$DESKTOP_DB" ".dump preferences"
        # sqlite3 "$DESKTOP_DB" "SELECT key FROM preferences WHERE picture_id=1;"
        # sqlite3 "$DESKTOP_DB" "SELECT key FROM preferences;" | head -n 2
        KEY1=20
        KEY2=1
    
        # last rows
        LAST_ROW_DATA=$(sqlite3 "$DESKTOP_DB" "SELECT ROWID FROM data ORDER BY ROWID DESC LIMIT 1;")
        if [[ "$LAST_ROW_DATA" == "" ]]; then LAST_ROW_DATA=0; else :; fi
        LAST_ROW_PREFERENCES=$(sqlite3 "$DESKTOP_DB" "SELECT ROWID FROM preferences ORDER BY ROWID DESC LIMIT 1;")
        if [[ "$LAST_ROW_PREFERENCES" == "" ]]; then LAST_ROW_PREFERENCES=0; else :; fi
    
        # deleting values to start cleanly
        sqlite3 "$DESKTOP_DB" "DELETE FROM data;"
        sqlite3 "$DESKTOP_DB" "DELETE FROM preferences;"
    
        # add needed row to data
        sqlite3 "$DESKTOP_DB" "INSERT INTO data(rowid,value) VALUES( $((LAST_ROW_DATA + 1)), $VALUE );"
        # add needed rows to preferences
        DATA_ID1=$(sqlite3 "$DESKTOP_DB" "SELECT rowid FROM data WHERE value=$VALUE;")
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 1)),$KEY1,$DATA_ID1,3);"
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 2)),$KEY1,$DATA_ID1,4);"
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 3)),$KEY1,$DATA_ID1,2);"
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 4)),$KEY1,$DATA_ID1,1);"
        
        # for desktop pictures that have a dynamic mode (light, dark, dynamic) more entreis are needed
        # add needed row to data
        sqlite3 "$DESKTOP_DB" "INSERT INTO data(rowid,value) VALUES( $((LAST_ROW_DATA + 2)), \"$DESKTOP_FILE\" );"
        # add needed rows to preferences
        DATA_ID2=$(sqlite3 "$DESKTOP_DB" "SELECT rowid FROM data WHERE value=\"$DESKTOP_FILE\"")
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 5)),$KEY2,$DATA_ID2,3);"
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 6)),$KEY2,$DATA_ID2,4);"
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 7)),$KEY2,$DATA_ID2,2);"
        sqlite3 "$DESKTOP_DB" "INSERT INTO preferences(rowid,key,data_id,picture_id) VALUES( $((LAST_ROW_PREFERENCES + 8)),$KEY2,$DATA_ID2,1);"
        
        # applying changes    
        killall Dock
        # killall "System Preferences"          # needed to see changes in system preferences
    fi

    # screen saver: 
    # defaults -currentHost read com.apple.screensaver
    # defaults -currentHost read com.apple.ScreenSaver.iLifeSlideShows
    
    # non-random
    #defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "iLifeSlideshows" path -string "/System/Library/Frameworks/ScreenSaver.framework/Resources/iLifeSlideshows.saver" type -int 0
    # example origami
    #defaults -currentHost write com.apple.ScreenSaver.iLifeSlideShows styleKey -string Origami
    # or 
    #defaults -currentHost write com.apple.screensaver moduleDict -dict path -string "/System/Library/Screen Savers/Flurry.saver" moduleName -string "Flurry" type -int 0

    # random
    #defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "Random" path -string "/System/Library/Screen Savers/Random.saver" type -int 8
    
    # idle time
    # time in seconds
    # never start = 0
    defaults -currentHost write com.apple.ScreenSaver idleTime -int 0
    
    # show clock
    defaults -currentHost write com.apple.ScreenSaver showClock -bool true

    
    
    ###
    ### preferences dock and menu bar
    ###
    
    echo "preferences dock and menu bar"
    
    # enable highlight hover effect for the grid view of a stack (dock)
    #defaults write com.apple.dock mouse-over-hilite-stack -bool true
    
    # set the icon size of Dock items
    defaults write com.apple.dock tilesize -int 53
    
    # magnification of dock items and size
    defaults write com.apple.dock magnification -bool true
    defaults write com.apple.dock largesize -int 72
    
    # dock position bottom, left, right
    ##
    defaults write com.apple.dock orientation -string "bottom"
    
    # minimize/maximize window effect
    # options: scale, genie
    ##
    defaults write com.apple.dock mineffect -string "genie"
    
    # double-click a window's title bar to minimize
    # true = minimize, false = zoom
    ##
    defaults write NSGlobalDomain AppleMiniaturizeOnDoubleClick -bool false
    
    # minimize windows into their applications icon
    ##
    defaults write com.apple.dock minimize-to-application -bool false
    
    # enable spring loading for all dock items
    #defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
    
    # animate opening applications from the dock
    ##
    defaults write com.apple.dock launchanim -bool true
    
    # automatically hide and show the dock
    defaults write com.apple.dock autohide -bool true
    
    # show indicator lights for open applications in the dock
    ##
    defaults write com.apple.dock show-process-indicators -bool true
    
    # show last used applications in the dock
    # also done in script 10_dock
    defaults write com.apple.dock show-recents -bool false
    
    # autohide menu bar on desktop
    # 0=no, 1=yes
    ##
    defaults write NSGlobalDomain _HIHideMenuBar -int 0
    
    # autohide menu bar in full scrren mode
    # 0=yes, 1=no
    defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -int 1
    
    
    ### hidden dock tweaks    
    
    # make dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true
    
    # remove the auto-hiding dock delay
    #defaults write com.apple.dock autohide-delay -float 0
    
    # remove the animation when hiding/showing the dock
    #defaults write com.apple.dock autohide-time-modifier -float 0
    
    
    ###
    ### preferences menu bar and control center
    ###
    
    echo "menu bar control center"
    # options for com.apple.controlcenter.$uuid1.plist
    
    set_menu_bar_and_control_center() {
        while IFS= read -r line || [[ -n "$line" ]]
	    do
	        if [[ "$line" == "" ]]; then continue; fi
            local ENTRY="$line"
            local MENU_BAR_CONTROL_CENTER_ENTRY=$(echo "$ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            local ENABLE_IN_CONTROL_CENTER=$(echo "$ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            local ENABLE_IN_MENU_BAR=$(echo "$ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            
            # control center
            # changes to com.apple.controlcenter.$uuid1.plist have to be made before changing com.apple.controlcenter to make the changes take effect
            if [[ "$ENABLE_IN_CONTROL_CENTER" == "no-option" ]]
            then
                if [[ "$ENABLE_IN_MENU_BAR" == "no" ]]
                then
                    CONTROL_CENTER_INT_VALUE=24
                elif [[ "$ENABLE_IN_MENU_BAR" == "yes" ]] || [[ "$ENABLE_IN_MENU_BAR" == "always" ]]
                then
                    CONTROL_CENTER_INT_VALUE=18
                elif [[ "$ENABLE_IN_MENU_BAR" == "if-active" ]]
                then
                    CONTROL_CENTER_INT_VALUE=2
                fi
            elif [[ "$ENABLE_IN_CONTROL_CENTER" == "no" ]]         
            then
                if [[ "$ENABLE_IN_MENU_BAR" == "no" ]]
                then
                    CONTROL_CENTER_INT_VALUE=24
                elif [[ "$ENABLE_IN_MENU_BAR" == "yes" ]]
                then
                    CONTROL_CENTER_INT_VALUE=18
                fi
            elif [[ "$ENABLE_IN_CONTROL_CENTER" == "yes" ]]         
            then
                if [[ "$ENABLE_IN_MENU_BAR" == "no" ]]
                then
                    CONTROL_CENTER_INT_VALUE=25
                elif [[ "$ENABLE_IN_MENU_BAR" == "yes" ]]
                then
                    CONTROL_CENTER_INT_VALUE=28
                fi
            fi
            defaults write /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/Users/"$USER"/Library/Preferences/ByHost/com.apple.controlcenter."$uuid1".plist "$MENU_BAR_CONTROL_CENTER_ENTRY" -int "$CONTROL_CENTER_INT_VALUE"
            
            # menu bar
            if [[ "$ENABLE_IN_MENU_BAR" == "yes" ]]
            then
                local MENU_BAR_BOOL_VALUE=true
            elif
            if [[ "$ENABLE_IN_MENU_BAR" == "no-option" ]]
            then
                local MENU_BAR_BOOL_VALUE=""     
            else
                local MENU_BAR_BOOL_VALUE=false
            fi
            if [[ "$MENU_BAR_BOOL_VALUE" == "" ]]
            then
                :
            else
                defaults write com.apple.controlcenter "NSStatusItem Visible "$MENU_BAR_CONTROL_CENTER_ENTRY"" -bool "$MENU_BAR_BOOL_VALUE"
            fi
            
        done <<< "$(printf "%s\n" "${MENU_BAR_CONTROL_CENTER_ARRAY[@]}")"
    }
    
    # battery percentage
    defaults write /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/Users/"$USER"/Library/Preferences/ByHost/com.apple.controlcenter."$uuid1".plist BatteryShowPercentage -bool true
    defaults write /Volumes/"$MACOS_CURRENTLY_BOOTED_VOLUME"/Users/"$USER"/Library/Preferences/ByHost/com.apple.controlcenter."$uuid1".plist Battery.ShowPercentage -bool true
    
    # other entries
    MENU_BAR_AND_CONTROL_CENTER_ENTRIES=(
    # 
    # name								 enabled in control center					enabled in menu bar
    "WiFi                                no-option                                  yes"
    "Bluetooth                           no-option                                  yes"
    "AirDrop                             no-option                                  no"
    "FocusModes                          no-option                                  if-active"
    "DoNotDisturb                        no-option                                  if-active"
    "KeyboardBrightness                  no-option                                  no"
    "AirPlay                             no-option                                  no"
    "ScreenMirroring                     no-option                                  if-active"
    "Display                             no-option                                  if-active"
    "Sound                               no-option                                  always"
    "NowPlaying                          no-option                                  no"
    "AccessibilityShortcuts              no                                         no"
    "Battery                             no                                         yes"
    "UserSwitcher                        no                                         no"
    )
    MENU_BAR_CONTROL_CENTER_ARRAY=$(printf "%s\n" "${MENU_BAR_AND_CONTROL_CENTER_ENTRIES[@]}")
    set_menu_bar_and_control_center
    
    # clock in menu bar
    # see date & time section below
    
    # spotlight menu bar icon
    # takes effect after logout or reboot
    /usr/libexec/PlistBuddy ~/Library/Preferences/ByHost/com.apple.Spotlight."$uuid1".plist -c 'Delete MenuItemHidden bool true' >/dev/null 2>&1
    /usr/libexec/PlistBuddy ~/Library/Preferences/ByHost/com.apple.Spotlight."$uuid1".plist -c 'Add MenuItemHidden bool true' >/dev/null 2>&1
    # or hide or move with bartender
    
    # siri menu bar icon
    # see siri section below
    
    # time machine menu bar icon
    # see time machine section below

    #killall ControlCenter
    #killall SystemUIServer
    
    # turning off the clock in the menu bar
    disable_menu_bar_clock() {
    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    
    tell application "System Preferences"
    	activate
    	set current pane to pane "com.apple.preference.dock"
    	delay 5
    	tell application "System Events"
    		select row 17 of outline 1 of scroll area 1 of window 1 of application process "System Preferences"
    	end tell
    end tell
    
    delay 2
    
    tell application "System Events"
    	tell process "System Preferences"
    		delay 0.5
    		#set theCheckbox to checkbox "Datum und Uhrzeit in der Menüleiste anzeigen" of tab group 1 of window 1
		    set theCheckbox to checkbox 3 of tab group 1 of window 1
    		tell theCheckbox
    			set checkboxStatus to value of theCheckbox as boolean
    			if checkboxStatus is true then click theCheckbox
    		end tell
    		delay 1
    	end tell
    end tell
    
    delay 2
    
    tell application "System Preferences"
    	quit
    end tell
    
EOF
    }
    # disabling the menu bar clock is not an available option any more
    #disable_menu_bar_clock
    
    
    
    ###
    ### preferences mission control
    ###
    
    echo "preferences mission control"
    
    # automatically rearrange spaces based on most recent use
    defaults write com.apple.dock mru-spaces -bool false
    
    # when switching applications, switch to respective space
    ##
    defaults write -g AppleSpacesSwitchOnActivate -bool true
    
    # group windows by application in mission control
    defaults write com.apple.dock expose-group-apps -bool true
    
    # monitors are using different spaces
    # false = yes, true = no
    ##
    if [[ "$MONITORS_USE_DIFFERENT_SPACES" != "" ]]
    then
        defaults write com.apple.spaces spans-displays -bool "$MONITORS_USE_DIFFERENT_SPACES"
    else
        defaults write com.apple.spaces spans-displays -bool false
    fi
    
    # expose
    #
    # 32 = all windows, mission control
    # 33 = application windows
    # 36 = show desktop
    # 62 = dashboard
    # 73 = front row
    #
    # F9 = 101
    # F10 = 109
    # F11 = 103
    # F12 = 111
    #
    # 0 = no modifier
    # 131072 = Shift
    # 262144 = Control
    # 524288 = Option
    # 1048576 = Apple, cmd
    
    # disable all windows
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:32'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:enabled bool false'
    # or
    #defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 32 "<dict><key>enabled</key><false/></dict>"
    
    # enable all windows on F9
    # doesn`t work because it does not set the data types like bool, string, integer
    #defaults write ~/Library/Preferences/com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 32 '{enabled = true; value = {parameters = (0, 101, 65535); type = standard; }; }'
    #
    defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 32 "
      <dict>
        <key>enabled</key>
        <true/>
        <key>value</key>
        <dict>
          <key>type</key>
          <string>standard</string>
          <key>parameters</key>
          <array>
            <integer>65535</integer>
            <integer>101</integer>
            <integer>0</integer>
          </array>
          <key>type</key>
          <string>standard</string>
        </dict>
      </dict>
    "
    # or
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:32'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:enabled bool true'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:value:type string standard'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:value:parameters array'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:value:parameters:"Item 0" integer 0'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:value:parameters:"Item 1" integer 101'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:32:value:parameters:"Item 2" integer 65535'
    
    # disable application windows
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:33'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:enabled bool false'
    
    # enable application windows on F10
    defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 33 "
      <dict>
        <key>enabled</key>
        <true/>
        <key>value</key>
        <dict>
          <key>parameters</key>
          <array>
            <integer>65535</integer>
            <integer>109</integer>
            <integer>0</integer>
          </array>
          <key>type</key>
          <string>standard</string>
        </dict>
      </dict>
    "
    # or
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:33'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:enabled bool true'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:value:type string standard'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:value:parameters array'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:value:parameters:"Item 0" integer 0'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:value:parameters:"Item 1" integer 109'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:33:value:parameters:"Item 2" integer 65535'
    
    # disable show desktop
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:36'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:enabled bool false'
    
    # enable show desktop on F11
    defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 36 "
      <dict>
        <key>enabled</key>
        <true/>
        <key>value</key>
        <dict>
          <key>type</key>
          <string>standard</string>
          <key>parameters</key>
          <array>
            <integer>65535</integer>
            <integer>103</integer>
            <integer>0</integer>
          </array>
          <key>type</key>
          <string>standard</string>
        </dict>
      </dict>
    "
    # or
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:36'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:enabled bool true'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:value:type string standard'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:value:parameters array'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:value:parameters:"Item 0" integer 0'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:value:parameters:"Item 1" integer 103'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:36:value:parameters:"Item 2" integer 65535'
    
    # disable dashboard
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Delete AppleSymbolicHotKeys:62'
    #/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.symbolichotkeys.plist -c 'Add AppleSymbolicHotKeys:62:enabled bool false'
    
    
    ### hidden mission control tweaks
    
    # speed up mission control animations
    defaults write com.apple.dock expose-animation-duration -float 0.1
    
    # don't show dashboard as a space
    #defaults write com.apple.dock dashboard-in-overlay -bool true
    
    
    
    ###
    ### preferences - siri
    ###
    
    echo "preferences siri"
    # config files
    # /Users/tom/Library/Preferences/com.apple.assistant.support.plist
    # /Users/tom/Library/Preferences/com.apple.assistant.backedup.plist
    # /Users/tom/Library/Preferences/com.apple.Siri.plist
    
    # enable / disable siri 
    defaults write com.apple.assistant.support "Assistant Enabled" -boolean false
    
    
    ### if enabled (true), settings
    # if enabled is set to false some of the following settings will not be set and not be shown correctly in the system preferences
    
    # listen to hey siri
    defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
    
    # allow hey siri on lock screen
    #defaults write com.apple.Siri LockscreenEnabled -bool false
    
    # hotkey
    # 0 = off, 2 = hold cmd+space, 3 = hold option (alt)+space, 4 = hold fn+space
    defaults write com.apple.Siri HotkeyTag -integer 0
    #/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:176:enabled NO" ~/Library/Preferences/com.apple.symbolichotkeys.plist
    defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 176 "
      <dict>
        <key>enabled</key>
        <false/>
      </dict>
    "
    # when setting to another value than off be sure to adjust the values for the keys in ~/Library/Preferences/com.apple.symbolichotkeys.plist
    # example 2 = hold cmd+space
    #defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 176 "
    #  <dict>
    #    <key>enabled</key>
    #    <true/>
    #    <key>value</key>
    #    <dict>
    #      <key>type</key>
    #      <string>modifier</string>
    #      <key>parameters</key>
    #      <array>
    #        <integer>32</integer>
    #        <integer>49</integer>
    #        <integer>2148532224</integer>
    #      </array>
    #    </dict>
    #  </dict>
    #"
    
    # language
    defaults write com.apple.assistant.backedup "Session Language" -string de-DE
    
    ## output voice (needs reboot)
    # custom
    if [[ -z $(/usr/libexec/PlistBuddy -c "Print :'Output Voice':Custom" ~/Library/Preferences/com.apple.assistant.backedup.plist) ]] > /dev/null 2>&1
    then
        /usr/libexec/PlistBuddy -c "Add :'Output Voice':Custom bool" ~/Library/Preferences/com.apple.assistant.backedup.plist
    	/usr/libexec/PlistBuddy -c "Set :'Output Voice':Custom YES" ~/Library/Preferences/com.apple.assistant.backedup.plist
    else
    	/usr/libexec/PlistBuddy -c "Set :'Output Voice':Custom YES" ~/Library/Preferences/com.apple.assistant.backedup.plist
    fi
    # footprint
    if [[ -z $(/usr/libexec/PlistBuddy -c "Print :'Output Voice':Footprint" ~/Library/Preferences/com.apple.assistant.backedup.plist) ]] > /dev/null 2>&1
    then
        /usr/libexec/PlistBuddy -c "Add :'Output Voice':Footprint integer" ~/Library/Preferences/com.apple.assistant.backedup.plist
        /usr/libexec/PlistBuddy -c "Set :'Output Voice':Footprint 2" ~/Library/Preferences/com.apple.assistant.backedup.plist
    else
        /usr/libexec/PlistBuddy -c "Set :'Output Voice':Footprint 2" ~/Library/Preferences/com.apple.assistant.backedup.plist
    fi
    # language
    if [[ -z $(/usr/libexec/PlistBuddy -c "Print :'Output Voice':Language" ~/Library/Preferences/com.apple.assistant.backedup.plist) ]] > /dev/null 2>&1
    then
        /usr/libexec/PlistBuddy -c "Add :'Output Voice':Language string" ~/Library/Preferences/com.apple.assistant.backedup.plist
    	/usr/libexec/PlistBuddy -c "Set :'Output Voice':Language de-DE" ~/Library/Preferences/com.apple.assistant.backedup.plist
    else
    	/usr/libexec/PlistBuddy -c "Set :'Output Voice':Language de-DE" ~/Library/Preferences/com.apple.assistant.backedup.plist
    fi
    # gender
    if [[ -z $(/usr/libexec/PlistBuddy -c "Print :'Output Voice':Gender" ~/Library/Preferences/com.apple.assistant.backedup.plist) ]] > /dev/null 2>&1
    then
        /usr/libexec/PlistBuddy -c "Add :'Output Voice':Gender integer" ~/Library/Preferences/com.apple.assistant.backedup.plist
        /usr/libexec/PlistBuddy -c "Set :'Output Voice':Gender 2" ~/Library/Preferences/com.apple.assistant.backedup.plist
    else
        /usr/libexec/PlistBuddy -c "Set :'Output Voice':Gender 2" ~/Library/Preferences/com.apple.assistant.backedup.plist
    fi
    # name
    if [[ -z $(/usr/libexec/PlistBuddy -c "Print :'Output Voice':Name" ~/Library/Preferences/com.apple.assistant.backedup.plist) ]] > /dev/null 2>&1
    then
        /usr/libexec/PlistBuddy -c "Add :'Output Voice':Name string" ~/Library/Preferences/com.apple.assistant.backedup.plist
        /usr/libexec/PlistBuddy -c "Set :'Output Voice':Name helena" ~/Library/Preferences/com.apple.assistant.backedup.plist
    else
        /usr/libexec/PlistBuddy -c "Set :'Output Voice':Name helena" ~/Library/Preferences/com.apple.assistant.backedup.plist
    fi
    
    # speech output
    # 2 = yes, 3 = no
    defaults write com.apple.assistant.backedup "Use device speaker for TTS" -integer 2
    
    # micro input (automatic)
    if [[ -e ~/Library/Preferences/com.apple.Siri.plist ]]
    then 
    	if [[ -z $(/usr/libexec/PlistBuddy -c "Print :PreferredMicrophoneIdentifier" ~/Library/Preferences/com.apple.Siri.plist) ]] >/dev/null 2>&1
    	then
    		:
    	else
    		/usr/libexec/PlistBuddy -c "Delete :PreferredMicrophoneIdentifier" ~/Library/Preferences/com.apple.Siri.plist
    	fi
    else
    	:
    fi
    
    # menu bar icon
    defaults write com.apple.Siri StatusMenuVisible -bool false
    
    ### siri suggestions and privacy
	# disable siri analytics, suggestions and learning
    if [[ -e "$SCRIPT_DIR_ONE_BACK"/15_finalizations/15c_disable_siri_analytics_and_learning_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh ]]
    then
        echo "disabling siri suggestions and learning"
        "$SCRIPT_DIR_ONE_BACK"/15_finalizations/15c_disable_siri_analytics_and_learning_"$MACOS_VERSION_MAJOR_UNDERSCORE".sh
    else
        echo "script for disabling siri suggestions and learning not found, skipping..."
    fi



    ###
    ### preferences spotlight
    ###
    
    # see separate script
    
    
    
    ###
    ### preferences language and region
    ###
    
    echo "preferences language and region"
    
    # setup assistant language (system and login screen)
    sudo languagesetup -langspec de
    
    # set language and text formats
    # note: if you are in the US, replace `EUR` with `USD`, `Centimeters` with
    # `Inches`, `en_GB` with `en_US`, and `true` with `false`
    ##.
    defaults write NSGlobalDomain AppleLanguages -array "de-DE"
    defaults write NSGlobalDomain AppleLocale -string "de_DE"
    ##
    # 2 = monday
    # 3 = tuesday
    # ...
    defaults write NSGlobalDomain AppleFirstWeekday -array "gregorian = 2"
    ##
    # 12 hour clock
    # 12 hour clock of = 24 h clock on
    # be sure the system preferences window is not open when using this or it won`t work
    #defaults write NSGlobalDomain AppleICUForce12HourTime -bool false
    # will be set to AppleICUForce24HourTime later
    #defaults delete NSGlobalDomain AppleICUForce12HourTime
    ##
    defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"
    ##
    defaults write NSGlobalDomain AppleLiveTextEnabled -bool true
    ##
    defaults write NSGlobalDomain AppleLocale -string "de_DE@currency=EUR"
    ##
    defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
    ##
    defaults write NSGlobalDomain AppleMetricUnits -bool true
    ##
    # sort order default (universal)
    defaults write NSGlobalDomain AppleCollationOrder -string "de@collation=universal"
    # or
    #defaults delete NSGlobalDomain AppleCollationOrder
    
    
    ### custom language settings for apps
    # writes to the config file of an app and to global user preferences
    # example changing app language from system default german to english for specific app
    set_custom_language_settings_coteditor() {
        APP_CONFIG_FILE="/Users/"$USER"/Library/Containers/com.coteditor.CotEditor/Data/Library/Preferences/com.coteditor.CotEditor.plist"
        APP_ID="com.coteditor.CotEditor"
        /usr/libexec/PlistBuddy -c "Delete :AppleLanguages" "$APP_CONFIG_FILE" 2> /dev/null
        /usr/libexec/PlistBuddy -c "Add :AppleLanguages array" "$APP_CONFIG_FILE" 2> /dev/null
        /usr/libexec/PlistBuddy -c "Add :AppleLanguages:0 string 'en-DE'" "$APP_CONFIG_FILE"
        /usr/libexec/PlistBuddy -c "Add :AppleLanguages:1 string 'de'" "$APP_CONFIG_FILE"
        /usr/libexec/PlistBuddy -c "Add :AppleLanguages:2 string 'de-DE'" "$APP_CONFIG_FILE"
        # activating changes
        defaults read "$APP_CONFIG_FILE" &> /dev/null
        
        # entry to system and gui
        SYSTEM_CONFIG_FILE="/Users/"$USER"/Library/Preferences/.GlobalPreferences.plist"
        /usr/libexec/PlistBuddy -c "Delete :ApplePerAppLanguageSelectionBundleIdentifiers" "$SYSTEM_CONFIG_FILE" 2> /dev/null
        /usr/libexec/PlistBuddy -c "Add :ApplePerAppLanguageSelectionBundleIdentifiers array" "$SYSTEM_CONFIG_FILE" 2> /dev/null
        /usr/libexec/PlistBuddy -c "Add :ApplePerAppLanguageSelectionBundleIdentifiers:0 string $APP_ID" "$SYSTEM_CONFIG_FILE"
        # activating changes
        defaults read "$SYSTEM_CONFIG_FILE" &> /dev/null
    }
    #set_custom_language_settings_coteditor
    
    
    
    ###
    ### preferences - notifications
    ###
    
    # disable notification center
	#sudo launchctl bootout system "/System/Library/LaunchAgents/com.apple.notificationcenterui.plist" 2>&1 | grep -v "in progress"
	#sleep 2
	#sudo launchctl disable system/com.apple.notificationcenterui

    # reenable notification center
    #sudo launchctl enable system/com.apple.notificationcenterui
    #sudo launchctl bootstrap system "/System/Library/LaunchAgents/com.apple.notificationcenterui.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	#sleep 2
        
    ### do not disturb
    
    # from macos 12 on the easiest way to toggle dnd on the command line seems to be the shortcuts.app
    # https://github.com/sindresorhus/do-not-disturb/issues/9#issuecomment-981590804
    # https://github.com/vitorgalvao/tiny-scripts/issues/206#issuecomment-974747114
    
    # open shortcuts
    # add shortcut - name dnd-on
    # add action focus on until switched off
    # add shortcut - name dnd-off
    # add action focus off until switched on
    
    check_dnd_status() {
    	# check dnd state
    	# 0 = off
    	# 1 = on
    	DND_STATUS=$(defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes")
    }
    
    # enable dnd
    enable_dnd() {
        echo "enabling dnd..."
    	if [[ -e "/System/Applications/Shortcuts.app" ]] && [[ $(shortcuts list | grep -x "dnd-on") != "" ]] 
    	then
    		shortcuts run dnd-on
    		sleep 1
    		defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes"
    	else
    		echo "shortcuts app or shortcuts name not found..."
    	fi
    }
    #enable_dnd
    
    #check_dnd_status
    #if [[ "$DND_STATUS" == "0" ]]
    #then
    #    enable_dnd
    #else
    # 	:
    #fi
    
    # wait to apply changes
    #sleep 3
    
    # disable dnd
    disable_dnd() {
        echo "disabling dnd..."
    	if [[ -e "/System/Applications/Shortcuts.app" ]] && [[ $(shortcuts list | grep -x "dnd-off") != "" ]] 
    	then
    		shortcuts run dnd-off
    		sleep 1
    		defaults read com.apple.controlcenter "NSStatusItem Visible FocusModes"
    	else
    		echo "shortcuts app or shortcuts name not found..."
    	fi
    }
    #disable_dnd
    
    #check_dnd_status
    #if [[ "$DND_STATUS" == "1" ]]
    #then
    #    disable_dnd
    #else
    #	:
    #fi
    
    dnd_settings() {
    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    
    tell application "System Preferences"
    	activate
    	#set paneids to (get the id of every pane)
    	#display dialog paneids
    	#return paneids
    	#set current pane to pane "com.apple.preference.notifications"
    	#get the name of every anchor of pane id "com.apple.preference.notifications"
    	#set tabnames to (get the name of every anchor of pane id "com.apple.preference.notifications")
    	#return tabnames
    	#display dialog tabnames
    	reveal anchor "Notifications" of pane id "com.apple.preference.notifications"
    	delay 4
    end tell
    
    tell application "System Events" to tell process "System Preferences" to set visible to true
    delay 1
    tell application "System Events" to tell process "System Preferences" to set frontmost to true
    delay 1
    
    tell application "System Events"
    	tell process "System Preferences"
    		# notifications
	        click radio button 1 of tab group 1 of window 1
    		delay 1
    	end tell
    end tell
        
    tell application "System Events"
    	tell process "System Preferences"
    		# if screen is sleeping
    		if exists checkbox 1 of tab group 1 of window 1 then
    			set theCheckbox to (checkbox 1 of tab group 1 of window 1)
    			tell theCheckbox
    				set checkboxStatus to value of theCheckbox as boolean
    				if checkboxStatus is true then click theCheckbox
    			end tell
    		end if
    		delay 0.2
    		# if screen is locked
		    if exists checkbox 2 of tab group 1 of window 1 then
    			set theCheckbox to (checkbox 2 of tab group 1 of window 1)
    			tell theCheckbox
    				set checkboxStatus to value of theCheckbox as boolean
    				if checkboxStatus is true then click theCheckbox
    			end tell
    		end if
    		delay 0.2
    		# sync tvs and projectors
		    if exists checkbox 3 of tab group 1 of window 1 then
    			set theCheckbox to (checkbox 3 of tab group 1 of window 1)
    			tell theCheckbox
    				set checkboxStatus to value of theCheckbox as boolean
    				if checkboxStatus is false then click theCheckbox
    			end tell
    		end if
    		delay 0.2
    	end tell
    end tell
    delay 1
    
    tell application "System Preferences"
    	quit
    end tell
    
EOF
    }
    dnd_settings
    
    ### focus
    # share focus status (allow important notifications)
    # read values
    #jq '.' ~/Library/DoNotDisturb/DB/ModeConfigurations.json
    #jq '.data' ~/Library/DoNotDisturb/DB/ModeConfigurations.json
    #jq '.data | .[] | .modeConfigurations | .[] | .configuration | .minimumBreakthroughUrgency' ~/Library/DoNotDisturb/DB/ModeConfigurations.json
    # enable allow important notifications
    sed -i '' 's|"minimumBreakthroughUrgency":0|"minimumBreakthroughUrgency":1|' ~/Library/DoNotDisturb/DB/ModeConfigurations.json
    # disable allow important notifications
    #sed -i '' 's|"minimumBreakthroughUrgency":1|"minimumBreakthroughUrgency":0|' ~/Library/DoNotDisturb/DB/ModeConfigurations.json
    
    # share focus status on multiple devices (allow important notifications on multiple devices) - needs logout
    # do not share = true
    # share = false
    defaults write com.apple.donotdisturbd disableCloudSync -bool true
    
    ### other apps
    # allow calls from everyone if do not disturb is active
    defaults write com.apple.messages.facetime FaceTimeFavoritesDNDEnabled -bool false
    
    # allow repeating calls within three minutes from the same caller if do not disturb is active
    defaults write com.apple.messages.facetime FaceTimeTwoTimeCallthroughEnabled -bool false
    
    # making the changes take effect
    killall NotificationCenter
    
    
    ### per app notification settings
    # see seperate script
    
    
    
    
    
    ### hidden notification center tweaks
    
    # changing notification banner persistence time (value in seconds)
    #defaults write com.apple.notificationcenterui bannerTime 15
    
    # resetting default notification banner persistence time
    #defaults delete com.apple.notificationcenterui bannerTime
    
    
    
    ###
    ### preferences users & groups
    ###
    
    echo "preferences users & groups"
    
    # disable guest account login
    # false = disabled
    ##
    sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
    
    # disable allowing guests to connect to shared folders
    #sudo /usr/bin/defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool no
    #sudo /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool no
    
    
    ### login options
    
    # disable automatic login
    ##
    sudo defaults write /Library/Preferences/com.apple.loginwindow.plist autoLoginUser 0
    sudo defaults delete /Library/Preferences/com.apple.loginwindow.plist autoLoginUser
    
    # login window shows
    # false = list of users
    # true = name and password
    ##
    sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool false
    
    # show buttons on loginwindow
    # false = show, true = do not show
    ##
    sudo defaults write /Library/Preferences/com.apple.loginwindow ShutDownDisabled -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow RestartDisabled -bool false
    sudo defaults write /Library/Preferences/com.apple.loginwindow SleepDisabled -bool false
    
    # show input sources on loginwindow
    ##
    sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool false
    
    # password hints
    # disable
    ##
    sudo defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0
    # enable
    #sudo /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 3
    
    # menu for fast user switching
    ##
    sudo defaults write /Library/Preferences/.GlobalPreferences MultipleSessionEnabled -bool false
    
    
    ### accessibility settings for loginwindow
    # disable    
    sudo defaults write /Library/Preferences/com.apple.loginwindow UseVoiceOverAtLoginwindow -bool false
    sudo /usr/libexec/PlistBuddy -c "Delete :accessibilitySettings" /Library/Preferences/com.apple.loginwindow.plist 2> /dev/null
    
    # enable
    enable_accessibilty_login_window_settings() {
        sudo defaults write /Library/Preferences/com.apple.loginwindow UseVoiceOverAtLoginwindow -bool true
        sudo /usr/libexec/PlistBuddy -c "Delete :accessibilitySettings" /Library/Preferences/com.apple.loginwindow.plist 2> /dev/null
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings dict" /Library/Preferences/com.apple.loginwindow.plist 2> /dev/null
        # voiceover
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:voiceOverOnOffKey bool true" /Library/Preferences/com.apple.loginwindow.plist
        # zoom
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:closeViewHotkeysEnabled bool true" /Library/Preferences/com.apple.loginwindow.plist
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:closeViewScrollWheelToggle bool true" /Library/Preferences/com.apple.loginwindow.plist
        # keyboard
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:virtualKeyboardOnOff bool true" /Library/Preferences/com.apple.loginwindow.plist
        # one finger input
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:stickyKey bool true" /Library/Preferences/com.apple.loginwindow.plist
        # slower key response
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:slowKey bool true" /Library/Preferences/com.apple.loginwindow.plist
        # keyboard mouse input
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:mouseDriver bool true" /Library/Preferences/com.apple.loginwindow.plist
        # on off key
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:switchOnOffKey bool false" /Library/Preferences/com.apple.loginwindow.plist
        # timeout
        sudo /usr/libexec/PlistBuddy -c "Add :accessibilitySettings:dwellHideUITimeout integer 15" /Library/Preferences/com.apple.loginwindow.plist
    }
    #enable_accessibilty_login_window_settings
    
    # activating changes in gui
    sudo defaults read /Library/Preferences/com.apple.loginwindow.plist &> /dev/null
    
    
    ### current user
    
    # setting new user password
    # dscl . -passwd /Users/$USER
    
    # user is allowed to reset password with appleid from icloud
    # this is an option you select when activating filevault in preferences gui
    #sudo dscl . delete /Users/$USER AuthenticationAuthority ";AppleID;YOUR_APPLE_ID"
    #sudo dscl . append /Users/$USER AuthenticationAuthority ";AppleID;YOUR_APPLE_ID"
    # check
    #dscl . -read /Users/$USER AuthenticationAuthority
    
    # clicking the button in the system preferences modifies /var/db/dslocal/nodes/Default/users/$USER.plist
    # this checking won`t work with command above, it completele removes the button after appending and brings it back with deleting
    #sudo plutil -p /var/db/dslocal/nodes/Default/users/$USER.plist
    #sudo /usr/libexec/PlistBuddy -c "Print :'LinkedIdentity':'0'" /var/db/dslocal/nodes/Default/users/$USER.plist
    
    # user is admin
    # this option has to be selected when creating a user account
    # dscl . -merge /Groups/admin GroupMembership "$USER"
    
    # parental control
    # con not be enabled for an admin user account
    # add a non-admin user account and setup parental control
    
    
    ### current user startup items
    
    # listing startup-items
    #osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g'
    
    # deleting startup-items
    # osascript -e 'tell application "System Events" to delete login item "itemname"'
    
    # deleting all startup items
    env_delete_all_startup_items
    
    # adding startup-items
    AUTOSTART_ITEMS_ALL_USERS=(
    # name													                  start hidden
    # bartender is started in third party preferences script 
    #"Bartender 4                                                              false"
    "AudioSwitcher                                                            false"   
    "KeepingYouAwake                                                          false" 
    "Alfred 5                                                                 false" 
    "GeburtstagsChecker                                                       false" 
    "AppCleaner SmartDelete                                                   true" 
    #"TotalFinder                                                              false" 
    #"XtraFinder                                                               false"
    #"Quicksilver                                                              false"
    # bettertouchtool is started in third party preferences script 
    #"BetterTouchTool                                                          false" 
    "witchdaemon                                                              false" 
    "Better                                                                   false"
    # adguard and virusscanner helper are started via launchd in third party preferences script
    #"AdGuard Login Helper                                                     true"
    #"VirusScannerHelper                                                       true"
    # overflow autostart is activated at login inside the app preferences, this way the overflow window does not open when starting the app on login                 
    #"Overflow 3                                                               true"                    
    )
    AUTOSTART_ITEMS=$(printf "%s\n" "${AUTOSTART_ITEMS_ALL_USERS[@]}")
    env_add_startup_items
    
    # adding some more user specific startup-items
    if [[ "$AUTOSTART_ITEMS_USER_SPECIFIC" != "" ]]
    then
        AUTOSTART_ITEMS=$(printf "%s\n" "${AUTOSTART_ITEMS_USER_SPECIFIC[@]}")
        env_add_startup_items
    else
        :
    fi
    
    if [[ $(sysctl hw.model | grep "iMac11,2") != "" || $(sysctl hw.model | grep "iMac12,1") != "" ]] && [[ $(system_profiler SPStorageDataType | grep "Medium Type" | grep SSD) != "" ]]
    #if [[ $(system_profiler SPHardwareDataType | grep "Model Identifier" | grep "iMac11,2") != "" ]]
    then
        AUTOSTART_ITEMS=(
        # name													              start hidden
        "Macs Fan Control                                                     false"                     
        )
        env_add_startup_items
    else
    	:
    fi
    
    
    ### opening autostart apps    
    # 10.15 is not opening autostart apps on next boot after install/update without explicitly granting permissions or opening manually before autostart
    opening_autostart_apps() {
        echo "opening autostart apps to make them available after reboot"
        if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') != "" ]]
        then
                
            while IFS= read -r line || [[ -n "$line" ]]        
        	do
        	    if [[ "$line" == "" ]]; then continue; fi
                autostartapp="$line"
                echo "$autostartapp"
                APP_NAME="$autostartapp"
                env_set_open_on_first_run_permissions
                
                if [[ "$line" == "XtraFinder" ]]
        		then
        			osascript <<EOF
        			tell application "System Events"
        				tell application "XtraFinder" to activate
        				delay 3
        				tell application "System Events"
        					keystroke "w" using command down
        				end tell
        				delay 1
        			end tell
EOF
                env_active_source_app
                else
                    # foreground
                    #timeout 10 osascript -e "tell application \"$autostartapp\" to activate" &
                    # hidden
                    timeout 10 osascript -e "tell application \"$autostartapp\" to run" &
                    sleep 1
                    #osascript -e "tell application \"$autostartapp\" to quit"
                fi
                
            done <<< "$(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')"
            
            if [[ -e "/Users/"$USER"/Library/PreferencePanes/Witch.prefPane/Contents/Helpers/witchdaemon.app" ]]
            then
                #open /Users/"$USER"/Library/PreferencePanes/Witch.prefPane/Contents/Helpers/witchdaemon.app
                killall witchdaemon &> /dev/null
                sleep 1
                osascript -e "tell application \"/Users/"$USER"/Library/PreferencePanes/Witch.prefPane/Contents/Helpers/witchdaemon.app\" to activate" &
                #/Users/"$USER"/Library/PreferencePanes/Witch.prefPane/Contents/Helpers/witchdaemon.app/Contents/MacOS/witchdaemon
            else
                :
            fi
        else
            :
        fi
        sleep 1
        env_identify_terminal
        osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
    }
    #opening_autostart_apps
    
    echo "setting permissions for autostart apps to make them available after reboot"
    env_get_autostart_items
    env_check_if_parallel_is_installed 1>/dev/null
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
    then
        NUMBER_OF_MAX_JOBS_ROUNDED=$(parallel --number-of-cores)
        if [[ "${AUTOSTART_ITEMS[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "env_set_permissions_autostart_apps {}" ::: "${AUTOSTART_ITEMS[@]}"; fi
    else
        env_set_permissions_autostart_apps_sequential
    fi
    

    ###
    ### preferences screen time
    ###
    
    # enable (needs logout)
    #defaults write com.apple.ScreenTimeAgent ScreenTimeEnabled -bool true
    
    # disbale (needs logout)
    defaults write com.apple.ScreenTimeAgent ScreenTimeEnabled -bool false
    
    
    
    ###
    ### preferences extensions
    ###
    
    # finder
    defaults write pbs FinderActive -dict-add APPEXTENSION-com.apple.finder.CreatePDFQuickAction -bool true
    defaults write pbs FinderActive -dict-add APPEXTENSION-com.apple.finder.MarkupQuickAction -bool true
    defaults write pbs FinderActive -dict-add APPEXTENSION-com.apple.finder.RotateQuickAction -bool true
    defaults write pbs FinderActive -dict-add APPEXTENSION-com.apple.finder.TrimQuickAction -bool true
    
    

    ###
    ### preferences - security
    ###
    
    echo "preferences security"
    
    ### security general
    # password required after sleep
    sudo osascript -e 'tell application "System Events" to set require password to wake of security preferences to true'
    #sudo osascript -e 'tell application "System Events" to set require password to wake of security preferences to false'
    ### no longer working
    # https://stackoverflow.com/questions/45867402/macos-10-13-high-sierra-no-longer-stores-screensaver-settings-in-com-apple-scr
    # 0 = no, 1 = yes
    #defaults -currentHost write com.apple.screensaver askForPassword -int 0
    
    # set time in seconds to wait until password after sleep or screen saver is required
    # 0 = immediatelly, e.g. 300 = 5 min
    ##
    #defaults -currentHost write com.apple.screensaver askForPasswordDelay -int 300
    
    # activate & define text for lockscreen
    #sudo defaults write /Library/Preferences/com.apple.loginwindow "LoginwindowText" 'yourtextgoeshere'
    
    # deactivate text for lockscreen
    ##
    sudo defaults write /Library/Preferences/com.apple.loginwindow "LoginwindowText" ''
    
    #### security gate keeper
    
    # disable completely
    #sudo spctl --master-disable
    
    # enable only app store
    #sudo spctl --master-enable
    #sudo spctl --disable
    
    # enable app store and identified developers
    ##
    sudo spctl --master-enable
    sudo spctl --enable
    
    # using a gatekeeper whitelist
    #sudo spctl --add --label "GitHub" "$PATH_TO_APPS"/GitHub.app
    #spctl --enable --label "GitHub"
    #spctl --disable --label "GitHub"
    
    
    #### security file vault
    # enabling filevault
    enabling_filevault() {
        
        if [[ $(fdesetup isactive) == "true" ]]
        then
        	echo "filevault is already already turned on, skipping..."
        else
        	echo "enabling encryption of disk via filevault..."
        	FILEVAULT_KEYFILE="/Users/"$USER"/Desktop/filevault_key_"$USER".txt"
        	touch "$FILEVAULT_KEYFILE"
        	echo $(date) > "$FILEVAULT_KEYFILE"
        	echo "$USER" >> "$FILEVAULT_KEYFILE"
        	echo "filevault" >> "$FILEVAULT_KEYFILE"
        	TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
            TERMINALWIDTH_WITHOUT_LEADING_SPACES=$((TERMINALWIDTH-5))
		    FILEVAULTUSER="$USER"
            expect -c "
#log_user 0
#spawn sudo echo "$FILEVAULTUSER"
#expect \"Password:\"
#send \"$SUDOPASSWORD\r\"
spawn sudo fdesetup enable -user "$FILEVAULTUSER"
expect \"Password:\"
send \"$SUDOPASSWORD\r\"
expect \"Enter the password for user '$FILEVAULTUSER':\"
# default timeout is 10, accepting the input here often takes longer
set timeout 40
send \"$SUDOPASSWORD\r\"
#log_user 1
expect eof
" 2>&1 | grep key | tee -a "$FILEVAULT_KEYFILE"
# if grep from output does not work to get the key, use this alternative
#" 2>&1 | tee -a "$FILEVAULT_KEYFILE"
#sed -i '' '/^spawn sudo/d' "$FILEVAULT_KEYFILE"
#sed -i '' '/^Password:/d' "$FILEVAULT_KEYFILE"
#sed -i '' '/^Enter the/d' "$FILEVAULT_KEYFILE"

        	#sudo fdesetup enable -user "$USER" 2>&1 | tee -a "$FILEVAULT_KEYFILE"
        	# to generate and use a new key
        	#sudo fdesetup changerecovery -user "$USER" -personal >> "$FILEVAULT_KEYFILE"
        	sleep 1
        	if [[ $(cat "$FILEVAULT_KEYFILE" | grep key) == "" ]]
        	then
        	    echo "no filevault key found in keyfile, setting new key"
        	    sleep 1
        	    expect -c "
spawn sudo fdesetup changerecovery -user "$FILEVAULTUSER" -personal
expect \"Password:\"
send \"$SUDOPASSWORD\r\"
expect \"Enter the password for user '$FILEVAULTUSER':\"
# default timeout is 10, accepting the input here often takes longer
set timeout 40
send \"$SUDOPASSWORD\r\"
expect eof
" 2>&1 | grep key | tee -a "$FILEVAULT_KEYFILE"
# if grep from output does not work to get the key, use this alternative
#" 2>&1 | tee -a "$FILEVAULT_KEYFILE"
#sed -i '' '/^spawn sudo/d' "$FILEVAULT_KEYFILE"
#sed -i '' '/^Password:/d' "$FILEVAULT_KEYFILE"
#sed -i '' '/^Enter the/d' "$FILEVAULT_KEYFILE"
            else
                :
            fi
        	# to disable, run
        	#sudo fdesetup disable -user "$USER"
        	
        	# make sure the user password is set correctly
        	#sudo dscl . -passwd /Users/"$USER" "$SUDOPASSWORD"
        	
        fi
    }
    # this can not be enabled here because login will not work after a reboot if the sharing command is used after enabling_filevault (in this script done by public shared folder and sharing user)
    # this is why enabling_filevault is moved to the end of this script to avoid complications with other commands
    
    # automatic login with filevault enabled
    # enable
    #sudo defaults delete /Library/Preferences/com.apple.loginwindow DisableFDEAutoLogin
    # disable
    #sudo defaults write /Library/Preferences/com.apple.loginwindow DisableFDEAutoLogin -bool YES
    
    #### security firewall
    
    # turning on firewall
    sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
    
    # allow integrated signed apps
    sudo defaults write /Library/Preferences/com.apple.alf allowsignedenabled -int 1
    
    # allow downloaded signed apps
    sudo defaults write /Library/Preferences/com.apple.alf allowdownloadsignedenabled -int 1
    
    # disable stealth mode
    sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 0
    
    # enable logging
    #defaults write /Library/Preferences/com.apple.alf loggingenabled -bool true
    
    # restart firewall
    if [[ $(sudo launchctl list | grep com.apple.alf) == "" ]] > /dev/null 2>&1
    then
        :
    else
        sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.alf.agent.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
        sleep 2
    fi
    if [[ $(sudo launchctl list | grep com.apple.alf.useragent) == "" ]] > /dev/null 2>&1
    then
        :
    else
        sudo launchctl bootout system "/System/Library/LaunchAgents/com.apple.alf.useragent.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
        sleep 2
    fi
	sudo launchctl bootstrap system "/System/Library/LaunchDaemons/com.apple.alf.agent.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
	sudo launchctl bootstrap system "/System/Library/LaunchAgents/com.apple.alf.useragent.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
    sleep 2
	
    #### security privacy
    
    # disable location services
    ##
    sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.locationd.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
    sleep 2
    #sudo defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$uuid1 LocationServicesEnabled -int 0
    sudo defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 0
    sudo chown -R _locationd:_locationd /var/db/locationd
    sudo launchctl bootstrap system "/System/Library/LaunchDaemons/com.apple.locationd.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
    #sudo -u _locationd defaults write -currentHost com.apple.locationd.plist LocationServicesEnabled -int 0

    # disable sending diagnostics data to apple
    ##
    defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmit -bool false
    defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" SeedAutoSubmit -bool false
    defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" AutoSubmitVersion -integer 4
    
    # disable sending siri diagnostics data to apple
    # 1 = enabled
    # 2 = disabled
    defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -integer 2
    
    # disable sending diagnostics data to developers
    ##
    defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" ThirdPartyDataSubmit -bool false
    defaults write "/Library/Application Support/CrashReporter/DiagnosticMessagesHistory.plist" ThirdPartyDataSubmitVersion -integer 4
    
    # disable sending icloud diagnostics data
    # only has to be done one time ever in the system preferences - security - privacy
    # or go to 
    # appleid.apple.com 
    # privacy
    # settings for data privacy
    # disable share icloud analytics data
    
    # no add tracking
    # true = no tracking
    # does not stay activated
    #defaults write com.apple.AdLib.plist forceLimitAdTracking -bool true
    
    no_add_tracking() {
    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    
    tell application "System Preferences"
    	activate
    	#set paneids to (get the id of every pane)
    	#display dialog paneids
    	#return paneids
    	#set current pane to pane "com.apple.preference.security"
    	#get the name of every anchor of pane id "com.apple.preference.security"
    	#set tabnames to (get the name of every anchor of pane id "com.apple.preference.security")  	
    	#return tabnames
    	reveal anchor "Privacy" of pane id "com.apple.preference.security"
    	delay 4
    end tell

    tell application "System Events" to tell process "System Preferences" to set visible to true
    delay 1
    tell application "System Events" to tell process "System Preferences" to set frontmost to true
    delay 1
        
    tell application "System Events"
    	tell process "System Preferences"
    		# resolution standard
    		#select row 21 of table 1 of scroll area 1 of tab group 1 of window 1
    		#select last row of table 1 of scroll area 1 of tab group 1 of window 1
    		select row -2 of table 1 of scroll area 1 of tab group 1 of window 1
    		delay 1
    	end tell
    end tell
    
    tell application "System Events"
    	tell process "System Preferences"
    		set theCheckbox to (checkbox 1 of group 1 of tab group 1 of window 1)
    		tell theCheckbox
    			set checkboxStatus to value of theCheckbox as boolean
    			if checkboxStatus is true then click theCheckbox
    		end tell
    		delay 0.2
    		#click checkbox 1 of group 1 of tab group 1 of window 1
    	end tell
    end tell
    
    delay 2
    
    tell application "System Preferences"
    	quit
    end tell
    
EOF
    }
    no_add_tracking
    
    ### security more options
    # autologout on inactivity
    sudo defaults write /Library/Preferences/.GlobalPreferences.plist com.apple.autologout.AutoLogOutDelay -int 0
    
    # require an administrator password to access system-wide preferences
    sudo security authorizationdb read system.preferences > /tmp/system.preferences.plist
    sleep 0.5
    # enabled = false
    # disabled = true
    #sudo /usr/libexec/PlistBuddy -c "Add :shared bool" /tmp/system.preferences.plist
    sudo /usr/libexec/PlistBuddy -c "Set :shared false" /tmp/system.preferences.plist
    sleep 0.5
    #defaults read /tmp/system.preferences.plist
    #(sudo security authorizationdb write "$i" < /tmp/"$i".plist) 2>&1 | grep -v "YES (0)"
    # Error Domain=NSCocoaErrorDomain Code=3840 "Cannot parse a NULL or zero-length data" UserInfo={NSDebugDescription=Cannot parse a NULL or zero-length data}
    # that occurs due to the changed sudo command env_sudo
    #( env_use_password | exec sudo -p '' -S "$SCRIPT_INTERPRETER" -c "security authorizationdb write system.preferences < /tmp/system.preferences.plist" )
    #sudo security authorizationdb write system.preferences < /tmp/system.preferences.plist
    sudo -S "$SCRIPT_INTERPRETER" -c "security authorizationdb write system.preferences < /tmp/system.preferences.plist"      
    #sudo security authorizationdb read system.preferences
    sleep 0.5
        
    ###
    ### preferences software update
    ###
    
    echo "preferences mac app store"
    
    # to enable the checkbox "automatically update my mac" just set all options below to true 
    
    # enable or disbale automatic update check
    sudo softwareupdate --schedule on
    #sudo softwareupdate --schedule off
    # or
    #sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    #sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
    
    # download updates automatically in the background
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
    
    # install app updates from appstore automatically
    ##
    sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
    
    # install macos updates automatically
    ##
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
    
    # install system and security updates automatically
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool false
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
    
    ### appstore
    
    # install app updates from appstore automatically
    # set above in software update
    
    # automatically install bought apps on other macs
    # sets the correct value but doesn`t set the marker in the gui
    # don`t know if setting this value is enough for it to work
    # seems like the setting is only to set once on one mac in the gui and is send to other macs connected to the same icloud account automatically so it doesn`t have to be set for a clean reinstall
    #APPSTOREACCOUNTIDS=$(defaults read com.apple.commerce.plist autopush-registered-dsids | grep -v '{' | grep -v '}' | awk '{print $1}' | cat )
    #for i in $APPSTOREACCOUNTIDS
    #do
    #	/usr/libexec/PlistBuddy -c "Set autopush-registered-dsids:${i} 0" ~/Library/Preferences/com.apple.commerce.plist
    #done
    
    # auto play appstore videos
    defaults write ~/Library/Preferences/com.apple.AppStore.plist AutoPlayVideoSetting -string "off"
    defaults write ~/Library/Preferences/com.apple.AppStore.plist UserSetAutoPlayVideoSetting -bool true
    # if this setting is needed then a reboot seems to be needed, too
    #defaults write ~/Library/Containers/com.apple.AppStore/Data/Library/Preferences/com.apple.appstore.plist AutoPlayVideoSetting -string "off"
    
    # in app reviews (needs reboot)
    defaults write com.apple.AppStore.plist InAppReviewEnabled -bool false

    ### hidden appstore tweaks
    
    # check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
    
    # enable the webkit developer tools in the mac app store
    #defaults write com.apple.appstore WebKitDeveloperExtras -bool true
    
    # enable debug menu in the mac app store
    #defaults write com.apple.appstore ShowDebugMenu -bool true
    
    
    
    ###
    ### preferences network
    ###
    
    # see separate script



    ###
    ### preferences bluetooth
    ###
    
    # show bluetooth in menu bar
    # see "menu bar"   
    
    # open bluetooth assistant on boot if no keyboard is detected
    ##
    #sudo defaults write /Library/Preferences/com.apple.Bluetooth.plist BluetoothAutoSeekKeyboard -bool true
    
    # open bluetooth assistant on boot if no mouse or trackpad is detected
    ## 
    #sudo defaults write /Library/Preferences/com.apple.Bluetooth BluetoothAutoSeekPointingDevice -bool true
    
    # if disabling via -bool false does not work if sip (partially) disabled
    #sudo mv "/System/Library/CoreServices/Bluetooth Setup Assistant.app" "/System/Library/CoreServices/Bluetooth Setup Assistant.dissabled.app"

    # allow bluetooth devices to wake up the mac
    defaults -currentHost write ~/Library/Preferences/ByHost/com.apple.Bluetooth RemoteWakeEnabled -boolean true



    ###
    ### preferences - sound
    ###
    
    echo "preferences sound"
    
    ### select an alert sound "Sosumi"
    #defaults write NSGlobalDomain com.apple.sound.beep.sound -string "/System/Library/Sounds/Sosumi.aiff"
    
    # play sound on boot
    # see nvram script
    
    ### play user interface sound effects
    # 1 = yes, 0 = no
    defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -int 1
    
    # feedback sound when changing volume
    # 1 = yes, 0 = no
    defaults write NSGlobalDomain com.apple.sound.beep.feedback -integer 1
    
    # show sound in menu bar
    # see "menu bar section above"    
    
    ### hidden sound tweaks
    
    # increase sound quality for Bluetooth headphones/headsets
    #defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
    


    ###
    ### preferences keyboard
    ###
    
    echo "preferences keyboard"
    
    
    ### keyboard
    
    # Set keyboard repeat rate
    defaults write NSGlobalDomain InitialKeyRepeat -int 25
    defaults write NSGlobalDomain KeyRepeat -int 6
    
    # adjust keyboard brightness in low light
    ##
    sudo defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Keyboard Enabled" -bool true
    
    # deactivate keyboard light if computer is inactive
    # -1 = never
    ##
    sudo defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Keyboard Dim Time" -int -1
    
    # if mac has touchbar, configure more settings
    if [[ $(pgrep "ControlStrip") != "" ]]
    then
        #echo "touchbar is present"
        
        # touchbar without fn keys
        # fullControlStrip
        # app
        # functionKeys
        defaults write com.apple.touchbar.agent PresentationModeGlobal -string functionKeys
        
        # touchbar when pressing fn
        # fullControlStrip
        # app
        defaults write com.apple.touchbar.agent PresentationModeFnModes -dict-add functionKeys -string fullControlStrip
        
        # activating settings
        killall ControlStrip
        
    else
        #echo "no touchbar present"
        :
    fi
    
    
    # use all F1, F2, etc. keys as standard function keys
    # 1=yes, 0=no
    defaults write NSGlobalDomain com.apple.keyboard.fnState -int 1
    
    
    ### text
    
    # auto-correct spelling
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    
    # auto capitalization
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    
    # substitute double space with dot and space
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    
    # touchbar suggestions
    defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false
        
    # smart quotes
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    
    # smart dashes
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    
    
    ### shortcuts
    # enable switch focus with keyboard
    # 2 = enable
    # 0 = disable
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
    
    
    ### input sources
    update_keyboard_layout() {
        while IFS= read -r line || [[ -n "$line" ]]
        do
            if [[ "$line" == "" ]]; then continue; fi
            CONFIG_VALUE="$line"
            ${PERMISSION} ${PLBUDDY} -c "Delete :"${CONFIG_VALUE}"" "$KEYBOARD_CONFIG_FILE" 2> /dev/null
            ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}" array" "$KEYBOARD_CONFIG_FILE"
            ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0 dict" "$KEYBOARD_CONFIG_FILE"
            ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0:InputSourceKind string 'Keyboard Layout'" "$KEYBOARD_CONFIG_FILE"
            ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0:'KeyboardLayout ID' integer "${KEYBOARD_LAYOUT}"" "$KEYBOARD_CONFIG_FILE"
            ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0:'KeyboardLayout Name' string '"${KEYBOARD_LOCALE}"'" "$KEYBOARD_CONFIG_FILE"
        done <<< "$(printf "%s\n" "${KEYBOARD_CONFIG_VALUES[@]}")"
    }
    
    # variables
    KEYBOARD_LOCALE="German"
    # 3 = QUERTZ
    KEYBOARD_LAYOUT="3"
    
    # system
    PERMISSION='sudo'
    PLBUDDY='/usr/libexec/PlistBuddy'
    KEYBOARD_CONFIG_FILE="/Library/Preferences/com.apple.HIToolbox.plist"
    KEYBOARD_CONFIG_VALUES=(
    "AppleDefaultAsciiInputSource"
    "AppleEnabledInputSources"
    )
    update_keyboard_layout "$KEYBOARD_CONFIG_FILE" "${KEYBOARD_LOCALE}" "${KEYBOARD_LAYOUT}" 2>&1 | grep -v "Will Create"
    #sudo chmod 644 "$KEYBOARD_CONFIG_FILE"
    #sudo chown root:wheel "$KEYBOARD_CONFIG_FILE"

    # user
    PERMISSION=''
    PLBUDDY='/usr/libexec/PlistBuddy'
    KEYBOARD_CONFIG_FILE="/USERS/$USER/Library/Preferences/com.apple.HIToolbox.plist"
    KEYBOARD_CONFIG_VALUES=(
    "AppleEnabledInputSources" 
    "AppleSelectedInputSources"
    )
    ${PERMISSION} ${PLBUDDY} -c "Delete :AppleCurrentKeyboardLayoutInputSourceID" "$KEYBOARD_CONFIG_FILE" 2> /dev/null
    ${PERMISSION} ${PLBUDDY} -c "Add :AppleCurrentKeyboardLayoutInputSourceID string com.apple.keylayout."${KEYBOARD_LOCALE}"" "$KEYBOARD_CONFIG_FILE"
    update_keyboard_layout "$KEYBOARD_CONFIG_FILE" "${KEYBOARD_LOCALE}" "${KEYBOARD_LAYOUT}"
    #chmod 644 "$KEYBOARD_CONFIG_FILE"
    #chown "$USER":staff "$KEYBOARD_CONFIG_FILE"
    
    # show input source in menu bar
    defaults write com.apple.TextInputMenu visible -bool false

    
    ### dictation
    defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMMasterDictationEnabled -bool false
    # advanced dictation
    defaults write com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMUseOnlyOfflineDictation -bool false
    # hotkeys
    # ~/Library/Preferences/com.apple.symbolichotkeys.plist
    # see dashboard above
    
    
    ### hidden keyboard tweaks
    
    # disable press-and-hold for keys in favor of key repeat
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    
    # enable full keyboard access for all controls
    # (e.g. enable tab in modal dialogs)
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3



    ###
    ### preferences mouse & trackpad keyboard, bluetooth accessories, and input
    ###
    
    echo "preferences mouse & trackpad"
    
    ### mouse
    
    # secondary mouse click
    # possible values: OneButton, TwoButton, TwoButtonSwapped
    if [[ "$MOUSE_BUTTON_MODE" != "" ]]
    then
        defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string "$MOUSE_BUTTON_MODE"
    else
        defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string OneButton
    fi
    
    ### trackpad
    # included in macbook is com.apple.AppleMultitouchTrackpad
    # bluetooth trackpad would be com.apple.driver.AppleBluetoothMultitouch.trackpad
    
    # trackpad secondary click

    # how to right click
    defaults write NSGlobalDomain ContextMenuGesture -int 1
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
    # 0 = two finger click
    defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
    # 1 = click left bottom corner of trackpad
    #defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 1
    # eventually this is needed to deactivate two finder click
    #defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool false
    # 2 = click right bottom corner of trackpad
    #defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 2
    # eventually this is needed to deactivate two finder click
    #defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool false

    # trackpad: enable tap to click for this user and for the login screen
    #defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    #defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    # 0 = disbled
    # 1 = enabled
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0
    
    # haptic feedback for force touch
    # 0 = light
    # 1 = medium
    # 2 = firm
    defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
    defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1    
    
    # trackpad cursor speed
    defaults write NSGlobalDomain com.apple.trackpad.scaling -float 0.875
    
    # mouse cursor speed
    # 0-5 with 5 being the fastest
    defaults write -g com.apple.mouse.scaling 0.875
    # default mouse cursor speed
    # defaults delete -g com.apple.mouse.scaling    
    
    # force click and haptic feedback
    #defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true
    #defaults write com.AppleMultitouchTrackpad ActuateDetents -bool true
    # true = force klick off
    # fallse = force klick on
    defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool true
    
    # disable "natural" scrolling
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    
    # trackpad: map bottom right corner to right-click
    #defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
    #defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    #defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
    #defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
    
    # use scroll gesture with the Ctrl (^) modifier key to zoom
    #defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
    #defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
    # follow the keyboard focus while zoomed in
    #defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true
    
    # disable smooth scrolling
    #defaults write -g AppleScrollAnimationEnabled -bool false
    #defaults write -g NSScrollAnimationEnabled -bool false
            
    
    
    ###
    ### preferences - displays
    ###
    
    echo "preferences displays"
    
    # nnable HiDPI display modes (requires restart) for non retina displays
    #sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
    
    # settings display scale factor (1 = 100%)
    # does not work for me in 10.11
    #defaults write NSGlobalDomain AppleDisplayScaleFactor 0.75
    
    # monitor preferences
    monitor_preferences() {
    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    
    tell application "System Preferences"
    	activate
    	#set paneids to (get the id of every pane)
    	#display dialog paneids
    	#return paneids
    	#set current pane to pane "com.apple.preference.displays"
    	#get the name of every anchor of pane id "com.apple.preference.displays"
    	#set tabnames to (get the name of every anchor of pane id "com.apple.preference.displays")
    	#display dialog tabnames
    	#return tabnames
    	reveal anchor "displaysDisplayTab" of pane id "com.apple.preference.displays"
    	delay 4
    end tell
    
    tell application "System Events" to tell process "System Preferences" to set visible to true
    delay 1
    tell application "System Events" to tell process "System Preferences" to set frontmost to true
    delay 1
    
    tell application "System Events"
    	tell process "System Preferences"
    		# resolution standard
    		click radio button 1 of radio group 1 of group 1 of window 1
    		delay 1
    	end tell
    end tell
    
    tell application "System Events"
    	tell process "System Preferences"
    		# enable adjust brightness automatically
    		if exists checkbox 1 of group 1 of window 1 then
    			set theCheckbox to (checkbox 1 of group 1 of window 1)
    			tell theCheckbox
    				set checkboxStatus to value of theCheckbox as boolean
    				if checkboxStatus is false then click theCheckbox
    			end tell
    		end if
    		delay 1
    		# enable true tone
    		if exists checkbox 2 of group 1 of window 1 then
    			set theCheckbox to (checkbox 2 of group 1 of window 1)
    			tell theCheckbox
    				set checkboxStatus to value of theCheckbox as boolean
    				if checkboxStatus is false then click theCheckbox
    			end tell
    		end if
    		delay 1
    	end tell
    end tell
    
    delay 2
    
    tell application "System Preferences"
    	quit
    end tell
    
EOF
    }
    monitor_preferences
    
    # display - automatically adjust brightness
    ##
    #sudo defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Display Enabled" -bool false
    
    # show monitor sync options in menu bar if available
    ##
    defaults write com.apple.airplay showInMenuBarIfPresent -bool true
    
    # night shift
    # controlled in /S*/L*/PrivateFrameworks/CoreBrightness.framework/CoreBrightness
    # https://github.com/jenghis/nshift
    # https://github.com/leberwurstsaft/nshift      (binary)
    # binary usage
    # nshift.dms strength (0-100)
    # nshift.dms on
    # nshift.dms off
    # nshift.dms reset
    # or
    # https://justgetflux.com



    ###
    ### preferences - printer
    ###
    
    echo "preferences printer"
    
    DEFAULTS_WRITE_DIR="$SCRIPT_DIR_TWO_BACK"
    if [[ -e "$DEFAULTS_WRITE_DIR"/_scripts_input_keep/printer/printer_data.sh ]]
    then
    
        # variables
        #PRINTER_NAME="NAME_HERE"
        #PRINTER_URL="ipp://IP_HERE/ipp/print"
        #PRINTER_URL="ipps://IP_HERE:443/ipp/print"
        # if ppd is commented out here and in printer_data.sh ipp everywhere is used
        #PRINTER_PPD="PATH_TO_PPD_GZ_FILE_HERE"
        
        # sourcing variables
        . "$DEFAULTS_WRITE_DIR"/_scripts_input_keep/printer/printer_data.sh
        
        # backing up printer config
        if [[ -e "/Users/"$USER"/Library/Preferences/com.apple.print.custompresets.forprinter."$PRINTER_NAME".plist" ]]
        then
        	#echo ''
        	echo "backing up printer preferences for "$PRINTER_NAME"..."
        	cp -a "/Users/"$USER"/Library/Preferences/com.apple.print.custompresets.forprinter."$PRINTER_NAME".plist" "/tmp/com.apple.print.custompresets.forprinter."$PRINTER_NAME".plist"
        else
        	:
        fi
        
        # deleting old printer/config
        if lpstat -p &>/dev/null
        then
        	if [[ $(lpstat -p | grep "$PRINTER_NAME") != "" ]]
        	then
        		#echo ''
        		echo "deleting old printer "$PRINTER_NAME"..."
        		lpadmin -x "$PRINTER_NAME"
        		sleep 1
        	else
        		:
        	fi
        else
        	:
        fi
        
        # restoring printer config if needed
        if [[ -e "/Users/"$USER"/Library/Preferences/com.apple.print.custompresets.forprinter."$PRINTER_NAME".plist" ]]
        then
        	:
        else
        	#echo ''
        	echo "restoring printer preferences for "$PRINTER_NAME"..."
        	cp -a "/tmp/com.apple.print.custompresets.forprinter."$PRINTER_NAME".plist" "/Users/"$USER"/Library/Preferences/com.apple.print.custompresets.forprinter."$PRINTER_NAME".plist"
        fi
        
        # adding printer printer/config
        #echo ''
        echo "adding printer "$PRINTER_NAME"..."
        # more options can be set via -o
        # -P option will be deprecated in a future cups release
        # lpadmin: Printer drivers are deprecated and will stop working in a future version of CUPS. 
        # man lpadmin on a macos >=10.15 for more details
        # recommends to use -m everywhere instead
        # -p seems to set the printer name in cups file, but does not show the correct name in system preferences
        # adding -D for setting printer info in cups file sets the correct printer name in system preferences
        # lpinfo -v
        # lpinfo -m
        # lpinfo --make-and-model "PART_OF_PRINTER_NAME" -m
        # listing printer attributes
        # ipptool -tv "$PRINTER_URL" get-printer-attributes.test | grep -i color
        # lpoptions -l | grep Color
        
        if [[ "$PRINTER_PPD" != "" ]] && [[ -e "$PRINTER_PPD" ]]
        then
        	#echo ''
        	echo "checking last change of printer driver..."
        	ls -la "$PRINTER_PPD"
        	#echo ''
	        echo "installing printer using driver..."
        	lpadmin -E -p "$PRINTER_NAME" -v "$PRINTER_URL" -P "$PRINTER_PPD" -o printer-is-shared=false
        else
        	#echo ''
	        echo "installing printer driverless using ipp everywhere..."
        	# only works if the printer is available via the given ipp address
        	lpadmin -E -p "$PRINTER_NAME" -D "$PRINTER_NAME" -v "$PRINTER_URL" -m everywhere -o printer-is-shared=false &>/dev/null
        fi
        # check if printer was added successfully
        if [[ $? -eq 0 ]]
    	then
        	# successful
        	echo "printer "$PRINTER_NAME" added successfully..."
        	cupsenable "$PRINTER_NAME"
    		cupsaccept "$PRINTER_NAME"
    	else
        	# failed
        	echo "adding "$PRINTER_NAME" printer failed, please check if the printer is available on the network..." >&2
        	if [[ "$PRINTER_INSTALL_SCRIPT_PATH" != "" ]] && [[ -e "$PRINTER_INSTALL_SCRIPT_PATH" ]]
        	then
        	    cp -a "$PRINTER_INSTALL_SCRIPT_PATH" ~/Desktop/
        		echo "printer install script copied to desktop for later usage..." >&2
        	else
                :
        	fi
    	fi

    else
    	echo ""$DEFAULTS_WRITE_DIR"/script_input_keep/printer/printer_data.sh not found, skipping reinstalling printer..."
    fi
    
    
    
    ###
    ### preferences - sidecar
    ###
    
    echo "preferences sidecar"
    
    ### sidebar
    # disable sidebar
    #defaults delete com.apple.sidecar.display sidebarRight &> /dev/null
    #defaults write com.apple.sidecar.display sidebarShown -bool false
    
    # show sidebar left
    defaults delete com.apple.sidecar.display sidebarRight &> /dev/null
    defaults write com.apple.sidecar.display sidebarShown -bool true
    
    # show sidebar right
    #defaults write com.apple.sidecar.display sidebarRight -bool true
    #defaults write com.apple.sidecar.display sidebarShown -bool true
    
    
    ### touchbar
    # disable touchbar
    #defaults delete com.apple.sidecar.display touchBarTop &> /dev/null
    #defaults write com.apple.sidecar.display showTouchbar -bool false    
    
    # show touchbar bottom
    #defaults delete com.apple.sidecar.display touchBarTop &> /dev/null
    #defaults write com.apple.sidecar.display showTouchbar -bool true
    
    # show touchbar top
    defaults write com.apple.sidecar.display touchBarTop -bool true
    defaults write com.apple.sidecar.display showTouchbar -bool true


    ### double tap on apple pencil
    defaults write com.apple.sidecar.display doubleTapEnabled -bool false
    
    

    ###
    ### preferences - battery
    ###
    
    echo "preferences battery"
    
    # checking current settings
    #pmset -g
    #sudo systemsetup -getsleep
    #sudo systemsetup -getwakeonnetworkaccess
    
    # automatic graphics switching
    # 0 = integrated (less powerfull)
    # 1 = dedicated (separate graphics card)
    # 2 = auto switch (default)
    if [[ "$GPU_SWITCH" != "" ]]
    then
        sudo pmset -a gpuswitch "$GPU_SWITCH"
    else
        :
    fi
    
    # set standbydelay on battery and ac power delay to 10 min (default is 3 hours = 10800), set in seconds
    #sudo pmset -a standbydelay 600
    
    # halfdim - display sleep will use an intermediate half-brightness state between full brightness and fully off (boolean)
    # 0 = off
    # 1 = on
    
    # on battery
    sudo pmset -b sleep 20 disksleep 15 displaysleep 10 halfdim 1
    
    # on power adapter
    sudo pmset -c sleep 20 disksleep 15 displaysleep 10 halfdim 1
    
    # disable automatic sleep when display off on battery (should only be used with disksleep 0)
    #sudo pmset -b sleep 0
    
    # disable disc sleep on ac power on battery (should only be used with sleep 0)
    #sudo pmset -b disksleep 0
    
    # slightly turn down display brightness when on battery
    # 1=yes, 0=no
    sudo pmset -b lessbright 0
    sudo pmset -c lessbright 0
    
    # activate powernap on battery power
    # 1=yes, 0=no
    #sudo pmset -b darkwakes 1
    #sudo /usr/libexec/PlistBuddy -c 'Set "Custom Profile":"Battery Power":DarkWakeBackgroundTasks bool true' /Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist
    
    # disable automatic sleep when display off on ac power (should only be used with disksleep 0)
    #sudo pmset -c sleep 0
    
    # disable disc sleep on ac power (should only be used with sleep 0)
    #sudo pmset -c disksleep 0
    
    # wake on lan over wifi on ac power
    sudo pmset -c womp 0
    
    # deactivate powernap on ac power
    sudo pmset -c darkwakes 0
    #sudo /usr/libexec/PlistBuddy -c 'Set "Custom Profile":"AC Power":DarkWakeBackgroundTasks bool false' /Library/Preferences/SystemConfiguration/com.apple.PowerManagement.plist
    
    # optimize videostreaming when on battery
    ##
    # 0 = disabled
    # 1 = enabled
    sudo defaults write /Library/Preferences/.GlobalPreferences.plist com.apple.coremedia.optimizeVideoStreamingOnBattery -int 0

    # optimized battery charging
    ##
    # needs reboot to take effect
    sudo defaults write com.apple.smartcharging.topoffprotection enabled -bool false
    #sudo defaults write com.apple.smartcharging.topoffprotection currentState -int 1

    # battery state
    ## options for battery health
    # 0 = enabled
    # 1 = disabled
    sudo pmset -a VACTDisabled 0



    ###
    ### preferences date & time
    ###
    
    echo preferences "date & time"
    
    ### date & time
    
    # set date and time automatically
    sudo systemsetup -setusingnetworktime on
    
    # set time server
    #sudo systemsetup -getnetworktimeserver
    # use default by not setting anything else
    sudo systemsetup -setnetworktimeserver time.apple.com
    
    
    ### timezone
    
    # set time zone automatically using current location
    sudo defaults write /Library/Preferences/com.apple.timezone.auto.plist Active -bool false
    
    # set the timezone; see "systemsetup -listtimezones" for other values
    sudo systemsetup -settimezone "Europe/Berlin"
    
    
    ### clock
    
    # show date and time in menu bar
    # see "menu bar"
    
    # time options: display the time with seconds: off
    # date options: show the day of the week: on
    # date options: show date: on
    # menu bar clock format
    # "h:mm" default
    # "HH"   use a 24-hour clock
    # "a"    show AM/PM
    # "ss"   display the time with seconds
    defaults write com.apple.menuextra.clock 'DateFormat' -string 'EEE MMM d   HH:mm'
    
    # analog menu bar clock
    ##
    #defaults write com.apple.menuextra.clock IsAnalog -bool false
    defaults write com.apple.menuextra.clock IsAnalog -bool true
    
    # flash the time separators
    ##
    defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
    
    # set 24 hour clock
    ##
    defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
    
    # date options
    # see above, included in time options
    
    # time announcement
    if [[ ! -e ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist ]]
    then
        /usr/libexec/PlistBuddy -c "Add TimeAnnouncementPrefs:TimeAnnouncementsEnabled bool" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist > /dev/null 2>&1
    else
        :
    fi

    if [[ -z $(/usr/libexec/PlistBuddy -c "Print TimeAnnouncementPrefs:TimeAnnouncementsEnabled" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist) ]] > /dev/null 2>&1
    then
        /usr/libexec/PlistBuddy -c "Add TimeAnnouncementPrefs:TimeAnnouncementsEnabled bool" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
        /usr/libexec/PlistBuddy -c "Set TimeAnnouncementPrefs:TimeAnnouncementsEnabled false" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    else
        /usr/libexec/PlistBuddy -c "Set TimeAnnouncementPrefs:TimeAnnouncementsEnabled false" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    fi
    #/usr/libexec/PlistBuddy -c "Set TimeAnnouncementPrefs:TimeAnnouncementsIntervalIdentifier EveryHourInterval" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    #/usr/libexec/PlistBuddy -c "Set TimeAnnouncementPrefs:TimeAnnouncementsPhraseIdentifier ShortTime" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    
    # time announcement voice config
    # custom speed
    #/usr/libexec/PlistBuddy -c "Add TimeAnnouncementPrefs:TimeAnnouncementsVoiceSettings:CustomRelativeRate integer" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    #/usr/libexec/PlistBuddy -c "Set TimeAnnouncementPrefs:TimeAnnouncementsVoiceSettings:CustomRelativeRate 1" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    
    #custom volume 
    #/usr/libexec/PlistBuddy -c "Add TimeAnnouncementPrefs:TimeAnnouncementsVoiceSettings:CustomVolume integer" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
    #/usr/libexec/PlistBuddy -c "Set TimeAnnouncementPrefs:TimeAnnouncementsVoiceSettings:CustomVolume 0.5" ~/Library/Preferences/com.apple.speech.synthesis.general.prefs.plist
        
    
    
    ###
    ### preferences sharing
    ###
    
    echo "preferences sharing"
    
    MY_HOSTNAME=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F":" '{print $2}' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed -e 's/ //g' | sed 's/^/'"$USER"'s-/g')    
    if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "macintosh_hd2" ]]
    then
        MY_HOSTNAME=$(echo "$MY_HOSTNAME" | sed 's/$/2/g') 
    else
        :
    fi
    #echo "$MY_HOSTNAME"
    
    # set computer name (as done via system preferences - sharing)
    if [[ "$MY_HOSTNAME" == "" ]]
    then
        echo 'only numbers, characters [a-zA-Z] and '-' are allowed...'
        read -p "Enter new hostname: " MY_HOSTNAME
    else
        echo "setting hostname to "$MY_HOSTNAME""
    fi
    
    sudo scutil --set ComputerName "$MY_HOSTNAME"
    sudo scutil --set LocalHostName "$MY_HOSTNAME"
    sudo scutil --set HostName "$MY_HOSTNAME"
    #sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$MY_HOSTNAME"
    dscacheutil -flushcache
    unset MY_HOSTNAME
    
    # screen sharing
    # enable
    if [[ $(sudo launchctl list | grep com.apple.screensharing) == "" ]] > /dev/null 2>&1
    then
        sudo launchctl enable system/com.apple.screensharing
        sudo launchctl bootstrap system "/System/Library/LaunchDaemons/com.apple.screensharing.plist" 2>&1 | grep -v "in progress" | grep -v "already bootstrapped"
    else
        :
    fi

    # ask for permission to share screen
    # enable
    sudo defaults write /Library/Preferences/com.apple.RemoteManagement.plist ScreenSharingReqPermEnabled -bool true
	#sleep 2
	# disable
	#if [[ $(sudo launchctl list | grep com.apple.screensharing) == "" ]] > /dev/null 2>&1
    #then
    #    :
    #else
	#    sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.screensharing.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	#    sleep 2
	#	sudo launchctl disable system/com.apple.screensharing
	#fi
    
    # turn off file sharing
    # deactivate smb file server
    ##
    if [[ $(sudo launchctl list | grep com.apple.smbd) == "" ]] > /dev/null 2>&1
    then
        :
    else
    	sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.smbd.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	    sleep 2
		sudo launchctl disable system/com.apple.smbd
    fi
    
    # deactivate afp file server
    ##
    if [[ $(sudo launchctl list | grep com.apple.AppleFileServer) == "" ]] > /dev/null 2>&1
    then
        :
    else
    	sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.AppleFileServer.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	    sleep 2
		sudo launchctl disable system/com.apple.AppleFileServer
    fi
    
    # turn off internet sharing
    if [[ $(sudo launchctl list | grep com.apple.InternetSharing) == "" ]] > /dev/null 2>&1
    then
        :
    else
    	sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.InternetSharing.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	    sleep 2
		sudo launchctl disable system/com.apple.InternetSharing
    fi
    
    # removing public share
    if [[ $(sudo sharing -l | grep /Users/$USER/Public) != "" ]]
    then
        PUBLIC_SHARED_FOLDER=$(sudo sharing -l | grep "name:" | grep "$USER" | head -n 1 | cut -f 2- | perl -p -e 's/^[\ \t]//')
        #PUBLIC_SHARED_FOLDER=$(sudo sharing -l | grep "name:" | head -n 1 | cut -f 2- | perl -p -e 's/^[\ \t]//')
    	sudo sharing -r "$PUBLIC_SHARED_FOLDER"
    else
    	:
    fi
    
    creating_sharing_user() {
        echo ''
        echo creating macos sharinguser...
        echo ''
        echo "please set sharinguser password..."
        sharinguser_password="    "
        while [[ "$sharinguser_password" != "$sharinguser_password2" ]] || [[ "$sharinguser_password" == "" ]]; do stty -echo && trap 'stty echo' EXIT && printf "sharinguser password: " && read -r "$@" sharinguser_password && printf "\n" && printf "re-enter sharinguser password: " && read -r "$@" sharinguser_password2 && stty echo && trap - EXIT && printf "\n" && USE_SHARINGUSER_PASSWORD='builtin printf '"$sharinguser_password\n"''; done
        
        # deleting user (if existing)
        if [[ $(dscl . list /Users | grep sharinguser) != "" ]]
        then
        	sudo dscl . delete /Users/sharinguser
        else
        	:
        fi    
        
        # creating user
        sudo dscl . create /Users/sharinguser
        sudo dscl . create /Users/sharinguser RealName "sharinguser"
        sudo dscl . create /Users/sharinguser hint "none"
        #sudo dscl . create /Users/sharinguser picture "/Path/To/Picture.png"
        sudo dscl . passwd /Users/sharinguser $sharinguser_password
        export LastID=`dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1`
        export NextID=$((LastID + 1))
        #echo $NextID
        sudo dscl . create /Users/sharinguser UniqueID $NextID
        sudo dscl . create /Users/sharinguser PrimaryGroupID 20
        sudo dscl . create /Users/sharinguser UserShell /usr/bin/false
        sudo dscl . create /Users/sharinguser NFSHomeDirectory /dev/null     
        
        ### defining smb shares
        echo ''
        echo defining macos smb shares...
        
        # listing shares
        #sudo sharing -l
        # creating shared folder with ownership and permissions
        #rm -rf /Users/$USER/Desktop/files/vbox_shared
        mkdir -p /Users/$USER/Desktop/files/vbox_shared
        sudo chown -R sharinguser:admin /Users/$USER/Desktop/files/vbox_shared
        sudo chmod 770 /Users/$USER/Desktop/files/vbox_shared
        # removing possible exiting share
        sudo sharing -r /Users/$USER/Desktop/files/vbox_shared
        # creating share
        sudo sharing -a /Users/$USER/Desktop/files/vbox_shared -S vbox_shared -s 001 -g 000
        # listing shares
        #sudo sharing -l
        # status if sharing is enabled is given by "shared" (0=disabled, 1=enabled)
        # sudo sharing -r /Users/$USER/Desktop/files/vbox_shared
        sudo chmod -R +a "staff allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" /Users/$USER/Desktop/files/vbox_shared
        # both sethashtypes commands have to be run for the login to work (bug?)
        # if it is not working run the second one incl. -a and -p twice
        sudo pwpolicy -u sharinguser -sethashtypes SMB-NT on
        sudo pwpolicy -u sharinguser -a sharinguser -p $sharinguser_password -sethashtypes SMB-NT on
        sudo pwpolicy -u sharinguser -gethashtypes
        
        # enabling sharing
    	#sudo launchctl bootstrap system "/System/Library/LaunchDaemons/com.apple.smbd.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
		#sleep 2
	    #sudo launchctl enable system/LaunchDaemons/com.apple.smbd
	    # use "$PATH_TO_APPS"/smb_enable.app
        
        # disabling sharing
    	#sudo launchctl bootout system "/System/Library/LaunchDaemons/com.apple.smbd.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
		#sleep 2
	    #sudo launchctl disable system/LaunchDaemons/com.apple.smbd
	    # use "$PATH_TO_APPS"/smb_disable.app
            
        unset sharinguser_password
        unset sharinguser_password2
    }
    
    ### separate user for smb sharing    
    if [[ "$CREATE_SHARING_USER" == "yes" ]]
    then
        creating_sharing_user
        :
    else
        :
    fi
    
    # media sharing (needs reboot)
    #defaults write com.apple.amp.mediasharingd public-sharing-enabled -bool false
    #defaults write com.apple.amp.mediasharingd home-sharing-enabled -bool false
    # turn off media sharing
    if [[ $(sudo launchctl list | grep com.apple.mediasharingd) == "" ]] > /dev/null 2>&1
    then
        :
    else
    	sudo launchctl bootout system "/System/Library/LaunchAgents/com.apple.amp.mediasharingd.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	    sleep 2
		sudo launchctl disable system/com.apple.mediasharingd
    fi

    # printer sharing
    # cupsctl --share-printers
    # cupsctl --no-share-printers
    # sets preferences in 
    # /etc/cups/cupsd.conf
    # /etc/cups/printers.conf
    # check
    # system_profiler SPPrintersDataType | grep "Printer Sharing"
    # system_profiler SPPrintersDataType | grep Shared
    
    # remote login
    #sudo systemsetup -setremotelogin on
    #sudo systemsetup -setremotelogin off
    # check
    #sudo systemsetup -getremotelogin
    
    # remote management
    # screen sharing has to be enabled additionally for this to work
    #sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate
    #sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
    
    # remote apple events
    #sudo systemsetup -setremoteappleevents on
    #sudo systemsetup -setremoteappleevents off
    # turn off remote apple events
    if [[ $(sudo launchctl list | grep com.apple.mediasharingd) == "" ]] > /dev/null 2>&1
    then
        :
    else
    	sudo launchctl bootout system "/System/Library/LaunchDaemons/eppc.plist" 2>&1 | grep -v "in progress" | grep -v "No such process"
	    sleep 2
		sudo launchctl disable system/eppc
    fi
    # check
    #sudo systemsetup -getremoteappleevents | grep "Apple Events"
    
    # bluetooth sharing
    # needs logout / reboot
    #defaults -currentHost write com.apple.bluetooth PrefKeyServicesEnabled -bool true
    #defaults -currentHost write com.apple.bluetooth PrefKeyServicesEnabled -bool false
    
    # internet sharing
    # disable
    #sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict Enabled -int 0
    # check
    #sudo defaults read /Library/Preferences/SystemConfiguration/com.apple.nat | grep -i Enabled
    
    # content caching
    #sudo AssetCacheManagerUtil activate
    #sudo AssetCacheManagerUtil deactivate
    
    # airplay receiver
    # enable/disable
    defaults write ByHost/com.apple.controlcenter.${uuid1} AirplayRecieverEnabled -bool false
    
    # if enabled
    # 1 = allow from same icloud user
    # 2 = allow from complete same network
    # 3 = allow from everyone
    defaults write ByHost/com.apple.controlcenter.${uuid1} AirplayReceiverAdvertising -int 1

    # disable airplay receiver with applescript
    disable_airplay_receiver() {
    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    
    tell application "System Preferences"
    	activate
    	#set paneids to (get the id of every pane)
    	#display dialog paneids
    	#return paneids
    	#set current pane to pane "com.apple.preference.sharing"
    	#get the name of every anchor of pane id "com.apple.preference.sharing"
    	#set tabnames to (get the name of every anchor of pane id "com.apple.preferences.sharing")
    	#return tabnames
    	reveal anchor "Services_AirPlayReceiver" of pane id "com.apple.preferences.sharing"
    	delay 4
    end tell
    
    tell application "System Events" to tell process "System Preferences" to set visible to true
    delay 1
    tell application "System Events" to tell process "System Preferences" to set frontmost to true
    delay 1
    
    tell application "System Events"
    	tell process "System Preferences"
    		try
    			click button "Zum Bearbeiten auf das Schloss klicken." of window "Freigaben"
    		on error
    			click button 1 of window 1
    		end try
    		delay 2
    		tell process "SecurityAgent"
    			try
    				tell application "System Events" to keystroke "$SUDOPASSWORD"
    			end try
    		end tell
    		delay 2
    	end tell
    end tell
    tell application "System Events"
    	try
    		tell application "System Events"
    			try
    				tell process "System Preferences"
    					try
    						click button "Schutz aufheben" of sheet 1 of window "Freigaben"
    					end try
    				end tell
    			end try
    		end tell
    	on error
    		tell application "System Events"
    			try
    				tell process "System Preferences"
    					try
    						click button 1 of sheet 1 of window 1
    					end try
    				end tell
    			end try
    		end tell
    	end try
    end tell
    delay 2
    
    tell application "System Events"
    	tell process "System Preferences"
    		set theCheckbox to (checkbox 1 of row 11 of table 1 of scroll area 1 of group 1 of window 1)
    		tell theCheckbox
    			set checkboxStatus to value of theCheckbox as boolean
    			if checkboxStatus is true then click theCheckbox
    		end tell
    		delay 0.2
    	end tell
    end tell
    
    delay 2
    
    tell application "System Preferences"
    	quit
    end tell
    
EOF
    }
    #disable_airplay_receiver
     
        
    ###
    ### preferences time machine
    ###
    
    echo "preferences time machine"
    
    # disable time machine
    ##
    sudo defaults write /Library/Preferences/com.apple.TimeMachine MobileBackups -bool false
    sudo defaults write /Library/Preferences/com.apple.TimeMachine AutoBackup -bool false
    
    # run time machine backups on battery power
    # false = yes
    sudo defaults write /Library/Preferences/com.apple.TimeMachine RequiresACPower -bool false
    
    # exclude system files
    sudo defaults write /Library/Preferences/com.apple.TimeMachine SkipSystemFiles -bool true
    
    # show warning after deleting old backups
    sudo defaults write /Library/Preferences/com.apple.TimeMachine AlwaysShowDeletedBackupsWarning -bool true
    
    # show time machine in menu bar
    # see "menu bar"
    
    
    ### hidden time machine tweaks
    
    # prevent time machine from prompting to use new hard drives as backup volume
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
    
    # disable local time machine backups / snapshots
    sudo tmutil disable
    
    # delete possible snapshots
    # list localsnapshots
    #tmutil listlocalsnapshots / | cut -d'.' -f4-
    #tmutil listlocalsnapshots / | rev | cut -d'.' -f1 | rev
    #tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]'
    
    if [[ $(tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]') == "" ]]
    then
        # no local time machine backups found
        :
    else
        #echo ''
        echo "local time machine backups found, deleting..."
        for i in $(tmutil listlocalsnapshotdates | grep -v '[a-zA-Z]')
        do
        	tmutil deletelocalsnapshots "$i"
        done
        echo ''
    fi
    
    
    
    ###
    ### more hidden tweaks
    ###
    
    echo "more hidden tweaks"
    
    # reopen all windows after next login
    # false = disable, true = enable
    defaults write com.apple.loginwindow TALLogoutSavesState -bool false
    
    # expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
    
    # expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
    
    # save to disk (not to icloud) by default
    # false = save to disk, true = save to icloud
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
    
    # automatically quit printer app once the print jobs complete
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
    
    # disable the "are you sure you want to open this application?" dialog
    #defaults write com.apple.LaunchServices LSQuarantine -bool false
    
    # increase window resize speed for cocoa applications
    #defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    
    # remove duplicates in the open with menu (also see `lscleanup` alias)
    #echo removing duplicate entries in open with menu, this can take a while...
    #/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user
    
    # display ascii control characters using caret notation in standard text views
    # try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
    #defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true
    
    # disable transparency in the menu bar and elsewhere
    #defaults write com.apple.universalaccess reduceTransparency -bool true
    
    # disable automatic termination of inactive apps
    #defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
    
    # disable the crash reporter
    #defaults write com.apple.CrashReporter DialogType -string "none"
    
    # turning crash reporter back on
    #defaults write com.apple.CrashReporter DialogType -string "crashreport"
    
    # set help viewer windows to non-floating mode
    #defaults write com.apple.helpviewer DevMode -bool true
    
    # reveal ip address, hostname, os version, etc. when clicking the clock in the login window
    #sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
    
    # restart automatically if the computer freezes
    #sudo systemsetup -setrestartfreeze on
    
    # use encrypted virtual memory
    #defaults write com.apple.virtualMemory UseEncryptedSwap -bool YES
    
    
    ### screenshots
    
    # save screenshots to the desktop
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    
    # save screenshots in png format
    # other options: bmp, gif, jpg, pdf, tiff
    defaults write com.apple.screencapture type -string "jpg"
    
    # disable shadow in screenshots
    # true = shadow disabled
    defaults write com.apple.screencapture disable-shadow -bool true
    
    
    ###
    ### macbook pro touchbar
    ###
    
    # always display full control strip (ignoring app Controls)
    #defaults write com.apple.touchbar.agent PresentationModeGlobal fullControlStrip
    
    
    
    ###
    ### finder                                                                    
    ###
    
    echo "finder"
    
    ### general
    
    # show icons for hard drives, servers, and removable media on the desktop
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
    
    # set default location for new finder windows
    # for other paths, use `PfLo` and `file:///full/path/here/`
    defaults write com.apple.finder NewWindowTarget -string "PfLo"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
    
    # open cmd+doubleclicked folders in new tab
    defaults write com.apple.Finder FinderSpawnTab -bool true
    
    
    ### sidebar
    
    # system items
    # see separate script
    
    
    ### advanced
    
    # show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    
    # warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
    
    # warning before deleting from icloud drive
    defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool true
    
    # warning before emptying the Trash
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
    
    # delete items in trash after 30 days automatically
    defaults write com.apple.finder FXRemoveOldTrashItems -bool false
    
    # sort folders on top when sorting by name in windows
    defaults write com.apple.finder _FXSortFoldersFirst -bool false
    
    # sort folders on top on desktop
    defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool false
    
    # when performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    
    
    ### more finder tweaks
    
    # empty trash securely by default
    defaults write com.apple.finder EmptyTrashSecurely -bool false
    
    # allow quitting via cmd + Q; doing so will also hide desktop icons
    #defaults write com.apple.finder QuitMenuItem -bool true
    
    # disable window animations and get info animations
    #defaults write com.apple.finder DisableAllAnimations -bool true
    
    # show hidden files by default
    #defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # show recent tags
    # see separate finder sidebar script
    #defaults write com.apple.finder ShowRecentTags -bool false
    
    # show side bar
    defaults write com.apple.finder ShowSidebar -bool true
    
    # show status bar
    ##
    defaults write com.apple.finder ShowStatusBar -bool false
    
    # show path bar
    ##
    defaults write com.apple.finder ShowPathbar -bool false
    
    # show tab bar
    ##
    defaults write com.apple.finder ShowTabView -bool false
    
    # show preview pane
    #defaults write com.apple.finder ShowPreviewPane -bool false
    
    # allow text selection in quick look
    defaults write com.apple.finder QLEnableTextSelection -bool true
    
    # display full posix path as finder window title
    ##
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
    
    # reopen finder windows after reboot
    # false = no
    # true = yes
    defaults write com.apple.finder NSQuitAlwaysKeepsWindows -bool false
    
    # enable spring loading for directories
    #defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    
    # remove the spring loading delay for directories
    #defaults write NSGlobalDomain com.apple.springing.delay -float 0
    
    # avoid creating .DS_Store files on network volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    
    # disable disk image verification
    #defaults write com.apple.frameworks.diskimages skip-verify -bool true
    #defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
    #defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
    
    # automatically open a new finder window when a volume is mounted
    #defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
    #defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
    #defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
    
    # show item info near icons on the desktop and in other icon views
    #/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
    
    # show item info to the right of the icons on the desktop
    #/usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false" ~/Library/Preferences/com.apple.finder.plist
    
    # enable snap-to-grid for icons on the desktop and in other icon views
    #/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
    
    # increase grid spacing for icons on the desktop and in other icon views
    #/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
    
    # increase the size of icons on the desktop and in other icon views
    #/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
    #/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80" ~/Library/Preferences/com.apple.finder.plist
    
    # set default view in all finder windows by default
    # Four-letter codes for the view modes: `icnv`, `clmv`, `Flwv`, "Nlsv"
    defaults write com.apple.finder FXPreferredViewStyle -string "clmv"
    
    ### airdrop
    # enable airdrop over ethernet and on unsupported macs
    #defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
    
    # set airport discoverable mode 
    # Off 
    # Contacts Only
    # Everyone
    defaults write com.apple.sharingd DiscoverableMode -string "Off"

    ### show the ~/Library folder
    # show extended attributes
    #ls -la@e ~/
    #xattr ~/Library
    #xattr -p com.apple.FinderInfo ~/Library
    #xattr -l ~/Library
    # show extended attributes to copy / paste for restore with xattr -wx
    #xattr -px com.apple.FinderInfo ~/Library
    # delete all extended attributes
    #xattr -c ~/Library
    # delete specific extended attribute
    if [[ $(xattr -l ~/Library | grep com.apple.FinderInfo) == "" ]]
    then
        :
    else
        xattr -d com.apple.FinderInfo ~/Library
    fi
    # set folder flag to not hidden
    chflags nohidden ~/Library
    
    ### undo show the ~/Library folder
    # set extended attribute
    #xattr -wx com.apple.FinderInfo "00 00 00 00 00 00 00 00 40 00 00 00 00 00 00 00
    #00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00" ~/Library
    #xattr -l ~/Library
    #chflags hidden ~/Library
    #ls -la@e ~/
    
    # remove dropbox‚ set green checkmark icons in finder
    #file="$PATH_TO_APPS"/Dropbox.app/Contents/Resources/emblem-dropbox-uptodate.icns
    #[ -e "${file}" ] && mv -f "${file}" "${file}.bak"
    
    # expand the following file info panes (cmd + i)
    defaults write com.apple.finder FXInfoPanesExpanded -dict \
    	General -bool true \
    	OpenWith -bool true \
    	Privileges -bool true


    
    ###
    ### launchpad
    ###
    
    echo "launchpad"
    
    
    # disable the launchpad gesture (pinch with thumb and three fingers)
    #defaults write com.apple.dock showLaunchpadGestureEnabled -int 0
    
    # reset launchpad, but keep the desktop wallpaper intact
    #find "${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete
    
    # add ios simulator to launchpad
    #sudo ln -sf ""$PATH_TO_APPS"/Xcode.app/Contents/Developer/Applications/iOS Simulator.app" ""$PATH_TO_APPS"/iOS Simulator.app"
    
    
    
    ###
    ### safari & webkit                                                           
    ###
    
    echo "safari & webkit"

    SAFARI_PREFERENCES_FILE="/Users/"$USER"/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist"
    
    # function to open and quit safari in background
    open_and_quit_safari_in_background() {
    if [[ -e "$WEBSITE_SAFARI_DATABASE" ]]
    then
        :
    else
        echo "opening and quitting safari in background..."
        open -j -a ""$PATH_TO_APPS"/Safari.app" "https://google.com"
	    
	    osascript <<EOF
    		try
        		tell application "Safari"
        			#run
        			delay 6
        			quit
        			delay 3
        		end tell
        	end try
EOF
    fi
    }
    
    ### safari general
    
    # safari opens with: a new window
    ##
    defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool false
    
    # new windows open with: empty page
    ##
    defaults write com.apple.Safari NewWindowBehavior -int 1
    
    # new tabs open with: empty page
    ##
    defaults write com.apple.Safari NewTabBehavior -int 1
    
    # homepage
    defaults write com.apple.Safari HomePage "about:blank"
    defaults write com.apple.Safari DidMigrateDownloadFolderToSandbox -bool false
    defaults write com.apple.Safari DidMigrateResourcesToSandbox -bool false
    defaults read com.apple.Safari >/dev/null 2>&1
    defaults write com.apple.Safari.SandboxBroker Homepage "about:blank"
    defaults write com.apple.Safari.SandboxBroker DidMigrateDownloadFolderToSandbox -bool false
    defaults write com.apple.Safari.SandboxBroker DidMigrateResourcesToSandbox -bool false
    defaults read com.apple.Safari.SandboxBroker >/dev/null 2>&1
    open_and_quit_safari_in_background
    
    # or directly in the data stream
    # get current data and format
    #plutil -extract Homepage xml1 -o - /Users/"$USER"/Library/Preferences/com.apple.Safari.SandboxBroker.plist | xmllint --xpath "string(//data)" - | base64 --decode | plutil -convert xml1 - -o -
    # write new data in variable
    SAFARI_HOMEPAGE_DATA=$(echo '
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>$archiver</key>
    	<string>NSKeyedArchiver</string>
    	<key>$objects</key>
    	<array>
    		<string>$null</string>
    		<dict>
    			<key>$class</key>
    			<dict>
    				<key>CF$UID</key>
    				<integer>3</integer>
    			</dict>
    			<key>NS.base</key>
    			<dict>
    				<key>CF$UID</key>
    				<integer>0</integer>
    			</dict>
    			<key>NS.relative</key>
    			<dict>
    				<key>CF$UID</key>
    				<integer>2</integer>
    			</dict>
    		</dict>
    		<string>about:blank</string>
    		<dict>
    			<key>$classes</key>
    			<array>
    				<string>NSURL</string>
    				<string>NSObject</string>
    			</array>
    			<key>$classname</key>
    			<string>NSURL</string>
    		</dict>
    	</array>
    	<key>$top</key>
    	<dict>
    		<key>root</key>
    		<dict>
    			<key>CF$UID</key>
    			<integer>1</integer>
    		</dict>
    	</dict>
    	<key>$version</key>
    	<integer>100000</integer>
    </dict>
    </plist>
    ' | plutil -convert binary1 - -o - | xxd -p | tr -d '\n')
    # write data
    #defaults write com.apple.Safari.SandboxBroker Homepage -data "$SAFARI_HOMEPAGE_DATA"
    
    # days of keeping history
    defaults write com.apple.Safari HistoryAgeInDaysLimit -int 1
    
    # in favorites
    # FavoritesViewCollectionBookmarkUUID       # big string uuid
    
    # topsites arrangement / display
    # 0 = 6 sites
    # 1 = 12 sites
    # 2 = 24 sites
    defaults write com.apple.Safari TopSitesGridArrangement -int 0
        
    ### safari download path
    # ask on every download
    defaults write com.apple.Safari.SandboxBroker AlwaysPromptForDownloadFolder -bool false

    # download path
    if [[ "$SAFARI_DOWNLOADS_PATH" != "" ]]
    then
        :
    else
        SAFARI_DOWNLOADS_PATH="~/Downloads"
    fi
    
    defaults write com.apple.Safari DownloadsPath "$SAFARI_DOWNLOADS_PATH"
    defaults write com.apple.Safari DidMigrateDownloadFolderToSandbox -bool false
    defaults write com.apple.Safari DidMigrateResourcesToSandbox -bool false
    defaults read com.apple.Safari >/dev/null 2>&1
    defaults write com.apple.Safari.SandboxBroker DownloadLocation "$SAFARI_DOWNLOADS_PATH"
    defaults write com.apple.Safari.SandboxBroker DidMigrateDownloadFolderToSandbox -bool false
    defaults write com.apple.Safari.SandboxBroker DidMigrateResourcesToSandbox -bool false
    defaults read com.apple.Safari.SandboxBroker >/dev/null 2>&1
    open_and_quit_safari_in_background
    
    # or directly in the data stream (currently not working due to an output error)
    # get current data and format
    #plutil -extract Homepage xml1 -o - /Users/"$USER"/Library/Preferences/com.apple.Safari.SandboxBroker.plist | xmllint --xpath "string(//data)" - | base64 --decode | plutil -convert xml1 - -o -
    
    # remove downloads list items
    # 0 = manually
    # 1 = when safari quits
    # 2 = upon successful download
    # 3 = after on day
    ##
    defaults write com.apple.Safari DownloadsClearingPolicy -int 3
    
    # open safe files after download
    ##
    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
    
    
    ### safari tabs
    
    # tabs layout
    # false = compact
    # true = separate
    defaults write com.apple.Safari ShowStandaloneTabBar -bool true

    # show color in tab bar
    # false = show color
    # true = do not show color
    defaults write com.apple.Safari NeverUseBackgroundColorInToolbar -bool true
    
    # automatically resize tabs and make them smaller if more tabs are open (ff turned of tabs stay the same size and you have to scroll through them)
    defaults write com.apple.Safari EnableNarrowTabs -bool true
    
    # open pages in tabs instead of windows
    # 0 = never
    # 1 = automatically
    # 2 = always
    ##
    defaults write com.apple.Safari TabCreationPolicy -int 1
    
    # command-clicking a link creates tabs
    ##
    defaults write com.apple.Safari CommandClickMakesTabs -bool true
    
    # make new tabs open in foreground
    ##
    defaults write com.apple.Safari OpenNewTabsInFront -bool false
    
    # command+1 through 9 switches tabs
    ##
    defaults write com.apple.Safari Command1Through9SwitchesTabs -bool false
    
    
    ### safari autofill
    
    # autofill using info from my contacts card
    ##
    defaults write com.apple.Safari AutoFillFromAddressBook -bool false
    
    # autofill user names and passwords
    ##
    defaults write com.apple.Safari AutoFillPasswords -bool false
    
    # autofill credit cards
    ##
    defaults write com.apple.Safari AutoFillCreditCardData -bool false
    
    # autofill other forms
    ##
    defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
    
    
    ### safari passwords
    # already done above, sets both to true or false
    #defaults write com.apple.Safari AutoFillPasswords -bool false
    
    
    ### safari search
    
    # default search engine (google)
    # reading values
    # defaults read -g NSPreferredWebServices
    ##
    defaults write -g NSPreferredWebServices '{NSWebServicesProviderWebSearch = { NSDefaultDisplayName = Google; NSProviderIdentifier = "com.google.www"; }; }';
    #defaults write -g NSPreferredWebServices '{NSWebServicesProviderWebSearch = { NSDefaultDisplayName = Startpage; NSProviderIdentifier = "com.startpage"; }; }';
    
    # search engine suggestions
    # true = disabled
    # false = enabled
    defaults write com.apple.Safari SuppressSearchSuggestions -bool true
    
    # safari suggestions
    defaults write com.apple.Safari UniversalSearchEnabled -bool false
    
    # quick website search
    defaults write com.apple.Safari WebsiteSpecificSearchEnabled -bool false
    
    # preload top hit in the background
    ##
    defaults write com.apple.Safari PreloadTopHit -bool false
    
    # show favorites under smart search field
    defaults write com.apple.Safari ShowFavoritesUnderSmartSearchField -bool false
    
    
    ### safari security
    
    # warn about fraudulent websites
    ##
    defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
    
    # enable javaScript
    ##
    defaults write com.apple.Safari WebKitJavaScriptEnabled -bool true
    defaults write com.apple.Safari WebKitPreferences.javaScriptEnabled -bool true
        
    
    ### safari privacy
    
    # try to prevent cross-site tracking
    # 0 = no
    # 1 = yes
    defaults write com.apple.Safari WebKitStorageBlockingPolicy -int 1
    
    # do not get tracked
    defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
    
    # block new cookies and website data
    # 0 = yes
    # 2 = no
    ##
    defaults write com.apple.Safari BlockStoragePolicy -int 2
    
    # allow websites to check if applepay is enabled
    defaults write com.apple.Safari WebKitPreferences.applePayCapabilityDisclosureAllowed -bool true
    
    # allow web measurement
    defaults write com.apple.Safari WebKitPreferences.privateClickMeasurementEnabled -bool false
    
    
    ### safari websites
    
    WEBSITE_SAFARI_DATABASE="/Users/"$USER"/Library/Safari/PerSitePreferences.db"

    # on a clean install (without restoring some data or preferences, e.g. PerSitePreferences.db) Safari has to be opened at least one time before the files will be created
    # opening without loading a website does not trigger creating the files, so "run" is not enough, opening and loading a first website is needed
    open_and_quit_safari_in_background
    
    # general preferences
    # /Users/$USER/Library/Safari/PerSitePreferences.db
    # sqlite3 /Users/$USER/Library/Safari/PerSitePreferences.db
    # .tables
    # .headers ON
    # select * from default_preferences;
    # id|preference|default_value
    # xx|PerSitePreferencesCamera|1
    # xx|PerSitePreferencesAutoplay|0
    # xx|PerSitePreferencesUseReader|0
    # xx|PerSitePreferencesContentBlockers|0
    # xx|PerSitePreferencesMicrophone|0
    # example
    # UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesCamera';
    # select * from default_preferences;
    # .quit
    
    # per site preferences
    # /Users/$USER/Library/Safari/PerSitePreferences.db
    # sqlite3 /Users/$USER/Library/Safari/PerSitePreferences.db
    # .tables
    # .headers ON
    # select * from preference_values;
    # id|domain|preference|preference_value|timestamp
    # 1|watch.nba.com|PerSitePreferencesAutoplay|0|
    # example
    # UPDATE preference_values SET preference_value='0' WHERE (preference='PerSitePreferencesAutoplay' and domain='watch.nba.com');
    # select * from preference_values;
    # .quit
    
    # checking values
    # sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;"
    # sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from preference_values;"
    
    # resetting / deleting values
    # sqlite3 "$WEBSITE_SAFARI_DATABASE" "delete from default_preferences WHERE preference='PerSitePreferencesMicrophone';"
    # sqlite3 "$WEBSITE_SAFARI_DATABASE" "delete from preference_values WHERE preference='PerSitePreferencesMicrophone';"
    
    # use reader
    # off = 0
    # on = 1
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesUseReader") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesUseReader', '0');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='0' WHERE preference='PerSitePreferencesUseReader'"
    fi
    
    # use content blocker
    # off = 0
    # on = 1
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesContentBlockers") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesContentBlockers', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesContentBlockers'"
    fi
    # per site preferences
    sqlite3 "$WEBSITE_SAFARI_DATABASE" "delete from preference_values WHERE preference='PerSitePreferencesContentBlockers';"
    for WEBSITE in "nba.com" "watch.nba.com" "spiegel.de" "sport1.de"
    do
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into preference_values (domain, preference, preference_value) values ('$WEBSITE', 'PerSitePreferencesContentBlockers', '0');"
    done
    
    # autoplay media
    # allow automatic autoplay for all = 0
    # stop media with sound = 1
    # never autoplay = 2
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesAutoplay") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesAutoplay', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesAutoplay'"
    fi
    # per site preferences
    sqlite3 "$WEBSITE_SAFARI_DATABASE" "delete from preference_values WHERE preference='PerSitePreferencesAutoplay';"
    for WEBSITE in "nba.com" "watch.nba.com"
    do
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into preference_values (domain, preference, preference_value) values ('$WEBSITE', 'PerSitePreferencesAutoplay', '0');"
    done
    
    # default page zoom
    # 1 = 100%, 1.25 = 125%, etc.
    defaults write com.apple.Safari DefaultPageZoom -integer 1
    
    # allow camera
    # ask = 0
    # do not allow = 1
    # allow = 2
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesCamera") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesCamera', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesCamera'"
    fi
    
    # allow microphone
    # ask = 0
    # do not allow = 1
    # allow = 2
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesMicrophone") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesMicrophone', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesMicrophone'"
    fi
    
    # allow screen sharing
    # adds entries to /Users/"$USER"/Library/Safari/UserMediaPermissions.plist

    # ask = 0
    # do not allow = 1
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesStoreKeyScreenCapture") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesStoreKeyScreenCapture', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesStoreKeyScreenCapture'"
    fi
    
    # website use of location services
    # location services in system preferences have to be enabled if option shall be enabled
    # 0 = deny without prompting
    # 1 = prompt for each website once each day
    # 2 = prompt for each website one time only
    ##
    defaults write com.apple.Safari SafariGeolocationPermissionPolicy -int 0
    
    # allow geolocation
    # ask = 0
    # do not allow = 1
    # allow = 2
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesGeolocation") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesGeolocation', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesGeolocation'"
    fi
    
    # downloads
    # allow = 0
    # ask = 1
    # not allow = 2
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesDownloads") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesDownloads', '0');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='0' WHERE preference='PerSitePreferencesDownloads'"
    fi
    
    # notifications
    # allow asking about the push notifications
    defaults write com.apple.Safari CanPromptForPushNotifications -bool false
    
    # plugins
    # enable plug-ins
    ##
    defaults write com.apple.Safari WebKitPluginsEnabled -bool true
    
    # popups
    # block and notify = 0
    # block = 1
    # allow = 2
    if [[ $(sqlite3 "$WEBSITE_SAFARI_DATABASE" "select * from default_preferences;" | grep "PerSitePreferencesPopUpWindow") == "" ]]
    then
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "insert into default_preferences (preference, default_value) values ('PerSitePreferencesPopUpWindow', '1');"
    else
        sqlite3 "$WEBSITE_SAFARI_DATABASE" "UPDATE default_preferences SET default_value='1' WHERE preference='PerSitePreferencesPopUpWindow'"
    fi
    
    # all plugins but flash are no longer allowed and are not working any more
    # enable / disable plugins individually
    # flash player
    if [[ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]]
    then
        /usr/libexec/PlistBuddy -c "Set :PlugInInfo:'com.macromedia.Flash Player.plugin':plugInCurrentState NO" "$SAFARI_PREFERENCES_FILE"
        
        # plugin policies
        # on = PlugInPolicyAllowWithSecurityRestrictions
        # off = PlugInPolicyBlock
        # ask = PlugInPolicyAsk
    
        # flash player
        /usr/libexec/PlistBuddy -c "Set :ManagedPlugInPolicies:'com.macromedia.Flash Player.plugin':PlugInFirstVisitPolicy PlugInPolicyAllowWithSecurityRestrictions" "$SAFARI_PREFERENCES_FILE"
    else
        :
    fi


    ### safari extensions
    
    # enable extensions
    ##
    defaults write com.apple.Safari ExtensionsEnabled -bool true
    
    # update extensions automatically
    ##
    defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true
    
    
    ### safari advanced
    
    # show full url
    ##
    defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool false
    
    # do not use font size smaller than x
    # 0 = off
    # any other number for the respective font size
    defaults write com.apple.Safari WebKitMinimumFontSize -int 0
    defaults write com.apple.Safari WebKitPreferences.minimumFontSize -int 0

    # press tab to highlight each item on a webpage
    defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool false
    
    # automatically save for offline reading
    defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool false
    
    # user style sheet
    defaults write com.apple.Safari UserStyleSheetEnabled -bool false
    
    # set default encoding
    defaults write com.apple.Safari WebKitDefaultTextEncodingName -string 'iso-8859-1'
    defaults write com.apple.Safari WebKitPreferences.defaultTextEncodingName -string 'iso-8859-1'
    
    # enable the developer menu and the web inspector
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true
    
    
    ### more safari settings
    
    # always show tab bar
    ##
    defaults write com.apple.Safari AlwaysShowTabBar -bool true
    
    # allow hitting the backspace key to go to the previous page in history
    #defaults write com.apple.Safari WebKitPreferences.backspaceKeyNavigationEnabled -bool true
    
    # show safaris bookmarks bar by default
    #defaults write com.apple.Safari ShowFavoritesBar -bool true
    ##
    defaults write com.apple.Safari ShowFavoritesBar-v2 -bool true
    
    # show sidebar by default
    ##
    defaults write com.apple.Safari ShowSidebarInNewWindows -bool false
    
    # hide safaris sidebar in top sites
    #defaults write com.apple.Safari ShowSidebarInTopSites -bool false
    
    # disable safaris thumbnail cache for history and top sites
    #defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2
    
    # enable safaris debug menu
    #defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    
    # search with contains instead of starts with
    # use contains = false
    # use starts with = true
    defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
    
    # show status bar
    ##
    defaults write com.apple.Safari ShowStatusBar -bool true
    
    
    
    ###
    ### mail
    ###
    
    echo "mail"
    
    
    ### opening mail
    echo "opening and quitting mail in background..."
	# without opening mail on first run favorites get double entries
	osascript <<EOF
	
			try
				tell application "Mail"
					run
					delay 5
					quit
				end tell
			end try	
EOF

    sleep 2
    
    
    ### preferences file
    MAIL_PREFERENCES_FILE="/Users/"$USER"/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail.plist"


    ### general
    
    # setting time to check for messages
    # -1 = automatic
    defaults write com.apple.mail PollTime -int -1
    
    # no sound for new mails
    defaults write com.apple.mail MailSound -string ""
    
    # play sound for other mail actions
    defaults write com.apple.mail PlayMailSounds -bool true
    
    # show unread messages in dock
    # 1 = inboxes only
    # 2 = all mailboxes
    defaults write com.apple.mail MailDockBadge -int 1
    
    # notification for new messages
    # 1 = inboxes only
    # 2 = vips only
    # 3 = contacts
    # 5 = all mailboxes
    defaults write com.apple.mail MailUserNotificationScope -int 1
    
    # delete not edited attachment downloads
    # each attachment that is opened gets "downloaded" (pop3 and imap)
    # files are stored in "~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads/"
    # never
    #   DeleteAttachmentsAfterHours   0
    #   DeleteAttachmentsEnabled      false
    # when mail quits
    #   DeleteAttachmentsAfterHours   0
    #   DeleteAttachmentsEnabled      true
    # when respective mail gets deleted
    #   DeleteAttachmentsAfterHours   2147483647
    #   DeleteAttachmentsEnabled      true
    defaults write com.apple.mail DeleteAttachmentsAfterHours -int 0
    defaults write com.apple.mail DeleteAttachmentsEnabled -bool true
    
    # add invitations to calendar app automatically
    # adds entry to ~/Library/Mail/V6/MailData/UnsyncedRules.plist
    
    # archive or delete suppressed messages
    defaults write com.apple.mail ArchiveOrDeleteMutedMessagesKey -bool false
    
    # try sending later automatically if server for sending is offline
    defaults write com.apple.mail SuppressDeliveryFailure -bool false
    
    # when in full screen mode prefer split mode
    defaults write com.apple.mail FullScreenPreferSplit -bool true
    
    # when searching, seach in trash, chunk, decrypted messages
    defaults write com.apple.mail IndexTrash -bool true
    defaults write com.apple.mail IndexJunk -bool true
    defaults write com.apple.mail IndexDecryptedMessages -bool true
    
    
    ### junk mails
    
    # filter for junk mails
    # sets values in
    # ~/Library/Mail/V*/MailData/RulesActiveState.plist
    # ~/Library/Mail/V*/MailData/UnsyncedRules.plist
    
    
    ### fonts and fonts colors
    
    # use non proportional font for pure text emails
    defaults write com.apple.mail AutoSelectFont -bool false
    
    # show quoted text in colors
    defaults write com.apple.mail ColorQuoterColorIncoming -bool true

    
    ### view
    
    # display emails in threaded mode, sorted by date
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedAscending" -string "yes"
    defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
    
    # move deleted emails to
    # 0 = trash
    # 1 = archive
    defaults write com.apple.mail SwipeAction -int 0
    
    # show from/to/cc label in mail list
    defaults write com.apple.mail EnableToCcInMessageList -bool false
    
    # show contact pictures in mail list
    defaults write com.apple.mail EnableContactPhotos -bool false
    
    # number of displayed lines
    defaults write com.apple.mail NumberOfSnippetLines -int 0
    
    # show unread messages in bold
    defaults write com.apple.mail ShouldShowUnreadMessagesInBold -bool false
    
    # copy email addresses as "foo@example.com" instead of "Foo Bar <foo@example.com>" in mail.app
    # false = copy without name
    defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
    
    # highlight non grouped messages from conversations
    defaults write com.apple.mail HighlightCurrentThread -bool true
    
    # include corresponding messages in conversations
    defaults write com.apple.mail ConversationViewSpansMailboxes -bool true
    
    # mark all messages as read when opening conversation
    defaults write com.apple.mail ConversationViewMarkAllAsRead -bool false
    
    # sort order in the conversation, latest on top
    defaults write com.apple.mail ConversationViewSortDescending -bool true
    
    
    ### writing and sending
    
    # text format
    # formatted = MIME
    # plain = Plain
    defaults write com.apple.mail SendFormat -string MIME
    
    # spell checking
    # during typing = InlineSpellCheckingEnabled
    # when clicking send = SpellCheckingOnSendEnabled
    # never = NoSpellCheckingEnabled
    defaults write com.apple.mail SpellCheckingBehavior -string InlineSpellCheckingEnabled
    
    # send copy to myself
    # copy
    defaults write com.apple.mail ReplyToSelf -bool false
    # blind copy
    defaults write com.apple.mail BccSelf -bool false

    # show all recipients when sending an email to a group
    defaults write com.apple.mail-shared ExpandPrivateAliases -bool true
    
    # highlight adresses that do not match pattern
    defaults write com.apple.mail-shared AlertForNonmatchingDomains -bool false
    
    # using the same format to reply (plain or formatted)
    defaults write com.apple.mail AutoReplyFormat -bool false

    # quote received message on reply
    defaults write com.apple.mail ReplyQuotesOriginal -bool true

    # quote in multiple levels
    # enabled = false
    # disabled = true
    defaults write com.apple.mail SupressQuoteBarsInComposeWindows -bool false
    
    # always include complete original message in quote (not just highlighted text)
    defaults write com.apple.mail AlwaysIncludeOriginalMessage -bool true
    
    
    ### signature
    
    # place signature above quoted text
    defaults write com.apple.mail SignaturePlacedAboveQuotedText -bool true
    
    # use default system font for signature
    # for enabling set SignatureIsRich -bool true in
    # ~/Library/Mail/V*/MailData/Signatures/AllSignatures.plist
    # ~/Library/Mail/V*/MailData/Signatures/SignaturesByAccount.plist  


    ### privacy
    # "/Users/"$USER"/Library/Group Containers/group.com.apple.mail/Library/Preferences/group.com.apple.mail.plist"
    # 1 =       protect mail activity   on;      
    # 9 =       protect mail activity   off;       hide ip  on;     block remote content    off
    # 11 =      protect mail activity   off;       hide ip  on;     block remote content    on  
    # 13 =      protect mail activity   off;       hide ip  off;     block remote content   off
    defaults write "/Users/"$USER"/Library/Group Containers/group.com.apple.mail/Library/Preferences/group.com.apple.mail.plist" LoadRemoteContent-v2 -int 11
    

    ### more mail tweaks
    
    # disable send and reply animations
    #defaults write com.apple.mail DisableReplyAnimations -bool true
    #defaults write com.apple.mail DisableSendAnimations -bool true
    
    # disable inline attachments (just show the icons)
    defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
    
    # always add attachments at the end of messages
    defaults write com.apple.mail AttachAtEnd -bool true
    
    # always send attachments windows friendly
    defaults write com.apple.mail SendWindowsFriendlyAttachments -bool true
    
    # flag color to display
    # 1=orange
    defaults write com.apple.mail FlagColorToDisplay -int 1

    # grammar checking
    defaults write com.apple.mail WebGrammarCheckingEnabled -bool false
    
    # spelling checking
    defaults write com.apple.mail WebContinuousSpellCheckingEnabled -bool true
    
    # automatic spelling correction
    defaults write com.apple.mail WebAutomaticSpellingCorrectionEnabled -bool false
    
    # un-collapse favorites
    defaults write com.apple.mail UserDidCollapseFavoritesSectionKey -bool false
    
    # organize favorites
    defaults delete com.apple.mail Favorites
    defaults write com.apple.mail Favorites "
	<array>
		<dict>
			<key>IsPrefferedSelection</key>
			<true/>
			<key>MailboxUidIsContainer</key>
			<true/>
			<key>MailboxUidPersistentIdentifier</key>
			<string>Inbox</string>
		</dict>
		<dict>
			<key>IsPrefferedSelection</key>
			<false/>
			<key>MailboxUidIsContainer</key>
			<true/>
			<key>MailboxUidPersistentIdentifier</key>
			<string>Flags</string>
		</dict>
		<dict>
			<key>IsPrefferedSelection</key>
			<false/>
			<key>MailboxUidIsContainer</key>
			<true/>
			<key>MailboxUidPersistentIdentifier</key>
			<string>Sent Messages</string>
		</dict>
		<dict>
			<key>IsPrefferedSelection</key>
			<false/>
			<key>MailboxUidIsContainer</key>
			<true/>
			<key>MailboxUidPersistentIdentifier</key>
			<string>Drafts</string>
		</dict>
		<dict>
			<key>IsPrefferedSelection</key>
			<false/>
			<key>MailboxUidIsContainer</key>
			<true/>
			<key>MailboxUidPersistentIdentifier</key>
			<string>Trash</string>
		</dict>
	</array>
    "
    
    # unfold the favorites section
    /usr/libexec/PlistBuddy -c "Add 'NSOutlineView Items Main Window Mailbox List-V2':1 string 'favoritemailboxdatum://Inbox?parent=0'" "$MAIL_PREFERENCES_FILE"


    
    ###
    ### terminal                                                  
    ###
    
    echo "terminal"
    
    # only use utf-16 in terminal
    defaults write com.apple.terminal StringEncodings -array 10
    
    # enable "focus follows mouse" for Terminal.app and all X11 apps, i.e. hover over a window and start typing in it without clicking first
    #defaults write com.apple.terminal FocusFollowsMouse -bool true
    #defaults write org.x.X11 wm_ffm -bool true
    
    # install the solarized dark theme for iTerm
    #open "${HOME}/init/Solarized Dark.itermcolors"
    
    # don't display the annoying prompt when quitting iTerm
    #defaults write com.googlecode.iterm2 PromptOnQuit -bool false
    
    # secure keyboard entry
    defaults write com.apple.terminal SecureKeyboardEntry -bool true
    # check
    #defaults read -app Terminal SecureKeyboardEntry

    
    
    ###
    ### activity monitor
    ###
    
    echo "activity monitor"
    
    
    # show the main window when launching activity monitor
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
    
    # visualize cpu usage in the activity monitor dock icon
    defaults write com.apple.ActivityMonitor IconType -int 5
    
    # show all processes in activity monitor
    defaults write com.apple.ActivityMonitor ShowCategory -int 0
    
    # sort activity monitor results by cpu usage
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0
    
    
    
    ###
    ### contacts
    ###
    
    echo "contacts"
    
	echo "opening and quitting contacts in background..."
	# without opening contacs first some settings could not be applied (e.g. ABDefaultAddressCountryCode)
	osascript <<EOF
			try
				tell application "Contacts"
					run
					delay 5
					quit
				end tell
			end try		
EOF

    sleep 2
    
    # enable the debug menu in contacts
    #defaults write com.apple.addressbook ABShowDebugMenu -bool true
    
    # show first name
    # 1 = before last name
    # 2 = after last name
    defaults write NSGlobalDomain NSPersonNameDefaultDisplayNameOrder -integer 2
    
    # sort by
    ##
    defaults write ~/Library/Preferences/com.apple.AddressBook ABNameSortingFormat -string "sortingLastName sortingFirstName"
    
    # short name format
    # 0 = full name
    # 1 = first name & last initial
    # 2 = first initial & last name
    # 3 = first name only
    # 4 = last name only
    defaults write NSGlobalDomain NSPersonNameDefaultShortNameFormat -integer 0
    
    # prefer nicknames
    # 1=yes, 0=no
    ##
    defaults write NSGlobalDomain NSPersonNameDefaultShouldPreferNicknamesPreference -integer 0
    
    # show contacts found in mail
    ##
    defaults write com.apple.suggestions.plist SuggestionsShowContactsFoundInMail -bool false
    
    # show siri suggestions
    # done in 15c_disable_siri_analytics_and_learning by adding contacts app to blacklist
    
    # address format
    ##
    defaults write ~/Library/Preferences/com.apple.AddressBook ABDefaultAddressCountryCode -string "de"
    
    # vcard format
    # false = 3.0
    # true = 2.1
    defaults write ~/Library/Preferences/com.apple.AddressBook ABUse21vCardFormat -bool false
    
    # enable filter for private data on me card
    ##
    defaults write ~/Library/Preferences/com.apple.AddressBook ABPrivateVCardFieldsEnabled -bool false
    
    # export notes in vcards
    ##
    defaults write ~/Library/Preferences/com.apple.AddressBook ABIncludeNotesInVCard -bool true
    
    # export photos in vcards
    ##
    defaults write ~/Library/Preferences/com.apple.AddressBook ABIncludePhotosInVCard -bool true
    
    
    ###
    ### text edit
    ###
    
    echo "text edit"
    
    TEXTEDIT_CONFIG_FILE="/Users/"$USER"/Library/Containers/com.apple.TextEdit/Data/Library/Preferences/com.apple.TextEdit.plist"
    mkdir -p /Users/"$USER"/Library/Containers/com.apple.TextEdit/Data/Library/Preferences/
    touch "$TEXTEDIT_CONFIG_FILE"
    
    # use plain text mode for new textedit documents
    #defaults write "$TEXTEDIT_CONFIG_FILE" RichText -int 0
    
    # show page breaks in new documents by default
    defaults write "$TEXTEDIT_CONFIG_FILE" ShowPageBreaks -bool false
    
    # window size for new documents default
    defaults write "$TEXTEDIT_CONFIG_FILE" HeightInChars -int 50
    defaults write "$TEXTEDIT_CONFIG_FILE" WidthInChars -int 120
    
    # open and save files as utf-8 in textedit
    defaults write "$TEXTEDIT_CONFIG_FILE" PlainTextEncoding -int 4
    defaults write "$TEXTEDIT_CONFIG_FILE" PlainTextEncodingForWrite -int 4
    
    # check spelling while typing
    defaults write "$TEXTEDIT_CONFIG_FILE" CheckSpellingWhileTyping -bool true   
    
    # check spelling and grammar
    defaults write "$TEXTEDIT_CONFIG_FILE" CheckGrammarWithSpelling -bool false
    
    # correct spelling automatically
    defaults write "$TEXTEDIT_CONFIG_FILE" CorrectSpellingAutomatically -bool false
    
    # check show ruler
    defaults write "$TEXTEDIT_CONFIG_FILE" ShowRuler -bool true
    
    # data detection
    defaults write "$TEXTEDIT_CONFIG_FILE" DataDetectors -bool false
    
    # smart substitutions of quotes and dashes only in formatted documents
    defaults write "$TEXTEDIT_CONFIG_FILE" SmartSubstitutionsEnabledInRichTextOnly -bool true
    
    # smart copy paste
    defaults write "$TEXTEDIT_CONFIG_FILE" SmartCopyPaste -bool true
    
    # disable smart quotes in textedit
    defaults write "$TEXTEDIT_CONFIG_FILE" SmartQuotes -bool false
    #defaults write ~/Library/Containers/com.apple.TextEdit/Data/Library/Preferences/com.apple.TextEdit.plist SmartQuotes -bool false

    # disable smart dashes in textedit
    defaults write "$TEXTEDIT_CONFIG_FILE" SmartDashes -bool false
    #defaults write ~/Library/Containers/com.apple.TextEdit/Data/Library/Preferences/com.apple.TextEdit.plist SmartDashes -bool false

    # enable smart links in textedit
    defaults write "$TEXTEDIT_CONFIG_FILE" SmartLinks -bool true
    #defaults write ~/Library/Containers/com.apple.TextEdit/Data/Library/Preferences/com.apple.TextEdit.plist SmartLinks -bool true
    
    # text replacement
    defaults write "$TEXTEDIT_CONFIG_FILE" TextReplacement -bool true
    
    
    ###
    ### preview
    ###
    
    echo "preview"
    
    # antialias preview of documents (text and lines)
    #defaults write ~/Library/Containers/com.apple.Preview/Data/Library/Preferences/com.apple.Preview.plist PVPDFAntiAliasOption -bool false
    
    # when opening multiple files open
    # all in same window = 0
    # groups in same window = 1
    # every file in separate window = 2
    defaults write com.apple.Preview PVImageOpeningMode -int 0

    
    
    ###
    ### disk utility
    ###
    
    echo "disk utility"
    
    
    # enable the debug menu in disk utility
    #defaults write com.apple.DiskUtility advanced-image-options -bool true
    
    # show all devices
    defaults write com.apple.DiskUtility SidebarShowAllDevices -bool true
    
    
    ###
    ### calendar
    ###
    
    echo "calendar"
    
    ### accepting privacy policy
    defaults write com.apple.iCal "privacyPaneHasBeenAcknowledgedVersion" -int 4


    ### general
    
    # show 7 days
    ##
    defaults write com.apple.iCal "n days of week" -int 7
    
    # week starts on monday
    ##
    defaults write com.apple.iCal "first day of week" -int 1
    
    # in weekly view scroll by week
    # week = 1, day = 0
    ##
    defaults write com.apple.iCal "scroll by weeks in week view" -integer 1
    
    # work day starts at
    # 480 = 8 a.m.
    defaults write com.apple.iCal "first minute of work hours" -integer 480
    
    # work day ends at
    # 1.020 = 5 p.m.
    defaults write com.apple.iCal "last minute of work hours" -integer 1020
    
    # number of hours displayed
    defaults write com.apple.iCal "number of hours displayed" -integer 12
    
    # default calendar
    defaults write com.apple.iCal "CalDefaultCalendar" -string "UseLastSelectedAsDefaultCalendar"
    
    # display birthdays calendar
    ##
    defaults write com.apple.iCal "display birthdays calendar" -bool true
    
    # display holiday calendar
    defaults write com.apple.iCal "add holiday calendar" -bool true
        
    # show alternate calendar
    #defaults write com.apple.iCal "CALPrefOverlayCalendarIdentifier" -string "chinese"
    
    
    ### notifications
    
    # time to leave
    defaults write com.apple.iCal "TimeToLeaveEnabled" -bool false
    
    # invitations of shared calendars in notifications
    # enabled = false
    # disabled = true
    defaults write com.apple.iCal "SharedCalendarNotificationsDisabled" -bool true

    # invitations in notifications
    # enabled = false
    # disabled = true
    defaults write com.apple.iCal "InvitationNotificationsDisabled" -bool false

    
    ### advanced
    
    # time zone support
    ##
    defaults write com.apple.iCal "TimeZone support enabled" -bool false
    
    # show events in year view
    defaults write com.apple.iCal "Show heat map in Year View" -bool false
    
    # show week numbers
    defaults write com.apple.iCal "Show Week Numbers" -bool false
    
    # open events in new windows
    defaults write com.apple.iCal "OpenEventsInWindowType" -bool false
    
    # warn before sending invitations
    defaults write com.apple.iCal "WarnBeforeSendingInvitations" -bool true
    
    
    ### more calendar settings
    
    # show sidebar
    defaults write com.apple.iCal "CalendarSidebarShown" -bool true
    defaults write com.apple.iCal "CalendarSidebarView" -int 0
    defaults write com.apple.iCal "CalendarSidebarWidth" -int 190
    
    # show event times
    defaults write com.apple.iCal "Show time in Month View" -bool true
    
    
    ### disabling calendars
    # done in 11j_set_calendar_reminder_alarms
    
    
    
    ###
    ### reminders
    ###
    
    # show reminder for whole day events
    # enable at 9 a.m.
    defaults write com.apple.remindd todayNotificationFireTime -int 900
    # disable
    defaults write com.apple.remindd todayNotificationFireTime -int -1
    
    # show whole day tasks for the next day as overdue
    defaults write com.apple.remindd showRemindersAsOverdue -bool false
    
    # assignment notifications
    # silent = false
    # notify = trua
    defaults write com.apple.remindd enableAssignmentNotifications -bool true

    
    
    ###
    ### archive utility
    ###
    
    echo "archive utility"
    
    # move archives to trash after extraction
    #defaults write com.apple.archiveutility "dearchive-move-after" -string "~/.Trash"
    
    # don't reveal extracted items
    #defaults write com.apple.archiveutility "dearchive-reveal-after" -bool false
    
    
    
    ###
    ### xcode
    ###
    
    echo "xcode"
    
    # backup and restore other xcode preferences from ~/Library/Developer/Xcode/UserData
    
    # agree to xcode system wide
    #sudo xcodebuild -license
    
    # always use spaces for indenting
    #defaults write com.apple.dt.Xcode DVTTextIndentUsingTabs -bool false
    
    # show tab bar
    #defaults write com.apple.dt.Xcode AlwaysShowTabBar -bool true
    
    # show line numbers
    defaults write com.apple.dt.Xcode DVTTextShowLineNumbers -boolean true
    
    
    
    ###
    ### messages
    ###
    
    echo "messages"
    
    # disable automatic emoji substitution (i.e. use plain text smileys)
    #defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
    
    # disable smart quotes as it is annoying for messages that contain code
    #defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
    
    # disable continuous spell checking
    #defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false
    
    # notifications for messages from all senders
    defaults write com.apple.MobileSMS NotifyAboutMessagesFromUnknownContacts -bool true
    
    # notifications if my name is mentioned
    defaults write com.apple.MobileSMS AddressMeInGroupchat -bool true

    # allow autoplay full screen in app effects 
    defaults write com.apple.MobileSMS autoPlayMessageEffects -bool false

    # message sounds
    defaults write com.apple.MobileSMS PlaySoundsKey -bool true

    # text size
    #defaults write com.apple.MobileSMS TextFontSize -int 13
    #defaults write com.apple.MobileSMS TextSize -int 4
    
    # shared with you
    defaults write com.apple.SocialLayer SharedWithYouEnabled -bool false
    if [[ -z $(/usr/libexec/PlistBuddy -c "Print SharedWithYouApps" /Users/"$USER"/Library/Preferences/com.apple.SocialLayer.plist) ]] > /dev/null 2>&1
    then
        :
    else
        for i in $(/usr/libexec/PlistBuddy -c "Print SharedWithYouApps" /Users/"$USER"/Library/Preferences/com.apple.SocialLayer.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
        do
            #echo "$i"
    	    /usr/libexec/PlistBuddy -c "Set SharedWithYouApps:$i false" /Users/"$USER"/Library/Preferences/com.apple.SocialLayer.plist
        done
    fi
    

    ###
    ### facetime
    ###
    
    echo "facetime"
    
    # calls from iphone (needs logout to take effect)
    # yes = false
    # no = true
    defaults write com.apple.TelephonyUtilities relayCallingDisabled -bool false

    # highlight speeking person
    defaults write com.apple.FaceTime allowAudioProminence -bool true
    
    # allow live photos during video calls
    defaults write com.apple.TelephonyUtilities FaceTimePhotosEnabled -bool false

    
    
    ###
    ### pages
    ###
    
    echo "pages"
    
    defaults write com.apple.iWork.Pages TSWPAutomaticSpellingCorrection -bool false
    #defaults write com.apple.iWork.Pages NSDocumentSuppressTempVersionStoreWarning -bool true
    
    
    
    ###
    ### photos
    ###
    
    # preventing photos from opening automatically when devices are plugged in
    defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true



    ###
    ### links to core service utilities
    ###
    
    # lining core service utilities to "$PATH_TO_APPS"/Utilities
    
    echo "creating links from core service apps..."
    
    for CORE_SERVICE_APP_PATH in /System/Library/CoreServices/Applications/*
    do
        CORE_SERVICE_APP=$(basename -- "$CORE_SERVICE_APP_PATH")
        #echo "$CORE_SERVICE_APP"
        if [[ ! -e "$PATH_TO_APPS"/Utilities/"$CORE_SERVICE_APP" ]]
        then
            sudo ln -s /System/Library/CoreServices/Applications/"$CORE_SERVICE_APP" "$PATH_TO_APPS"/Utilities/"$CORE_SERVICE_APP"
        else
            :
        fi
        #echo ''
    done
    
    if [[ ! -e ""$PATH_TO_APPS"/Finder.app" ]] && [[ -e "/System/Library/CoreServices/Finder.app" ]]
    then
        ln -s "/System/Library/CoreServices/Finder.app" ""$PATH_TO_APPS"/Finder.app"
    else
        :
    fi
    
    # ios simulator
    #sudo ln -s ""$PATH_TO_APPS"/Xcode.app/Contents/Applications/iPhone Simulator.app" ""$PATH_TO_APPS"/iOS Simulator.app"    
    
    
    
    ###
    ### repairing permissions
    ###
    
    # seems to no longer work on 10.11 and newer
    
    #sudo diskutil verifyvolume /Volumes/macintosh_hd
    #sudo diskutil repairvolume /Volumes/macintosh_hd
    
    
    
    ###
    ### enabling filevault
    ###
    
    # this can not be done before using the sharing command or login will not work after a reboot if the sharing command is used after enabling_filevault (in this script done by public shared folder and sharing user)
    # this is why enabling_filevault is moved to the end of this script to avoid complications with other commands, leave it to ensure maximum compatibility
    enabling_filevault
    sleep 3
    
    # destroying filevault key when going to standby
    sudo pmset -a destroyfvkeyonstandby 1
    # check
    # 1 = on / yes
    #pmset -g | grep DestroyFVKeyOnStandby
    
    
    ### removing security permissions
    #remove_apps_security_permissions_stop
    
    
    ###
    ### killing affected applications
    ###
    
    echo "restarting affected apps"
    
    for app in "Activity Monitor" "Calendar" "Contacts" "cfprefsd" "blued" "Dock" "Finder" "Mail" "Messages" "System Preferences" "Safari" "SystemUIServer" "TextEdit" "ControlStrip" "Photos" "NotificationCenter"; do
    	killall "${app}" > /dev/null 2>&1
    done
    
}

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    setting_preferences | tee "$HOME"/Desktop/"$SCRIPT_NAME"_log.txt
else
    setting_preferences 2>&1 | tee "$HOME"/Desktop/"$SCRIPT_NAME"_log.txt
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo "done ;)"
echo "a few changes need a reboot or logout to take effect"

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    :
else  
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'           # reboot
    #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'          # shutdown
    #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'          # logout
fi

###
### unsetting password
###

unset SUDOPASSWORD


