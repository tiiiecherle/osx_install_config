#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### forcing smb3 connection
###

# forcing smb3 for every connection as user do

if [ -f "~/Library/Preferences/nsmb.conf" ] ; then : ; else rm -rf ~/Library/Preferences/nsmb.conf ; fi

echo "[default]" >> ~/Library/Preferences/nsmb.conf; echo "smb_neg=smb3_only" >> ~/Library/Preferences/nsmb.conf

# restore default as user do
#rm ~/Library/Preferences/nsmb.conf


echo "done"