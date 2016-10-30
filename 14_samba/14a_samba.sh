#!/usr/bin/env bash

###
### forcing smb3 connection
###

# forcing smb3 for every connection as user do

if [ -f "~/Library/Preferences/nsmb.conf" ]
then 
	:
	#echo ""~/Library/Preferences/nsmb.conf" does not exist, will be created..."
else 
	#echo ""~/Library/Preferences/nsmb.conf" exists will be deleted and recreated..."
	rm -f ~/Library/Preferences/nsmb.conf
fi

if [ -f "/etc/nsmb.conf" ]
then 
	:
else 
	sudo rm -f /etc/nsmb.conf
fi

### el captian or earlier
# closing EOL has to stay unindented
#bash -c "cat > ~/Library/Preferences/nsmb.conf" <<'EOL'
#[default]
#smb_neg=smb3_only
#signing_required=no
#EOL

### sierra
bash -c "cat > ~/Library/Preferences/nsmb.conf" <<'EOL'
[default]
protocol_vers_map=4
signing_required=no
EOL

# more options see
# man nsmb.conf

# checking effects while connected to a share
#smbutil statshares -a 

# restore default as user do
#rm ~/Library/Preferences/nsmb.conf

echo 'done ;)'