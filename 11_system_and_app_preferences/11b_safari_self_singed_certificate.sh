#!/bin/bash

### safari extensions
# as apple changed the format of extensions for 10.14 and up it is no longer necessary to restore the "*.safariextz" files
# "/$HOMEFOLDER/Library/Safari/Extensions/Extensions.plist"
# "/$HOMEFOLDER/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.Extensions.plist"
# are restored by the restore script if they were present at backup

### accepting self signed sever certificate
# opening safari again to accept self signed certificate for syncing calendar, contacts and reminders on local network via https
echo ''
echo "please accept self-signed certificate by showing details, opening the webiste and entering the password..."
open -a /Applications/Safari.app https://172.16.1.200	
echo "safari has to be quit before continuing..."
while ps aux | grep 'Safari.app' | grep -v grep > /dev/null; do sleep 1; done

echo 'done ;)'