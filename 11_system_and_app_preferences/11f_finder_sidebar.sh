#!/usr/bin/env bash

# sfltool
# sfltool restore|add-item|save-lists|test|archive|enable-modern|dump-server-state|clear|disable-modern|dump-storage|list-info [options]

# mysides
# installs to /usr/local/bin/mysides
# -rwxr-xr-x    1 root  wheel  47724 14 Apr 02:07 mysides
# https://github.com/mosen/mysides
MYSIDESVERSION="1.0.1"
read -r -p "do you want to install / update to mysides "$MYSIDESVERSION"? [y/N] " answer
response="$(echo "$answer" | tr '[:upper:]' '[:lower:]')"    # tolower
#echo $response
# >= bash 4
#if [[ $response =~ ^(yes|y|"")$ ]]
# >= bash 3.2
#if [[ $response =~ ^([yes]|[y]|[""])$ ]]
#
#if [[ $response == "y" || $response == "yes" || $response == "" ]]
if [[ $response == "y" || $response == "yes" ]]
then
	echo "downloading and installing mysides..."
	MYSIDESINSTALLER="/Users/$USER/Desktop/mysides-"$MYSIDESVERSION".pkg"
	wget https://github.com/mosen/mysides/releases/download/v1.0.0/mysides-1.0.0.pkg -O "$MYSIDESINSTALLER"
	open "$MYSIDESINSTALLER"
	echo "waiting for installer to finish..."
	while ps aux | grep 'Installer.app.*Installer' | grep -v grep > /dev/null; do sleep 1; done
	echo "removing installer file..."
	if [ -e "$MYSIDESINSTALLER" ]; then rm "$MYSIDESINSTALLER"; else :; fi
	echo "continuing setting finder sidebar entries..."
	sleep 2
else
    :
fi

echo ''
echo "clearing and setting finder sidebare items..."

# clearing out settings and removes icloud
#sfltool clear
# if everything is cleared with this command, block three (device, external drives, cds, dvds and ipods) would need a second reboot and applying settings again to work after first reboot
#sleep 5

# currently only working with latest git version, not with 1.0.0
# disable sip
# copy build file to /usr/local/bin/mysides
# sudo chown root:wheel "/usr/local/bin/mysides"
# sudo chmod 755 "/usr/local/bin/mysides"
#mysides remove all
#
#mysides remove "Alle meine Dateien"
mysides remove myDocuments.cannedSearch
mysides remove iCloud
mysides add domain-AirDrop nwnode://domain-AirDrop
mysides remove domain-AirDrop
mysides add Applications file:///Applications
mysides add Desktop file:///Users/${USER}/Desktop
mysides add Documents file:///Users/${USER}/Documents
mysides add Downloads file:///Users/${USER}/Downloads
mysides add Movies file:///Users/${USER}/Movies
mysides add Music file:///Users/${USER}/Music
mysides add Pictures file:///Users/${USER}/Pictures
mysides add ${USER} file:///Users/${USER}
if [[ $USER == tom ]]
then
	mysides add files file:///Users/${USER}/Desktop/files
	# or
	#/usr/bin/sfltool add-item com.apple.LSSharedFileList.FavoriteItems file:///Users/$USER/Desktop/files && sleep 2
else
	:
fi	
if [[ $USER == wolfgang ]]
then
	echo ''
	read -r -p $'to add entries form a network volume you have to be connected to the volume as the user that uses the links later.\nplease connect to /Volumes/office/ as the respective user.\nare you connected to /Volumes/office/ as the user that uses the links later? [Y/n] ' answer
	response="$(echo "$answer" | tr '[:upper:]' '[:lower:]')"    # tolower
	if [[ $response == "y" || $response == "yes" || $response == "" ]]
	then
		mysides add Aufträge file:///Volumes/office/documents/gep/material/VIII%20Auftra%CC%88ge/
		mysides add Scans file:///Volumes/office/documents/_scan
		mysides add Tabellen file:///Volumes/office/documents/mfs/allg/_tabellen
		mysides add Solarplan file:///Volumes/office/documents/mfs/solarplan
		mysides add Projektordner file:///Volumes/office/documents/mfs/projektordner
		mysides add Überwacchung file:///Volumes/office/documents/mfs/projektordner/ueberwachung
		echo ''
	else
		echo ''
	fi
else
	:
fi	

#touch ~/Library/Preferences/com.apple.sidebarlists.plist

###


# access to my mac
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.backToMyMacEnabled" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.backToMyMacEnabled bool false" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	/usr/libexec/PlistBuddy -c "Delete :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.backToMyMacEnabled" ~/Library/Preferences/com.apple.sidebarlists.plist
	/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.backToMyMacEnabled bool false" ~/Library/Preferences/com.apple.sidebarlists.plist
fi

# connected servers
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.connectedEnabled" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.connectedEnabled bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	/usr/libexec/PlistBuddy -c "Delete :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.connectedEnabled" ~/Library/Preferences/com.apple.sidebarlists.plist
	/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.connectedEnabled bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
