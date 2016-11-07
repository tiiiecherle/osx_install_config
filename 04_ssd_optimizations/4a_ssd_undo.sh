#!/bin/bash

###
### asking password upfront
###

# solution 1
# only working for sudo commands, not for commands that need a password and are run without sudo
# and only works for specified time
# asking for the administrator password upfront
#sudo -v
# keep-alive: update existing 'sudo' time stamp until script is finished
#while true; do sudo -n true; sleep 600; kill -0 "$$" || exit; done 2>/dev/null &

# solution 2
# working for all commands that require the password (use sudo -S for sudo commands)
# working until script is finished or exited

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
### ssd optimizations
###

read -p "Is your disk an ssd, otherwise it is not recommended to run this script (y/N)?" CONT_SSD
CONT_SSD="$(echo "$CONT_SSD" | tr '[:upper:]' '[:lower:]')"    # tolower
if [[ "$CONT_SSD" == "y" || "$CONT_SSD" == "yes" ]]
then
echo "continuing script..."

	###
	### SSD
	###
	
	echo "SSD"
	
	echo 'enabling deep sleep / hibernation...'
	
	# disable hibernation (speeds up entering sleep mode)
	#sudo pmset -a hibernatemode 0
	# enable hibernation
	sudo pmset -a hibernatemode 3
	
	# remove the sleep image file to save disk space
	# only do that with hibernation disabled
	sudo rm -rf /private/var/vm/sleepimage
	
	# create a zero-byte file instead
	#sudo touch /private/var/vm/sleepimage
	
	# and make sure it can be rewritten
	#sudo chflags uchg /private/var/vm/sleepimage
	
	# checking file size
	#du -h /private/var/vm/sleepimage
	
	# preventing going from sleep to deep sleep / hibernate
	# time for waiting from going to deep sleep (autopoweroffdelay) can be found with
	# pmset -g | grep autopower
	#sudo pmset -a autopoweroff 0
	# enable going from sleep to deep sleep / hibernate
	sudo pmset -a autopoweroff 1
	
	# disable the sudden motion sensor as it is not useful for SSDs
	# not included for my macbookpro 2012 in sierra
	# pmset -g | grep sms
	#echo "disabling sudden motion sensor..."
	#sudo pmset -a sms 0
	# enable the sudden motion sensor
	#sudo pmset -a sms 1
	
	# disable local time machine backup
	#echo "disabling local time machine backup..."
	# already done in system preferences script
	#sudo tmutil disablelocal
	
	### noatime
    echo "stopping and deleting noatime launchd..."
    sudo launchctl unload "/Library/LaunchDaemons/com.noatime.plist"
    sleep 5
    sudo rm "/Library/LaunchDaemons/com.noatime.plist"
    
    echo "waiting before checking if launchd is enabled..."
    sleep 10
    echo "checking if launchd service is enabled..."
    sudo launchctl list | grep com.noatime
    
    echo ''
    if [[ $(mount | grep " / " | grep noatime) == "" ]]
    then
    	echo "noatime is not enabled..."
    else
    	echo "noatime is enabled..."
    fi
    
    # undo changes
    # sudo launchctl unload "/Library/LaunchDaemons/com.noatime.plist"
    # sudo rm "/Library/LaunchDaemons/com.noatime.plist"
	
	echo "done"
	
	echo "a few changes need a reboot or logout to take effect"
    echo "initializing reboot"
    
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'        # reboot
    #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
    #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout

else
	echo "this script is only for ssds... exiting..."
fi



###
### unsetting password
###

unset SUDOPASSWORD