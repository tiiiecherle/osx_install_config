#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

env_enter_sudo_password



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
# sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db
# .dump access

# quit database
# .quit

DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_SYSTEM"
DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_USER"

# getting application identifier
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APPS"/enterapplicaitonnamehere.app/Contents/Info.plist
# example
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APPS"/Overflow.app/Contents/Info.plist
# com.stuntsoftware.Overflow
# example2
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' ""$PATH_TO_APPS"/System Preferences.app/Contents/Info.plist"
# com.apple.systempreferences


### privacy - accessibility

## 	x 	calendars backup			com.apple.ScriptEditor.id.calendars-backup
# 	x 	gui apps backup			com.apple.ScriptEditor.id.gui-apps-backup
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
#com.apple.ScriptEditor.id.calendars-backup
com.apple.ScriptEditor.id.gui-apps-backup
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

## 	x 	contacts backup             com.apple.ScriptEditor.id.contacts-backup
# 	x 	gui apps backup			com.apple.ScriptEditor.id.gui-apps-backup
#	x	terminal					com.apple.Terminal
#	x	iterm2                      com.googlecode.iterm2
#	x	dialectic					com.jen.dialectic
#	x	alfred 3					com.runningwithcrayons.Alfred-3
#	x	geburtstagschecker			earthlingsoft.GeburtstagsChecker

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAddressBook';"

CONTACTSAPPS=(
#com.apple.ScriptEditor.id.contacts-backup
com.apple.ScriptEditor.id.gui-apps-backup
#com.apple.Terminal
#com.googlecode.iterm2
com.jen.dialectic
com.runningwithcrayons.Alfred-3
earthlingsoft.GeburtstagsChecker
)

for contacts_apps in ${CONTACTSAPPS[@]}; do
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','"$contacts_apps"',0,1,1,NULL,NULL);"
done



### privacy - calendar

## 	x 	calendars backup			com.apple.ScriptEditor.id.calendars-backup
# 	x 	gui apps backup			com.apple.ScriptEditor.id.gui-apps-backup
#	x	istat menus                 com.bjango.istatmenusstatus


sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceCalendar';"

CALENDARAPPS=(
#com.apple.ScriptEditor.id.calendars-backup
com.apple.ScriptEditor.id.gui-apps-backup
com.bjango.istatmenusstatus
)

for calendar_apps in ${CALENDARAPPS[@]}; do
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','"$calendar_apps"',0,1,1,NULL,NULL);"
done


### privacy - reminders

# 	x 	gui apps backup			com.apple.ScriptEditor.id.gui-apps-backup


sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceReminders';"

REMINDERAPPS=(
com.apple.ScriptEditor.id.gui-apps-backup
)

for reminder_apps in ${REMINDERAPPS[@]}; do
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceReminders','"$reminder_apps"',0,1,1,NULL,NULL);"
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



