#!/bin/bash

EXECTIME=$(date '+%Y-%m-%d %T')
LOGFILE=/var/log/hosts_file_update.log

# deleting logfile after 30 days
if [ "$(sudo find /var/log/* -name 'hosts_file_update.log' -type f -maxdepth 0 -mtime +30d | grep -x '/var/log/hosts_file_update.log')" == "" ]
then
    :
else
    # deleting logfile
    echo "deleting logfile..."
    sudo rm $LOGFILE
    touch $LOGFILE
fi

function hosts_file {

# checking modification date of /etc/hosts
if [ "$(find /etc/* -name 'hosts' -type f -maxdepth 0 -mtime +7d | grep -x '/etc/hosts')" == "" ]
then
    echo "/etc/hosts was already updated in the last 7 days, no need to update..."
    echo "exiting script..."
    exit
else
    echo "/etc/hosts is older than 7 days, updating..."
fi

# checking if online
ping -c5 google.com 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]
then
    echo "we are online... updating hosts file..."

    # creating installation directory
    mkdir -p /Applications/hosts_file_generator/

    # downloading / updating hosts file creator from git repository
    if [ -d /Applications/hosts_file_generator/.git ];
    then
        # updating
        echo "updating hosts file generator..."
        if [ -d /Applications/hosts_file_generator/ ];
        then
            cd /Applications/hosts_file_generator/
            git pull origin master
            cd -
        else
            :
        fi
    else
        # installing
        echo "downloading hosts file generator..."
        if [ -d /Applications/hosts_file_generator/ ];
        then
            rm -rf /Applications/hosts_file_generator/.*
            git clone https://github.com/StevenBlack/hosts.git /Applications/hosts_file_generator/
        else
            :
        fi
    fi

    # backing up original hosts file
    if [ ! -f /etc/hosts.orig ];
    then
        echo "backing up original hosts file..."
        sudo cp -a /etc/hosts /etc/hosts.orig
    else
        :
    fi

    # updating / creating hostsfile
    echo "updating hosts file..."
    cd /Applications/hosts_file_generator/
    sudo python updateHostsFile.py -a -r -o alternates/gambling-porn-social -e gambling porn social
    #sudo python updateHostsFile.py -a -n -r -o alternates/gambling-porn-social -e gambling porn social
    python updateReadme.py
    cd -

    # activating hosts file
    echo "activating hosts file..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder

else
    echo "we are not not online, skipping update of hosts file... exiting script..."
fi
}

echo "" >> $LOGFILE
echo $EXECTIME >> $LOGFILE
time hosts_file 2>&1 | tee -a $LOGFILE
