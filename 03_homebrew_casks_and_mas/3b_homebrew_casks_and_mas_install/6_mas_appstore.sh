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
    trap_function_exit_start() { env_delete_tmp_mas_script_fifo; }
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi

        

###
### password
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_sudo_mas_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_sudo_mas_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_sudo_mas_script_fifo
        #set +a
    else
        env_enter_sudo_password
    fi
else
    :
fi

### appstore password
if [[ "$MAS_APPSTORE_PASSWORD" != "" ]]
then
    :
else
    if [[ -e /tmp/tmp_appstore_mas_script_fifo ]]
    then
        unset MAS_APPSTORE_PASSWORD
        MAS_APPSTORE_PASSWORD=$(cat "/tmp/tmp_appstore_mas_script_fifo" | head -n 1)
        env_delete_tmp_appstore_mas_script_fifo
    else
        :
    fi
fi



###
### command line tools
###

#echo ''
env_command_line_tools_install_shell


###
### mas
###

checking_homebrew
env_check_if_second_macos_volume_is_mounted



### activating caffeinate
env_activating_caffeinate


### installing mas
# mas has its own formula for all macos versions
# if mas in homebrew core is not working or out of date use
# https://github.com/mas-cli/homebrew-tap
# when used brew info --formula $item 2>/dev/null has to be used in homebrew update script to avoid warnings
#brew tap mas-cli/tap
#brew tap-pin mas-cli/tap
#brew install mas
# to unpin and get back to homebrew-core version
#brew tap-unpin mas-cli/tap

# install version from homebrew-core
brew install mas

echo ''

### parallel
env_check_if_parallel_is_installed

### accepting privacy policy
defaults write ~/Library/Preferences/com.apple.AppStore.plist ASAcknowledgedOnboardingVersion -int 1

### setting notifications
APPLICATIONS_TO_SET_NOTIFICATIONS=(
"App Store																41943375"
)
SET_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications
CHECK_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications
sleep 1
echo ''


