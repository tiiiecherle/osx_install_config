#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" != "" ]]
then
    #USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    :
else
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
    
fi
    
# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}


###
### starting installation
###


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

function unset_variables() {
    unset SUDOPASSWORD
    unset SUDO_PID
}

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    ( while true; do ${USE_PASSWORD} | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID="$!"
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then
            sudo kill -9 $SUDO_PID &> /dev/null
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}

function activating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
	echo "activating keepingyouawake..."
    #echo ''
	open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///activate
else
        :
fi
}

function deactivating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
    echo "deactivating keepingyouawake..."
    open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///deactivate
else
    :
fi
}


### variables
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)


### trapping
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_SOURCED="yes" || SCRIPT_SOURCED="no"
[[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"
# a sourced script does not exit, it ends with return, so checking for session master is sufficent
# subprocesses will not be killed on return, only on exit
#if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_SOURCED" == "no" ]]
if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]]
then
    # script is session master and not run from another script (S on mac Ss on linux)
    trap "stop_sudo; printf '\n'; stty sane; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    # kill main process only if it hangs on regular exit
    trap "stop_sudo; stty sane; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
else
    # script is not session master and run from another script (S+ on mac and linux) 
    trap "stop_sudo; printf '\n'; stty sane; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    # kill main process only if it hangs on regular exit
    trap "stop_sudo; stty sane; unset SUDOPASSWORD; exit" EXIT
fi
#set -e

# checking if online
echo ''
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "we are online, running script..."
    #echo ''
    
    # starting sudo keep alive loop
    start_sudo
    
    # registering xtrafinder
    echo ''
    SCRIPT_DIR_LICENSE=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && pwd)")
	if [[ -e "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/xtrafinder_register.sh ]]
	then
	    "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/xtrafinder_register.sh
	else
	    echo "script to register xtrafinder not found..."
	fi
        	
	# as xtrafinder is no longer installable by cask let`s install it that way ;)
    echo ''
	echo "downloading xtrafinder..."
	XTRAFINDER_INSTALLER="/Users/$USER/Desktop/XtraFinder.dmg"
	#wget https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -O "$XTRAFINDER_INSTALLER"
	curl https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -o "$XTRAFINDER_INSTALLER" --progress-bar
	#open "$XTRAFINDER_INSTALLER"
	echo "mounting image..."
	hdiutil attach "$XTRAFINDER_INSTALLER" -quiet
	sleep 5
	# uninstall
	echo "uninstalling application..."
	#${USE_PASSWORD} | sudo /Volumes/XtraFinder/Extra/Uninstall.app/Contents/MacOS/Uninstall 1>/dev/null
	${USE_PASSWORD} | sudo /Volumes/XtraFinder/Extra/Uninstall.app/Contents/MacOS/Uninstall 2>&1 | grep -v "Failed to connect (window) outlet"
	sleep 10
	echo "installing application..."
	${USE_PASSWORD} | sudo installer -pkg /Volumes/XtraFinder/XtraFinder.pkg -target / 1>/dev/null
	#sudo installer -pkg /Volumes/XtraFinder/XtraFinderInstaller.pkg -target / 1>/dev/null
	sleep 1
	#echo "waiting for installer to finish..."
	#while ps aux | grep 'installer' | grep -v grep > /dev/null; do sleep 1; done
	echo "unmounting and removing installer..."
	hdiutil detach /Volumes/XtraFinder -quiet
	if [ -e "$XTRAFINDER_INSTALLER" ]; then rm "$XTRAFINDER_INSTALLER"; else :; fi
	# automation permissions
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        # working, but does not show in gui of system preferences, use csreq for the entry to show
        #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.trankynam.XtraFinder',0,1,1,?,NULL,0,'com.apple.finder',?,NULL,?);"
        # working
	    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.trankynam.XtraFinder',0,1,1,X'fade0c00000000a000000001000000060000000200000018636f6d2e7472616e6b796e616d2e5874726146696e646572000000060000000f000000060000000b000000000000000a7375626a6563742e434e000000000001000000274d616320446576656c6f7065723a205472616e204b79204e616d202850594e3545554748363629000000000e000000010000000a2a864886f76364060201000000000000',NULL,0,'com.apple.finder',X'fade0c000000002c00000001000000060000000200000010636f6d2e6170706c652e66696e64657200000003',NULL,?);"
	    :
    fi
	
	if [ -e "/Applications/XtraFinder.app" ]
    then
    
    	echo "setting xtrafinder preferences..."
    	
    	# automatically check for updates
    	defaults write com.apple.finder XFAutomaticChecksForUpdate -bool true
    	
    	# enable copy / cut - paste
    	defaults write com.apple.finder XtraFinder_XFCutAndPastePlugin -bool true
    	
    	# disable xtrafinder tabs
    	defaults write com.apple.finder XtraFinder_XFTabPlugin -bool false
    	
    	# # disable xtrafinder menu bar icon
    	#defaults write com.apple.finder XtraFinder_ShowStatusBarIcon -bool false
    	
    	
    	### right click finder plugins
    	
    	# show copy path
    	#defaults write com.apple.finder XtraFinder_XFCopyPathMenuPlugin -bool true
    	
    	# path type options
    	# 0 = path, 3 = hfs path, 4 = terminal path
    	defaults write com.apple.finder XtraFinder_XFCopyPathMenuPlugin_Default -integer 0
    	
    	# show make symbolic link
    	defaults write com.apple.finder XtraFinder_XFMakeSymbolicLinkActionPlugin -bool false
    	
    	# show open in new window
    	defaults write com.apple.finder XtraFinder_XFOpenInNewWindowPlugin -bool true
    	
    	# autostart
    	osascript -e 'tell application "System Events" to make login item at end with properties {name:"XtraFinder", path:"/Applications/XtraFinder.app", hidden:false}'
    	
    else
    	:
    fi

    	
else
    echo "not online, skipping installation..."
    #echo ''
fi

echo ''
echo "done ;)"
echo ''

###
### unsetting password
###

unset SUDOPASSWORD
