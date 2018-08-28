#!/bin/bash

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
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
SCRIPT_DIR_PROFILES="$SCRIPT_DIR"/11a_app_profiles
if [[ ! -e "$SCRIPT_DIR_PROFILES" ]]
then
    echo ''
    echo "directory for app profiles not found, exiting..."
    echo ''
    exit
else
    :
fi
SCRIPT_NAME=$(basename -- "$0")

MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)

# macos 10.14 and higher
#if [[ $(echo $MACOS_VERSION | cut -f1 -d'.') == "10" ]] && [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
# macos 10.14 only
if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.') != "10.14" ]]
then
    #echo "this script is only compatible with macos 10.14 mojave and newer, exiting..."
    echo ''
    echo "this script is only compatible with macos 10.14 mojave, exiting..."
    echo ''
    exit
else
    :
fi



###
### functions
###

function write_permissions_to_database() {
    for APP_ENTRY in "${!INPUT_ARRAY}"
    do
        #echo "$APP_ENTRY"
        #APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/   */:/g' | cut -d':' -f1)
        #APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/ \{2,\}/:/g' | cut -d':' -f2)
       	#APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | awk -F '  +' '{print $1}')
       	#APP_NAME=$(echo "$app_entry" | sed $'s/\t/|/g' | sed 's/   */:/g' | cut -d':' -f1)
       	APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
       	#APP_NAME_NO_SPACES=$(echo "$APP_NAME" | sed 's/ /_/g' | sed 's/^ //g' | sed 's/ $//g')
        APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
        APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
        #echo "$APP_NAME"
        #echo "$APP_ARRAY"
        #echo "$APP_ID"
        #echo "$APP_CSREQ"
        #
        PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
        #
        if [[ "$INPUT_SERVICE" == "kTCCServiceAccessibility" ]]
        then
            # working, but no csreq
            #sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,?,NULL,0,?);"
            # working with csreq
            sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,$APP_CSREQ,NULL,0,?);"
        else
            # working, but no csreq
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);"
            # working with csreq
            sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,$APP_CSREQ,NULL,NULL,?,NULL,NULL,?);"
        fi
        #
        APP_NAME_PRINT=$(echo "$APP_NAME" | cut -d ":" -f1 | awk -v len=28 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        #
        printf "%-30s %-30s %-5s\n" "$APP_NAME_PRINT" "" "$PERMISSION_GRANTED"
        #
        unset APP_NAME
        unset APP_ID
        unset APP_CSREQ   
        unset PERMISSION_GRANTED
    done
}



###
### general
###

# sqlite database for accessibility
#  /Library/Application Support/com.apple.TCC/TCC.db

# sqlite database for calendar, contacts, reminders, ...
#  ~/Library/Application Support/com.apple.TCC/TCC.db

DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_SYSTEM"
DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_USER"

# reading database
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db
# and
# sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db
# .dump access
# .schema access

# quit database
# .quit

# getting entries from database
# examples
# sqlite3 "$DATABASE_USER" "select * from access where service='kTCCServiceAppleEvents';"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and indirect_object_identifier='com.apple.systempreferences');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and indirect_object_identifier='com.apple.finder');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.finder' and allowed='1');"

# getting application identifier
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/enterapplicaitonnamehere.app/Contents/Info.plist
# example
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/Overflow.app/Contents/Info.plist
# com.stuntsoftware.Overflow
# example2
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "/Applications/System Preferences.app/Contents/Info.plist"
# com.apple.systempreferences


###
### app data
###

#echo ''
#APP_NAME=Finder
#echo $APP_NAME
#ARRAY_NAME="$APP_NAME""_DATA"[@]

### getting identifier
# APP_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/"$APP_NAME".app/Contents/Info.plist)
#APP_IDENTIFIER=$(printf '%s\n' "${!ARRAY_NAME}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
#echo $APP_IDENTIFIER
#CSREQ_BLOB=$(printf '%s\n' "${!ARRAY_NAME}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
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
#for APP_ARRAY_NAME in $(cat "$SCRIPT_DIR"/"$SCRIPT_NAME" | sed 's/^ //g' | sed 's/ $//g' | grep "_DATA=($" | sed 's/_DATA.*//')
#do
#    APP_ARRAY="$APP_ARRAY_NAME""_DATA"[@]
#    APP_NAME=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '1p' | sed 's/^ //g' | sed 's/ $//g')
#    echo "$APP_NAME"
#    osascript -e "tell application \"$APP_NAME\" to «event BATFinit»"
#done
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'select quote(csreq) from access'
#exit


