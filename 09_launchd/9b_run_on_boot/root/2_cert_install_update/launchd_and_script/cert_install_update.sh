#!/bin/bash

if [ $(id -u) -ne 0 ]
then 
    echo script is not run as root, exiting...
    exit
else

EXECTIME=$(date '+%Y-%m-%d %T')
LOGFILE=/var/log/cert_update.log

if [ -f $LOGFILE ]
then
    # only macos takes care of creation time, linux doesn`t because it is not part of POSIX
    LOGFILEAGEINSECONDS="$(( $(date +"%s") - $(stat -f "%B" $LOGFILE) ))"
    MAXLOGFILEAGE=$(echo "30*24*60*60" | bc)
    #echo $LOGFILEAGEINSECONDS
    #echo $MAXLOGFILEAGE
    # deleting logfile after 30 days
    if [ "$LOGFILEAGEINSECONDS" -lt "$MAXLOGFILEAGE" ];
    then
        echo "logfile not older than 30 days..."
    else
        # deleting logfile
        echo "deleting logfile..."
        sudo rm $LOGFILE
        sudo touch $LOGFILE
        sudo chmod 644 $LOGFILE
        #sudo chmod 666 $LOGFILE
    fi
else
    sudo touch $LOGFILE
    sudo chmod 644 $LOGFILE
    #sudo chmod 666 $LOGFILE
fi

sudo echo "" >> $LOGFILE
sudo echo $EXECTIME >> $LOGFILE


# do NOT add to "/Users/$USER/Library/Keychains/login.keychain"
# does not work
# use "/System/Library/Keychains/SystemRootCertificates.keychain"

KEYCHAIN="/System/Library/Keychains/SystemRootCertificates.keychain"
CERTIFICATE_NAME="FILL_IN_NAME_HERE"
SERVER_IP="FILL_IN_IP_HERE"

if [[ $(echo "$CERTIFICATE_NAME" | grep "^FILL_IN_*") != "" ]] || [[ $(echo "$CERTIFICATE_NAME" | grep "^FILL_IN_*") != "" ]]
then
    echo "at least one variable not set correctly, exiting..."
    exit
else
    :
fi

install_update_certificate() {

    # deleting old installed certificate
    if [[ $(security find-certificate -a -c "$CERTIFICATE_NAME" "$KEYCHAIN") != "" ]]
    then
        #CERT_SHA1=$(security find-certificate -c "$CERTIFICATE_NAME" -a -Z "$KEYCHAIN" | awk '/SHA-1/{print $NF}')
        #sudo security delete-certificate -Z "$CERT_SHA1" "$KEYCHAIN"
        sudo security delete-certificate -c "$CERTIFICATE_NAME" "$KEYCHAIN"
    else
        :
    fi
    
    # downloading new certificate
    if [[ -e /tmp/"$CERTIFICATE_NAME".crt ]]
    then
        rm -f /tmp/"$CERTIFICATE_NAME".crt
    else
        :
    fi
    #echo quit | openssl s_client -showcerts -servername "$SERVER_IP" -connect "$SERVER_IP":443 2>/dev/null > /tmp/"$CERTIFICATE_NAME".crt
    echo quit | openssl s_client -showcerts -connect "$SERVER_IP":443 2>/dev/null > /tmp/"$CERTIFICATE_NAME".crt

    # add certificate to keychain and trust all
    #sudo security add-trusted-cert -d -r trustAsRoot -k "$KEYCHAIN" "/Users/$USER/Desktop/cacert.pem"

    # add certificate to keychain and no value set
    #sudo security add-trusted-cert -r trustAsRoot -k "$KEYCHAIN" "/Users/$USER/Desktop/cacert.pem"
    
    # add certificate to keychain and trust ssl
    sudo security add-trusted-cert -d -r trustAsRoot -p ssl -e hostnameMismatch -k "$KEYCHAIN" /tmp/"$CERTIFICATE_NAME".crt
    
    # checking that certificate is installed, not untrusted and matches the domain
    # exporting certificate
    security find-certificate -a -p -c "$CERTIFICATE_NAME" "$KEYCHAIN" > /tmp/local_"$CERTIFICATE_NAME".pem
    if [[ $(security verify-cert -r /tmp/local_"$CERTIFICATE_NAME".pem -p ssl -s "$CERTIFICATE_NAME" | grep "successful") != "" ]]
    then
        echo "the certificate is installed, trusted and working..."
    else
        echo "there seems to be a problem with the installation of the certificate..."
    fi

}

check_weekday() {
    # checking if it is needed to check the certificates by weekday
    if [[ "$(LANG=en_US date +%A)" != "Thursday" ]]
    then
        echo "it's not thursday, no need to check certificates..."
        echo "exiting script..."
        exit
    else
        :
    fi
}