fi

# bonjour computers
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.bonjourEnabled" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.bonjourEnabled bool false" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	/usr/libexec/PlistBuddy -c "Delete :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.bonjourEnabled" ~/Library/Preferences/com.apple.sidebarlists.plist
	/usr/libexec/PlistBuddy -c "Add :networkbrowser:CustomListProperties:com.apple.NetworkBrowser.bonjourEnabled bool false" ~/Library/Preferences/com.apple.sidebarlists.plist
fi

###

# device enable
#if [[ -z $(/usr/libexec/PlistBuddy -c "Print :systemitems:VolumesList:0:Flags" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
#then
#	/usr/libexec/PlistBuddy -c "Add :systemitems:VolumesList:0:Flags integer 1" ~/Library/Preferences/com.apple.sidebarlists.plist
#else
#	:
#fi

# device disable
if [[ ! -z $(/usr/libexec/PlistBuddy -c "Print :systemitems:VolumesList:0:Flags" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Delete :systemitems:VolumesList:0:Flags" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	:
fi

# hard disks
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :systemitems:ShowHardDisks" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Add :systemitems:ShowHardDisks bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	/usr/libexec/PlistBuddy -c "Delete :systemitems:ShowHardDisks" ~/Library/Preferences/com.apple.sidebarlists.plist
	/usr/libexec/PlistBuddy -c "Add :systemitems:ShowHardDisks bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
fi
# when all harddisks should be shown the following is needed, comment out when setting hard disks false
for VOLUMENAME in macintosh_hd2 macintosh_hd
do 
	for i in 0 1 2 3 4 5
	do
		if [[ $(/usr/libexec/PlistBuddy -c "Print :systemitems:VolumesList:$i:Name" ~/Library/Preferences/com.apple.sidebarlists.plist) == "$VOLUMENAME" ]] >/dev/null 2>&1
		then
			if [[ $(/usr/libexec/PlistBuddy -c "Print :systemitems:VolumesList:$i:Visibility" ~/Library/Preferences/com.apple.sidebarlists.plist) != "" ]] >/dev/null 2>&1
			then
				#echo "yes"
				#echo "$i"
				/usr/libexec/PlistBuddy -c "Delete :systemitems:VolumesList:$i:Visibility" ~/Library/Preferences/com.apple.sidebarlists.plist
			else
				#echo "no"
				:
			fi
		else
			#echo "no"
			:
		fi
	done
done

# external drives
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :systemitems:ShowRemovable" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Add :systemitems:ShowRemovable bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	/usr/libexec/PlistBuddy -c "Delete :systemitems:ShowRemovable" ~/Library/Preferences/com.apple.sidebarlists.plist
	/usr/libexec/PlistBuddy -c "Add :systemitems:ShowRemovable bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
fi

# removables
if [[ -z $(/usr/libexec/PlistBuddy -c "Print :systemitems:ShowEjectables" ~/Library/Preferences/com.apple.sidebarlists.plist) ]] > /dev/null 2>&1
then
	/usr/libexec/PlistBuddy -c "Add :systemitems:ShowEjectables bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
else
	/usr/libexec/PlistBuddy -c "Delete :systemitems:ShowEjectables" ~/Library/Preferences/com.apple.sidebarlists.plist
	/usr/libexec/PlistBuddy -c "Add :systemitems:ShowEjectables bool true" ~/Library/Preferences/com.apple.sidebarlists.plist
fi

# do not show cds, dvds, but keep showing dmgs (removables have to be enabled)
NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print systemitems:VolumesList" ~/Library/Preferences/com.apple.sidebarlists.plist | awk '/^[[:blank:]]*Dict {/' | wc -l)
#echo $NUMBER_OF_ENTRIES
# -1 because counting of items starts with 0, not with 1
LISTED_ENTRIES=$(($NUMBER_OF_ENTRIES-1))
#echo $LISTED_ENTRIES
for i in $(seq 0 $LISTED_ENTRIES)
do 
    if [[ $(/usr/libexec/PlistBuddy -c "Print systemitems:VolumesList:$i" ~/Library/Preferences/com.apple.sidebarlists.plist | grep "Remote Disc") != "" ]]
    then
        #echo $i
        NEEDED_ENTRY=$i
    else
        :
        #echo $i
    fi
done
if [[ $NEEDED_ENTRY != "" ]]
then
    /usr/libexec/PlistBuddy -c "Add systemitems:VolumesList:$NEEDED_ENTRY:Visibility string NeverVisible" ~/Library/Preferences/com.apple.sidebarlists.plist
else
    :
fi

# show tags
defaults write com.apple.finder ShowRecentTags -bool false

# restart finder
#killall Finder

echo "done ;)"
echo "the changes need a reboot to take effect..."
#echo "initializing reboot"
echo ""

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout