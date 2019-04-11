 #!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)


###
### script frame
###

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
        . "$SCRIPT_DIR"/1_script_frame.sh
    else
        echo ''
        echo "script for functions and prerequisits is missing, exiting..."
        echo ''
        exit
    fi
fi


###
### command line tools
###

checking_command_line_tools


###
### homebrew
###

checking_homebrew


### keepingyouawake
if [[ "$KEEPINGYOUAWAKE" != "active" ]]
then
    echo ''
    activating_keepingyouawake
    echo ''
else
    echo ''
fi


### starting sudo
start_sudo


### installing mas
# mas has its own formula for all macos versions
# if mas in homebrew core is not working or out of date use
# https://github.com/mas-cli/homebrew-tap
# when used brew info $item 2>/dev/null has to be used in homebrew update script to avoid warnings
#brew tap mas-cli/tap
#brew tap-pin mas-cli/tap
#brew install mas
# to unpin and get back to homebrew-core version
#brew tap-unpin mas-cli/tap

# install version from homebrew-core
brew install mas

echo ''

### parallel
checking_parallel

### accepting privacy policy
defaults write ~/Library/Preferences/com.apple.AppStore.plist ASAcknowledgedOnboardingVersion -int 1

### mas login

function mas_login() {
    
    mas signout
    sleep 3
    
    #echo ''
    MAS_APPLE_ID="    "
    read -r -p "please enter apple id to log into appstore: " MAS_APPLE_ID
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

ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}

function mas_login_applescript() {
    
    # macos 10.14 only
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.') != "10.14" ]]
    then
        #echo ''
        echo "this part of the script to login to the appstore automatically via applescript is only compatible with macos 10.14 mojave..."
        echo "please login to the appstore manually and press enter when logged in..."
        
        VARIABLE_TO_CHECK="$CONT1_MAS"
        QUESTION_TO_ASK="are you logged in on the appstore (Y/n)? "
        ask_for_variable
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
            echo ''
            MAS_APPLE_ID="    "
            read -r -p "please enter apple id to log into appstore: " MAS_APPLE_ID
            #echo $MAS_APPLE_ID
        else
            :
        fi
        
        if [[ "$MAS_APPSTORE_PASSWORD" == "" ]]
        then
            echo ''
            echo "please enter appstore password..."
            MAS_APPSTORE_PASSWORD="    "
        
            # ask for password twice
            #while [[ $MAS_APPSTORE_PASSWORD != $MAS_APPSTORE_PASSWORD2 ]] || [[ $MAS_APPSTORE_PASSWORD == "" ]]; do stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && printf "re-enter appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD2 && stty echo && printf "\n" && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''; done
        
            # only ask for password once
            stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && stty echo && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''
            echo ''
        else
            :
        fi
        
        mas signout
        sleep 3
    
    	osascript <<EOF
        tell application "App Store"
            try
        	    activate
        	    delay 5
        	end try
        end tell
    
        tell application "System Events"
        	tell process "App Store"
        		set frontmost to true
        		delay 2
        		### on first run when installing the appstore asks for accepting privacy policy
        		try
    			    click button 2 of UI element 1 of sheet 1 of window 1
    			    #click button "Weiter" of UI element 1 of sheet 1 of window 1
    			    delay 3
    		    end try
    		    ### login
        		click menu item 15 of menu "Store" of menu bar item "Store" of menu bar 1
        		#click menu item "Anmelden" of menu "Store" of menu bar item "Store" of menu bar 1
        		delay 2
        		tell application "System Events" to keystroke "$MAS_APPLE_ID"
        		delay 2
        		tell application "System Events" to keystroke return
        		delay 2
        		tell application "System Events" to keystroke "$MAS_APPSTORE_PASSWORD"
        		delay 2
        		tell application "System Events" to keystroke return
        	end tell
        end tell
        
        tell application "App Store"
            try
                delay 10
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
	#echo doing it for $1
	if [[ "$USE_PARALLELS" == "yes" ]]
	then
		# if parallels is used i needs to redefined
		i="$1"
	else
		:
	fi
	#echo ''
	#echo "$i"
	MAS_NUMBER=$(echo "$i" | awk '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
	#echo $MAS_NUMBER
	MAS_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
	#echo $MAS_NAME
	echo installing app "$MAS_NAME"...
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
	    # formatting of output gets lost
	    #mas install --force "$MAS_NUMBER" | grep "Installed"
	    #mas install --force "$MAS_NUMBER"
	    mas install "$MAS_NUMBER"
	else
	    #mas install --force "$MAS_NUMBER"
	    mas install "$MAS_NUMBER"
	fi
	            
}
export -f install_mas_apps


### installing mas apps
#echo ''

if [[ "$CONT3_BREW" == "y" || "$CONT3_BREW" == "yes" || "$CONT3_BREW" == "" ]]
then
	
	mas_login_applescript

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
	        printf '%s\n' "${mas_apps[@]}" | tr "\n" "\0" | xargs -0 -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
	        i="{}"
	        install_mas_apps
	        '
	    else
	    	old_IFS=$IFS
	        IFS=$'\n'
        	for i in ${mas_apps[@]}
        	do
        		IFS=$old_IFS
        		#export USE_PARALLELS="no"
        		install_mas_apps
        		echo ''
        	done
        	#unset USE_PARALLELS
	    fi
	fi

else
	:
fi
   
    
# cleaning up
#echo ''
#echo "cleaning up..."
# appstore cache should clean itself or should be cleaned by mas

# if script is run standalone, not sourced from another script or run from run_all script
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] || [[ "$RUN_FROM_RUN_ALL_SCRIPT" == "yes" ]]
then
    # script is sourced or run from run_all script
    :
else
    # script is not sourced and not run from run_all script, it is run standalone
    :
fi

CHECK_IF_FORMULAE_INSTALLED="no"
CHECK_IF_CASKS_INSTALLED="no"
echo ''
# waiting for apps to be registered correctly before checking success
echo "waiting 20s for apps to be registered correctly before checking success"...
echo ''
sleep 20
. "$SCRIPT_DIR"/7_formulae_and_casks_install_check.sh


###

stop_sudo