###
### app list
###

# list of possible values from 11a_system_preferences_privacy_app_profiles_.sh

APP_LIST=(
"System Events"
iTerm
Terminal
Finder
"BL Banking Launcher"
XtraFinder
brew_casks_update
video_720p_h265_aac_shrink
video_1080p_h265_aac_shrink
gui_apps_backup
decrypt_finder_input_gpg_progress
unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress
Overflow
"Script Editor"
"System Preferences"
witchdaemon
VirtualBox
PasswordWallet
"VirtualBox Menulet"
"Bartender 3"
"Ondesoft AudioBook Converter"
"VNC Viewer"
"Commander One"
Dialectic
"Alfred 3"
GeburtstagsChecker
pdf_200dpi_shrink
iTunes
Mail
backup_files_tar_gz
virtualbox_backup
run_on_login_signal
run_on_login_whatsapp
EagleFiler
"iStat Menus"
)



###
### privacy settings
###


### privacy - accessibility

echo ''
tput bold; echo "accessibility..." ; tput sgr0

# add application to accessibility
#terminal
#INSERT INTO access VALUES('kTCCServiceAccessibility','com.apple.Terminal',0,1,1,NULL,NULL,NULL,?,NULL,0,1533680610);
#overflow
#'IDENTIFIER',0,0,1     # added, but not enabled
#'IDENTIFIER',0,1,1     # added and enabled
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.stuntsoftware.Overflow',0,1,1,NULL,NULL,NULL,?,NULL,0,1533680686);" 

# remove application from accessibility
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='IDENTIFIER';"
# example
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='com.stuntsoftware.Overflow';"

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
"brew_casks_update                                                      1"
"video_720p_h265_aac_shrink                                             1"
"video_1080p_h265_aac_shrink                                            1"
"gui_apps_backup                                                        1"
"BL Banking Launcher                                                    1"
"decrypt_finder_input_gpg_progress                                      1"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress        1"
"Overflow                                                               1"
"Script Editor                                                          1"
"System Preferences                                                     1"
"witchdaemon                                                            1"
"Terminal                                                               1"
"iTerm                                                                  1"
"VirtualBox                                                             1"
"PasswordWallet                                                         1"
"VirtualBox Menulet                                                     1"
"Bartender 3                                                            1"
"Ondesoft AudioBook Converter                                           1"
"VNC Viewer                                                             1"
"Commander One                                                          0"
)

INPUT_ARRAY="ACCESSIBILITYAPPS"[@]
INPUT_SERVICE=kTCCServiceAccessibility

write_permissions_to_database


### privacy - contacts

echo ''
tput bold; echo "contacs..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAddressBook';"

CONTACTSAPPS=(
"gui_apps_backup                                                        1"
"Dialectic                                                              1"
"Alfred 3                                                               1"
"GeburtstagsChecker                                                     1"
)

INPUT_ARRAY="CONTACTSAPPS"[@]
INPUT_SERVICE=kTCCServiceAddressBook

write_permissions_to_database


### privacy - calendar

echo ''
tput bold; echo "calendar..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceCalendar';"

CALENDARAPPS=(
"gui_apps_backup                                                        1"
"iStat Menus                                                            1"
)

INPUT_ARRAY="CALENDARAPPS"[@]
INPUT_SERVICE=kTCCServiceCalendar

write_permissions_to_database


### privacy - reminders

echo ''
tput bold; echo "reminders..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceReminders';"

REMINDERAPPS=(
"gui_apps_backup                                                        1"
)

INPUT_ARRAY="REMINDERAPPS"[@]
INPUT_SERVICE=kTCCServiceReminders

write_permissions_to_database


### privacy - microphone

echo ''
tput bold; echo "microphone..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceMicrophone';"

MICROPHONEAPPS=(
"VirtualBox                                                             1"
)

