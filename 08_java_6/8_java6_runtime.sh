#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### java 6
###

# before running download and install the latest version of java jre from www.java.com or through homebrew cask

# restoring functionality of apps that need java 6 without installing apple java
# e.g. adobe cs 5.5
sudo mkdir -p /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
sudo ln -s '/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents' /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents
sudo mkdir -p /System/Library/Java/Support/Deploy.bundle


# to undo this do
#sudo rm -rf /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
#sudo rm -rf /System/Library/Java/Support/Deploy.bundle

echo "done"