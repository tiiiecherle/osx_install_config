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
### profiles
###

SCRIPT_DIR_PROFILES="$SCRIPT_DIR"/11a_app_profiles

# no longer needed after introducing multiple ways in the config file to get the app id
#if [[ ! -e "$SCRIPT_DIR_PROFILES" ]]
#then
#    echo ''
#    echo "directory for app profiles not found, exiting..."
#    echo ''
#    exit
#else
#    :
#fi



###
### compatibility
###

# specific macos version only
if [[ "$MACOS_VERSION_MAJOR" != "10.14" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.14, exiting..."
    echo ''
    exit
else
    :
fi



###
### preparations
###

starting_witchdaemon () {
    if [[ -e /Users/"$USER"/Library/PreferencePanes/Witch.prefPane/Contents/Helpers/witchdaemon.app/Contents/MacOS/witchdaemon ]]
    then
        ACCESSIBILITYAPPS=(
        # app name									                         security service					allowed (1=yes, 0=no)
        "Terminal                                                            kTCCServiceAccessibility           1"
        )
        APPS_SECURITY_ARRAY=$(printf "%s\n" "${ACCESSIBILITYAPPS[@]}")
        PRINT_SECURITY_PERMISSIONS_ENTRIES="no" env_set_apps_security_permissions
        /Users/"$USER"/Library/PreferencePanes/Witch.prefPane/Contents/Helpers/witchdaemon.app/Contents/MacOS/witchdaemon &
        sleep 3
        #killall witchdaemon
    else
        :
    fi
}
echo ''
echo "starting witchdaemon to make it available to get the app_id..."
starting_witchdaemon &> /dev/null
#echo ''



###
### general
###

# sqlite database for accessibility
#  /Library/Application Support/com.apple.TCC/TCC.db

# sqlite database for calendar, contacts, reminders, ...
#  ~/Library/Application Support/com.apple.TCC/TCC.db

env_databases_apps_security_permissions
#DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_SYSTEM"
#DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_USER"

# reading database
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db
# and
# sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db
# .dump access
# .schema access

# quit database
# .quit

### getting entries from database
# examples
# sqlite3 "$DATABASE_USER" "select * from access where service='kTCCServiceAppleEvents';"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and indirect_object_identifier='com.apple.systempreferences');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and indirect_object_identifier='com.apple.finder');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.finder' and allowed='1');"

### getting application identifier
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APPS"/enterapplicaitonnamehere.app/Contents/Info.plist
# example
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' ""$PATH_TO_APPS"/Overflow 3.app/Contents/Info.plist"
# com.stuntsoftware.Overflow3
# example2
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' ""$PATH_TO_APPS"/System Preferences.app/Contents/Info.plist"
# com.apple.systempreferences
# or        
# osascript -e "id of app \"Overflow 3\""
# or
# PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin / | grep -i "/Overflow 3.app$" | head -1)
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APP/Contents/Info.plist"
# or
# APP_NAME="Overflow 3"; APP_NAME2="${APP_NAME//\'/\'}.app"; APP_NAME2=${APP_NAME2//"/\\"}; APP_NAME2=${APP_NAME2//\\/\\\\}; mdls -name kMDItemCFBundleIdentifier -raw "$(mdfind 'kMDItemContentType==com.apple.application-bundle&&kMDItemFSName=="'"$APP_NAME2"'"' | head -n1)"


###
### app data
###

#echo ''
#APP_NAME=Finder
#echo $APP_NAME
#ARRAY_NAME="$APP_NAME""_DATA"[@]

### getting identifier
# APP_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APPS"/"$APP_NAME".app/Contents/Info.plist)
#APP_IDENTIFIER=$(printf '%s\n' "${!ARRAY_NAME}" | sed -n '2p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
#echo $APP_IDENTIFIER
#CSREQ_BLOB=$(printf '%s\n' "${!ARRAY_NAME}" | sed -n '3p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
#echo $CSREQ_BLOB

### getting csreq_blob
# tccutil reset AppleEvents
# osascript -e "tell application \"Appname\" to «event BATFinit»"
# osascript -e "tell application \"Finder\" to «event BATFinit»"
# sqlite3 "$DATABASE_USER"
# .dump access

#echo ''
#echo "$SCRIPT_DIR"/"$SCRIPT_NAME"

#sudo tccutil reset AppleEvents
#tccutil reset AppleEvents
#for APP_ARRAY_NAME in $(cat "$SCRIPT_DIR"/"$SCRIPT_NAME" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | grep "_DATA=($" | sed 's/_DATA.*//')
#do
#    APP_ARRAY="$APP_ARRAY_NAME""_DATA"[@]
#    APP_NAME=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '1p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
#    echo "$APP_NAME"
#    osascript -e "tell application \"$APP_NAME\" to «event BATFinit»"
#done
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'select quote(csreq) from access'
#exit



###
### privacy settings
###


### privacy - accessibility

echo ''
tput bold; echo "accessibility..." ; tput sgr0

# add application to accessibility
#terminal
#INSERT INTO access VALUES('kTCCServiceAccessibility','com.apple.Terminal',0,1,1,NULL,NULL,NULL,?,NULL,0,1533680610);
#overflow 3
#'IDENTIFIER',0,0,1     # added, but not enabled
#'IDENTIFIER',0,1,1     # added and enabled
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.stuntsoftware.Overflow3',0,1,1,NULL,NULL,NULL,?,NULL,0,1533680686);" 

# remove application from accessibility
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='IDENTIFIER';"
# example
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='com.stuntsoftware.Overflow3';"

# clearing complete access table
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "DELETE FROM access"

# permission on for all apps listed
# sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'UPDATE access SET allowed = "1";'

# permission off for all apps listed
# sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'UPDATE access SET allowed = "0";'

# getting entries from database
# sudo sqlite3 "$DATABASE_SYSTEM" "select * from access where service='kTCCServiceAccessibility';"

sudo sqlite3 "$DATABASE_SYSTEM" "DELETE FROM access"

ACCESSIBILITYAPPS=(
# app name									                         security service					allowed (1=yes, 0=no)
"brew_casks_update                                                   kTCCServiceAccessibility           1"
"video_720p_h265_aac_shrink                                          kTCCServiceAccessibility           1"
"gui_apps_backup                                                     kTCCServiceAccessibility           1"
"backup_files_tar_gz                                                 kTCCServiceAccessibility           1"
"BL Banking Launcher                                                 kTCCServiceAccessibility           1"
"decrypt_finder_input_gpg_progress                                   kTCCServiceAccessibility           1"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress     kTCCServiceAccessibility           1"
"Overflow 3                                                          kTCCServiceAccessibility           1"
"Script Editor                                                       kTCCServiceAccessibility           1"
"System Preferences                                                  kTCCServiceAccessibility           1"
"witchdaemon                                                         kTCCServiceAccessibility           1"
"Terminal                                                            kTCCServiceAccessibility           1"
"iTerm                                                               kTCCServiceAccessibility           1"
"VirtualBox                                                          kTCCServiceAccessibility           1"
"PasswordWallet                                                      kTCCServiceAccessibility           1"
"VirtualBox Menulet                                                  kTCCServiceAccessibility           1"
"Bartender 3                                                         kTCCServiceAccessibility           1"
"Ondesoft AudioBook Converter                                        kTCCServiceAccessibility           1"
"VNC Viewer                                                          kTCCServiceAccessibility           1"
"Commander One                                                       kTCCServiceAccessibility           1"
"MacPass                                                             kTCCServiceAccessibility           1"
"pdf_200dpi_shrink                                                   kTCCServiceAccessibility           1"
)

APPS_SECURITY_ARRAY=$(printf "%s\n" "${ACCESSIBILITYAPPS[@]}")
PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions


### privacy - contacts

echo ''
tput bold; echo "contacs..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAddressBook';"

CONTACTSAPPS=(
# app name									security service										    allowed (1=yes, 0=no)
"gui_apps_backup                            kTCCServiceAddressBook                                      1"
"Alfred 5                                   kTCCServiceAddressBook                                      1"
"GeburtstagsChecker                         kTCCServiceAddressBook                                      1"
)

APPS_SECURITY_ARRAY=$(printf "%s\n" "${CONTACTSAPPS[@]}")
PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions


### privacy - calendar

echo ''
tput bold; echo "calendar..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceCalendar';"

CALENDARAPPS=(
# app name									security service										    allowed (1=yes, 0=no)
"gui_apps_backup                            kTCCServiceCalendar                                         1"
"iStat Menus                                kTCCServiceCalendar                                         1"
)

APPS_SECURITY_ARRAY=$(printf "%s\n" "${CALENDARAPPS[@]}")
PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions


### privacy - reminders

echo ''
tput bold; echo "reminders..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceReminders';"

REMINDERAPPS=(
# app name									security service										    allowed (1=yes, 0=no)
"gui_apps_backup                            kTCCServiceReminders                                        1"
)

APPS_SECURITY_ARRAY=$(printf "%s\n" "${REMINDERAPPS[@]}")
PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions


### privacy - microphone

echo ''
tput bold; echo "microphone..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceMicrophone';"

MICROPHONEAPPS=(
# app name									security service										    allowed (1=yes, 0=no)
"VirtualBox                                 kTCCServiceMicrophone                                       1"
"VirtualBox Menulet                         kTCCServiceMicrophone                                       1"
)

APPS_SECURITY_ARRAY=$(printf "%s\n" "${MICROPHONEAPPS[@]}")
PRINT_SECURITY_PERMISSIONS_ENTRIES="yes" env_set_apps_security_permissions


### privacy - automation
# does not show in system preferences window, but works

# asking for permission to use terminal to automate the finder
# osascript -e "tell application \"Finder\" to «event BATFinit»"

echo ''
tput bold; echo "automation..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAppleEvents';"
#sudo tccutil reset AppleEvents   

AUTOMATION_APPS=(
# source app name							                                automated app name		    allowed (1=yes, 0=no)
"brew_casks_update                                                          System Events               1"
"brew_casks_update                                                          Terminal                    1"
"pdf_200dpi_shrink                                                          System Events               1"
"pdf_200dpi_shrink                                                          Terminal                    1"
"decrypt_finder_input_gpg_progress                                          System Events               1"
"decrypt_finder_input_gpg_progress                                          Terminal                    1"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress            System Events               1"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress            Terminal                    1"
"video_720p_h265_aac_shrink                                                 System Events               1"
"video_720p_h265_aac_shrink                                                 Terminal                    1"
"BL Banking Launcher                                                        System Events               1"
"BL Banking Launcher                                                        Terminal                    1"
"backup_files_tar_gz                                                        System Events               1"
"backup_files_tar_gz                                                        Terminal                    1"
"gui_apps_backup                                                            System Events               1"
"gui_apps_backup                                                            Terminal                    1"
"virtualbox_backup                                                          System Events               1"
"virtualbox_backup                                                          Terminal                    1"
"run_on_login_signal                                                        System Events               1"
"run_on_login_whatsapp                                                      System Events               1"
"iTerm                                                                      System Events               1"
"XtraFinder                                                                 Finder                      1"
"Ondesoft AudioBook Converter                                               iTunes                      1"
"EagleFiler                                                                 Mail                        1"
"EagleFiler                                                                 Finder                      1"
"witchdaemon                                                                Mail                        0"
)
        
PRINT_AUTOMATING_PERMISSIONS_ENTRIES="yes" env_set_apps_automation_permissions


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''

#echo "the changes need a reboot or logout to take effect"
#echo "please logout or reboot"
#echo "initializing loggin out"

#sleep 2

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout



###
### unsetting password
###

unset SUDOPASSWORD



