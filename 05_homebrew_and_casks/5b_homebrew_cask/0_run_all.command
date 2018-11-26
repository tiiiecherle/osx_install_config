#!/bin/bash

# wrap in function for getting time
run_all() {

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
FILENAME_INSTALL_SCRIPT=$(basename "$BASH_SOURCE")
export FILENAME_INSTALL_SCRIPT



###
### script frame
###

if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
then
    . "$SCRIPT_DIR"/1_script_frame.sh
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi



###
### script
###

#echo ''
echo "installing homebrew and homebrew casks..."
echo ''


### killing possible old processes
#ps aux | grep -ie /5_casks.sh | grep -v grep | awk '{print $2}' | xargs kill -9 
#ps aux | grep -ie /6_mas_appstore.sh | grep -v grep | awk '{print $2}' | xargs kill -9 


### asking for mas apps
read -p "do you want to install appstore apps via mas? (Y/n)? " CONT3_BREW
CONT3_BREW="$(echo "$CONT3_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower

if [[ "$CONT3_BREW" =~ ^(y|yes|n|no)$ || "$CONT3_BREW" == "" ]]
then
    :
else
    echo ''
    echo "wrong input, exiting script..."
    echo ''
    exit
fi

if [[ "$CONT3_BREW" == "y" || "$CONT3_BREW" == "yes" || "$CONT3_BREW" == "" ]]
then
    if [[ "$MAS_APPLE_ID" == "" ]]
    then
        #echo ''
        MAS_APPLE_ID="    "
        read -r -p "please enter apple id to log into appstore: " MAS_APPLE_ID
        #echo $MAS_APPLE_ID
    else
        :
    fi
    
    if [[ "$MAS_APPSTORE_PASSWORD" == "" ]]
    then
        #echo ''
        #echo "please enter appstore password..."
        MAS_APPSTORE_PASSWORD="    "
    
        # ask for password twice
        #while [[ $MAS_APPSTORE_PASSWORD != $MAS_APPSTORE_PASSWORD2 ]] || [[ $MAS_APPSTORE_PASSWORD == "" ]]; do stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && printf "re-enter appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD2 && stty echo && printf "\n" && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''; done
    
        # only ask for password once
        stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && stty echo && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''
        echo ''
    else
        :
    fi
else
    echo ''
fi


### asking for casks
#read -p "do you want to install casks apps? select no when using restore script on clean install (Y/n)? " CONT2_BREW
read -p "do you want to install casks apps? (Y/n)? " CONT2_BREW
CONT2_BREW="$(echo "$CONT2_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower
if [[ "$CONT2_BREW" =~ ^(y|yes|n|no)$ || "$CONT2_BREW" == "" ]]
then
    :
else
    #echo ''
    echo "wrong input, exiting script..."
    echo ''
    exit
fi

if [[ -e "/tmp/Caskroom" ]]
then
    read -p "$(echo -e 'found a backup of cask specifications in /tmp/Caskroom \ndo you wanto to restore /tmp/Caskroom/. to /usr/local/Caskroom/' '(Y/n)? ')" CONT_CASKROOM
    if [[ "$CONT_CASKROOM" == "" ]]
    then
        CONT_CASKROOM=y
    else
        :
    fi
    CONT_CASKROOM="$(echo "$CONT_CASKROOM" | tr '[:upper:]' '[:lower:]')"    # tolower
    if [[ "$CONT_CASKROOM" =~ ^(y|yes|n|no)$ || "$CONT_CASKROOM" == "" ]]
    then
        :
    else
        #echo ''
        echo "wrong input, exiting script..."
        echo ''
        exit
    fi
else
    :
fi
echo ''


### command line tools
. "$SCRIPT_DIR"/2_command_line_tools.sh


### homebrew, homebrew-cask and other taps
. "$SCRIPT_DIR"/3_homebrew_caskbrew.sh


### updating homebrew
UPDATE_HOMEBREW="yes"
homebrew_update


### mas
if [[ "$CONT3_BREW" == "y" || "$CONT3_BREW" == "yes" || "$CONT3_BREW" == "" ]]
then

    create_tmp_homebrew_script_fifo
    identify_terminal
    UPDATE_HOMEBREW="no"

    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    tell application "Terminal"
    	if it is running then
    		#if not (exists window 1) then
    		if (count of every window) is 0 then
    			reopen
    			activate
    			set Window1 to front window
    			set runWindow to front window
    		else
    			activate
    			delay 2
    			set Window1 to front window
    			#
    			tell application "System Events" to keystroke "t" using command down
    			delay 2
    			set Window2 to front window
    			set runWindow to front window
    		end if
    	else
    		activate
    		set Window1 to front window
    		set runWindow to front window
    	end if
    	#delay 2
        #    	
        do script "export SCRIPT_DIR=\"$SCRIPT_DIR\"; export FIRST_RUN_DONE=\"$FIRST_RUN_DONE\"; export UPDATE_HOMEBREW=\"$UPDATE_HOMEBREW\"; export MAS_APPLE_ID=\"$MAS_APPLE_ID\"; (time  \"$SCRIPT_DIR/6_mas_appstore.sh\") && echo ''" in runWindow
    	#
    	delay 40
        set frontmost of Window1 to true
    end tell
EOF

else 
    CHECK_IF_MASAPPS_INSTALLED="no"
fi


### casks
if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
    sleep 5
    create_tmp_homebrew_script_fifo
    identify_terminal
    UPDATE_HOMEBREW="no"

    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    tell application "Terminal"
    	if it is running then
    		#if not (exists window 1) then
    		if (count of every window) is 0 then
    			reopen
    			activate
    			set Window1 to front window
    			set runWindow to front window
    		else
    			activate
    			delay 2
    			set Window1 to front window
    			#
    			tell application "System Events" to keystroke "t" using command down
    			delay 2
    			set Window2 to front window
    			set runWindow to front window
    		end if
    	else
    		activate
    		set Window1 to front window
    		set runWindow to front window
    	end if
    	#delay 2
    	#
    	do script "export SCRIPT_DIR=\"$SCRIPT_DIR\"; export FIRST_RUN_DONE=\"$FIRST_RUN_DONE\"; export UPDATE_HOMEBREW=\"$UPDATE_HOMEBREW\"; export CONT_CASKROOM=\"$CONT_CASKROOM\"; (time \"$SCRIPT_DIR/5_casks.sh\") && echo ''" in runWindow
    	#
    	delay 10
        set frontmost of Window1 to true
    end tell
EOF

else 
    CHECK_IF_CASKS_INSTALLED="no"
fi


### homebrew formulae
UPDATE_HOMEBREW="no"
. "$SCRIPT_DIR"/4_homebrew_formulae.sh


### waiting for the scripts in the separate tabs to finish
#echo ''
echo "waiting for casks and mas scripts..."
while ps aux | grep /5_casks.sh | grep -v grep >/dev/null; do sleep 1; done
while ps aux | grep /6_mas_appstore.sh | grep -v grep >/dev/null; do sleep 1; done


### checking success of installations
echo ''
. "$SCRIPT_DIR"/7_formulae_and_casks_install_check.sh

}
time run_all