INPUT_ARRAY="MICROPHONEAPPS"[@]
INPUT_SERVICE=kTCCServiceMicrophone

write_permissions_to_database


### privacy - automation
# does not show in system preferences window, but works

# asking for permission to use terminal to automate the finder
# osascript -e "tell application \"Finder\" to «event BATFinit»"

echo ''
tput bold; echo "automation..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAppleEvents';"
#sudo tccutil reset AppleEvents   

AUTOMATIONAPPS=(
"brew_casks_update                                                      System Events                   1"
"brew_casks_update                                                      Terminal                        1"
"pdf_200dpi_shrink                                                      System Events                   1"
"pdf_200dpi_shrink                                                      Terminal                        1"
"decrypt_finder_input_gpg_progress                                      System Events                   1"
"decrypt_finder_input_gpg_progress                                      Terminal                        1"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress        System Events                   1"
"unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress        Terminal                        1"
"video_720p_h265_aac_shrink                                             System Events                   1"
"video_720p_h265_aac_shrink                                             Terminal                        1"
"video_1080p_h265_aac_shrink                                            System Events                   1"
"video_1080p_h265_aac_shrink                                            Terminal                        1"
"BL Banking Launcher                                                    System Events                   1"
"BL Banking Launcher                                                    Terminal                        1"
"backup_files_tar_gz                                                    System Events                   1"
"backup_files_tar_gz                                                    Terminal                        1"
"gui_apps_backup                                                        System Events                   1"
"gui_apps_backup                                                        Terminal                        1"
"virtualbox_backup                                                      System Events                   1"
"run_on_login_signal                                                    System Events                   1"
"run_on_login_whatsapp                                                  System Events                   1"
"iTerm                                                                  System Events                   1"
"XtraFinder                                                             Finder                          1"
"Ondesoft AudioBook Converter                                           iTunes                          1"
"EagleFiler                                                             Mail                            1"
"EagleFiler                                                             Finder                          1"
"witchdaemon                                                            Mail                            0"
)
        
        
for APP_ENTRY in "${AUTOMATIONAPPS[@]}"
do
    #echo "$APP_ENTRY"
    SOURCE_APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
    SOURCE_APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    SOURCE_APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$SOURCE_APP"
    #echo "$SOURCE_APP_ID"
    #echo "$SOURCE_APP_CSREQ"
    #
    AUTOMATED_APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
    AUTOMATED_APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    AUTOMATED_APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$AUTOMATED_APP"
    #echo "$AUTOMATED_APP_ID"
    #echo "$AUTOMATED_APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^ //g' | sed 's/ $//g')
    #
    # working, but does not show in gui of system preferences, use csreq for the entry to make it work and show
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,0,'"$AUTOMATED_APP_ID"',?,NULL,?);"
    # not working, but shows correct entry in gui of system preferences, use csreq to make it work and show
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP_ID"',0,$PERMISSION_GRANTED,1,'UNUSED',NULL,0,'"$AUTOMATED_APP_ID"','UNUSED',NULL,?);"
    # working and showing in gui of system preferences with csreq
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP_ID"',0,$PERMISSION_GRANTED,1,$SOURCE_APP_CSREQ,NULL,0,'"$AUTOMATED_APP_ID"',$AUTOMATED_APP_CSREQ,NULL,?);"
    #
    SOURCE_APP_NAME_PRINT=$(echo "$SOURCE_APP_NAME" | cut -d ":" -f1 | awk -v len=28 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
    AUTOMATED_APP_NAME_PRINT=$(echo "$AUTOMATED_APP_NAME" | cut -d ":" -f1 | awk -v len=28 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
    #
    printf "%-30s %-30s %-5s\n" "$SOURCE_APP_NAME_PRINT" "$AUTOMATED_APP_NAME_PRINT" "$PERMISSION_GRANTED"
    #
    unset SOURCE_APP_NAME
    unset SOURCE_APP_ID
    unset SOURCE_APP_CSREQ   
    unset AUTOMATED_APP_NAME
    unset AUTOMATED_APP_ID
    unset AUTOMATED_APP_CSREQ
    unset PERMISSION_GRANTED
done


###

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



