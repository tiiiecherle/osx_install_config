#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### ownerships and permissions
###

# checking if SELECTEDUSER is exported from backup / restore script
if [[ "$SELECTEDUSER" == "" ]]
then
    SELECTEDUSER="$loggedInUser"
    #echo "user is $SELECTEDUSER"
else
    :
fi

if [[ "$SUDOPASSWORD" == "" ]]
then
    ### asking password upfront
    env_enter_sudo_password

    # unset password if script is run seperately
    UNSET_PASSWORD="YES"
    
    ### trapping
    trap_function_exit_middle() { env_stop_sudo; unset SUDOPASSWORD; unset USE_PASSWORD; }
    "${ENV_SET_TRAP_SIG[@]}"
    "${ENV_SET_TRAP_EXIT[@]}"
else
    #echo "SELECTEDUSER is $SELECTEDUSER"
    :
fi

HOMEFOLDER=/Users/"$SELECTEDUSER"
#echo "HOMEFOLDER before function is "$HOMEFOLDER""

env_start_sudo

# starting a function to tee a record to a logfile
backup_restore_permissions() {

    echo "SELECTEDUSER in function is ""$SELECTEDUSER"
    echo "HOMEFOLDER in function is ""$HOMEFOLDER"
        
    #USER_ID=$UID
    export USER_ID="$UNIQUE_USER_ID"
    
    echo "USER_ID of ""$SELECTEDUSER"" is ""$USER_ID"
    
    # app permissions in applications folder
    echo "setting ownerships and permissions in "$PATH_TO_APPS"..."
    find ""$PATH_TO_APPS"" -mindepth 1 ! -group wheel ! -path "*/*.app/*" -name "*.app" ! -type l -print0 | xargs -0 -n100 sudo chmod 755 &
    find ""$PATH_TO_APPS"" -mindepth 1 ! -group wheel ! -path "*/*.app/*" -name "*.app" ! -type l -print0 | xargs -0 -n100 sudo chown "$USER_ID":admin
    if [[ -e "$PATH_TO_APPS"/VirtualBox.app ]]; then sudo chown root:admin "$PATH_TO_APPS"/VirtualBox.app; else :; fi
    #sudo chmod 644 ""$PATH_TO_APPS"/.DS_Store"

    ### outside user folder
    echo "setting ownerships and permissions outside the user folder..."

    # color profiles
    FILE_OR_FOLDER_TO_CHECK_FOR="/Library/ColorSync/Profiles/eci"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]
    then
        sudo chmod 755 "/Library/ColorSync/Profiles/eci"
        sudo chown root:wheel "/Library/ColorSync/Profiles/eci"
        sudo find "/Library/ColorSync/Profiles/eci" -maxdepth 1 -type f -print0 | xargs -0 -n100 sudo chmod 644
        sudo find "/Library/ColorSync/Profiles/eci" -maxdepth 1 -type f -print0 | xargs -0 -n100 sudo chown root:wheel
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi

    # display profiles
    FILE_OR_FOLDER_TO_CHECK_FOR="/Library/ColorSync/Profiles/Displays"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]
    then
        sudo find "/Library/ColorSync/Profiles/Displays" -maxdepth 1 -type f -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find "/Library/ColorSync/Profiles/Displays" -maxdepth 1 -type f -print0 | xargs -0 -n100 sudo chown root:wheel &
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi

    # google earth web plugin
    #FILE_OR_FOLDER_TO_CHECK_FOR="/Library/Internet Plug-Ins/Google Earth Web Plug-in.plugin"
    #if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]
    #then
    #    sudo chmod 755 "/Library/Internet Plug-Ins/Google Earth Web Plug-in.plugin"
    #    sudo chown root:wheel "/Library/Internet Plug-Ins/Google Earth Web Plug-in.plugin"
    #else
    #    echo ''
    #    echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    #fi
    
    # canon printer driver
    FILE_OR_FOLDER_TO_CHECK_FOR="/Library/Printers/PPDs/Contents/Resources/CNMCIRAC3325S2.ppd.gz"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]
    then
        sudo chmod 644 "/Library/Printers/PPDs/Contents/Resources/CNMCIRAC3325S2.ppd.gz"
        sudo chown root:admin "/Library/Printers/PPDs/Contents/Resources/CNMCIRAC3325S2.ppd.gz"
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi

    FILE_OR_FOLDER_TO_CHECK_FOR="/Library/Printers/Canon/CUPSPS2"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]    
    then
        # do not use & for the -R lines
        sudo chown -R root:admin "/Library/Printers/Canon/CUPSPS2"
        sudo chown root:wheel "/Library/Printers/Canon/CUPSPS2/backend/backend.bundle/Contents/Library/canonoipnets2" &
        # do not use & for the -R lines
        sudo chmod -R 755 "/Library/Printers/Canon/CUPSPS2"
        sudo chmod 700 "/Library/Printers/Canon/CUPSPS2/backend/backend.bundle/Contents/Library/canonoipnets2" &
        sudo find /Library/Printers/Canon -type f -name "*.nib" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.DAT" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.TBL" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.icc" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.icns" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.plist" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.strings" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.png" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.gif" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.html" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.js" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.gif" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.jpg" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.css" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.xib" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.helpindex" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "*.PRF" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "CodeResources" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "CodeDirectory" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "CodeRequirements*" -print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "CodeSignature"-print0 | xargs -0 -n100 sudo chmod 644 &
        sudo find /Library/Printers/Canon -type f -name "PkgInfo" -print0 | xargs -0 -n100 sudo chmod 644 &
        # find files with respective ownership and permission
        # find /Library/Printers/Canon -type f ! -user root
        # find /Library/Printers/Canon -type f ! -group admin
        # find /Library/Printers/Canon -type d ! -perm 755
        # find /Library/Printers/Canon -type f ! -perm 755 ! -perm 644
        # findung more 644 files 
        # find /Library/Printers/Canon -type f ! -name "*.nib" ! -name "*.DAT" ! -name "*.TBL" ! -name "*.icc" ! -name "*.icns" ! -name "*.plist" ! -name "*.strings" ! -name "*.png" ! -name "*.gif" ! -name "*.html" ! -name "*.js" ! -name "*.gif" ! -name "*.jpg" ! -name "*.css" ! -name "*.xib" ! -name "*.helpindex" ! -name "*.PRF" ! -name "CodeResources" ! -name "CodeDirectory" ! -name "CodeRequirements*" ! -name "CodeSignature" ! -name "PkgInfo" -perm 644
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi

    # custom scripts
    FILE_OR_FOLDER_TO_CHECK_FOR="/Library/Scripts/custom/"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]    
    then
        sudo chown -R root:wheel "/Library/Scripts/custom/"
        sudo chmod -R 755 "/Library/Scripts/custom/"
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi
    
    # launchd hostsfile
    #FILE_OR_FOLDER_TO_CHECK_FOR="/Library/LaunchDaemons/com.hostsfile.install_update.plist"
    #if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]  
    #then
    #    sudo chown root:wheel "/Library/LaunchDaemons/com.hostsfile.install_update.plist"
    #    sudo chmod 644 "/Library/LaunchDaemons/com.hostsfile.install_update.plist"
    #else
    #    echo ''
    #    echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    #fi
    
    # mysides
    # currently not used, using finder-sidebar-editor instead
    check_mysides() {
        if command -v brew &> /dev/null
        then
            # installed
            BREW_PATH_PREFIX=$(brew --prefix)
        else
            # not installed
            echo "homebrew is not installed, exiting..."
            echo ''
            exit
        fi
        FILE_OR_FOLDER_TO_CHECK_FOR=""$BREW_PATH_PREFIX"/bin/mysides"
        if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]  
        then
            sudo chown root:wheel ""$BREW_PATH_PREFIX"/bin/mysides"
            sudo chmod 755 ""$BREW_PATH_PREFIX"/bin/mysides"
        else
            echo ''
            # mysides currently not used, therefor no entry to error log necessary
            #echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
            echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
        fi
    }
    #check_mysides
    
    # cups printer
    FILE_OR_FOLDER_TO_CHECK_FOR="/etc/cups/printers.conf"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]]  
    then
        sudo chown root:_lp "/etc/cups/printers.conf"
        sudo chmod 600 "/etc/cups/printers.conf"
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi
    FILE_OR_FOLDER_TO_CHECK_FOR="/etc/cups/ppd/"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    then
        sudo chown -R root:_lp "/etc/cups/ppd/"
        sudo find /etc/cups/ppd/ -type f -print0 | xargs -0 -n100 sudo chmod 644
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi
    
    # avg antivirus
    #FILE_OR_FOLDER_TO_CHECK_FOR="/Library/Application Support/AVGAntivirus/config"
    #if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    #then
    #    sudo find "/Library/Application Support/AVGAntivirus/config" -type f -name "*.conf" -print0 | xargs -0 -n100 sudo chmod 644
    #    sudo find "/Library/Application Support/AVGAntivirus/config" -type f -name "*.conf" -print0 | xargs -0 -n100 sudo chown root:wheel
    #    sudo find "/Library/Application Support/AVGAntivirus/config" -type f -name "*.whls" -print0 | xargs -0 -n100 sudo chmod 644
    #    sudo find "/Library/Application Support/AVGAntivirus/config" -type f -name "*.whls" -print0 | xargs -0 -n100 sudo chown root:wheel
    #else
    #    echo ''
    #    echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    #fi
    
    # network / wireguard
    FILE_OR_FOLDER_TO_CHECK_FOR="/Library/Preferences/SystemConfiguration/preferences.plist"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    then
        sudo chown root:wheel "/Library/Preferences/SystemConfiguration/preferences.plist"
        sudo chmod 644 "/Library/Preferences/SystemConfiguration/preferences.plist"
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi
    
    # istat menus
    FILE_OR_FOLDER_TO_CHECK_FOR=""$PATH_TO_APPS"/iStat Menus.app"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    then
        #sudo chmod -R 755 "/Library/Application Support/iStat Menus 6"
        sudo chown -R root:wheel "/Library/Application Support/iStat Menus 6"
    	sudo chown root:wheel "/Library/LaunchDaemons/com.bjango.istatmenus.fans.plist"
    	sudo chown root:wheel "/Library/LaunchDaemons/com.bjango.istatmenus.daemon.plist"
    	sudo chown root:wheel "/Library/LaunchDaemons/com.bjango.istatmenus.installerhelper.plist"
    	sudo chown root:wheel "/Library/PrivilegedHelperTools/com.bjango.istatmenus.installerhelper"
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi
    
    # bresink software update helper
    FILE_OR_FOLDER_TO_CHECK_FOR=""$PATH_TO_APPS"/BresinkSoftwareUpdater.app"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    then
        sudo chmod 544 "/Library/PrivilegedHelperTools/BresinkSoftwareUpdater-PrivilegedTool"
        sudo chown root:wheel "/Library/PrivilegedHelperTools/BresinkSoftwareUpdater-PrivilegedTool"
        sudo chmod 644 "/Library/LaunchDaemons/BresinkSoftwareUpdater-PrivilegedTool.plist"
        sudo chown root:wheel "/Library/LaunchDaemons/BresinkSoftwareUpdater-PrivilegedTool.plist"
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    fi
    
    ### inside user folder
    echo "setting ownerships and permissions inside the user folder..."
    #echo "SELECTEDUSER is $SELECTEDUSER"
    # dscl . -read /Users/$USER UniqueID
    # id
    # 80=group admin
    
    # reset acls (only for repair)
    #sudo chmod -R -N /"$HOMEFOLDER"/*
    
    # setting ownership and permissions
    #sudo chown -R "$USER_ID":staff /"$HOMEFOLDER"/.*
    
    # apple support advice
    # https://support.apple.com/en-us/HT203538
    #chflags -R nouchg /"$HOMEFOLDER"
    #diskutil resetUserPermissions / `id -u`
    
    if [[ "$RESTOREMASTERDIR" != "" ]] && [[ "$RESTOREUSERDIR" != "" ]]
    then
        #echo running 1
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" -type f -print0 | xargs -0 -n100 sudo chown "$USER_ID":staff ) & pids+=($!)
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" ! -name "*.app" -type d -print0 | xargs -0 -n100 sudo chown "$USER_ID":staff ) & pids+=($!)
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" -type f -print0 | xargs -0 -n100 sudo chmod 600 ) & pids+=($!)
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" ! -name "*.app" -type d -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        #wait "${pids[@]}"
        while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${pids[@]}")"
    else
        #echo running 2
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -type f -print0 | xargs -0 -n100 sudo chown "$USER_ID":staff ) & pids+=($!)
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -type d -print0 | xargs -0 -n100 sudo chown "$USER_ID":staff ) & pids+=($!)
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -type f -print0 | xargs -0 -n100 sudo chmod 600 ) & pids+=($!)
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -type d -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        #wait "${pids[@]}"
        while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${pids[@]}")"
    fi
    
    #sudo chmod -R u+rwX /"$HOMEFOLDER"/.*
    sudo chown root:wheel /Users
    sudo chmod 755 /Users
    sudo chmod 700 "$HOMEFOLDER"
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
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" ! -name "*.app" -name "*.sh" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        # .command files
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" ! -name "*.app" -name "*.command" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        # .py files
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path ""$RESTOREMASTERDIR"/*" -not -path ""$RESTOREUSERDIR"/*" ! -name "*.app" -name "*.py" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        # bash files without extension
        #sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" -not -path "$RESTOREMASTERDIR"/* -not -path "$RESTOREUSERDIR"/* ! -name "*.app" -type f ! -name "*.*" | while read i; do if [[ $(head -n 1 "$i") == $(echo "#!/bin/bash") ]]; then sudo chmod 770 "$i"; else :; fi; done & pids+=($!)
        #
        #wait "${pids[@]}"
        while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${pids[@]}")"
    else
        #echo running 2
        # .sh files
        #sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.sh" -type f -print0 | xargs -0 -n100 sudo chmod 700
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.sh" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        # .command files
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.command" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        # .py files
        ( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.py" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
        # bash files without extension
        #find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -type f ! -name "*.*" | while read i; do if [[ $(head -n 1 "$i") == $(echo "#!/bin/bash") ]]; then sudo chmod 770 "$i"; else :; fi; done & pids+=($!)
        #
        #wait "${pids[@]}"
        while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${pids[@]}")"
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
        sudo find "$HOMEFOLDER"/Library/Widgets -type f -print0 | xargs -0 -n100 sudo chmod 644
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
    FILE_OR_FOLDER_TO_CHECK_FOR=""$HOMEFOLDER"/Library/Application Support/Tunnelblick/Configurations"
    if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    then
        sudo chown -R "$USER_ID":admin ""$HOMEFOLDER"/Library/Application Support/Tunnelblick/Configurations"
        sudo find ""$HOMEFOLDER"/Library/Application Support/Tunnelblick/Configurations" -name .tblk -print0 | xargs -0 -n100 sudo chmod 700
        sudo find ""$HOMEFOLDER"/Library/Application Support/Tunnelblick/Configurations" -type f -print0 | xargs -0 -n100 sudo chmod 600
    else
        echo ''
        echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..."
    fi
    
    # homebrew permissions
    #if [ -e "$(brew --prefix)" ] 
    #then
    #	echo "setting ownerships and permissions for homebrew..."
    #	BREWGROUP="admin"
    #	BREWPATH=$(brew --prefix)
    #	sudo chown -R $UID:"$BREWGROUP" "$BREWPATH"
    #	sudo find "$BREWPATH" -type f -print0 | xargs -0 -n100 sudo chmod g+rw
    #	sudo find "$BREWPATH" -type d -print0 | xargs -0 -n100 sudo chmod g+rwx
    #else
    #	:
    #fi
    
    # vbox_shared folder
    #FILE_OR_FOLDER_TO_CHECK_FOR="/Users/"$USER"/Desktop/files/vbox_shared"
    #if [[ -e "$FILE_OR_FOLDER_TO_CHECK_FOR" ]] 
    #then
    #    #rm -rf /Users/$USER/Desktop/files/vbox_shared
    #    #mkdir -p /Users/$USER/Desktop/files/vbox_shared
    #    sudo chown -R sharinguser:admin "$FILE_OR_FOLDER_TO_CHECK_FOR"
    #    sudo chmod 770 "$FILE_OR_FOLDER_TO_CHECK_FOR"
    #    sudo chmod -R +a "staff allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" "$FILE_OR_FOLDER_TO_CHECK_FOR"
    #else
    #    echo ''
    #    echo ""$FILE_OR_FOLDER_TO_CHECK_FOR" not found, skipping setting permissions..." >&2
    #fi
    
    # script finfished
        
    wait
    
    echo ''
    echo 'done setting ownerships and permissions ;)'
    echo ''

}

# running function to tee a record to a logfile
if [[ -e "$HOMEFOLDER"/Desktop/backup_restore_log.txt ]]
then
    :
else
    touch "$HOMEFOLDER"/Desktop/backup_restore_log.txt
fi

(time ( backup_restore_permissions )) | tee -a "$HOMEFOLDER"/Desktop/backup_restore_log.txt
#echo ''

if [[ "$UNSET_PASSWORD" == "YES" ]]
then
    ###
    ### unsetting password
    ###
    
    unset SUDOPASSWORD
    
else
    :
fi


###
### documentation
###

# example for working find and xargs permissions with sudo
# env_start_sudo has to be used before or xargs -0 -n100 sudo would ask for the password again
# sudo -0 xargs does NOT work in this situation
# the subshell () is needed for getting all pids in "${pids[@]}" and wait for them
# -nx (default 5000, see man xargs) is needed to avoid unable to execute /bin/chmod: Argument list too long
#( sudo find "$HOMEFOLDER" -mount ! -path "*/*.app/*" ! -name "*.app" -name "*.sh" -type f -print0 | xargs -0 -n100 sudo chmod 700 ) & pids+=($!)
# env_stop_sudo or include in trap



