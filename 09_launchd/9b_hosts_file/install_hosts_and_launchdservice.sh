#!/bin/bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 300; kill -0 "$$" || exit; done 2>/dev/null &

# script directory
SCRIPTDIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")
#echo $SCRIPTDIR

# uninstalling possible old files
echo "uninstalling possible old files..."
sudo $SCRIPTDIR/launchd_and_script/uninstall_hosts_and_launchdservice.sh
sudo wait

# hosts install / update file
echo "installing hosts update script..."
sudo mkdir -p /Library/Scripts/custom/
sudo cp $SCRIPTDIR/launchd_and_script/hosts_file_generator.sh /Library/Scripts/custom/hosts_file_generator.sh
sudo chown -R root:wheel /Library/Scripts/custom/
sudo chmod -R 755 /Library/Scripts/custom/

# launcd service file
echo "installing launchd service..."
sudo cp $SCRIPTDIR/launchd_and_script/com.hostsfile.install_update.plist /Library/LaunchDaemons/com.hostsfile.install_update.plist
sudo chown root:wheel /Library/LaunchDaemons/com.hostsfile.install_update.plist
sudo chmod 644 /Library/LaunchDaemons/com.hostsfile.install_update.plist

# forcing later script update by setting last modification time of /etc/hosts earlier
sudo touch -mt 201512010000 /etc/hosts

# run installation
sudo /Library/Scripts/custom/hosts_file_generator.sh

# launchd service
echo ""
echo "enabling launchd service..."
if [[ $(sudo launchctl list | grep hostsfile.install_update) != "" ]];
then
    sudo launchctl unload /Library/LaunchDaemons/com.hostsfile.install_update.plist
else
    :
fi
sudo launchctl load /Library/LaunchDaemons/com.hostsfile.install_update.plist
echo "checking if launchd service is enabled..."
sudo launchctl list | grep hostsfile.install_update
#echo ""
#echo "waiting 60s for updating in background..."
#sleep 60
#ls -la /etc/hosts

# hosts filesize
#du -h /etc/hosts

echo "opening /etc/hosts and logfile..."
#nano /etc/hosts
open /etc/hosts
#nano /var/log/hosts_file_update.log
open /var/log/hosts_file_update.log
