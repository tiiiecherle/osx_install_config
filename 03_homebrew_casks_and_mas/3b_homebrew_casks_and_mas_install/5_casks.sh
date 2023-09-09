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
### script frame
###

if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
then
    . "$SCRIPT_DIR"/1_script_frame.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
    trap_function_exit_start() { env_delete_tmp_casks_script_fifo; }
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi



###
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_TWO_BACK"/_user_profiles
env_check_for_user_profile



###
### password
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_sudo_cask_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_sudo_cask_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_casks_script_fifo
        #set +a
        :
    else
        env_enter_sudo_password
    fi
else
    :
fi

env_sudo
#env_sudo_homebrew



###
### command line tools
###

echo ''
env_command_line_tools_install_shell



###
### variables
###

BREW_CASKS_PATH=$(brew doctor --verbose 2>/dev/null | grep -A1 -B1 "Cask Staging Location" | tail -1)



###
### functions
###

install_casks_parallel() {
    # always use _ instead of - because some sh commands called by parallel would give errors
    # if parallels is used i needs to be redefined
    i="$1"
    #if [[ $(brew info --cask "$i" | grep "Not installed") != "" ]]
    if [[ $(brew list --cask | grep "^$i$") == "" ]]
    then
        echo "installing cask "$i"..."
        env_use_password | env_timeout 600 brew install --cask --force "$i" 2> /dev/null | grep "successfully installed"
        if [[ $? -eq 0 ]]
        then
            # successfull
            :
        else
            # failed
            # try a second time at the end of the script
            if [[ "$SECOND_TRY" == "yes" ]]
            then
                # do nothing if it already is the second try
                echo "installing cask $i failed for the second time..." >&2
            else
                if [[ -e /tmp/casks_second_try.txt ]]; then :; else touch /tmp/casks_second_try.txt; fi
                echo "installing cask $i failed, noting for a second try..." >&2
                #echo "installing cask $i failed, noting for a second try..."
                echo "$i" >> /tmp/casks_second_try.txt
            fi
            # making sure install check recognizes the failed install when using brew list --cask | grep "$i"
            if [[ -e "$BREW_CASKS_PATH"/"$i" ]]
            then
            	rm -rf "$BREW_CASKS_PATH"/"$i"
            else
            	:
            fi
        fi
        #
        if [[ "$i" == "avg-antivirus" ]]
        then 
        	sleep 2
        	#osascript -e "tell app \""$PATH_TO_APPS"/AVGAntivirus.app\" to quit" >/dev/null 2>&1
        	osascript -e "tell app \"AVGAntivirus.app\" to quit" >/dev/null 2>&1
        fi
        if [[ "$i" == "avast-security" ]]
        then 
        	sleep 2
        	#osascript -e "tell app \""$PATH_TO_APPS"/Avast.app\" to quit" >/dev/null 2>&1
        	osascript -e "tell app \"Avast.app\" to quit" >/dev/null 2>&1
        fi
        if [[ "$i" == "teamviewer" ]]
        then 
        	sleep 2
        	#osascript -e "tell app \""$PATH_TO_APPS"/TeamViewer.app\" to quit" >/dev/null 2>&1
        	osascript -e "tell app \"TeamViewer.app\" to quit" >/dev/null 2>&1
        	sleep 2
            env_active_source_app
        fi
        if [[ "$i" == "libreoffice-language-pack" ]]
        then
            if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
            then
                :
            else
                # waiting for libreoffice to be detectable by language pack
                sleep 120
                # installung libreoffice language pack
                LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK=$(ls -1 "$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack | sort -V | head -n 1)
                PATH_TO_FIRST_RUN_APP=""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app"
                env_set_open_on_first_run_permissions
                PATH_TO_FIRST_RUN_APP=""$PATH_TO_APPS"/LibreOffice.app"
                env_set_open_on_first_run_permissions
                open ""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app" &
                sleep 2
                env_active_source_app
            fi
        fi
        if [[ "$i" == "textmate" ]]
        then
            # removing quicklook syntax highlight
            #rm -r "$PATH_TO_APPS"/TextMate.app/Contents/Library/QuickLook/TextMateQL.qlgenerator
            :
        fi
        if [[ "$i" == "nextcloud" ]]
        then
            sleep 2
            env_active_source_app
        fi
    else
        # listing dependencies
        #brew info --cask --json=v2 "$i" | jq -r '.casks | .[] | .depends_on.cask | .[]'
        brew info --cask --json=v2 "$i" | jq -r '.casks | .[] | .depends_on.cask | .[]' >/dev/null 2>&1 && CASK_HAS_DEPENDENCIES="yes" || CASK_HAS_DEPENDENCIES="no"
        #echo CASK_HAS_DEPENDENCIES for $i is $CASK_HAS_DEPENDENCIES
        if [[ "$CASK_HAS_DEPENDENCIES" == "yes" ]]
        then
            #CASK_DEPENDENCIES=$(brew info --cask --json=v2 "$i" | jq -r '.casks | .[] | .depends_on.cask | .[]')
            #echo CASK_DEPENDENCIES for $i is $CASK_DEPENDENCIES
            for d in $(brew info --cask --json=v2 "$i" | jq -r '.casks | .[] | .depends_on.cask | .[]')
            do
                #echo d for $i is $d
                if [[ $(brew list --cask | grep "^$d$") == "" ]]
                then
                    echo "installing missing dependency "$d"..."
                    env_use_password | env_timeout 300 brew install --cask --force "$d" 2> /dev/null | grep "successfully installed"
                    if [[ $? -eq 0 ]]
                    then
                        # successfull
                        :
                    else
                        # failed
                        # making sure install check recognizes the failed install when using brew list --cask | grep "$i"
                        if [[ -e "$BREW_CASKS_PATH"/"$d" ]]
                        then
                        	rm -rf "$BREW_CASKS_PATH"/"$d"
                        else
                        	:
                        fi
                    fi
                else
                    :
                fi
            done
        else
            :
        fi    
        echo "cask "$i" already installed..."
    fi
}


###
### homebrew
###

checking_homebrew
BREW_PATH_PREFIX=$(brew --prefix)
env_homebrew_update


### activating caffeinate
env_activating_caffeinate


### parallel
env_check_if_parallel_is_installed


### starting sudo
env_start_sudo


###
env_databases_apps_security_permissions
env_identify_terminal

# installing homebrew packages
#echo ''

if [[ -e "/tmp/Caskroom" ]]
then
    if [[ "$CONT_CASKROOM" =~ ^(no|n)$ ]]
    then
        :
    else
        VARIABLE_TO_CHECK="$CONT_CASKROOM"
        QUESTION_TO_ASK="$(echo -e 'found a backup of cask specifications in /tmp/Caskroom \ndo you wanto to restore /tmp/Caskroom/* to $(brew --prefix)/Caskroom/' '(Y/n)? ')"
        env_ask_for_variable
        CONT_CASKROOM="$VARIABLE_TO_CHECK"
        
        if [[ "$CONT_CASKROOM" =~ ^(yes|y)$ ]]
        then
            #echo ''
            echo "restoring /tmp/Caskroom/. to "$BREW_PATH_PREFIX"/Caskroom/..."
            if [[ -e ""$BREW_PATH_PREFIX"/Caskroom" ]]
            then
                cp -a /tmp/Caskroom/. "$BREW_PATH_PREFIX"/Caskroom/
            else
                echo ""$BREW_PATH_PREFIX"/Caskroom/ not found, skipping restore..."
            fi
        else
            :
        fi
        #echo ''
    fi
else
    :
fi



if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
    
    cleaning_before_installing() {
        #echo ''
    	echo "uninstalling and cleaning some casks..."
    	#echo ''
    	
    	#if [[ $(brew info --cask java | grep "Not installed") != "" ]]
    	if [[ $(brew list --cask | grep "^java$") == "" ]] && [[ $(printf '%s\n' "${casks[@]}" | grep "^java$") != "" ]]
        then
            echo ''
        	# making sure java gets installed on reinstall
        	if [[ -e "/Library/Java/JavaVirtualMachines/" ]] && [[ -n "$(ls -A /Library/Java/JavaVirtualMachines/)" ]]
        	then
                env_use_password | brew uninstall --cask --zap --force java
            else
                :
            fi
        else
            :
        fi
    
    	#if [[ $(brew info --cask flash-npapi | grep "Not installed") != "" ]]
    	if [[ $(brew list --cask | grep "^flash-npapi$") == "" ]] && [[ $(printf '%s\n' "${casks[@]}" | grep "^flash-npapi$") != "" ]]
        then
        	# making sure flash gets installed on reinstall
        	if [[ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]]
        	then
        	    #env_start_sudo
        	    echo ''
                if [[ -e "/Library/Internet Plug-Ins/flashplayer.xpt" ]]
                then
                    sudo rm -f "/Library/Internet Plug-Ins/flashplayer.xpt"
                else
                    :
                fi
                env_use_password | brew uninstall --cask --zap --force flash-npapi
        	    #env_stop_sudo
        	    #echo ''
            else
                :
            fi
        else
            :
        fi
    
    	# making sure libreoffice gets installed as a dependency of libreoffice-language-pack
    	# installation would be refused if restored via restore script or already installed otherwise
    	#if [[ $(brew info --cask libreoffice | grep "Not installed") != "" ]] || [[ $(brew info --cask libreoffice-language-pack | grep "Not installed") != "" ]]
    	if [[ $(brew list --cask | grep "^libreoffice$") == "" ]] || [[ $(brew list --cask | grep "^libreoffice-language-pack$") == "" ]]
        then
            echo ''
        	if [[ -e ""$PATH_TO_APPS"/LibreOffice.app" ]]
        	then
        	    env_use_password | brew uninstall --cask --force libreoffice
        	    env_use_password | brew uninstall --cask --force libreoffice-language-pack
        	    #echo ''
        	else
        	    :
        	fi
        else
            :
        fi
    
    	# making sure adobe-acrobat-reader gets installed on reinstall
    	#if [[ $(brew info --cask adobe-acrobat-reader | grep "Not installed") != "" ]]
    	if [[ $(brew list --cask | grep "^adobe-acrobat-reader$") == "" ]]
        then
        	if [[ -e ""$PATH_TO_APPS"/Adobe Acrobat Reader DC.app" ]]
        	then
        	    echo ''
    	        if [[ -e /Library/Preferences/com.adobe.reader.DC.WebResource.plist ]]
    	        then
    	            sudo rm -f /Library/Preferences/com.adobe.reader.DC.WebResource.plist
    	        else
    	            :
    	        fi
        	    if [[ -e /Users/$USER/Library/Preferences/com.adobe.Reader.plist ]]
        	    then
        	        mv /Users/$USER/Library/Preferences/com.adobe.Reader.plist /tmp/com.adobe.Reader.plist
        	        env_use_password | brew uninstall --cask --zap --force adobe-acrobat-reader
        	        mv /tmp/com.adobe.Reader.plist /Users/$USER/Library/Preferences/com.adobe.Reader.plist
        	    else
                    env_use_password | brew uninstall --cask --zap --force adobe-acrobat-reader
        	    fi
        	else
        	    :
        	fi
        	#echo ''
        else
            :
        fi
    
    	reinstall_avg_antivirus() {
        	#if [[ $(brew info --cask avg-antivirus | grep "Not installed") != "" ]]
        	if [[ $(brew list --cask | grep "^avg-antivirus$") == "" ]]
            then
            	# making sure avg-antivirus gets installed on reinstall
            	if [[ $(printf '%s\n' "${casks[@]}" | grep "^avg-antivirus$") != "" ]] && [[ -e ""$PATH_TO_APPS"/AVGAntivirus.app" ]]
            	then
                    avg_config_files=(
                    "/Users/$USER/Library/Preferences/com.avg.Antivirus.plist"
                    "/Library/Application Support/AVGAntivirus/config/com.avg.proxy.conf"
                    "/Library/Application Support/AVGAntivirus/config/com.avg.update.conf"
                    "/Library/Application Support/AVGAntivirus/config/com.avg.daemon.conf"
                    "/Library/Application Support/AVGAntivirus/config/com.avg.daemon.whls"
                    "/Library/Application Support/AVGAntivirus/config/com.avg.fileshield.conf"
                    )
                    for i in "${avg_config_files[@]}"
                    do
                        DIRNAME_ENTRY=$(dirname "$i")
                        BASENAME_ENTRY=$(basename "$i")
                    	if [ -e "$i" ]
                    	then
            	            sudo mv "$i" /tmp/"$BASENAME_ENTRY"
                    	else
                    		:
                    	fi
                    done
                    #if [[ -e "/Library/Application Support/AVGAntivirus" ]]; then sudo rm -rf "/Library/Application Support/AVGAntivirus"; fi
                    if [[ -e "/Library/Application Support/AVGHUB" ]]; then sudo rm -rf "/Library/Application Support/AVGHUB"; fi
                    env_use_password | brew uninstall --cask --zap --force avg-antivirus
                    env_use_password | brew install --cask --force avg-antivirus
                    sleep 2
                    osascript -e "tell app \""$PATH_TO_APPS"/AVGAntivirus.app\" to quit" >/dev/null 2>&1
                    sleep 2
                    for i in "${avg_config_files[@]}"
                    do
                        DIRNAME_ENTRY=$(dirname "$i")
                        BASENAME_ENTRY=$(basename "$i")
                    	if [ -e /tmp/"$BASENAME_ENTRY" ]
                    	then
                    	    sudo mkdir -p "$DIRNAME_ENTRY"
            	            sudo mv /tmp/"$BASENAME_ENTRY" "$i" 
                    	else
                    		:
                    	fi
                    done
                    defaults write /Users/$USER/Library/Preferences/com.avg.Antivirus.plist improveSecurity -bool false
                    echo ''
            	else
            	    :
            	fi
            else
                :
            fi
    	}
    	reinstall_avg_antivirus
    
    	reinstall_avast_security() {
        	#if [[ $(brew info --cask avast-security | grep "Not installed") != "" ]]
        	if [[ $(brew list --cask | grep "^avast-security$") == "" ]]
            then
            	# making sure avast-security gets installed on reinstall
            	if [[ $(printf '%s\n' "${casks[@]}" | grep "^avast-security$") != "" ]] && [[ -e ""$PATH_TO_APPS"/Avast.app" ]]
            	then
                    avast_config_files=(
                    "/Users/$USER/Library/Preferences/com.avast.helper.plist"
                    "/Library/Application Support/Avast/config/com.avast.daemon.conf"
                    "/Library/Application Support/Avast/config/com.avast.proxy.conf"
                    "/Library/Application Support/Avast/config/com.avast.fileshield.conf"
                    )
                    for i in "${avast_config_files[@]}"
                    do
                        DIRNAME_ENTRY=$(dirname "$i")
                        BASENAME_ENTRY=$(basename "$i")
                    	if [[ -e "$i" ]]
                    	then
            	            sudo mv "$i" /tmp/"$BASENAME_ENTRY"
                    	else
                    		:
                    	fi
                    done
                    env_use_password | brew uninstall --cask --zap --force avast-security
                    env_use_password | brew install --cask --force avast-security
                    sleep 2
                    osascript -e "tell app \""$PATH_TO_APPS"/Avast.app\" to quit" >/dev/null 2>&1
                    sleep 2
                    for i in "${avast_config_files[@]}"
                    do
                        DIRNAME_ENTRY=$(dirname "$i")
                        BASENAME_ENTRY=$(basename "$i")
                    	if [ -e /tmp/"$BASENAME_ENTRY" ]
                    	then
                    	    sudo mkdir -p "$DIRNAME_ENTRY"
            	            sudo mv /tmp/"$BASENAME_ENTRY" "$i" 
                    	else
                    		:
                    	fi
                    done
                    # restarting avast services to make the changes take effect
                    echo "restarting avast services to make the changes take effect..."
                    AVAST_BACKEND='"$PATH_TO_APPS"/Avast.app/Contents/Backend/hub'
                    if [[ -e "$AVAST_BACKEND" ]]
                    then
                        echo "stopping avast services..."
                        sh "$AVAST_BACKEND"/usermodules/010_helper.sh stop >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/010_daemon.sh stop >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/014_fileshield.sh stop >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/020_service.sh stop >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/030_proxy.sh stop >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/060_wifiguard.sh stop >/dev/null 2>&1
                        sleep 1
                        echo "starting avast services..."
                        sh "$AVAST_BACKEND"/usermodules/010_helper.sh start >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/010_daemon.sh start >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/014_fileshield.sh start >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/020_service.sh start >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/030_proxy.sh start >/dev/null 2>&1
                        sudo sh "$AVAST_BACKEND"/modules/060_wifiguard.sh start >/dev/null 2>&1
                    else
                        echo "avast services not found, skipping..."
                    fi
                    echo ''
            	else
            	    :
            	fi
            else
                :
            fi
    	}
    	reinstall_avast_security
    }
    cleaning_before_installing

	#echo ''
	echo "installing casks..."
	
	# installing some casks that have to go first for compatibility reasons
	casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
	if [[ -e /tmp/casks_second_try.txt ]]; then rm -f /tmp/casks_second_try.txt; else :; fi
	if [[ "$casks_pre" == "" ]]
    then
    	:
    else
	    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	    then
	        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
            # it is not neccessary to export variables or functions when using env_parallel
            # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
            if [[ "${casks_pre[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "install_casks_parallel {}" ::: "${casks_pre[@]}"; fi
	    else
            while IFS= read -r line || [[ -n "$line" ]]
    		do
    		    if [[ "$line" == "" ]]; then continue; fi
                caskstoinstall_pre="$line"
    			# xquartz is a needed dependency for xpdf, so it has to be installed first
    			echo "installing cask $caskstoinstall_pre"...
    			env_use_password | brew install --cask --force "$caskstoinstall_pre"
    			echo ''
            done <<< "$(printf "%s\n" "${casks_pre[@]}")"
	    fi
	fi
	
	casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d' | grep -vi "xtrafinder" | grep -vi "totalfinder")
	finder_enhancements=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d' | grep -i -e "xtrafinder" -e "totalfinder")
    if [[ "$casks" == "" ]]
    then
    	:
    else
        # adding kext entries
        # read values
        # sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "select * from kext_policy;"
        # delete all entries from the same team id
        # sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "DELETE FROM kext_policy WHERE team_id = 'VB5E2TV963';"
        # allowing kext extensions via mobileconfig profile does not work locally, has to be deployed by a trusted mdm server
        # a reboot is needed for the changes to take effect
        #
        # to reset the complete kext policy and make macos ask for permission again
        #       boot into recovery (cmd + R)
        #           open disk utility and unlock volume and data volume
        #           open terminal
        #               chroot /Volumes/macintosh_hd
        #               sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy
        #                   delete from kext_policy;
        #                   delete from kext_load_history_v3;
        #                   .quit
        #           if a firmware password is set deactivate the firmware password (needed to reset PRAM)
        #       reset PRAM by rebooting and pressing cmd+option+P+R (release after second time chime or logo comes up)
        #       boot into macOS and uninstall and reinstall virtualbox and extension pack and macfuse
        #           brew reinstall --cask--force virtualbox virtualbox-extension-pack macfuse
        #       open system settings - security - general and accept extension
        #       open system settings - sound and disable startup chime (if wanted)
        #       reboot if needed
        #       boot into recovery (cmd + R)
        #           disable sip (if wanted)
        #           set firmware password (if wanted)
        #
        if [[ $(printf "%s\n" "${casks[@]}" | grep "^virtualbox" ) != "" ]]
        then
            echo ''
            echo "adding kext entry for virtualbox..."
            sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "REPLACE INTO kext_policy VALUES('VB5E2TV963','org.virtualbox.kext.VBoxDrv',1,'Oracle America, Inc.',5);"
            sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "REPLACE INTO kext_policy VALUES('VB5E2TV963','org.virtualbox.kext.VBoxUSB',1,'Oracle America, Inc.',5);"
            sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "REPLACE INTO kext_policy VALUES('VB5E2TV963','org.virtualbox.kext.VBoxNetFlt',1,'Oracle America, Inc.',5);"
            sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "REPLACE INTO kext_policy VALUES('VB5E2TV963','org.virtualbox.kext.VBoxNetAdp',1,'Oracle America, Inc.',5);"
            #echo ''
        fi
        if [[ $(printf "%s\n" "${casks[@]}" | grep "^macfuse$" ) != "" ]] || [[ $(printf "%s\n" "${casks[@]}" | grep "^veracrypt$" ) != "" ]]
        then
            echo "adding kext entry for macosfuse..."
            sudo sqlite3 /var/db/SystemPolicyConfiguration/KextPolicy "REPLACE INTO kext_policy VALUES('3T5GSNBU6W','io.macfuse.filesystems.macfuse',1,'Benjamin Fleischer',5);"
            echo ''
        fi
        # installing casks
	    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	    then
	        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
            # it is not neccessary to export variables or functions when using env_parallel
            # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
            if [[ "${casks[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "install_casks_parallel {}" ::: "${casks[@]}"; fi
	    else
	        while IFS= read -r line || [[ -n "$line" ]]
			do
			    if [[ "$line" == "" ]]; then continue; fi
                caskstoinstall="$line"
	            echo "installing cask $caskstoinstall"...
	        	env_use_password | brew install --cask --force "$caskstoinstall"
	        done <<< "$(printf "%s\n" "${casks[@]}")"
	    fi
	fi
	
	# making sure to have the latest version of macosfuse after installing virtualbox (which often ships with an outdated version)
	if [[ $(brew list --cask | grep "^virtualbox$") != "" ]]
    then
        echo ''
        echo "updating macosfuse after virtualbox install..."
        i="macfuse"
        env_use_password | env_timeout 300 brew install --cask --force "$i" 2> /dev/null | grep "successfully installed"
        if [[ $? -eq 0 ]]
        then
            # successfull
            :
        else
            # failed
            # making sure install check recognizes the failed install when using brew list --cask | grep "$i"
            if [[ -e "$BREW_CASKS_PATH"/"$i" ]]
            then
            	rm -rf "$BREW_CASKS_PATH"/"$i"
            else
            	:
            fi
        fi
        unset i
    else
        :
    fi
    
	# finder enhancement
	# as "$FINDER_ENHANCEMENT" is no longer installable by cask let`s install it that way ;)
	#FINDER_ENHANCEMENT=XtraFinder
	if [[ "${finder_enhancements[@]}" != "" ]]
    then
	    while IFS= read -r line || [[ -n "$line" ]] 
		do
		    if [[ "$line" == "" ]]; then continue; fi
            FINDER_ENHANCEMENT="$line"
        	FINDER_ENHANCEMENT_LOWERED=$(echo "$FINDER_ENHANCEMENT" | tr '[:upper:]' '[:lower:]')
        	if [[ -e ""$PATH_TO_APPS"/"$FINDER_ENHANCEMENT".app" ]]
        	then
        	    echo ''
        	    echo ""$FINDER_ENHANCEMENT_LOWERED" already installed..."
        	else
        
                SCRIPT_DIR_HOMEBREW_CASK="$SCRIPT_DIR_ONE_BACK"
            	if [[ -e "$SCRIPT_DIR_HOMEBREW_CASK"/3d_"$FINDER_ENHANCEMENT_LOWERED"_install.sh ]]
            	then
            	    RUN_FROM_CASKS_SCRIPT="yes" . "$SCRIPT_DIR_HOMEBREW_CASK"/3d_"$FINDER_ENHANCEMENT_LOWERED"_install.sh
            	    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
            	else
            	    echo "script to install "$FINDER_ENHANCEMENT_LOWERED" not found..."
            	fi
            	
            fi
    	done <<< "$(printf "%s\n" "${finder_enhancements[@]}")"
    else
        :
    fi

else
	:
fi

# installing user specific casks
if [[ "$INSTALL_SPECIFIC_CASKS1" == "yes" ]]
then
    if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
    then
        echo ''
    	echo "installing casks specific1..."
    	casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
    	if [[ "$casks_specific1" == "" ]]
	    then
	    	:
	    else
	        if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	        then
	        	# by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
                # it is not neccessary to export variables or functions when using env_parallel
                # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
                if [[ "${casks_specific1[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "install_casks_parallel {}" ::: "${casks_specific1[@]}"; fi
	        else
	        	while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                    caskstoinstall_specific1="$line"
	        	    echo "installing cask $caskstoinstall_specific1"...
	        		env_use_password | brew install --cask --force "$caskstoinstall_specific1"
	        	done <<< "$(printf "%s\n" "${casks_specific1[@]}")"
	        fi
		fi
    else
        :
    fi
else
    :
fi

# second try for casks that failed the first time
if [[ -e /tmp/casks_second_try.txt ]]
then
    SECOND_TRY="yes"
    echo ''
    echo "second try for casks that failed the first time..."
    casks_second_try=$(cat /tmp/casks_second_try.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d' | uniq)
    if [[ "$casks_second_try" == "" ]]
    then
    	:
    else
        if [[ "$INSTALLATION_METHOD" == "parallel" ]]
        then
        	# by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
            # it is not neccessary to export variables or functions when using env_parallel
            # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
            if [[ "${casks_second_try[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "install_casks_parallel {}" ::: "${casks_second_try[@]}"; fi
        else
        	while IFS= read -r line || [[ -n "$line" ]]
    		do
    		    if [[ "$line" == "" ]]; then continue; fi
                caskstoinstall_second_try="$line"
        	    echo "installing cask $caskstoinstall_second_try"...
        		env_use_password | brew install --cask --force "$caskstoinstall_second_try"
        	done <<< "$(printf "%s\n" "${casks_second_try[@]}")"
        fi
    fi
else
    :
fi

# allow opening apps
echo ''
echo "allowing casks to open..."
# list
#ALLOWED_CASKS_LIST=(
#jitsi-meet
#chromium
#)
# all casks
ALLOWED_CASKS_LIST=$(brew list --cask | tr "," "\n" | uniq)
ALLOWED_CASKS=$(printf "%s\n" "${ALLOWED_CASKS_LIST[@]}")

allow_opening_casks() {
    line="$1"
    if [[ $(brew list --cask | tr "," "\n" | grep "^$line$") != "" ]]
    then
        echo "$line"
        local CASK_INFO=$(brew info --cask --json=v2 "$line" | jq -r '.casks | .[]')
        #local CASK_INFO=$(brew info --cask "$CASK")
        local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
        #brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[]|(.artifacts|map(.[]?|select(type=="string")|select(test(".app$"))))|.[]'
        local CASK_ARTIFACT_APP=$(printf '%s\n' "$CASK_INFO" | jq -r '.artifacts|map(.[]?|select(type=="string")|select(test(".app$")))|.[]')
        if [[ "$CASK_ARTIFACT_APP" != "" ]]
        then
            local CASK_ARTIFACT_APP_NO_EXTENSION=$(echo ${$(basename $CASK_ARTIFACT_APP)%.*})
        else
            local CASK_ARTIFACT_APP_NO_EXTENSION="$CASK_NAME"
        fi
        local APP_NAME="$CASK_ARTIFACT_APP_NO_EXTENSION"
        #echo "$APP_NAME"
        env_set_open_on_first_run_permissions
        # allow additional apps inside of other apps
        if [[ "$line" == "bettertouchtool" ]]
        then
            local APP_NAME="BTTRelaunch"
            env_set_open_on_first_run_permissions
        else
            :
        fi
        if [[ "$line" == "alfred" ]]
        then
            local APP_NAME="Alfred Preferences"
            env_set_open_on_first_run_permissions
        else
            :
        fi
        if [[ "$line" == "bartender" ]]
        then
            local APP_NAME="BartenderStartAtLoginHelper"
            env_set_open_on_first_run_permissions
        else
            :
        fi
    else
        :
    fi
}

if [[ "$INSTALLATION_METHOD" == "parallel" ]]
then
    # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
    # it is not neccessary to export variables or functions when using env_parallel
    # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
    if [[ "${ALLOWED_CASKS[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "allow_opening_casks {}" ::: "${ALLOWED_CASKS[@]}"; fi
else
    while IFS= read -r line || [[ -n "$line" ]]
    do
        if [[ $(brew list --cask | tr "," "\n" | grep "^$line$") != "" ]]
        then
            echo "$line"
            local CASK_INFO=$(brew info --cask --json=v2 "$line" | jq -r '.casks | .[]')
            #local CASK_INFO=$(brew info --cask "$CASK")
            local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
            #brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[]|(.artifacts|map(.[]?|select(type=="string")|select(test(".app$"))))|.[]'
            local CASK_ARTIFACT_APP=$(printf '%s\n' "$CASK_INFO" | jq -r '.artifacts|map(.[]?|select(type=="string")|select(test(".app$")))|.[]')
            if [[ "$CASK_ARTIFACT_APP" != "" ]]
            then
                local CASK_ARTIFACT_APP_NO_EXTENSION=$(echo ${$(basename $CASK_ARTIFACT_APP)%.*})
            else
                local CASK_ARTIFACT_APP_NO_EXTENSION="$CASK_NAME"
            fi
            local APP_NAME="$CASK_ARTIFACT_APP_NO_EXTENSION"
            #echo "$APP_NAME"
            env_set_open_on_first_run_permissions
            # allow additional apps inside of other apps
            if [[ "$line" == "bettertouchtool" ]]
            then
                local APP_NAME="BTTRelaunch"
                env_set_open_on_first_run_permissions
            else
                :
            fi
            if [[ "$line" == "alfred" ]]
            then
                local APP_NAME="Alfred Preferences"
                env_set_open_on_first_run_permissions
            else
                :
            fi
        else
            :
        fi
    done <<< "$(printf "%s\n" "${ALLOWED_CASKS[@]}")"
fi

# if script is run standalone, not sourced or run from run_all script, clean up
if [[ "$SCRIPT_IS_SOURCED" == "yes" ]] || [[ "$RUN_FROM_RUN_ALL_SCRIPT" == "yes" ]]
then
    # script is sourced or run from run_all script
    :
else
    # script is not sourced and not run from run_all script, it is run standalone

    # cleaning up
    echo ''
    echo "cleaning up..."
    env_cleanup_all_homebrew
fi

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then 
    :
else
    CHECK_IF_FORMULAE_INSTALLED="no" CHECK_IF_MASAPPS_INSTALLED="no" . "$SCRIPT_DIR"/7_formulae_casks_and_mas_install_check.sh
fi

# installing user specific casks
if [[ "$INSTALL_JAVA8" == "yes" ]]
then
    
    echo ''
    
    brew tap AdoptOpenJDK/openjdk
    env_use_password | brew install --cask adoptopenjdk8
    #env_use_password | brew install --cask caskroom/versions/java8
    #env_use_password | brew install --cask AdoptOpenJDK/openjdk/adoptopenjdk8
    
    java8_install_script() {
    	SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_THREE_BACK"
    	if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/java8_install.sh ]]
    	then
    		echo ''
    	    JAVA_OPTION="i" 
    	    . "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/java8_install.sh
    	else
    	    echo "script to install java8 not found..." >&2
    	fi
	}
	#java8_install_script
    
    echo ''
    
else
    :
fi

### removing security permissions and stopping sudo
#env_remove_apps_security_permissions_stop


### stopping sudo
env_stop_sudo

echo ''

#exit

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

