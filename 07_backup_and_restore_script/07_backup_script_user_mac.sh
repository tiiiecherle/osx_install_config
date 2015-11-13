#!/bin/bash

###
### backup / restore script v27
###

# checking if the script is run as root
if [ $EUID != 0 ]; then
    sudo sh "$0" "$@"
    exit $?
fi
sudo echo password correct, running script...

# choosing the backup and defining $BACKUP variable
export PS3="Please select option by typing the number: "
select OPTION in BACKUP RESTORE
  do
  echo You selected option $OPTION.
    break
done

# check if a valid option was selected
if [ "$OPTION" == "" ]; then
    echo "no valid option selected - exiting script..."
    exit
else
    :
fi

###
### defining the variables
###

# starting a function to tee a record to a logfile
function backup_restore {

# backupdate
DATE=$(date +%F)

# users on the system without ".localized" and "Shared"
SYSTEMUSERS=$(ls /Users | egrep -v "^[.]" | egrep -v "Shared")

# user directory
if [ "$OPTION" == "BACKUP" ]; then
export PS3="Please select user to backup by typing the number: "
else
:
fi

if [ "$OPTION" == "RESTORE" ]; then
    export PS3="Please select user to restore to by typing the number: "
else
    :
fi

select SELECTEDUSER in "$SYSTEMUSERS"
  do
  echo You selected user "$SELECTEDUSER".
    break
done

# check1 if a valid user was selected
USERCHECK=$(find /Users -maxdepth 1 -name "$SELECTEDUSER" -exec basename {} \;)
if [ "$SELECTEDUSER" != "$USERCHECK" ]; then
    echo "no valid user selected - exiting script because of no real username..."
    exit
else
    :
fi

# check2 if a valid user was selected
if [ "$SELECTEDUSER" == "" ]; then
    echo "no valid user selected - exiting script because of empty username..."
    exit
else
    :
fi

# user home folder
HOME=Users/"$SELECTEDUSER"

# checking if user directory exists
if [ -d "/$HOME" ]; then
    echo "user home directory exists - running script..."

# path to current working directory
CURRENT_DIR="$(pwd)"
echo current directory is "$CURRENT_DIR"

# path to running script directory
SCRIPT_DIR="$(dirname $0)"
echo script directory is "$SCRIPT_DIR"

###
### backup
###

# checking if backup option was selected
if [[ "$OPTION" == "BACKUP" ]]; 
    then
    echo "running backup..."
    sleep 1

    # running contacts backup applescript
    read -p "do you want to run an address book backup (y/n)?" CONT1
    if [ "$CONT1" == "y" ]
    then
        echo running contacts backup... please wait...
        # service entry for for contacts backup
        sudo sqlite3 "/"$HOME"/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceAddressBook','com.apple.ScriptEditor.id.contacts-backup',0,1,1,NULL,NULL);"
        sleep 2
        open "$SCRIPT_DIR"/addressbook/contacts_backup.app
        #PID=$(ps aux | grep contacts_backup | grep -v grep | awk "{ print \$2 }")
        #echo $PID
        # waiting for the process to finish
        while ps aux | grep contacts_backup | grep -v grep > /dev/null; do sleep 1; done
        # cleaning up old backups (only keeping the latest 3)
        find /"$HOME"/Documents/backup/addressbook -type d -maxdepth 0 -print0 | xargs -0 ls -m -1 | cat | sed 1,3d | while read -r ADDRESSBOOKBACKUPS
        do
            sudo rm -rf /"$HOME"/Documents/backup/addressbook/"$ADDRESSBOOKBACKUPS"
        done
        osascript -e 'tell application "Terminal" to activate'
    else
        :
    fi

    # running calendars backup applescript
    read -p "do you want to run an calendars backup (y/n)?" CONT2
    if [ "$CONT2" == "y" ]
    then
        echo "running calendars backup... please do not touch your computer until the calendar app quits..."
        # accessibility entry for calendar backup
        sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);"
        # service entry for for calendar backup
        sudo sqlite3 "/"$HOME"/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceCalendar','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);"
        sleep 2
        open "$SCRIPT_DIR"/calendar/calendars_backup.app
        #PID=$(ps aux | grep calendars_backup | grep -v grep | awk "{ print \$2 }")
        #echo $PID
        # waiting for the process to finish
        while ps aux | grep calendars_backup | grep -v grep > /dev/null; do sleep 1; done
        # cleaning up old backups (only keeping the latest 3)
        find /"$HOME"/Documents/backup/calendar -type d -maxdepth 0 -print0 | xargs -0 ls -m -1 | cat | sed 1,3d | while read -r CALENDARSBACKUPS
        do
            sudo rm -rf /"$HOME"/Documents/backup/addressbook/"$CALENDARSBACKUPS"
        done
        osascript -e 'tell application "Terminal" to activate'
    else
        :
    fi

    # backup destination
    DESTINATION="$HOME"/Desktop/backup_"$SELECTEDUSER"_"$DATE"
    mkdir -p /"$DESTINATION"

    # master directory
    cd "$SCRIPT_DIR"/master
    for TEXTFILES in *.txt
        do
        cd "$SCRIPT_DIR"/master
        # read first line of textfile and cd to it
        PATH1=$(head -n 1 "$TEXTFILES" | sed 's|~|'"/$HOME"'|')
        if [ -d "$PATH1" ]
            then
            cd "$PATH1"
            echo backing up master "$PATH1"/...
            cd "$SCRIPT_DIR"/master
            # read all lines, starting from line 2 and cat them to a list
            cat "$TEXTFILES" | sed 1,1d | while read -r ENTRIES
            do
