#!/bin/bash

###
### backup / restore script v33
###

#TARGZSAVEDIR=/Users/tom/Desktop/targz
#APPLESCRIPTDIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")

# checking if the script is run as root
if [ $EUID != 0 ]; then
    sudo -E bash "$0" "$@"
    #sudo bash "$0" "$@"
    exit $?
fi
echo ""
sudo echo password correct, running script...
echo ""

# trapping script to kill subprocesses when script is stopped
#trap 'echo "" && kill $(jobs -rp) >/dev/null 2>&1' SIGINT SIGTERM EXIT
trap "echo "" && killall background >/dev/null 2>&1" EXIT
#trap "echo "" && trap - SIGTERM >/dev/null 2>&1 && kill -- -$$ >/dev/null 2>&1" SIGINT SIGTERM EXIT
set -e

# choosing the backup and defining $BACKUP variable
export PS3="Please select option by typing the number: "
select OPTION in BACKUP RESTORE
do
    echo You selected option $OPTION.
    echo ""
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
### backup / restore function
###

# starting a function to tee a record to a logfile
function backup_restore {
    
# backupdate
DATE=$(date +%F)

# users on the system without ".localized" and "Shared"
SYSTEMUSERS=$(ls /Users | egrep -v "^[.]" | egrep -v "Shared")

# user directory
if [ "$OPTION" == "BACKUP" ]
then
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
    echo ""
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

###
### variables and checks
###

# user home folder
HOMEFOLDER=Users/"$SELECTEDUSER"
echo HOMEFOLDER is "$HOMEFOLDER"

# checking if user directory exists
if [ -d "/$HOMEFOLDER" ]; then
    echo "user home directory exists - running script..."

# path to current working directory
CURRENT_DIR="$(pwd)"
echo current directory is "$CURRENT_DIR"

# path to running script directory
#SCRIPT_DIR="$(dirname $0)"
#SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
echo script directory is "$SCRIPT_DIR"

# checking syntax of backup / restore list
BACKUP_RESTORE_LIST="$SCRIPT_DIR"/list/backup_restore_list.txt
echo ""
SYNTAXERRORS=0
LINENUMBER=0
while IFS='' read -r line || [[ -n "$line" ]]
do
    LINENUMBER=$(($LINENUMBER+1))
	if [ ! "$line" == "" ] && [[ ! $line =~ ^[\#] ]] && [[ ! $line =~ ^m[[:blank:]] ]] && [[ ! $line =~ ^u[[:blank:]] ]] && [[ ! $line =~ ^echo[[:blank:]] ]]
	then
        echo "wrong syntax for entry in line "$LINENUMBER": "$line""
        SYNTAXERRORS=$(($SYNTAXERRORS+1))
    else
    	:
        #echo "correct entry"
    fi
	    
done <"$BACKUP_RESTORE_LIST"

#echo "$SYNTAXERRORS"
if [ "$SYNTAXERRORS" -gt "0" ]
then
    echo "there are syntax errors in the backup / restore list, please correct the entries and rerun the script..."
    exit
else
	echo "sytanx of backup / restore list o.k., continuing..."
	echo ""
fi

###
### checking installation of needed tools
###

echo checking if all needed tools are installed...

# installing command line tools
if xcode-select --install 2>&1 | grep installed >/dev/null
then
  	echo command line tools are installed...
else
  	echo command line tools are not installed, installing...
  	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
  	#sudo xcodebuild -license accept
fi

# checking and updating homebrew including tools
if [[ $(sudo su $(who | grep console | awk '{print $1}') -c 'which brew') != "" ]]
then
    echo homebrew is installed...
    
    if [[ $(sudo su $(who | grep console | awk '{print $1}') -c 'brew list' | grep gnu-tar) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}') -c 'brew list' | grep pigz) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}') -c 'brew list' | grep pv) == '' ]] || [[ $(sudo su $(who | grep console | awk '{print $1}') -c 'brew list' | grep coreutils) == '' ]]
    then
        echo at least one needed homebrew tool of gnu-tar, pigz, pv and coreutils is missing, exiting...
        exit
    else
        echo needed homebrew tools are installed...     
    fi
else
    echo homebrew is not installed, exiting...
    exit
fi

echo ''

###
### backup
###

# checking if backup option was selected
if [[ "$OPTION" == "BACKUP" ]]; 
    then
    echo "running backup..."
    sleep 1
    
    # opening applescript which will ask for saving location of compressed file
    echo "asking for directory to save the backup to..."
    TARGZSAVEDIR=$(sudo su $(who | grep console | awk '{print $1}') -c 'osascript '"$SCRIPT_DIR"'/backup_restore_script/ask_save_to.scpt' | sed s'/\/$//')
    sleep 1
    #echo ''
    # checking if valid path for backup was selected
    if [ -e "$TARGZSAVEDIR" ]
    then
        echo "backup will be saved to "$TARGZSAVEDIR""
    else
        echo "no valid path for saving the backup selected, exiting script..."
        exit
    fi
    echo ''
    
    # virtualbox backup
    if [ "$SELECTEDUSER" == tom ]
    then
            read -p "do you want to backup virtualbox images (y/N)? " CONT1
            if [ "$CONT1" == "y" ]
            then
                echo "running virtualbox backup..."
                open "$SCRIPT_DIR"/vbox_backup/virtualbox_backup.app
            else
                :
            fi
    else
        :
    fi
    
    # files backup
    if [ "$SELECTEDUSER" == tom ] || [ "$SELECTEDUSER" == bobby ]
    then
            read -p "do you want to backup local files (y/N)? " CONT2
            if [ "$CONT2" == "y" ]
            then
                echo "running files backup..."
                export FILESTARGZSAVEDIR="$TARGZSAVEDIR"
                export FILESAPPLESCRIPTDIR="$APPLESCRIPTDIR"
                export SELECTEDUSER
                bash "$SCRIPT_DIR"/files/run_files_backup.sh
                #echo ''
                #sleep 5
            else
                :
            fi
    else
        :
    fi

    # running contacts backup applescript
    read -p "do you want to run an address book backup (y/N)? " CONT3
    if [ "$CONT3" == "y" ]
    then
        echo running contacts backup... please wait...
        # service entry for for contacts backup
        sudo sqlite3 "/"$HOMEFOLDER"/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceAddressBook','com.apple.ScriptEditor.id.contacts-backup',0,1,1,NULL,NULL);"
        sleep 2
        # cleaning up old backups (only keeping the latest 4)
        find /"$HOMEFOLDER"/Documents/backup/addressbook -type d -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d | while read -r ADDRESSBOOKBACKUPS
        do
            sudo rm -rf /"$HOMEFOLDER"/Documents/backup/addressbook/"$ADDRESSBOOKBACKUPS"
        done
        # running contacts backup
        open "$SCRIPT_DIR"/addressbook/contacts_backup.app
        #PID=$(ps aux | grep contacts_backup | grep -v grep | awk "{ print \$2 }")
        #echo $PID
        # waiting for the process to finish
        while ps aux | grep contacts_backup | grep -v grep > /dev/null; do sleep 1; done
        osascript -e 'tell application "Terminal" to activate'
    else
        :
    fi

    # running calendars backup applescript
    read -p "do you want to run an calendars backup (y/N)? " CONT4
    if [ "$CONT4" == "y" ]
    then
        echo "running calendars backup... please do not touch your computer until the calendar app quits..."
        # accessibility entry for calendar backup
        sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);"
        # service entry for for calendar backup
        sudo sqlite3 "/"$HOMEFOLDER"/Library/Application Support/com.apple.TCC/TCC.db" "REPLACE INTO access VALUES('kTCCServiceCalendar','com.apple.ScriptEditor.id.calendars-backup',0,1,1,NULL,NULL);"
        sleep 2
        # cleaning up old backups (only keeping the latest 4)
        find /"$HOMEFOLDER"/Documents/backup/calendar -type d -maxdepth 0 -print0 | xargs -0 ls | sort -r | cat | sed 1,4d | while read -r CALENDARSBACKUPS
        do
            sudo rm -rf /"$HOMEFOLDER"/Documents/backup/calendar/"$CALENDARSBACKUPS"
        done
        # running calendar backup
        open "$SCRIPT_DIR"/calendar/calendars_backup.app
        #PID=$(ps aux | grep calendars_backup | grep -v grep | awk "{ print \$2 }")
        #echo $PID
        # waiting for the process to finish
        while ps aux | grep calendars_backup | grep -v grep > /dev/null; do sleep 1; done
        osascript -e 'tell application "Terminal" to activate'
    else
        :
    fi

    # backup destination
    DESTINATION="$HOMEFOLDER"/Desktop/backup_"$SELECTEDUSER"_"$DATE"
    mkdir -p /"$DESTINATION"
    
    # backup
    #
    echo ""
    echo "starting backup..."
    #    
    BACKUP_RESTORE_LIST="$SCRIPT_DIR"/list/backup_restore_list.txt
    #STTY_ORIG=$(stty -g)
    #TERMINALWIDTH=$(echo $COLUMNS)
    #TERMINALWIDTH=$(stty size | awk '{print $2}')
    TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
    LINENUMBER=0
    
    while IFS='' read -r line || [[ -n "$line" ]]
    do
    	
    	LINENUMBER=$(($LINENUMBER+1))
    	
        # if starting with one # and whitespace / tab
    	#if [[ $line =~ ^[\#][[:blank:]] ]]
    	
    	# if starting with more than one #
    	#if [[ $line =~ ^[\#]{2,} ]]
    
    	# if line is empty
    	#if [ -z "$line" ]
    	if [ "$line" == "" ]
    	then
            :
        else
            :
        fi
    	
    	# if starting with #
    	if [[ $line =~ ^[\#] ]]
    	then
            :
        else
            :
        fi
        
        # if starting with echo and whitespace / tab
    	if [[ $line =~ ^echo[[:blank:]] ]]
    	then
            OUTPUT=$(echo "$line" | sed 's/^echo*//' | sed -e 's/^[ \t]*//')
			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
            echo "$OUTPUT" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
        else
            :
        fi   
         	
    	# if starting with m and space / tab
    	if [[ $line =~ ^m[[:blank:]] ]]
    	then
            ENTRY=$(echo "$line" | cut -f2 | sed 's|~|'"/$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
            #echo "$ENTRY"
            DIRNAME_ENTRY=$(dirname "$ENTRY")
            #echo "$DIRNAME_ENTRY"
            BASENAME_ENTRY=$(basename "$ENTRY")
            #echo "$BASENAME_ENTRY"
            if [ -e "$ENTRY" ]
            then
                cd "$DIRNAME_ENTRY"
                mkdir -p /"$DESTINATION$DIRNAME_ENTRY"
                rsync -a "$BASENAME_ENTRY" /"$DESTINATION$DIRNAME_ENTRY"
            else
				TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-8))
                #echo "        ""$ENTRY" does not exist, skipping...
                echo "$BASENAME_ENTRY" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/        /g"
            fi
        else
            :
        fi
        
        # if starting with u and space / tab
    	if [[ $line =~ ^u[[:blank:]] ]]
    	then
            ENTRY=$(echo "$line" | cut -f2 | sed 's|~|'"/$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
            #echo "$ENTRY"
            DIRNAME_ENTRY=$(dirname "$ENTRY")
            #echo "$DIRNAME_ENTRY"
            BASENAME_ENTRY=$(basename "$ENTRY")
            #echo "$BASENAME_ENTRY"
            if [ -e "$ENTRY" ]
            then
                cd "$DIRNAME_ENTRY"
                mkdir -p /"$DESTINATION$DIRNAME_ENTRY"
                rsync -a "$BASENAME_ENTRY" /"$DESTINATION$DIRNAME_ENTRY"
            else
				TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-8))
                #echo "        ""$ENTRY" does not exist, skipping...
                echo "$BASENAME_ENTRY" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/        /g"           
            fi
        else
            :
        fi
        
    done <"$BACKUP_RESTORE_LIST"
    
    # resetting terminal settings or further input will not work
    #reset
    #stty "$STTY_ORIG"
    stty sane

    echo ''            
    echo "backup done ;)"
    echo ''
    # opening app for archiving
    #osascript -e 'tell application "Keka.app" to activate'
    
    #open -g -a "$SCRIPT_DIR"/archive/archive_tar_gz.app
    #osascript -e 'display dialog "backup finished, starting archiving..."'
    #osascript -e 'tell application "'"$SCRIPT_DIR"'/archive/archive_tar_gz.app" to activate'
    
    # homebrew updates
    echo "updating homebrew and tools..."
    # checking if online
    #wget -q --tries=1 --timeout=4 --spider google.com > /dev/null 2>&1
    ping -c 3 google.com > /dev/null 2>&1
    if [ $? -eq 0 ]
    then 
        # online
        echo "running brew update commands..."
        #sudo -u $(users)
        sudo su $(who | grep console | awk '{print $1}') -c 'brew update 1> /dev/null'
        if [[ $(sudo su $(who | grep console | awk '{print $1}') -c 'brew outdated') == "" ]] > /dev/null 2>&1
        then
        	echo "all homebrew packages are up to date..."
        else
        	echo "the following homebrew packages are outdated and will now be updated..."
        	sudo su $(who | grep console | awk '{print $1}') -c 'brew outdated --verbose'
        fi
        sudo su $(who | grep console | awk '{print $1}') -c 'brew upgrade --all 1> /dev/null'
        sudo su $(who | grep console | awk '{print $1}') -c 'brew cleanup 1> /dev/null'
        sudo su $(who | grep console | awk '{print $1}') -c 'brew cask cleanup 1> /dev/null'
        #sudo su $(who | grep console | awk '{print $1}') -c 'brew install pigz gnu-tar coreutils pv 1> /dev/null'
        sudo su $(who | grep console | awk '{print $1}') -c 'brew doctor 1> /dev/null'
        #sudo su $(who | grep console | awk '{print $1}') -c '"'$SCRIPT_DIR'"/homebrew_update.sh'
    else
        # not online
        echo "not online, skipping homebrew update..."
    fi  
    # homebrew permissions
    #BREWGROUP="admin"
    #BREWPATH=$(sudo su $(who | grep console | awk '{print $1}') -c 'brew --prefix') 
    #eval "echo $BREWPATH" > /dev/null 2>&1
    #if [ $? -eq 0 ] && [[ "$BREWPATH" != "" ]]
    #then
    #    echo "setting ownerships and permissions for homebrew..."
    #    echo homebrew path is "$BREWPATH"
    #    sudo chown -R 501:"$BREWGROUP" "$BREWPATH"
    #    sudo find "$BREWPATH" -type f -print0 | sudo xargs -0 chmod g+rw
    #    sudo find "$BREWPATH" -type d -print0 | sudo xargs -0 chmod g+rwx		
    #else
    #    echo homebrew path is empty or invalid, skipping setting ownerships and permissions for homebrew...
	#fi
	
    # moving log to backup directory
    mv /"$HOMEFOLDER"/Desktop/backup_restore_log.txt /"$DESTINATION"/_backup_restore_log.txt

    # compressing and moving backup
    echo ''
    echo "compressing and moving backup..."

    # checking and defining some variables
	#echo "TARGZSAVEDIR is "$TARGZSAVEDIR""
    #echo "APPLESCRIPTDIR is "$APPLESCRIPTDIR""
    DESKTOPBACKUPFOLDER=/"$DESTINATION"
    #echo "DESKTOPBACKUPFOLDER is "$DESKTOPBACKUPFOLDER""

    export TARGZSAVEDIR
    export APPLESCRIPTDIR
    export DESKTOPBACKUPFOLDER
    bash "$SCRIPT_DIR"/backup_restore_script/compress_and_move_backup.sh
    wait
    
    # deleting backup folder on desktop
    #echo ''
    echo "deleting backup folder on desktop..."
    if [ -e /"$DESTINATION" ]
    then
        #:
        rm -rf /"$DESTINATION"
    else
        :
    fi
    
    # done
    echo 'script finished ;)'
    exit

else
    :
fi

###
### restore
###

# place the files from the backup in two folders
# /Users/USERNAME/Desktop/restore/master/backup_directories (Applications, Library, User)
# /Users/USERNAME/Desktop/restore/user/backup_directories (Applications, Library, User)

RESTOREDIR=/"$HOMEFOLDER"/Desktop/restore
RESTOREMASTERDIR="$RESTOREDIR"/master
RESTOREUSERDIR="$RESTOREDIR"/user

#RESTORETODIR=/"$HOMEFOLDER"/Desktop/testrestore
#mkdir -p "$RESTORETODIR"
RESTORETODIR=""

# checking if restore option was selected
if [[ "$OPTION" == "RESTORE" ]]; 
    then
    echo "running restore..."

    # master user restore directory
    MASTERUSER=$(ls "$RESTOREMASTERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared" | head -n 1 )
    echo masteruser for restore is "$MASTERUSER"

    # user from restore directory
    USERUSER=$(ls "$RESTOREUSERDIR"/Users | egrep -v "^[.]" | egrep -v "Shared" | head -n 1 )
    echo useruser for restore is "$USERUSER"

    # user to restore to
    echo user to restore to is "$SELECTEDUSER"
    echo ""
    
    # stopping services and backing up files
    sudo launchctl stop org.cups.cupsd

    ### running restore
    BACKUP_RESTORE_LIST="$SCRIPT_DIR"/list/backup_restore_list.txt
    #STTY_ORIG=$(stty -g)
    #TERMINALWIDTH=$(echo $COLUMNS)
    #TERMINALWIDTH=$(stty size | awk '{print $2}')
    TERMINALWIDTH=$(stty cbreak -echo size | awk '{print $2}')
    LINENUMBER=0
    
    while IFS='' read -r line || [[ -n "$line" ]]
    do
        
        LINENUMBER=$(($LINENUMBER+1))
    	
        # if starting with one # and whitespace / tab
    	#if [[ $line =~ ^[\#][[:blank:]] ]]
    	
    	# if starting with more than one #
    	#if [[ $line =~ ^[\#]{2,} ]]
    
    	# if line is empty
    	#if [ -z "$line" ]
    	if [ "$line" == "" ]
    	then
            :
        else
            :
        fi
    	
    	# if starting with #
    	if [[ $line =~ ^[\#] ]]
    	then
            :
        else
            :
        fi
        
        # if starting with echo and whitespace / tab
    	if [[ $line =~ ^echo[[:blank:]] ]]
    	then
            OUTPUT=$(echo "$line" | sed 's/^echo*//' | sed -e 's/^[ \t]*//')
			TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
            echo "$OUTPUT" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
        else
            :
        fi
            	
    	# if starting with m and space / tab
    	if [[ $line =~ ^m[[:blank:]] ]]
    	then
    	    LOWERCASESECTION=master
            SECTIONUSER="$MASTERUSER"
            RESTORESECTIONDIR="$RESTOREMASTERDIR"
            #
            ENTRY_TO=$(echo "$line" | cut -f2 | sed 's|~|'"/$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
            ENTRY_FROM=$(echo "$line" | cut -f2 | sed 's|~|'"/Users/$SECTIONUSER"'|' | sed -e 's/[ /]\{2,\}/\//')
            #
            RESTORE_FROM=$(echo "$RESTORESECTIONDIR$ENTRY_FROM" | sed -e 's/[ /]\{2,\}/\//')
            RESTORE_TO=$(echo "$RESTORETODIR$ENTRY_TO" | sed -e 's/[ /]\{2,\}/\//')
            #
            DIRNAME_RESTORE_FROM=$(dirname "$RESTORE_FROM")
            #echo "$DIRNAME_RESTORE_FROM"
            BASENAME_RESTORE_FROM=$(basename "$RESTORE_FROM")
            #echo "$DIRNAME_RESTORE_FROM"
            DIRNAME_RESTORE_TO=$(dirname "$RESTORE_TO")
            #echo "$DIRNAME_RESTORE_TO"
            BASENAME_RESTORE_TO=$(basename "$RESTORE_TO")
            #
            sudo mkdir -p "$DIRNAME_RESTORE_TO"
            if [ -e "$DIRNAME_RESTORE_TO" ]
            then
                if [ -e "$RESTORE_FROM" ]
                then
                    sudo mkdir -p "$DIRNAME_RESTORE_TO"
                    if [ -e "$RESTORE_TO" ]
                    then
                        cd "$DIRNAME_RESTORE_TO"
                        sudo rm -rf "$BASENAME_RESTORE_TO"
                    else
                        :
                    fi
                    cd "$DIRNAME_RESTORE_FROM"
					TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
                    echo "$RESTORE_FROM" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
                    echo "to ""$RESTORE_TO" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
                    echo '     '
                    sudo rsync -a "$BASENAME_RESTORE_FROM" "$DIRNAME_RESTORE_TO"
                else
                    echo "no "$ENTRY_FROM" in "$LOWERCASESECTION" backup - skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
                    echo ''
                fi
            else
                echo "$DIRNAME_RESTORE_TO" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
            fi
        else
            :
        fi
        
        # if starting with u and space / tab
    	if [[ $line =~ ^u[[:blank:]] ]]
    	then
    	    LOWERCASESECTION=user
            SECTIONUSER="$USERUSER"
            RESTORESECTIONDIR="$RESTOREUSERDIR"
            #
            ENTRY_TO=$(echo "$line" | cut -f2 | sed 's|~|'"/$HOMEFOLDER"'|' | sed -e 's/[ /]\{2,\}/\//')
            ENTRY_FROM=$(echo "$line" | cut -f2 | sed 's|~|'"/Users/$SECTIONUSER"'|' | sed -e 's/[ /]\{2,\}/\//')
            #
            RESTORE_FROM=$(echo "$RESTORESECTIONDIR$ENTRY_FROM" | sed -e 's/[ /]\{2,\}/\//')
            RESTORE_TO=$(echo "$RESTORETODIR$ENTRY_TO" | sed -e 's/[ /]\{2,\}/\//')
            #
            DIRNAME_RESTORE_FROM=$(dirname "$RESTORE_FROM")
            #echo "$DIRNAME_RESTORE_FROM"
            BASENAME_RESTORE_FROM=$(basename "$RESTORE_FROM")
            #echo "$DIRNAME_RESTORE_FROM"
            DIRNAME_RESTORE_TO=$(dirname "$RESTORE_TO")
            #echo "$DIRNAME_RESTORE_TO"
            BASENAME_RESTORE_TO=$(basename "$RESTORE_TO")
            #
            sudo mkdir -p "$DIRNAME_RESTORE_TO"
            if [ -e "$DIRNAME_RESTORE_TO" ]
            then
                if [ -e "$RESTORE_FROM" ]
                then
                    sudo mkdir -p "$DIRNAME_RESTORE_TO"
                    if [ -e "$RESTORE_TO" ]
                    then
                        cd "$DIRNAME_RESTORE_TO"
                        sudo rm -rf "$BASENAME_RESTORE_TO"
                    else
                        :
                    fi
                    cd "$DIRNAME_RESTORE_FROM"
					TERMINALWIDTH_WITHOUT_LEADING_SPACES=$(($TERMINALWIDTH-5))
                    echo "$RESTORE_FROM" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
                    echo "to ""$RESTORE_TO" | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
                    echo '     '
                    sudo rsync -a "$BASENAME_RESTORE_FROM" "$DIRNAME_RESTORE_TO"
                else
                    echo "no "$ENTRY_FROM" in "$LOWERCASESECTION" backup - skipping..." | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
                    echo ''
                fi
            else
                echo "$DIRNAME_RESTORE_TO" does not exist, skipping... | fold -w "$TERMINALWIDTH_WITHOUT_LEADING_SPACES" | sed "s/^/     /g"
            fi
        else
            :
        fi
        
    done <"$BACKUP_RESTORE_LIST"
    
    # resetting terminal settings or further input will not work
    #reset
    #stty "$STTY_ORIG"
    stty sane

    #echo ""
    echo "restore done ;)"

    ### cleaning up old unused files after restore

    echo ""
    echo "cleaning up some files..."

    # virtualbox extpack
    find /"$HOMEFOLDER"/Library/VirtualBox -name "*.vbox-extpack" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r VBOXEXTENSIONS
    do
        sudo rm "$VBOXEXTENSIONS"
    done

    # virtualbox logs
    find /"$HOMEFOLDER"/Library/VirtualBox -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r VBOXLOGS
    do
        sudo rm "$VBOXLOGS"
    done

    # fonts
    find /"$HOMEFOLDER"/Library/Fonts \( -name "*.dir" -o -name "*.list" -o -name "*.scale" \) -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r FONTSFILES
    do
        sudo rm "$FONTSFILES"
    done

    # jameica backups
    find /"$HOMEFOLDER"/Library/jameica -name "jameica-backup-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r JAMEICABACKUPS
    do
        sudo rm "$JAMEICABACKUPS"
    done

    # jameica logs
    find /"$HOMEFOLDER"/Library/jameica -name "jameica.log-*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,1d | while read -r JAMEICALOGS
    do
        sudo rm "$JAMEICALOGS"
    done

    # address book migration
    find /"$HOMEFOLDER"/Library/"Application Support"/AddressBook -name "Migration*.abbu.tbz" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r ADDRESSBOOKMIGRATION
    do
        sudo rm "$ADDRESSBOOKMIGRATION"
    done

    # 2do
    find /"$HOMEFOLDER"/Library/"Application Support"/Backups -name "*.db" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | sed 1,2d | while read -r TODOBACKUPS
    do
        sudo rm "$TODOBACKUPS"
    done

    # unified remote
    find /"$HOMEFOLDER"/Library/"Application Support"/"Unified Remote" -name "*.log.*" -type f -maxdepth 1 -print0 | xargs -0 ls -m -t -1 | cat | while read -r UNIFIEDREMOTELOGS
    do
        sudo rm "$UNIFIEDREMOTELOGS"
    done

    echo "cleaning done ;)"
    
    # post restore operations
    echo ""
    echo "running post restore operations..."
    sudo launchctl start org.cups.cupsd
    /System/Library/CoreServices/pbs -flush

    ### ownership and permissions
    echo ""
    echo "setting ownerships and permissions..."
    export SELECTEDUSER
    bash "$SCRIPT_DIR"/permissions/ownerships_and_permissions_restore.sh
    wait
    
    ### safari extensions settings restore
    # this can not be included in the restore script if the keychain is restored
    # a reboot is needed after restoring the keychain before running the safari extensions restore script
    # or the changes to safari would not be kept
    #echo ""
    #echo "restoring safari extensions and their settings..."
    #export SELECTEDUSER
    #export MASTERUSER
    #export RESTOREMASTERDIR
    #export HOMEFOLDER
    #bash -c "export SELECTEDUSER=\"$SELECTEDUSER\"; export MASTERUSER=\"$MASTERUSER\"; export RESTOREMASTERDIR=\"$RESTOREMASTERDIR\"; export HOMEFOLDER=\"$HOMEFOLDER\"; "$SCRIPT_DIR"/safari_extensions/safari_extensions_settings_restore.sh"
    #bash "$SCRIPT_DIR"/safari_extensions/safari_extensions_settings_restore.sh
    #wait
    
    echo ""
    echo "script done ;)"
    
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'           # reboot
    #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'          # shutdown
    #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'          # logout

else
    :
fi
#
else
    echo "user home directory does not exist - exiting script..."
    exit
fi

}

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")

set -e
FUNC=$(declare -f backup_restore)
#time bash -c "OPTION=\"$OPTION\"; SCRIPT_DIR=\"$SCRIPT_DIR\"; TARGZSAVEDIR=\"$TARGZSAVEDIR\"; APPLESCRIPTDIR=\"$APPLESCRIPTDIR\"; $FUNC; backup_restore | tee /"$HOMEFOLDER"/Desktop/backup_restore_log.txt"
time bash -c "OPTION=\"$OPTION\"; SCRIPT_DIR=\"$SCRIPT_DIR\"; APPLESCRIPTDIR=\"$APPLESCRIPTDIR\"; $FUNC; backup_restore | tee "$HOME"/Desktop/backup_restore_log.txt"





