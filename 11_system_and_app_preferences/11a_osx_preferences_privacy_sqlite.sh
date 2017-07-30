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

# sqlite database for calendar, contacts, ...
#  ~/Library/Application Support/com.apple.TCC/TCC.db

# reading database
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db
# or
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db
# .dump access

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

# 	x 	calendars backup			com.apple.ScriptEditor.id.calendars-backup
#	x	overflow					com.stuntsoftware.Overflow
#	x	script-editor				com.apple.ScriptEditor2
#   x   system-preferences          com.apple.systempreferences
#	x	witch						com.manytricks.WitchWrapper
#	x	witchdaemon                 com.manytricks.witchdaemon

# add application to accessibility
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAccessibility','IDENTIFIER',0,1,1,NULL,NULL);" 
# example
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.stuntsoftware.Overflow',0,1,1,NULL,NULL);" 

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
com.apple.ScriptEditor.id.calendars-backup
com.stuntsoftware.Overflow
com.apple.ScriptEditor2
com.apple.systempreferences
com.manytricks.WitchWrapper
com.manytricks.witchdaemon
com.apple.Terminal
com.googlecode.iterm2
)

for accessibility_apps in ${ACCESSIBILITYAPPS[@]}; do
sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','"$accessibility_apps"',0,1,1,NULL,NULL);"
done



### privacy - contacts

# 	x 	contacts backup             com.apple.ScriptEditor.id.contacts-backup
#	x	terminal					com.apple.Terminal
#	x	iterm2                      com.googlecode.iterm2
#	x	dialectic					com.jen.dialectic
#	x	alfred 3					com.runningwithcrayons.Alfred-3
#	x	geburtstagschecker			earthlingsoft.GeburtstagsChecker

# add application to accessibility
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAddressBook','IDENTIFIER',0,1,1,NULL,NULL);" 
# example
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAddressBook','com.apple.ScriptEditor.id.contacts-backup',0,1,1,NULL,NULL);" 

# remove application from accessibility
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='IDENTIFIER';"
# example
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='com.apple.ScriptEditor.id.contacts-backup';"


sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAddressBook';"

CONTACTSAPPS=(
com.apple.ScriptEditor.id.contacts-backup
com.apple.Terminal
com.googlecode.iterm2
com.jen.dialectic
com.runningwithcrayons.Alfred-3
earthlingsoft.GeburtstagsChecker
)

for contacts_apps in ${CONTACTSAPPS[@]}; do
sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','"$contacts_apps"',0,1,1,NULL,NULL);"
done



### privacy - calendar

# 	x 	calendars backup			com.apple.ScriptEditor.id.calendars-backup
#	x	istat menus                 com.bjango.istatmenusstatus

# add application to accessibility
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceCalendar','IDENTIFIER',0,1,1,NULL,NULL);" 
# example
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceCalendar','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);" 

# remove application from accessibility
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='IDENTIFIER';"
# example
# sudo sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='com.apple.ScriptEditor.id.calendars-backup';"


sudo sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceCalendar';"

CALENDARAPPS=(
com.apple.ScriptEditor.id.calendars-backup
com.bjango.istatmenusstatus
)

for calendar_apps in ${CALENDARAPPS[@]}; do
sudo sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','"$calendar_apps"',0,1,1,NULL,NULL);"
done



###

echo "done ;)"
echo "the changes need a reboot or logout to take effect"
echo "please logout or reboot"
#echo "initializing loggin out"

#sleep 2

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout



###
### unsetting password
###

unset SUDOPASSWORD



