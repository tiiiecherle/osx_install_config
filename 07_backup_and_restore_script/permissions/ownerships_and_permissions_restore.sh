#!/bin/bash

###
### ownerships and permissions
###

# checking if SELECTEDUSER is exported from restore script
if [[ "$SELECTEDUSER" == "" ]]
then
    #SELECTEDUSER="$USER"
    SELECTEDUSER="$(who | grep console | awk '{print $1}' | egrep -v '_mbsetupuser')"
    #echo "user is $SELECTEDUSER"
else
    :
fi

if [[ "$SUDOPASSWORD" == "" ]]
then
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
    
    # setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
    trap 'unset SUDOPASSWORD' EXIT
    
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
    
    # replacing sudo command with a function, so all sudo commands of the script do not have to be changed
    sudo()
    {
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
    }

    # unset password if script is run seperately
    UNSET_PASSWORD="YES"
    
    function get_running_subprocesses()
    {
        SUBPROCESSES_PID_TEXT=$(pgrep -lg $(ps -o pgid= $$) | grep -v $$ | grep -v grep)
        SCRIPT_COMMAND=$(ps -o comm= $$)
    	PARENT_SCRIPT_COMMAND=$(ps -o comm= $PPID)
    	if [[ $PARENT_SCRIPT_COMMAND == "bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "-bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "" ]]
    	then
            RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | awk '{print $1}')
        else
            RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | grep -v "$PARENT_SCRIPT_COMMAND" | awk '{print $1}')
        fi
    }
    
    function kill_subprocesses() 
    {
        # kills only subprocesses of the current process
        #pkill -15 -P $$
        #kill -15 $(pgrep -P $$)
        #echo "killing processes..."
        
        # kills all descendant processes incl. process-children and process-grandchildren
        # giving subprocesses the chance to terminate cleanly kill -15
        get_running_subprocesses
        if [[ $RUNNING_SUBPROCESSES != "" ]]
        then
            kill -15 $RUNNING_SUBPROCESSES
            # do not wait here if a process can not terminate cleanly
            #wait $RUNNING_SUBPROCESSES 2>/dev/null
        else
            :
        fi
        # waiting for clean subprocess termination
        TIME_OUT=0
        while [[ $RUNNING_SUBPROCESSES != "" ]] && [[ $TIME_OUT -lt 3 ]]
        do
            get_running_subprocesses
            sleep 1
            TIME_OUT=$((TIME_OUT+1))
        done
        # killing the rest of the processes kill -9
        get_running_subprocesses
        if [[ $RUNNING_SUBPROCESSES != "" ]]
        then
            kill -9 $RUNNING_SUBPROCESSES
            wait $RUNNING_SUBPROCESSES 2>/dev/null
        else
            :
        fi
        # unsetting variable
        unset RUNNING_SUBPROCESSES
    }
    
    function kill_main_process() 
    {
        # kills processes itself
        #kill $$
        kill -13 $$
    }
    
    ### trapping
    [[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_SOURCED="yes" || SCRIPT_SOURCED="no"
    [[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"
    # a sourced script does not exit, it ends with return, so checking for session master is sufficent
    # subprocesses will not be killed on return, only on exit
    #if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_SOURCED" == "no" ]]
    if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]]
    then
        # script is session master and not run from another script (S on mac Ss on linux)
        trap "unset SUDOPASSWORD; printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
        trap "unset SUDOPASSWORD; kill_subprocesses >/dev/null 2>&1; exit" EXIT
    else
        # script is not session master and run from another script (S+ on mac and linux) 
        trap "unset SUDOPASSWORD; printf '\n'; kill_main_process" SIGHUP SIGINT SIGTERM
        trap "unset SUDOPASSWORD; exit" EXIT
    fi
    #set -e
else
    #echo "SELECTEDUSER is $SELECTEDUSER"
    :
fi

HOMEFOLDER=/Users/"$SELECTEDUSER"
#echo "HOMEFOLDER before function is "$HOMEFOLDER""

# starting a function to tee a record to a logfile
function backup_restore_permissions {

    echo "SELECTEDUSER in function is ""$SELECTEDUSER"
    echo "HOMEFOLDER in function is ""$HOMEFOLDER"
        
    #USER_ID=$UID
    USER_ID=`id -u`
    
    echo "USER_ID of ""$SELECTEDUSER"" is ""$USER_ID"
    
    # app permissions in applications folder
    echo "setting ownerships and permissions in /Applications..."
    find "/Applications" -mindepth 1 ! -group wheel ! -path "*/*.app/*" -name "*.app" -print0 | sudo xargs -0 chmod 755 &
    find "/Applications" -mindepth 1 ! -group wheel ! -path "*/*.app/*" -name "*.app" -print0 | sudo xargs -0 chown "$USER_ID":admin &
    if [ -e /Applications/VirtualBox.app ]; then sudo chown root:admin /Applications/VirtualBox.app; else :; fi
    #sudo chmod 644 "/Applications/.DS_Store"
    
    # color profiles
    echo "setting ownerships and permissions outside the user folder..."
    if [ -e "/Library/Application Support/Adobe/Color/Profiles/Recommended/profiles_tom" ]
    then
        sudo chmod 755 "/Library/Application Support/Adobe/Color/Profiles/Recommended/profiles_tom"
        sudo chown root:admin "/Library/Application Support/Adobe/Color/Profiles/Recommended/profiles_tom"
        sudo bash -c 'find "/Library/Application Support/Adobe/Color/Profiles/Recommended/profiles_tom" -maxdepth 1 -type f -print0 | xargs -0 chmod 644'
        sudo bash -c 'find "/Library/Application Support/Adobe/Color/Profiles/Recommended/profiles_tom" -maxdepth 1 -type f -print0 | xargs -0 chown root:wheel'
    else
        :
    fi
    
    # display profiles
    if [ -e "/Library/ColorSync/Profiles/Displays" ]
    then
        sudo bash -c 'find "/Library/ColorSync/Profiles/Displays" -maxdepth 1 -type f -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find "/Library/ColorSync/Profiles/Displays" -maxdepth 1 -type f -print0 | xargs -0 chown root:wheel' &
    else
        :
    fi
    
    # google earth web plugin
    if [ -e "/Library/Internet Plug-Ins/Google Earth Web Plug-in.plugin" ]
    then
        sudo chmod 755 "/Library/Internet Plug-Ins/Google Earth Web Plug-in.plugin"
        sudo chown root:wheel "/Library/Internet Plug-Ins/Google Earth Web Plug-in.plugin"
    else
        :
    fi
    
    # canon printer driver
    if [ -e "/Library/Printers/PPDs/Contents/Resources/CNMCIRAC3325S2.ppd.gz" ]
    then
        sudo chmod 644 "/Library/Printers/PPDs/Contents/Resources/CNMCIRAC3325S2.ppd.gz"
        sudo chown root:admin "/Library/Printers/PPDs/Contents/Resources/CNMCIRAC3325S2.ppd.gz"
    else
        :
    fi
    
    if [ -e "/Library/Printers/Canon/CUPSPS2" ]
    then
        # do not use & for the -R lines
        sudo chown -R root:admin "/Library/Printers/Canon/CUPSPS2"
        sudo chown root:wheel "/Library/Printers/Canon/CUPSPS2/backend/backend.bundle/Contents/Library/canonoipnets2" &
        # do not use & for the -R lines
        sudo chmod -R 755 "/Library/Printers/Canon/CUPSPS2"
        sudo chmod 700 "/Library/Printers/Canon/CUPSPS2/backend/backend.bundle/Contents/Library/canonoipnets2" &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.nib" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.DAT" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.TBL" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.icc" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.icns" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.plist" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.strings" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.png" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.gif" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.html" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.js" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.gif" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.jpg" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.css" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.xib" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.helpindex" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "*.PRF" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "CodeResources" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "CodeDirectory" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "CodeRequirements*" -print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "CodeSignature"-print0 | xargs -0 chmod 644' &
        sudo bash -c 'find /Library/Printers/Canon -type f -name "PkgInfo" -print0 | xargs -0 chmod 644' &
        # find files with respective ownership and permission
        # find /Library/Printers/Canon -type f ! -user root
        # find /Library/Printers/Canon -type f ! -group admin
        # find /Library/Printers/Canon -type d ! -perm 755
        # find /Library/Printers/Canon -type f ! -perm 755 ! -perm 644
        # findung more 644 files 
        # find /Library/Printers/Canon -type f ! -name "*.nib" ! -name "*.DAT" ! -name "*.TBL" ! -name "*.icc" ! -name "*.icns" ! -name "*.plist" ! -name "*.strings" ! -name "*.png" ! -name "*.gif" ! -name "*.html" ! -name "*.js" ! -name "*.gif" ! -name "*.jpg" ! -name "*.css" ! -name "*.xib" ! -name "*.helpindex" ! -name "*.PRF" ! -name "CodeResources" ! -name "CodeDirectory" ! -name "CodeRequirements*" ! -name "CodeSignature" ! -name "PkgInfo" -perm 644
    else
        :
    fi
    
    # custom scripts
    if [ -e "/Library/Scripts/custom/" ]
    then
        sudo chown -R root:wheel "/Library/Scripts/custom/"
        sudo chmod -R 755 "/Library/Scripts/custom/"
    else
        :
    fi
    
    # launchd hostsfile
    if [ -e "/Library/LaunchDaemons/com.hostsfile.install_update.plist" ]
    then
        sudo chown root:wheel "/Library/LaunchDaemons/com.hostsfile.install_update.plist"
        sudo chmod 644 "/Library/LaunchDaemons/com.hostsfile.install_update.plist"
    else
        :
    fi
    
    # mysides
    if [ -e "/usr/local/bin/mysides" ]
    then
        sudo chown root:wheel "/usr/local/bin/mysides"
        sudo chmod 755 "/usr/local/bin/mysides"
    else
        :
    fi
    
    # cups printer
    if [ -e "/etc/cups/printers.conf" ]
    then
        sudo chown root:_lp "/etc/cups/printers.conf"
        sudo chmod 600 "/etc/cups/printers.conf"
    else
        :
    fi
    if [ -e "/etc/cups/ppd/" ]
    then
        sudo chown -R root:_lp "/etc/cups/ppd/"
        sudo bash -c 'find /etc/cups/ppd/ -type f -print0 | xargs -0 chmod 644'
    else
        :
    fi
    
    # user folder ~
    echo "setting ownerships and permissions inside the user folder..."
    #echo "SELECTEDUSER is $SELECTEDUSER"
    # dscl . -read /Users/$USER UniqueID
    # id
    # 501=UID of user
    # 80=group admin
    
    # reset acls (only for repair)
    #sudo chmod -R -N /"$HOMEFOLDER"/*
    
    # setting ownership and permissions
    #sudo chown -R 501:staff /"$HOMEFOLDER"/.*
    
    # apple support advice
    # https://support.apple.com/en-us/HT203538
    #chflags -R nouchg /"$HOMEFOLDER"
    #diskutil resetUserPermissions / `id -u`
    
    if [[ "$RESTOREMASTERDIR" != "" ]] && [[ "$RESTOREUSERDIR" != "" ]]
    then
        #echo running 1
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" -type f -print0 | xargs -0 chown '"$USER_ID"':staff' & pids+=($!)
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" ! -name "*.app" -type d -print0 | xargs -0 chown '"$USER_ID"':staff' & pids+=($!)
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" -type f -print0 | xargs -0 chmod 600' & pids+=($!)
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" ! -name "*.app" -type d -print0 | xargs -0 chmod 700' & pids+=($!)
        wait "${pids[@]}"
    else
        #echo running 2
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -type f -print0 | xargs -0 chown "$USER_ID":staff' & pids+=($!)
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" ! -name "*.app" -type d -print0 | xargs -0 chown "$USER_ID":staff' & pids+=($!)
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -type f -print0 | xargs -0 chmod 600' & pids+=($!)
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" ! -name "*.app" -type d -print0 | xargs -0 chmod 700' & pids+=($!)
        wait "${pids[@]}"
    fi
    
    #sudo chmod -R u+rwX /"$HOMEFOLDER"/.*
    sudo chown root:wheel /Users
    sudo chmod 755 /Users
    sudo chmod 755 "$HOMEFOLDER"
    sudo chmod 777 "$HOMEFOLDER"/Public
    sudo chmod 733 "$HOMEFOLDER"/Public/"Drop Box"
    # ssh
    #chmod 700 ~/
    if [[ -e "$HOMEFOLDER"/.ssh ]] && [[ ! -z "$(ls -A ""$HOMEFOLDER""/.ssh)" ]]
    then
        chmod 700 "$HOMEFOLDER"/.ssh
        #chmod 600 "$HOMEFOLDER"/.ssh/config
        chmod 600 "$HOMEFOLDER"/.ssh/*
    else
        :
    fi
    
    if [[ "$RESTOREMASTERDIR" != "" ]] && [[ "$RESTOREUSERDIR" != "" ]]
    then
        #echo running 1
        # .sh files
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" ! -name "*.app" -name "*.sh" -type f -print0 | xargs -0 chmod 700' & pids+=($!)
        # .command files
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" ! -name "*.app" -name "*.command" -type f -print0 | xargs -0 chmod 700' & pids+=($!)
        # bash files without extension
        #sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" -not -path "'"$RESTOREMASTERDIR"/*'" -not -path "'"$RESTOREUSERDIR"/*'" ! -name "*.app" -type f ! -name "*.*" | while read i; do if [[ $(head -n 1 "$i") == $(echo "#!/bin/bash") ]]; then chmod 770 "$i"; else :; fi; done' & pids+=($!)
        #
        wait "${pids[@]}"
    else
        #echo running 2
        # .sh files
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.sh" -type f -print0 | xargs -0 chmod 700' & pids+=($!)
        # .command files
        sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.command" -type f -print0 | xargs -0 chmod 700' & pids+=($!)
        # bash files without extension
        #sudo bash -c 'find '"$HOMEFOLDER"' -mount ! -path "*/*.app/*" ! -name "*.app" -type f ! -name "*.*" | while read i; do if [[ $(head -n 1 "$i") == $(echo "#!/bin/bash") ]]; then chmod 770 "$i"; else :; fi; done' & pids+=($!)
        #
        wait "${pids[@]}"
    fi
    
    if [[ -e "$HOMEFOLDER"/Library/Services/ ]] && [[ $(ls -A "$HOMEFOLDER"/Library/Services/) ]]
    then
        sudo chmod 700 "$HOMEFOLDER"/Library/Services/*
    else
        :
        #echo directory does not exist or is empty...
    fi
    #
    if [[ -e "$HOMEFOLDER"/Library/Widgets/ ]] && [[ $(ls -A "$HOMEFOLDER"/Library/Widgets/) ]]
    then
        sudo find "$HOMEFOLDER"/Library/Widgets -type f -print0 | sudo xargs -0 chmod 644
        sudo chmod 755 "$HOMEFOLDER"/Library/Widgets/*
    else
        :
        #echo directory does not exist or is empty...
    fi
    #
    if [[ -e "$HOMEFOLDER"/Library/"Application Scripts"/com.apple.mail/ ]] && [[ $(ls -A "$HOMEFOLDER"/Library/"Application Scripts"/com.apple.mail/) ]]
    then
        sudo chmod 750 "$HOMEFOLDER"/Library/"Application Scripts"/com.apple.mail/*
    else
        :
        #echo directory does not exist or is empty...
    fi
    # oversight whitelist
    if [[ -e "$HOMEFOLDER"/Library/"Application Support"/Objective-See/OverSight/whitelist.plist ]]
    then
        sudo chmod 644 "$HOMEFOLDER"/Library/"Application Support"/Objective-See/OverSight/whitelist.plist
    else
        :
    fi
    # tunnelblick
    if [ -e """$HOMEFOLDER""/Library/Application Support/Tunnelblick/Configurations" ]
    then
        sudo chown -R "$USER_ID":admin """$HOMEFOLDER""/Library/Application Support/Tunnelblick/Configurations"
        sudo bash -c 'find "'"$HOMEFOLDER"'/Library/Application Support/Tunnelblick/Configurations" -name .tblk -print0 | xargs -0 chmod 700'
        sudo bash -c 'find "'"$HOMEFOLDER"'/Library/Application Support/Tunnelblick/Configurations" -type f -print0 | xargs -0 chmod 600'
    else
        :
    fi
    
    # homebrew permissions
    #if [ -e "$(brew --prefix)" ] 
    #then
    #	echo "setting ownerships and permissions for homebrew..."
    #	BREWGROUP="admin"
    #	BREWPATH=$(brew --prefix)
    #	sudo chown -R $UID:"$BREWGROUP" "$BREWPATH"
    #	sudo find "$BREWPATH" -type f -print0 | sudo xargs -0 chmod g+rw
    #	sudo find "$BREWPATH" -type d -print0 | sudo xargs -0 chmod g+rwx
    #else
    #	:
    #fi
    
    # vbox_shared folder
    VBOX_SHARED_FOLDER="/Users/"$USER"/Desktop/files/vbox_shared"
    if [[ -e "$VBOX_SHARED_FOLDER" ]]
    then
        #rm -rf /Users/$USER/Desktop/files/vbox_shared
        #mkdir -p /Users/$USER/Desktop/files/vbox_shared
        sudo chown -R sharinguser:admin "$VBOX_SHARED_FOLDER"
        sudo chmod 770 "$VBOX_SHARED_FOLDER"
        sudo chmod -R +a "staff allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" "$VBOX_SHARED_FOLDER"
    else
        :
    fi
    
    # script finfished
        
    wait
    
    echo 'done setting ownerships and permissions ;)'

}

# running function to tee a record to a logfile
if [[ -e "$HOMEFOLDER"/Desktop/backup_restore_log.txt ]]
then
    :
else
    touch "$HOMEFOLDER"/Desktop/backup_restore_log.txt
fi

(time backup_restore_permissions) | tee -a "$HOMEFOLDER"/Desktop/backup_restore_log.txt

if [ "$UNSET_PASSWORD" == "YES" ]
then
    ###
    ### unsetting password
    ###
    
    unset SUDOPASSWORD
    
    exit

else
    :
fi

# exit




