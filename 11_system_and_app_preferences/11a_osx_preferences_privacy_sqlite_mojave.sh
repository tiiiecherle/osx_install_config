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
### privacy settings
###

### general

# sqlite database for accessibility
#  /Library/Application Support/com.apple.TCC/TCC.db

# sqlite database for calendar, contacts, reminders, ...
#  ~/Library/Application Support/com.apple.TCC/TCC.db

# reading database
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db
# or
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db
# .dump access
# .schema access

# quit database
# .quit

DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_SYSTEM"
DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_USER"

# getting application identifier
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/enterapplicaitonnamehere.app/Contents/Info.plist
# example
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/Overflow.app/Contents/Info.plist
# com.stuntsoftware.Overflow
# example2
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "/Applications/System Preferences.app/Contents/Info.plist"
# com.apple.systempreferences


### privacy - accessibility

# add application to accessibility
#terminal
#INSERT INTO access VALUES('kTCCServiceAccessibility','com.apple.Terminal',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,1533680610);
#overflow
#'IDENTIFIER',0,0,1     # added, but not enabled
#'IDENTIFIER',0,1,1     # added and enabled
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.stuntsoftware.Overflow',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,1533680686);" 

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

sudo sqlite3 "$DATABASE_SYSTEM" "DELETE FROM access"

ACCESSIBILITYAPPS=(
com.apple.ScriptEditor.id.brew-casks-update
com.apple.ScriptEditor.id.video-720p-h265-aac-shrink
com.apple.ScriptEditor.id.video-1080p-h265-aac-shrink
com.apple.ScriptEditor.id.gui-apps-backup
com.apple.automator.decrypt_finder_input_gpg_progress
com.apple.automator.unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress
com.stuntsoftware.Overflow
com.apple.ScriptEditor2
com.apple.systempreferences
com.manytricks.WitchWrapper
com.manytricks.witchdaemon
com.apple.Terminal
com.googlecode.iterm2
org.virtualbox.app.VirtualBox
com.selznick.PasswordWallet
com.kiwifruitware.VirtualBox_Menulet
)

for accessibility_app in ${ACCESSIBILITYAPPS[@]}; 
do
    sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','"$accessibility_app"',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,0,?);"
done



### privacy - contacts

sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAddressBook';"

CONTACTSAPPS=(
#com.apple.ScriptEditor.id.contacts-backup
com.apple.ScriptEditor.id.gui-apps-backup
#com.apple.Terminal
#com.googlecode.iterm2
com.jen.dialectic
com.runningwithcrayons.Alfred-3
earthlingsoft.GeburtstagsChecker
)

for contacts_app in ${CONTACTSAPPS[@]}
do
    sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','"$contacts_app"',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
done



### privacy - calendar

sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceCalendar';"

CALENDARAPPS=(
#com.apple.ScriptEditor.id.calendars-backup
com.apple.ScriptEditor.id.gui-apps-backup
com.bjango.istatmenus.status
)

for calendar_app in ${CALENDARAPPS[@]}
do
    sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','"$calendar_app"',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
done



### privacy - reminders

sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceReminders';"

REMINDERAPPS=(
com.apple.ScriptEditor.id.gui-apps-backup
)

for reminder_app in ${REMINDERAPPS[@]}
do
    sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceReminders','"$reminder_app"',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
done



### privacy - microphone

sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceMicrophone';"

MICROPHONEAPPS=(
org.virtualbox.app.VirtualBox
)

for microphone_app in ${MICROPHONEAPPS[@]}
do
    sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceMicrophone','"$microphone_app"',0,1,1,?,NULL,NULL,NULL,NULL,NULL,?);"
done


### privacy - automation
# does not show in system preferences window, but works

sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAppleEvents';"
#sudo tccutil reset AppleEvents   

AUTOMATIONAPPS=(
"com.apple.ScriptEditor.id.brew-casks-update                            com.apple.systemevents"
"com.apple.ScriptEditor.id.brew-casks-update                            com.apple.Terminal"
"com.apple.ScriptEditor.id.pdf-200dpi-shrink                            com.apple.systemevents"
"com.apple.ScriptEditor.id.pdf-200dpi-shrink                            com.apple.Terminal"
"com.apple.automator.decrypt_finder_input_gpg_progress                  com.apple.systemevents"
"com.apple.automator.decrypt_finder_input_gpg_progress                  com.apple.Terminal"
"com.apple.automator.unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress    com.apple.systemevents"
"com.apple.automator.unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress    com.apple.Terminal"
"com.apple.ScriptEditor.id.video-720p-h265-aac-shrink                   com.apple.systemevents"
"com.apple.ScriptEditor.id.video-720p-h265-aac-shrink                   com.apple.Terminal"
"com.apple.ScriptEditor.id.video-1080p-h265-aac-shrink                  com.apple.systemevents"
"com.apple.ScriptEditor.id.video-1080p-h265-aac-shrink                  com.apple.Terminal"
"com.apple.ScriptEditor.id.BL-Banking-Launcher-ts                       com.apple.systemevents"
"com.apple.ScriptEditor.id.BL-Banking-Launcher-ts                       com.apple.Terminal"
"com.apple.ScriptEditor.id.BL-Banking-Launcher-ws                       com.apple.systemevents"
"com.apple.ScriptEditor.id.BL-Banking-Launcher-ws                       com.apple.Terminal"
"com.apple.ScriptEditor.id.backup-files-tar-gz                          com.apple.systemevents"
"com.apple.ScriptEditor.id.backup-files-tar-gz                          com.apple.Terminal"
"com.apple.ScriptEditor.id.gui-apps-backup                              com.apple.systemevents"
"com.apple.ScriptEditor.id.virtualbox-backup                            com.apple.systemevents"
"com.apple.ScriptEditor.id.virtualbox-backup                            com.apple.Terminal"
"com.apple.ScriptEditor.id.run-on-login-signal                          com.apple.systemevents"
"com.apple.ScriptEditor.id.run-on-login-whatsapp                        com.apple.systemevents"
"com.googlecode.iterm2                                                  com.apple.systemevents"
)

for automation in "${AUTOMATIONAPPS[@]}"
do
    SOURCE_APP=$(echo "$automation" | awk '{print $1}' | sed 's/ //g') 
    AUTOMATED_APP=$(echo "$automation" | awk '{print $2}' | sed 's/ //g')
    #echo "$SOURCE_APP"
    #echo "$AUTOMATED_APP"
    sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP"',0,1,1,?,NULL,0,'"$AUTOMATED_APP"',?,NULL,?);"
done



###

echo "done ;)"
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