#                IFS=$'\n'
                if [ -d "$PATH1"/"$ENTRIES" ] || [ -f "$PATH1"/"$ENTRIES" ]
                    then
                    cd "$PATH1"
                    mkdir -p /"$DESTINATION$PATH1"
                    echo "   ""$ENTRIES"
#                    echo "   ""$PATH1"/"$ENTRIES"
                    rsync -a "$ENTRIES" /"$DESTINATION$PATH1"
                else
                    :
                fi
            done
        else
        echo "$PATH1" is not a directory, skipping "$TEXTFILES"
        fi
    done
    # user directory
    cd "$SCRIPT_DIR"/user
    for TEXTFILES in *.txt
        do
        cd "$SCRIPT_DIR"/user
        # read first line of textfile and cd to it
        PATH1=$(head -n 1 "$TEXTFILES" | sed 's|~|'"/$HOME"'|')
        if [ -d "$PATH1" ]
            then
            cd "$PATH1"
            echo backing up user "$PATH1"/...
            cd "$SCRIPT_DIR"/user
            # read all lines, starting from line 2 and cat them to a list
            cat "$TEXTFILES" | sed 1,1d | while read -r ENTRIES
            do
#                IFS=$'\n'
                if [ -d "$PATH1"/"$ENTRIES" ] || [ -f "$PATH1"/"$ENTRIES" ]
                    then
                    cd "$PATH1"
                    mkdir -p /"$DESTINATION$PATH1"
                    echo "   ""$ENTRIES"
#                    echo "   ""$PATH1"/"$ENTRIES"
                    rsync -a "$ENTRIES" /"$DESTINATION$PATH1"
                else
                    :
                fi
            done
        else
        echo "$PATH1" is not a directory, skipping "$TEXTFILES"
        fi
    done
    echo "backup done ;)"
    # opening keka for archiving
    osascript -e 'tell application "Keka.app" to activate'
    # moving log to backup directory
    mv /"$HOME"/Desktop/backup_restore_log.txt /"$DESTINATION"/_backup_restore_log.txt
else
    :
fi

###
### restore
###

# place the files from the backup in two folders
# /Users/USERNAME/Desktop/restore/master/backup_directories (Applications, Library, User)
# /Users/USERNAME/Desktop/restore/user/backup_directories (Applications, Library, User)

RESTOREDIR=/"$HOME"/Desktop/restore
RESTOREMASTERDIR="$RESTOREDIR"/master
RESTOREUSERDIR="$RESTOREDIR"/user

#RESTORETO=/$HOME/Desktop/testrestore
#mkdir -p $RESTORETO
RESTORETO=""

# checking if restore option was selected
if [[ "$OPTION" == "RESTORE" ]]; 
    then
    echo "running restore..."

    # master user restore directory
    MASTERUSER=$(ls "$RESTOREMASTERDIR"/Users | head -n 1)
    echo masteruser for restore is "$MASTERUSER"

    # user from restore directory
    USERUSER=$(ls "$RESTOREUSERDIR"/Users | head -n 1)
    echo user for restore is "$USERUSER"

    # user to restore to
    echo user to restore to is "$SELECTEDUSER"

    ### running restore

    # master directory
    cd "$SCRIPT_DIR"/master
    for TEXTFILES in *.txt
        do
        cd "$SCRIPT_DIR"/master
        # read first line of textfile, create directory if it does not exist and cd to it
        PATH1=$(head -n 1 "$TEXTFILES" | sed 's|~|'"/$HOME"'|')
        PATH2=$(head -n 1 "$TEXTFILES" | sed 's|~|'"/Users/$MASTERUSER"'|')
        mkdir -p "$PATH1"
        if [ -d "$PATH1" ]
            then
            echo restoring master "$PATH1"/...
            cd "$SCRIPT_DIR"/master
            # read all lines, starting from line 2 and cat them to a list
            cat "$TEXTFILES" | sed 1,1d | while read -r ENTRIES
            do
