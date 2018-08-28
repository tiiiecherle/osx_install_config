#!/usr/bin/env bash

###
### variables
###

MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)


###
### forcing smb3 connection
###

# forcing smb3 for every connection as user do

if [ -f "~/Library/Preferences/nsmb.conf" ]
then 
	:
	echo ""~/Library/Preferences/nsmb.conf" does not exist, will be created..."
else 
	echo ""~/Library/Preferences/nsmb.conf" exists will be deleted and recreated..."
	rm -f "~/Library/Preferences/nsmb.conf"
fi

if [ -f "/etc/nsmb.conf" ]
then 
	:
else 
	sudo rm -f "/etc/nsmb.conf"
fi

if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "12" ]]
then
    # macos versions until and including 10.12
    bash -c "cat > ~/Library/Preferences/nsmb.conf" <<'EOL'
[default]
smb_neg=smb3_only
signing_required=no
EOL

else
    # macos versions 10.13 and up
	bash -c "cat > ~/Library/Preferences/nsmb.conf" <<'EOL'
[default]
protocol_vers_map=4
signing_required=no
EOL

fi


### more options and default values
# man nsmb.conf


### allowing unkown servers
# keeps finder from asking an extra question about connecting
# you are trying to connect to server xyz, press connect to connect...
#sudo defaults write /Library/Preferences/com.apple.NetworkAuthorization AllowUnknownServers -bool true

# checking effects while connected to a share
#smbutil statshares -a 


### speed testing
# disconnect from share, logout from macos account and reconnect to smb share after changing nsmb.conf
# creating empty file
#mkfile 4769m /Users/$USER/Desktop/5gb_file1.img
# or
#dd if=/dev/zero of=/Users/$USER/Desktop/5gb_file.img count=5000000 bs=1000
#
#rsync --progress -a /Users/$USER/Desktop/5gb_file.img /Volumes/office/

# macos 10.14
# signing_required=yes 		max 29 MB/s			average 28 MB/s
# signing_required=no 		max 58 MB/s			average 54 MB/s


### restore default as user do
#rm ~/Library/Preferences/nsmb.conf


echo 'done ;)'