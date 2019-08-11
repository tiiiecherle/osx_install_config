#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

env_enter_sudo_password



###
### configuring network
###

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

# ask if thunderbolt bridge on macbook pro is already created, if not stop script
# preferences - network - preferences - virtual devices - add bridge - Thunderbolt-Bridge as bridge0
#       activate thunderbolt 1 (en1) & thunderbolt 2 (en2) & thunderbolt ethernet (en5)
#       deactivate WLAN

#read -p "Is the Thunderbolt-Ethernet adapter connected (y/n)?" CONT
#if [ "$CONT" == "y" ]
#then
#echo "continuing script..."

# creating and switching to _temp network location, not necessary when deleting preferences.plist
#echo creating and switching to _temp network location
#sudo networksetup -createlocation _temp
#sleep 3
#sudo networksetup -switchtolocation _temp
#sleep 3

# deleting all locations except _temp, not necessary when deleting preferences.plist
#NETWORKLOCATIONS=$(networksetup -listlocations | grep -Ev '_temp')
#for item in ${NETWORKLOCATIONS//\\n/}; do
#echo deleting location $item
#sudo networksetup -deletelocation $item
#done

# name of ethernet device
# networksetup -listallhardwareports
ETHERNET_DEVICE="Thunderbolt Ethernet"

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

# creating new location tom_wlan
echo adding location tom_wlan
sudo networksetup -createlocation "tom_wlan"
sleep 3
sudo networksetup -switchtolocation "tom_wlan"
echo ""
sleep 3
sudo networksetup -createnetworkservice "WLAN" Wi-Fi
#sudo networksetup -createnetworkservice WLAN en0
sleep 3
sudo networksetup -setmanual "WLAN" 172.16.2.2 255.255.255.0 172.16.2.1
sleep 3
sudo networksetup -setdnsservers "WLAN" 172.16.2.1
sleep 3


# creating new location office_lan
echo adding location office_lan
sudo networksetup -createlocation "office_lan"
sleep 3
sudo networksetup -switchtolocation "office_lan"
echo ""
sleep 3
sudo networksetup -createnetworkservice "$ETHERNET_DEVICE" "$ETHERNET_DEVICE"
#sudo networksetup -createnetworkservice Thunderbolt-Bridge bridge0
sleep 3
sudo networksetup -setmanual "$ETHERNET_DEVICE" 172.16.1.4 255.255.255.0 172.16.1.1
sleep 3
sudo networksetup -setdnsservers "$ETHERNET_DEVICE" 172.16.1.1
sleep 3

# creating new location mozart_wlan
echo adding location mozart_wlan
sudo networksetup -createlocation "mozart_wlan"
sleep 3
sudo networksetup -switchtolocation "mozart_wlan"
echo ""
sleep 3
sudo networksetup -createnetworkservice "WLAN" Wi-Fi
#sudo networksetup -createnetworkservice WLAN en0
sleep 3
sudo networksetup -setmanual "WLAN" 192.168.1.202 255.255.255.0 192.168.1.1
sleep 3
sudo networksetup -setdnsservers "WLAN" 192.168.1.1
sleep 3

# creating new location berente_wlan
#echo adding location berente_wlan
#sudo networksetup -createlocation "berente_wlan"
#sleep 3
#sudo networksetup -switchtolocation "berente_wlan"
#echo ""
#sleep 3
#sudo networksetup -createnetworkservice "WLAN" Wi-Fi
#sleep 3
#sudo networksetup -setmanual "WLAN" 192.168.2.202 255.255.255.0 192.168.2.1
#sleep 3
#sudo networksetup -setdnsservers "WLAN" 192.168.2.1
#sleep 3

# deleting _temp network location, not necessary when deleting preferences.plist
#echo deleting _temp network location
#sudo networksetup -deletelocation _temp
#sleep 3

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

#else
#echo "please connect your Thunderbolt-Ethernet adapter before running the script... exiting..."
#fi



###
### unsetting password
###

unset SUDOPASSWORD
