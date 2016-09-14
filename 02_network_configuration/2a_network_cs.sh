#!/bin/sh

# manpage
# https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/networksetup.8.html

# to reset all the network settings completely do
#sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.network.identification.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
#sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist
#sudo reboot

# a few commands
# networksetup -detectnewhardware
# networksetup -listallhardwareports
# networksetup -listallnetworkservices
# networksetup -listlocations

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# deleting all network locations
#echo please ignore error about missing preferences.plist file, it will be created automatically
sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist >/dev/null 2>&1

# creating new location automatic
echo adding location automatic
sudo networksetup -createlocation "Automatisch" populate >/dev/null 2>&1
sleep 3
sudo networksetup -switchtolocation "Automatisch"
echo ""
sleep 3

# creating new location office_lan
echo adding location office_lan
sudo networksetup -createlocation "office_lan"
sleep 3
sudo networksetup -switchtolocation "office_lan"
echo ""
sleep 3
sudo networksetup -createnetworkservice "Ethernet" "Ethernet"
sleep 3
sudo networksetup -setmanual "Ethernet" 172.16.1.2 255.255.255.0 172.16.1.1
sleep 3
sudo networksetup -setdnsservers "Ethernet" 172.16.1.1
sleep 3

# deleting created preferences backup file
sleep 3
sudo rm -rf /Library/Preferences/SystemConfiguration/preferences.plist.old >/dev/null 2>&1

# echo script finished
#echo ""
echo "all network locations created ;)"

# changing to automatic location
echo "changing to location automatic" 
sudo networksetup -switchtolocation "Automatisch"
echo ""
echo "done ;)" 
