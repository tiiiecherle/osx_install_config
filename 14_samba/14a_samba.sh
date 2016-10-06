#!/usr/bin/env bash

###
### forcing smb3 connection
###

# forcing smb3 for every connection as user do

if [ -f "~/Library/Preferences/nsmb.conf" ]
then 
	echo ""~/Library/Preferences/nsmb.conf" does not exist, will be created..."
else 
	echo ""~/Library/Preferences/nsmb.conf" exists will be deleted and recreated..."
	rm -f ~/Library/Preferences/nsmb.conf
fi

echo "[default]" >> ~/Library/Preferences/nsmb.conf; echo "smb_neg=smb3_only" >> ~/Library/Preferences/nsmb.conf

# restore default as user do
#rm ~/Library/Preferences/nsmb.conf

echo 'done ;)'