#!/bin/bash

# uninstalling homebrew and all casks
# https://github.com/Homebrew/brew/blob/master/share/doc/homebrew/FAQ.md
yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
sudo rm -rf /opt/homebrew-cask
sudo rm -rf /usr/local/Caskroom
sudo rm -rf /usr/local/lib/librtmp.dylib
sudo chmod 0755 /usr/local
sudo chown root:wheel /usr/local
sed -i '' '\|/usr/local/sbin:$PATH|d' ~/.bash_profile
