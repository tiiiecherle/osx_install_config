#!/bin/bash

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")

BREW_CASKS_UPDATE_APP="brew_casks_update"

if [ -e /Applications/"$BREW_CASKS_UPDATE_APP".app ]
then
	rm -rf /Applications/"$BREW_CASKS_UPDATE_APP".app
else
	:
fi
cp -a "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_APP".app /Applications/
chown 501:admin /Applications/"$BREW_CASKS_UPDATE_APP".app
chown -R 501:admin /Applications/"$BREW_CASKS_UPDATE_APP".app/custom_files/
chmod 755 /Applications/"$BREW_CASKS_UPDATE_APP".app
chmod 770 /Applications/"$BREW_CASKS_UPDATE_APP".app/custom_files/"$BREW_CASKS_UPDATE_APP".sh
xattr -dr com.apple.quarantine /Applications/"$BREW_CASKS_UPDATE_APP".app

#open /Applications/"$BREW_CASKS_UPDATE_APP".app