#                IFS=$'\n'
                if [ -d "$RESTOREMASTERDIR$PATH2"/"$ENTRIES" ] || [ -f "$RESTOREMASTERDIR$PATH2"/"$ENTRIES" ]
                    then
                    cd "$RESTORETO$PATH1"
                    rm -rf "$ENTRIES"
                    cd "$RESTOREMASTERDIR$PATH2"
                    mkdir -p "$RESTORETO$PATH1"
                    echo "   ""$RESTOREMASTERDIR$PATH2"/"$ENTRIES"
                    echo "   ""to ""$RESTORETO$PATH1"/"$ENTRIES"
                    echo "   "
                    #echo "   ""$ENTRIES"
                    rsync -a "$ENTRIES" "$RESTORETO$PATH1"
                else
                    echo no "$ENTRIES" in master backup - skipping...
                fi
            done
        else
        echo "$PATH1" is not a directory, skipping "$TEXTFILES"
        fi
    done
    # user directory
    cd "$SCRIPT_DIR"/user
    for TEXTFILES in *.txt
        do
        cd "$SCRIPT_DIR"/user
        # read first line of textfile and cd to it
        PATH1=$(head -n 1 "$TEXTFILES" | sed 's|~|'"/$HOME"'|')
        PATH2=$(head -n 1 "$TEXTFILES" | sed 's|~|'"/Users/$USERUSER"'|')
        mkdir -p "$PATH1"
        if [ -d "$PATH1" ]
            then
            echo restoring user "$PATH1"/...
            cd "$SCRIPT_DIR"/user
            # read all lines, starting from line 2 and cat them to a list
            cat "$TEXTFILES" | sed 1,1d | while read -r ENTRIES
            do
#                IFS=$'\n'
                if [ -d "$RESTOREUSERDIR$PATH2"/"$ENTRIES" ] || [ -f "$RESTOREUSERDIR$PATH2"/"$ENTRIES" ]
                    then
                    cd "$RESTORETO$PATH1"
                    rm -rf "$ENTRIES"
                    cd "$RESTOREUSERDIR$PATH2"
                    mkdir -p "$RESTORETO$PATH1"
                    echo "   ""$RESTOREUSERDIR$PATH2"/"$ENTRIES"
                    echo "   ""to ""$RESTORETO$PATH1"/"$ENTRIES"
                    echo "   "
                    #echo "   ""$ENTRIES"
                    rsync -a "$ENTRIES" "$RESTORETO$PATH1"
                else
                    echo no "$ENTRIES" in user backup - skipping...
                fi
            done
        else
        echo "$PATH1" is not a directory, skipping "$TEXTFILES"
        fi
    done

#    IFS=$SAVEIFS
    echo "restore done ;)"

    ### cleaning up old unused files after restore

    echo "cleaning up some files..."

    # virtualbox extpack
    find /"$HOME"/Library/VirtualBox -name "*.vbox-extpack" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r VBOXEXTENSIONS
    do
        sudo rm "$VBOXEXTENSIONS"
    done

    # virtualbox logs
    find /"$HOME"/Library/VirtualBox -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r VBOXLOGS
    do
        sudo rm "$VBOXLOGS"
    done

    # fonts
    find /"$HOME"/Library/Fonts \( -name "*.dir" -o -name "*.list" -o -name "*.scale" \) -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r FONTSFILES
    do
        sudo rm "$FONTSFILES"
    done

    # jameica backups
    find /"$HOME"/Library/jameica -name "jameica-backup-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r JAMEICABACKUPS
    do
        sudo rm "$JAMEICABACKUPS"
    done

    # jameica logs
    find /"$HOME"/Library/jameica -name "jameica.log-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r JAMEICALOGS
    do
        sudo rm "$JAMEICALOGS"
    done

    # address book migration
    find /"$HOME"/Library/"Application Support"/AddressBook -name "Migration*.abbu.tbz" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r ADDRESSBOOKMIGRATION
    do
        sudo rm "$ADDRESSBOOKMIGRATION"
    done

    # 2do
    find /"$HOME"/Library/"Application Support"/Backups -name "*.db" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,2d | while read -r TODOBACKUPS
    do
        sudo rm "$TODOBACKUPS"
    done

    # unified remote
    find /"$HOME"/Library/"Application Support"/"Unified Remote" -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r UNIFIEDREMOTELOGS
    do
        sudo rm "$UNIFIEDREMOTELOGS"
    done

    echo "cleaning done ;)"

    ### repairing file permissions in user ~/ folder
    echo "repairing file permissions in user ~/ folder..."
    chown -R "$SELECTEDUSER" /"$HOME"/*
    echo "done ;)"

else
    :
fi
#
else
    echo "user home directory does not exist - exiting script..."
    exit
fi

}

# running function to tee a record to a logfile
backup_restore | tee ~/Desktop/backup_restore_log.txt

