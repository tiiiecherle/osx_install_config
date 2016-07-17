#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### installing xcode command line tools
###

echo "opening xcode to install components"  
open "/Applications/Xcode.app"
#xcode-select --install

echo "done"
