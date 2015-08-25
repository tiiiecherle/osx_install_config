#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### system integrity protection
###

echo "rootless system integrity protection"

sudo csrutil status

sudo csrutil disable

sudo csrutil status

# if root is not working after a reboot, reboot your mac to recovery mode (reboot with command + R pressed) and deactivate it manually in...
# utilities
# security configuration
# disable enforce system integrity protection
# reboot

###
### reboot
###

osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


