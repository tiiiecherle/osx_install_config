#!/bin/bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 300; kill -0 "$$" || exit; done 2>/dev/null &

EXECTIME=$(date '+%Y-%m-%d %T')
LOGFILE=/var/log/hosts_file_update.log

function hosts_file {

# checking if online
ping -c5 google.com 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]
then
    echo "we are online..."
    echo "updating hosts file..."

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
            sudo git fetch --all
            sudo git reset --hard origin/master
            sudo git pull origin master
            cd -
        else
            :
        fi
    else
        # installing
        echo "downloading hosts file generator..."
        if [ -d /Applications/hosts_file_generator/ ];
        then
            rm -rf /Applications/hosts_file_generator/
            mkdir -p /Applications/hosts_file_generator/
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
    #sudo python updateHostsFile.py -a -r -o alternates/gambling-porn-social -e gambling porn social
    sudo python updateHostsFile.py -a -r -o alternates/gambling-porn -e gambling porn
    #sudo python updateHostsFile.py -a -n -r -o alternates/gambling-porn-social -e gambling porn social
    sudo python updateReadme.py
    cd -

    # comment out lines
    # sport1 videos
    sudo sed -i '' '/cdn-static.liverail.com/s/^/#/g' /etc/hosts
    #or
    #sudo awk -i inplace '/cdn-static.liverail.com/ {$0="#"$0}1' /etc/hosts

    # activating hosts file
    echo "activating hosts file..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder

else
    echo "we are not not online, skipping update of hosts file... exiting script..."
fi

}

sudo chmod 666 $LOGFILE
sudo echo "" >> $LOGFILE
sudo echo $EXECTIME >> $LOGFILE
sudo chmod 644 $LOGFILE

time hosts_file 2>&1 | sudo tee -a $LOGFILE
