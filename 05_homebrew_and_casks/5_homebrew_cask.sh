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

if [ ! -d /usr/local ]; then
sudo mkdir /usr/local
fi
sudo chown -R $USER:staff /usr/local


# installing homebrew without pressing enter at the beginning
echo "installing homebrew..."

if [ ! -x /usr/local/bin/brew ]; then
yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi


# checking installation and updating homebrew
#echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile
brew doctor
#cd /usr/local/Library && git stash && git clean -d -f
brew update
brew upgrade
brew prune


# installing homebrew cask
echo "installing cask..."

brew tap caskroom/cask
#brew install brew-cask
#brew install caskroom/cask/brew-cask
#brew upgrade brew-cask

# switching to the new system
brew uninstall --force brew-cask
brew update


# installing some homebrew packages
echo "installing homebrew packages..."

homebrewpackages=(
#ffmpeg
git
rename
wget
pv
pigz
htop
pigz
coreutils
)

brew install ${homebrewpackages[@]}


# installing some casks
echo "installing casks (players, plugins, prefpanes, etc.) ..."

casks=(
flash
java
silverlight
xquartz
paragon-extfs
#osxfuse
)

#brew cask install --force ${casks[@]}
for installedcasks_noapps in ${casks[@]}; do
brew cask install --force $installedcasks_noapps
done

open "/opt/homebrew-cask/Caskroom/paragon-extfs/latest/FSinstaller.app" &

# installing some casks to /Applications
echo "installing casks to /Applications..."

casks_apps_with_installer=(
adobe-reader
teamviewer
virtualbox
totalfinder
owncloud
# xtrafinder
# divxplayer (not available yet)
)

#brew cask install --force --caskroom="/Applications" ${casks_apps_with_installer[@]}
for installedcasks_installer in ${casks_apps_with_installer[@]}; do
#brew cask install --force --caskroom="/Applications" $installedcasks_installer
brew cask install --force --caskroom="/Applications" $installedcasks_installer
done

# solving virtualbox error "effective UID is not root"
#for bin in VirtualBox VirtualBoxVM VBoxNetAdpCtl VBoxNetDHCP VBoxNetNAT VBoxHeadless; do
#sudo chmod u+s "/Applications/VirtualBox.app/Contents/MacOS/${bin}"
#done

#osascript -e 'tell application "TeamViewer" to quit' &

casks_apps_without_installer=(
keka
the-unarchiver
)

#brew cask install --force --caskroom="/Applications" ${casks_apps_without_installer[@]}
for installedcasks_noinstaller in ${casks_apps_without_installer[@]}; do
#brew cask install --force --caskroom="/Applications" $installedcasks_noinstaller
brew cask install --force $installedcasks_noinstaller
done

for installedcasks_noinstaller in ${casks_apps_without_installer[@]}; do
cd /Applications/$installedcasks_noinstaller/
cd "$(ls)"
cp -a "$(ls | grep ."."app$)" /Applications/
cd ~
done


# cleaning up
echo "cleaning up..."

brew update
brew cleanup
brew cask cleanup

for installedcasks_installer in ${casks_apps_with_installer[@]}; do
rm -rf /Applications/$installedcasks_installer
done

for installedcasks_noinstaller in ${casks_apps_without_installer[@]}; do
rm -rf /Applications/$installedcasks_noinstaller
done

rm -rf ~/Applications


# listing installed homebrew packages
echo "the following top-level homebrew packages incl. dependencies are installed..."
brew leaves | tr "," "\n"
# echo "the following homebrew packages are installed..."
#brew list | tr "," "\n"
echo ""

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




