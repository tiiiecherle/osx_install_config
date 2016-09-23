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
#sudo chown -R $USER:staff /usr/local
sudo chown -R $(whoami) /usr/local

# installing command line tools
if xcode-select --install 2>&1 | grep installed >/dev/null
then
  	echo command line tools are installed...
else
  	echo command line tools are not installed, installing...
  	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
  	#sudo xcodebuild -license accept
fi

sudo xcode-select --switch /Library/Developer/CommandLineTools

# updating command line tools and system
echo ""
echo "checking for command line tools update..."
COMMANDLINETOOLUPDATE=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools")
if [ "$COMMANDLINETOOLUPDATE" == "" ]
then
	echo "no update for command line tools available..."
else
	echo "update for command line tools available, updating..."
	softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLUPDATE" | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//')"
fi
#softwareupdate -i --verbose "$(softwareupdate --list | grep "* Command Line" | sed 's/*//' | sed -e 's/^[ \t]*//')"

# installing homebrew without pressing enter at the beginning
echo "installing homebrew..."

if [ ! -x /usr/local/bin/brew ]; then
yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# permissions
sudo chown -R $(whoami) /usr/local

# including homebrew commands in PATH
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile

# checking installation and updating homebrew
brew analytics off
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
duti
ghostscript
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




