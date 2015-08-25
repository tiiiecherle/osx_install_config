#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### nvram
###

echo "nvram"

# disable the sound effects on boot
#sudo nvram SystemAudioVolume=" "

# disable rootless (introduced in 10.11) - lo longer working, use separate script instead
#sudo nvram boot-args="rootless=0"

# enable verbose booting
#sudo nvram boot-args="-v"

# showing already set nvram variables
#sudo nvram -p

# reset / disable all boot-agrs
#sudo nvram boot-args=""
#sudo nvram -d boot-args


###
### reboot
###

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