### mas login
mas_login() {
    
    mas signout
    sleep 3
    
    #echo ''
    MAS_APPLE_ID=""
    VARIABLE_TO_CHECK="$MAS_APPLE_ID"
    QUESTION_TO_ASK="please enter apple id to log into appstore: "
    env_ask_for_variable
    MAS_APPLE_ID="$VARIABLE_TO_CHECK"
    #echo $MAS_APPLE_ID
    
    if [[ "$MAS_APPLE_ID" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]
    then
        :
    else
        echo "this is not a valid apple-id, exiting..."
        exit
    fi
    
    #mas signin --dialog "$MAS_APPLE_ID"
    mas signin "$MAS_APPLE_ID"
	
}
#mas_login

mas_login_applescript() {
    
    # macos 10.14 and newer
    VERSION_TO_CHECK_AGAINST=10.13
    if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
    then
        #echo ''
        echo "this part of the script to login to the appstore automatically via applescript is only compatible with macos 10.14 mojave..."
        echo "please login to the appstore manually and press enter when logged in..."
        
        VARIABLE_TO_CHECK="$CONT1_MAS"
        QUESTION_TO_ASK="are you logged in on the appstore (Y/n)? "
        env_ask_for_variable
        CONT1_MAS="$VARIABLE_TO_CHECK"
        
        if [[ "$CONT1_MAS" =~ ^(yes|y)$ ]]
        then
            :
        else
            echo ''
            echo "exiting script..."
            echo ''
            exit
        fi
    else
        if [[ "$MAS_APPLE_ID" == "" ]]
        then
            #echo ''
            MAS_APPLE_ID=""
            VARIABLE_TO_CHECK="$MAS_APPLE_ID"
            QUESTION_TO_ASK="please enter apple id to log into appstore: "
            env_ask_for_variable
            MAS_APPLE_ID="$VARIABLE_TO_CHECK"
            #echo $MAS_APPLE_ID
        else
            :
        fi
        
        if [[ "$MAS_APPSTORE_PASSWORD" == "" ]]
        then
            echo ''
            echo "please enter appstore password..."
            MAS_APPSTORE_PASSWORD=""
        
            # ask for password twice
            while [[ $MAS_APPSTORE_PASSWORD != $MAS_APPSTORE_PASSWORD2 ]] || [[ $MAS_APPSTORE_PASSWORD == "" ]]; do stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && printf "re-enter appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD2 && stty echo && printf "\n" && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''; done
        
            # only ask for password once
            #stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && stty echo && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''
            echo ''
        else
            :
        fi
        
        mas signout
        sleep 3
    
    	osascript <<EOF
        tell application "App Store"
            launch
            delay 5
            #activate
            #delay 2
        end tell
        
        ## do not use visible as it makes the window un-clickable
        #tell application "System Events" to tell process "App Store" to set visible to true
    	#delay 1
    	tell application "System Events" to tell process "App Store" to set frontmost to true
    	delay 2
    
        tell application "System Events"
        	tell process "App Store"
        		### on first run when installing the appstore asks for accepting privacy policy
        		# to reset delete ASAcknowledgedOnboardingVersion from ~/Library/Preferences/com.apple.AppStore.plist and reboot
        		try
        		   if "$MACOS_VERSION_MAJOR" is equal to "10.14" then
            		    click button 2 of UI element 1 of sheet 1 of window 1
            		    #click button "Weiter" of UI element 1 of sheet 1 of window 1
                    end if
                    if "$MACOS_VERSION_MAJOR" is equal to "10.15" then
            		    click button 2 of UI element 1 of sheet 1 of window 1
            		    #click button "Weiter" of UI element 1 of sheet 1 of window 1
                    end if
                    if "$MACOS_VERSION_MAJOR" greater than or equal to "11" then
            		    click button 2 of UI element 1 of sheet 1 of window "App Store" 
                    end if
    		    end try
                delay 8
                
    		    ### on clean install on first run the appstore asks for enabling notifications
    		    # set before login by adding preferences for app store for notification center
    		    
    		    ### login
    		    if "$MACOS_VERSION_MAJOR" is equal to "10.14" then
        		    click menu item 15 of menu "Store" of menu bar item "Store" of menu bar 1
                end if
                if "$MACOS_VERSION_MAJOR" is equal to "10.15" then
        		    click menu item 16 of menu "Store" of menu bar item "Store" of menu bar 1
                end if
                if "$MACOS_VERSION_MAJOR" greater than or equal to "11" then
        		    click menu item 16 of menu "Store" of menu bar item "Store" of menu bar 1
                end if
        		#click menu item "Anmelden" of menu "Store" of menu bar item "Store" of menu bar 1
        		delay 2
        		if "$MACOS_VERSION_MAJOR" is equal to "10.14" then
        		    set focused of text field "Apple-ID:" of sheet 1 of window 1 to true
                end if
                if "$MACOS_VERSION_MAJOR" is equal to "10.15" then
        		    set focused of text field "Apple-ID:" of sheet 1 of window 1 to true
                end if
                if "$MACOS_VERSION_MAJOR" greater than or equal to "11" then
                    try
        		        set focused of text field "Apple-ID:" of sheet 1 of sheet 1 of window "App Store" to true
        		    on error
        		        set focused of text field 1 of sheet 1 of sheet 1 of window "App Store" to true
        		    end try
                end if
        		delay 3
        		tell application "System Events" to keystroke "$MAS_APPLE_ID"
        		delay 3
        		tell application "System Events" to keystroke return
        		delay 3
        		tell application "System Events" to keystroke "$MAS_APPSTORE_PASSWORD"
        		delay 3
        		tell application "System Events" to keystroke return
        		# leave two factor auth disabled if disabled before
                if "$MACOS_VERSION_MAJOR" greater than or equal to "11" then
            		try
            		    delay 15
            		    try
            		        # german
            		        click button "Weitere Optionen" of group 6 of group 1 of UI element 1 of scroll area 1 of sheet 1 of sheet 1 of window "App Store"
            		    on error
            		        # universal
            		        click button 1 of group 6 of group 1 of UI element 1 of scroll area 1 of sheet 1 of sheet 1 of window "App Store"
            		    end try
            		    delay 8
            		    try
            		        # german
            		        click button "Nicht aktualisieren" of sheet 1 of sheet 1 of window "App Store" 
            		    on error
            		        # universal
            		        click button 1 of sheet 1 of sheet 1 of window "App Store" 
            		    end try
                        delay 8
                    end try
                end if
        	end tell
        end tell
        
        tell application "App Store"
            try
                delay 15
        	    quit
        	end try
        end tell
        
EOF

    fi
 
}


### quitting a few apps before continuing

echo "quitting some apps before installation..."
echo ''

	osascript <<EOF
    
    tell application "VirusScannerPlus"
        try
    	    quit
    	end try
    end tell
    
    tell application "AudioSwitcher"
        try
    	    quit
    	end try
    end tell
    
EOF


###

install_mas_apps() {
    # always use _ instead of - because some sh commands called by parallel would give errors
	# if parallels is used i needs to redefined
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# if parallels is used i needs to redefined
		i="$1"
	else
		:
	fi
	#echo ''
	#echo "$i"
	MAS_NUMBER=$(echo "$i" | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	#echo $MAS_NUMBER
	MAS_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	#echo $MAS_NAME
    if [[ $(find "$PATH_TO_APPS" -path '*Contents/_MASReceipt/receipt' -maxdepth 4 -print | sed 's#.app/Contents/_MASReceipt/receipt#.app#g; s#/Applications/##' | rev | cut -s -f 1 -d '/' | rev | grep "$MAS_NAME") == "" ]]
    then
        echo installing app "$MAS_NAME"...
        mas install --force "$MAS_NUMBER" | grep "Installed"
    else
        echo ""$MAS_NAME" already installed..."
    fi
}


### installing mas apps
#echo ''

if [[ "$CONT3_BREW" == "y" || "$CONT3_BREW" == "yes" || "$CONT3_BREW" == "" ]]
then
	
	mas_login_applescript
	
	# make sure mas is aware of installed and uninstalled apps
	sleep 2
	mas reset
	sleep 2
	mas list >/dev/null
	sleep 2
	mas list >/dev/null
	sleep 2

    echo "the app store has to be quit before continuing..."
    while ps aux | grep 'App Store.app' | grep -v grep > /dev/null; do sleep 1; done
    echo ''

	echo "installing mas appstore apps..."
	# keep order of lines in file
    mas_apps=$(cat "$SCRIPT_DIR"/_lists/04_mas_apps.txt | sed '/^#/ d'  | sed '/^$/d')
    # sorting alpahabetically
    #mas_apps=$(cat "$SCRIPT_DIR"/_lists/04_mas_apps.txt | sed '/^#/ d'  | sed '/^$/d' | sort -k 2 -t $'\t' --ignore-case)
    if [[ "$mas_apps" == "" ]]
    then
    	:
    else
	    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	    then
	    	# by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
            # it is not neccessary to export variables or functions when using env_parallel
            # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
            if [[ "${mas_apps[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "install_mas_apps {}" ::: "${mas_apps[@]}"; fi
	    else
    	    while IFS= read -r line || [[ -n "$line" ]]
			do
			    if [[ "$line" == "" ]]; then continue; fi
                i="$line"
                install_mas_apps "$i"
            done <<< "$(printf "%s\n" "${mas_apps[@]}")"
	    fi
	fi

else
	:
fi
   
    
# cleaning up
#echo ''
#echo "cleaning up..."
# appstore cache should clean itself or should be cleaned by mas

# if script is run standalone, not sourced or run from run_all script, clean up
if [[ "$SCRIPT_IS_SOURCED" == "yes" ]] || [[ "$RUN_FROM_RUN_ALL_SCRIPT" == "yes" ]]
then
    # script is sourced or run from run_all script
    :
else
    # script is not sourced and not run from run_all script, it is run standalone
    :
fi

echo ''

# waiting for apps to be registered correctly before checking success
#sleep 1
#mas reset
#killall Finder

# no longer waiting time needed
# changed testing method in 7_formulae_casks_and_mas_install_check.sh
WAITING_TIME=1
NUM1=0
echo ''
while [[ "$NUM1" -le "$WAITING_TIME" ]]
do 
	NUM1=$((NUM1+1))
	if [[ "$NUM1" -le "$WAITING_TIME" ]]
	then
		#echo "$NUM1"
		sleep 1
		tput cuu 1 && tput el
		# output has to fit in one terminal line
		echo "waiting $((WAITING_TIME-NUM1)) seconds for apps to be registered before checking success..."
	else
		:
	fi
done

if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    echo ''
else
    CHECK_IF_FORMULAE_INSTALLED="no" CHECK_IF_CASKS_INSTALLED="no" . "$SCRIPT_DIR"/7_formulae_casks_and_mas_install_check.sh
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

