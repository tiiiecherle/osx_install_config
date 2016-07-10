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

# including homebrew commands in PATH
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile

# checking installation and updating homebrew
brew doctor
#cd /usr/local/Library && git stash && git clean -d -f
brew update
brew upgrade
brew prune

# installing some homebrew packages
echo "installing homebrew packages..."

homebrewpackages=(
#ffmpeg
git
rename
wget
pv
pigz
gnu-tar
htop
coreutils
)

brew install ${homebrewpackages[@]}

# cleaning up
echo "cleaning up..."

brew cleanup

# listing installed homebrew packages
echo "the following top-level homebrew packages incl. dependencies are installed..."
brew leaves | tr "," "\n"
# echo "the following homebrew packages are installed..."
#brew list | tr "," "\n"
echo ""

# done
echo "done ;)"

# finding a cask
#brew cask search CASKNAME

# updating everything
#brew update
#brew upgrade --all
#brew cleanup
#brew cask cleanup

#brew update && brew upgrade --all && brew cleanup && brew cask cleanup