cert_check() {

    #check_weekday
    
    ### getting logged in user
    #echo "LOGNAME is $(logname)..."
    #/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
    #stat -f%Su /dev/console
    #defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
    # recommended way
    loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    NUM=0
    MAX_NUM=15
    SLEEP_TIME=3
    # waiting for loggedInUser to be available
    while [[ "$loggedInUser" == "" ]] && [[ "$NUM" -lt "$MAX_NUM" ]]
    do
        sleep "$SLEEP_TIME"
        NUM=$(($NUM+1))
        loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
    done
    #echo ''
    #echo "NUM is $NUM..."
    echo "loggedInUser is $loggedInUser..."
    if [[ "$loggedInUser" == "" ]]
    then
        WAIT_TIME=$(($MAX_NUM*$SLEEP_TIME))
        echo "loggedInUser could not be set within "$WAIT_TIME"s, exiting..."
        exit
    else
        :
    fi
      
    # sourcing .bash_profile or setting PATH
    # as the script is run as root from a launchd it would not detect the brew command and would fail checking if brew is installed
    #export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
    if [[ -e /Users/$loggedInUser/.bash_profile ]]
    then
        . /Users/$loggedInUser/.bash_profile
    else
        :
    fi
    
    # checking homebrew and script dependencies
    if [[ $(sudo -u $loggedInUser command -v brew) == "" ]]
    then
        echo homebrew is not installed, exiting...
        exit
    else
        echo homebrew is installed...
        # checking for missing dependencies
        for formula in openssl
        #for formula in 123
        do
        	if [[ $(sudo -u "$loggedInUser" brew list | grep "$formula") == '' ]]
        	then
        		#echo """$formula"" is NOT installed..."
        		MISSING_SCRIPT_DEPENDENCY="yes"
        		osascript -e 'tell app "System Events" to display dialog "the script cert_install_update.sh needs '$formula' to be installed via homebrew..."'
        	else
        		#echo """$formula"" is installed..."
        		:
        	fi
        done
        if [[ "$MISSING_SCRIPT_DEPENDENCY" == "yes" ]]
        then
            echo at least one needed homebrew tool is missing, exiting...
            exit
        else
            echo needed homebrew tools are installed...     
        fi
        unset MISSING_SCRIPT_DEPENDENCY
    fi
    
    # giving the network some time
    ping -c5 "$SERVER_IP" >/dev/null 2>&1
    if [ "$?" = 0 ]
    then
        :
    else
        echo "server not found, waiting 60s for next try..."
        sleep 60
    fi
 
    # checking if online
    ping -c5 "$SERVER_IP" >/dev/null 2>&1
    if [ "$?" = 0 ]
    then
        echo "server found, checking certificates..."
        
        # server cert in pem format
        if [[ -e /tmp/server_"$CERTIFICATE_NAME".pem ]]
        then
            rm -f /tmp/server_"$CERTIFICATE_NAME".pem
        else
            :
        fi
        SERVER_CERT_PEM=$(echo quit | openssl s_client -connect "$SERVER_IP":443 2>/dev/null | openssl x509)
        #echo quit | openssl s_client -connect "$SERVER_IP":443 2>/dev/null | openssl x509 > /tmp/server_"$CERTIFICATE_NAME".pem
        #SERVER_CERT_PEM=$(cat /tmp/server_"$CERTIFICATE_NAME".pem)
        # or
        #true | openssl s_client -connect services.greenenergypeak.de:443 2>/dev/null | openssl x509
        
        # checking if certificate is installed
        if [[ $(security find-certificate -a -c "$CERTIFICATE_NAME" "$KEYCHAIN") == "" ]]
        then
            echo "certificate $CERTIFICATE_NAME not found, installing..."
            install_update_certificate
        else
            :
        fi
        
        # local cert in pem format
        if [[ -e /tmp/local_"$CERTIFICATE_NAME".pem ]]
        then
            rm -f /tmp/local_"$CERTIFICATE_NAME".pem
        else
            :
        fi
        LOCAL_CERT_PEM=$(security find-certificate -a -p -c "$CERTIFICATE_NAME" "$KEYCHAIN")
        #security find-certificate -a -p -c "$CERTIFICATE_NAME" "$KEYCHAIN" > /tmp/local_"$CERTIFICATE_NAME".pem
        #LOCAL_CERT_PEM=$(cat /tmp/local_"$CERTIFICATE_NAME".pem)

        # checking if update needed
        if [[ "$SERVER_CERT_PEM" == "$LOCAL_CERT_PEM" ]]
        then
            echo "server certificate matches local certificate, no need to update..."
        else
            echo "server certificate does not match local certificate, updating..."
            install_update_certificate
        fi
        
        # cleaning up
        if [[ -e /tmp/"$CERTIFICATE_NAME".crt ]]
        then
            rm -f /tmp/"$CERTIFICATE_NAME".crt
        else
            :
        fi
        if [[ -e /tmp/server_"$CERTIFICATE_NAME".pem ]]
        then
            rm -f /tmp/server_"$CERTIFICATE_NAME".pem
        else
            :
        fi
        if [[ -e /tmp/local_"$CERTIFICATE_NAME".pem ]]
        then
            rm -f /tmp/local_"$CERTIFICATE_NAME".pem
        else
            :
        fi        
        
    else
        echo "server not found, exiting script..."
        exit
    fi
    
}

(time cert_check) 2>&1 | tee -a $LOGFILE

#sudo chmod 644 $LOGFILE
#sudo chmod 666 $LOGFILE

#(time cert_check) 2>&1 | sudo tee -a $LOGFILE
# does not work, so the whole script has to be run as root or the privileges of the logfile have to be changed before and after running the script

fi
