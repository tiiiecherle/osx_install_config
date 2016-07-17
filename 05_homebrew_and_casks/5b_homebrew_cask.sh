#!/bin/sh

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 1200; kill -0 "$$" || exit; done 2>/dev/null &

# creating directory and adjusting permissions
echo "creating directory..."

# checking installation and updating homebrew
brew doctor
#cd /usr/local/Library && git stash && git clean -d -f
brew update
brew upgrade
brew prune

# installing homebrew cask
echo "installing cask..."

brew tap caskroom/cask

# switching to the new system
#brew uninstall --force brew-cask
#brew update

# installing some casks
echo "installing casks ..."

casks=(
flash
java
silverlight
xquartz
paragon-extfs
#osxfuse
adobe-reader
teamviewer
virtualbox
virtualbox-extension-pack
totalfinder
owncloud
keka
the-unarchiver
#the-archive-browser
)

#brew cask install --force ${casks[@]}
for caskstoinstall in ${casks[@]}; do
brew cask install --force $caskstoinstall
done

open "/opt/homebrew-cask/Caskroom/paragon-extfs/latest/FSinstaller.app" &

# cleaning up
echo "cleaning up..."

brew cleanup
brew cask cleanup

rm -rf ~/Applications

# listing installed casks
echo "the following casks are installed..."
brew cask list | tr "," "\n"

# hint that apps in Applications are not shown
echo "apps installed directly to /Applications are not shown in the installed casks list"

# done
echo "done ;)"


# uninstalling a cask with all versions
#brew cask uninstall --force CASKNAME

# finding a cask
#brew cask search CASKNAME

# updating everything
#brew update
#brew upgrade brew-cask
#brew upgrade --all
#brew cleanup
#brew cask cleanup

#brew update && brew upgrade --all && brew cleanup && brew cask cleanup




