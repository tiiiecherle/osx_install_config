#!/bin/bash

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

### functions
# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}

ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}



###
### ssd optimizations
###

VARIABLE_TO_CHECK="$DISK_IS_SSD"
QUESTION_TO_ASK="Is your disk an ssd, otherwise it is not recommended to run this script (y/N)? "
ask_for_variable
DISK_IS_SSD="$VARIABLE_TO_CHECK"

if [[ "$DISK_IS_SSD" =~ ^(yes|y)$ ]]
then
echo "continuing script..."

	###
	### SSD
	###
	
	echo "SSD"
	
	echo 'disabling deep sleep / hibernation...'
	
	# disable hibernation (speeds up entering sleep mode)
	sudo pmset -a hibernatemode 0
	# enable hibernation
	#sudo pmset -a hibernatemode 3
	
	# remove the sleep image file to save disk space
	# only do that with hibernation disabled
	sudo rm -rf /private/var/vm/sleepimage
	
	# create a zero-byte file instead
	sudo touch /private/var/vm/sleepimage
	
	# and make sure it can be rewritten
	sudo chflags uchg /private/var/vm/sleepimage
	
	# checking file size
	du -h /private/var/vm/sleepimage
	
	# preventing going from sleep to deep sleep / hibernate
	# time for waiting from going to deep sleep (autopoweroffdelay) can be found with
	# pmset -g | grep autopower
	sudo pmset -a autopoweroff 0
	# enable going from sleep to deep sleep / hibernate
	#sudo pmset -a autopoweroff 1
	
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
    echo "creating noatime launchd..."
    
    if [ -e "/Library/LaunchDaemons/com.noatime.plist" ]
    then
    	sudo rm "/Library/LaunchDaemons/com.noatime.plist"
    else
    	:
    fi
    
    # closing EOL has to stay unindented
    sudo bash -c "cat >/Library/LaunchDaemons/com.noatime.plist" <<'EOL'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    <key>Label</key>
    <string>com.noatime</string>
    <key>ProgramArguments</key>
    <array>
    <string>mount</string>
    <string>-uwo</string>
    <string>noatime</string>
    <string>/</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    </dict>
    </plist>
EOL
    
    sudo chown root:wheel "/Library/LaunchDaemons/com.noatime.plist"
    sudo chmod 644 "/Library/LaunchDaemons/com.noatime.plist"
    
    #ls -la /Library/LaunchDaemons/ | grep noatime.plist
    #open /Library/LaunchDaemons/com.noatime.plist
    
    # launchd service
    echo ""
    echo "enabling launchd service..."
    if [[ $(sudo launchctl list | grep com.noatime) != "" ]];
    then
        sudo launchctl unload "/Library/LaunchDaemons/com.noatime.plist"
    else
        :
    fi
    sudo launchctl load "/Library/LaunchDaemons/com.noatime.plist"
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
    
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
    #osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
    #osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout

else
	echo "this script is for ssds only... exiting..."
fi



###
### unsetting password
###

unset SUDOPASSWORD