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


### mas apps
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


### casks
read -p "do you want to install casks apps? select no when using restore script on clean install (Y/n)? " CONT2_BREW
CONT2_BREW="$(echo "$CONT2_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower
echo ''

if [[ "$CONT2_BREW" =~ ^(y|yes|n|no)$ || "$CONT2_BREW" == "" ]]
then
    :
else
    #echo ''
    echo "wrong input, exiting script..."
    echo ''
    exit
fi


### scripts
. "$SCRIPT_DIR"/2_command_line_tools.sh
. "$SCRIPT_DIR"/3_homebrew_caskbrew.sh

if [[ "$CONT3_BREW" == "y" || "$CONT3_BREW" == "yes" || "$CONT3_BREW" == "" ]]
then

    create_tmp_homebrew_script_fifo
    identify_terminal

    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    tell application "Terminal"
    	if not (exists window 1) then reopen
    	activate
    	delay 2
    	set newWindow1 to front window
    	tell application "System Events" to keystroke "t" using command down
    	#repeat while contents of selected tab of window 1 starts with linefeed
    	delay 2
    	#
    	#end repeat
    	set newWindow2 to front window
    	#set newTab's selected to true
    	do script "export SCRIPT_DIR=\"$SCRIPT_DIR\"; export FIRST_RUN_DONE=\"$FIRST_RUN_DONE\"; export MAS_APPLE_ID=\"$MAS_APPLE_ID\"; export MAS_APPSTORE_PASSWORD=\"$MAS_APPSTORE_PASSWORD\"; (time  \"$SCRIPT_DIR/6_mas_appstore.sh\") && echo ''" in newWindow2
    	delay 40
        set frontmost of newWindow1 to true
    end tell
EOF

else 
    CHECK_IF_MASAPPS_INSTALLED="no"
fi

if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
    
    sleep 5
    create_tmp_homebrew_script_fifo
    identify_terminal

    #osascript 2>/dev/null <<EOF
    osascript <<EOF
    tell application "Terminal"
    	if not (exists window 1) then reopen
    	activate
    	delay 2
    	set newWindow1 to front window
    	tell application "System Events" to keystroke "t" using command down
    	#repeat while contents of selected tab of window 1 starts with linefeed
    	delay 2
    	#
    	#end repeat
    	set newWindow2 to front window
    	#set newTab's selected to true
    	do script "export SCRIPT_DIR=\"$SCRIPT_DIR\"; export FIRST_RUN_DONE=\"$FIRST_RUN_DONE\"; (time \"$SCRIPT_DIR/5_casks.sh\") && echo ''" in newWindow2
    	delay 10
        set frontmost of newWindow1 to true
    end tell
EOF

else 
    CHECK_IF_CASKS_INSTALLED="no"
fi

. "$SCRIPT_DIR"/4_homebrew_formulae.sh

# waiting for the scripts in the separate tabs to finish
echo ''
echo "waiting for casks and mas scripts..."
while ps aux | grep /5_casks.sh | grep -v grep > /dev/null; do sleep 1; done
while ps aux | grep /6_mas_appstore.sh | grep -v grep > /dev/null; do sleep 1; done

echo ''
. "$SCRIPT_DIR"/7_formulae_and_casks_install_check.sh

}
time run_all
