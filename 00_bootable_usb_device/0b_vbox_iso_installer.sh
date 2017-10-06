#!/bin/bash

# format usb drive with guid partition table
# format partition with OS X Extended (Journaled) and name it "Untitled" and leave it mounted
# download installer to some directory and put the POSIX path in the variable
# adjust installer path and name and run the following command in terminal and enter admin password

#INSTALLERPATH="/Applications/Install macOS 10.13 Beta.app"#
INSTALLERPATH="/Applications/Install macOS High Sierra.app"
VOLUMEPATH="/Volumes/Untitled"

hdiutil attach "$INSTALLERPATH"/Contents/SharedSupport/InstallESD.dmg -noverify -mountpoint /Volumes/highsierra
hdiutil create -o /tmp/HighSierraBase.cdr -size 7316m -layout SPUD -fs HFS+J
hdiutil attach /tmp/HighSierraBase.cdr.dmg -noverify -mountpoint /Volumes/install_build
asr restore -source "$INSTALLERPATH"/Contents/SharedSupport/BaseSystem.dmg -target /Volumes/install_build -noprompt -noverify -erase
rm /Volumes/OS\ X\ Base\ System/System/Installation/Packages
cp -R /Volumes/highsierra/Packages /Volumes/OS\ X\ Base\ System/System/Installation
hdiutil detach /Volumes/OS\ X\ Base\ System/
hdiutil detach /Volumes/highsierra/
mv /tmp/HighSierraBase.cdr.dmg /tmp/BaseSystem.dmg

# Restore the 10.13 Installer's BaseSystem.dmg into file system and place custom BaseSystem.dmg into the root
hdiutil create -o /tmp/HighSierra.cdr -size 8965m -layout SPUD -fs HFS+J
hdiutil attach /tmp/HighSierra.cdr.dmg -noverify -mountpoint /Volumes/install_build
asr restore -source "$INSTALLERPATH"/Contents/SharedSupport/BaseSystem.dmg -target /Volumes/install_build -noprompt -noverify -erase
cp /tmp/BaseSystem.dmg /Volumes/OS\ X\ Base\ System

hdiutil detach /Volumes/OS\ X\ Base\ System/
rm /tmp/BaseSystem.dmg

hdiutil convert /tmp/HighSierra.cdr.dmg -format UDTO -o /tmp/HighSierra.iso
mv /tmp/HighSierra.iso.cdr ~/Desktop/HighSierra.iso
rm /tmp/HighSierra.cdr.dmg

#
VBOX_NAME=macos_high_sierra
VBoxManage modifyvm "$VBOX_NAME" --cpuidset 00000001 000106e5 00100800 0098e3fd bfebfbff
VBoxManage setextradata "$VBOX_NAME" "VBoxInternalDevicesefi0Config DmiSystemProduct" "iMac11,3"
VBoxManage setextradata "$VBOX_NAME" "VBoxInternalDevicesefi/0Confi gDmiSystemVersion" "1.0"
VBoxManage setextradata "$VBOX_NAME" "VBoxInternalDevicesefi/0Confi gDmiBoardProduct" "Iloveapple"
VBoxManage setextradata "$VBOX_NAME" "VBoxInternalDevicessmc/0Confi gDeviceKey" " ourhardworkbythesewordsguarded pleasedontsteal(c) AppleComputerInc"
VBoxManage setextradata "$VBOX_NAME" "VBoxInternalDevicessmc/0Confi g/GetKeyFromRealSMC" 1