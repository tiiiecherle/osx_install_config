#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search

# asking for the administrator password upfront
#sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
#while true; do sudo -n true; sleep 1200; kill -0 "$$" || exit; done 2>/dev/null &

read -s -p "Password: " SUDOPASSWORD
echo ''
echo "$SUDOPASSWORD" | sudo -S echo "" > /dev/null 2>&1
if [ $? -eq 0 ]
then 
    :
else
    echo "Sorry, try again."
    read -s -p "Password: " SUDOPASSWORD
    echo ''
    echo "$SUDOPASSWORD" | sudo -S echo "" > /dev/null 2>&1
    if [ $? -eq 0 ]
    then 
        :
    else
        echo "Sorry, try again."
        read -s -p "Password: " SUDOPASSWORD
        echo ''
        echo "$SUDOPASSWORD" | sudo -S echo "" > /dev/null 2>&1
        if [ $? -eq 0 ]
        then 
            :
        else
            echo "wrong sudo password, exiting..."
            exit
        fi
    fi
fi

echo ''
echo "installing homebrew and homebrew casks..."

echo ''
# xquartz
read -p "do you want to install xquartz (Y/n)? " CONT1_BREW
CONT1_BREW="$(echo "$CONT1_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower

# casks
read -p "do you want to install casks packages (Y/n)? " CONT2_BREW
CONT2_BREW="$(echo "$CONT2_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower
echo ''

# creating directory and adjusting permissions
echo "creating directory..."

if [ ! -d /usr/local ]; then
echo "$SUDOPASSWORD" | sudo -S mkdir /usr/local
fi
#sudo chown -R $USER:staff /usr/local
echo "$SUDOPASSWORD" | sudo -S chown -R $(whoami) /usr/local

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
#echo ""
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
echo ''
echo "installing homebrew..."

if [ ! -x /usr/local/bin/brew ]; then
yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# homebrew permissions
#if [ -e "$(brew --prefix)" ] 
#then
#	echo "setting ownerships and permissions for homebrew..."
#	BREWGROUP="admin"
#	BREWPATH=$(brew --prefix)
#	sudo chown -R 501:"$BREWGROUP" "$BREWPATH"
#	sudo find "$BREWPATH" -type f -print0 | sudo xargs -0 chmod g+rw
#	sudo find "$BREWPATH" -type d -print0 | sudo xargs -0 chmod g+rwx
#else
#	:
#fi

# including homebrew commands in PATH
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile

# checking installation and updating homebrew
brew analytics off
#cd /usr/local/Library && git stash && git clean -d -f
brew update
brew upgrade
brew prune
brew doctor

# cleaning up
echo "cleaning up..."

brew cleanup

# homebrew cask
echo "installing homebrew cask..."

brew tap caskroom/cask

# cleaning up
echo "cleaning up..."

brew cleanup
brew cask cleanup

#rm -rf ~/Applications

# installing xquartz
if [[ "$CONT1_BREW" == "y" || "$CONT1_BREW" == "yes" || "$CONT1_BREW" == "" ]]
then
	echo "installing cask xquartz..."
	casks_pre=(
	xquartz
	)
	#brew cask install --force ${casks[@]}
	for caskstoinstall_pre in ${casks_pre[@]}; do
		echo "$SUDOPASSWORD" | sudo -S brew cask install --force $caskstoinstall_pre
	done
else
	:
fi

# installing some homebrew packages
echo ''
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
homebrew/x11/xpdf
)

echo "$SUDOPASSWORD" | brew install ${homebrewpackages[@]}

# installing casks
if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
    # without this install of flash failed (2016-09)
    echo "$SUDOPASSWORD" | brew zap --force flash
    
	echo "installing casks ..."
	
	casks=(
	flash
	java
	silverlight
	#xquartz
	paragon-extfs
	#osxfuse
	adobe-reader
	teamviewer
	virtualbox
	virtualbox-extension-pack
	totalfinder
	xtrafinder
	owncloud
	#keka
	the-unarchiver
	#the-archive-browser
	)
	
	#brew cask install --force ${casks[@]}
	for caskstoinstall in ${casks[@]}; do
		echo "$SUDOPASSWORD" | sudo -S brew cask install --force $caskstoinstall
	done
	
	open "/opt/homebrew-cask/Caskroom/paragon-extfs/latest/FSinstaller.app" &
else
	:
fi

# cleaning up
echo ''
echo "cleaning up..."

brew cleanup
brew cask cleanup

# listing installed homebrew packages
#echo "the following top-level homebrew packages incl. dependencies are installed..."
#brew leaves | tr "," "\n"
# echo "the following homebrew packages are installed..."
#brew list | tr "," "\n"
#echo ""

# listing installed casks
#echo "the following casks are installed..."
#brew cask list | tr "," "\n"

# checking if successfully installed
# homebrew packages
echo ''
echo checking homebrew package installation...
for homebrewpackage in ${homebrewpackages[@]}; do
    if [[ $(brew info "$homebrewpackage" | grep "Not installed") == "" ]]
    #if [[ $(brew list | grep "$homebrewpackage") != "" ]]
    then
        printf "%-50s\e[0;32mok\e[0m%-10s\n" "$homebrewpackage"
    else
        printf "%-50s\e[0;31mFAILED\e[0m%-10s\n" "$homebrewpackage"
    fi
done

# casks
if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
	echo ''
	echo checking casks installation...
    for caskstoinstall in ${casks[@]}; do
        if [[ $(brew cask info "$caskstoinstall" | grep "Not installed") == "" ]]
        #if [[ $(brew cask list | grep "$caskstoinstall") != "" ]]
        then
        	printf "%-50s\e[0;32mok\e[0m%-10s\n" "$caskstoinstall"
        else
        	printf "%-50s\e[0;31mFAILED\e[0m%-10s\n" "$caskstoinstall"
        fi
    done
else
	:
fi

# unsetting password
unset SUDOPASSWORD

# done
echo ''
echo "done ;)"
echo ''
