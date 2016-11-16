#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



###
### asking password upfront
###

# solution 1
# only working for sudo commands, not for commands that need a password and are run without sudo
# and only works for specified time
# asking for the administrator password upfront
#sudo -v
# keep-alive: update existing 'sudo' time stamp until script is finished
#while true; do sudo -n true; sleep 600; kill -0 "$$" || exit; done 2>/dev/null &

# solution 2
# working for all commands that require the password (use sudo -S for sudo commands)
# working until script is finished or exited

# function for reading secret string (POSIX compliant)
enter_password_secret()
{
    # read -s is not POSIX compliant
    #read -s -p "Password: " SUDOPASSWORD
    #echo ''
    
    # this is POSIX compliant
    # disabling echo, this will prevent showing output
    stty -echo
    # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
    trap 'stty echo' EXIT
    # asking for password
    printf "Password: "
    # reading secret
    read -r "$@" SUDOPASSWORD
    # reanabling echo
    stty echo
    trap - EXIT
    # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
    printf "\n"
    # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
    # has to be part of the function or it wouldn`t be updated during the maximum three tries
    #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
}

# unset the password if the variable was already set
unset SUDOPASSWORD

# making sure no variables are exported
set +a

# asking for the SUDOPASSWORD upfront
# typing and reading SUDOPASSWORD from command line without displaying it and
# checking if entered password is the sudo password with a set maximum of tries
NUMBER_OF_TRIES=0
MAX_TRIES=3
while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
do
    NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
    #echo "$NUMBER_OF_TRIES"
    if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    then
        enter_password_secret
        ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
        if [ $? -eq 0 ]
        then 
            break
        else
            echo "Sorry, try again."
        fi
    else
        echo ""$MAX_TRIES" incorrect password attempts"
        exit
    fi
done

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}



###
### starting installation
###

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

# installing homebrew without pressing enter or entering the password again
echo ''
if [[ $(which brew) == "" ]]
then
    echo "installing homebrew..."
    # redefining sudo so it is possible to run homebrew without entering the password again
    sudo()
    {
        ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
    }
    # giving the sudo passoword and keeping it alive for sleep x seconds
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    # homebrew installation
    yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    # forcing sudo to forget the sudo password (can still be used with ${USE_PASSWORD})
    sudo -K
    # redefining sudo back for the rest of the script
    #sudo()
    #{
    #    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #}
else
    echo "homebrew already installed, skipping..."
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
source ~/.bash_profile

# checking installation and updating homebrew
brew analytics off
#cd /usr/local/Library && git stash && git clean -d -f
brew update
brew upgrade
# temp fix for no plain text file error
#cd "$(brew --repository)" && git checkout master && git pull origin master && cd -
brew prune
brew doctor

# cleaning up
echo ''
echo "cleaning up..."

brew cleanup

# homebrew cask
echo ''
echo "installing homebrew cask..."

brew tap caskroom/cask

# cleaning up
echo ''
echo "cleaning up..."

brew cleanup
brew cask cleanup

#rm -rf ~/Applications

# installing xquartz
if [[ "$CONT1_BREW" == "y" || "$CONT1_BREW" == "yes" || "$CONT1_BREW" == "" ]]
then
    echo ''
	echo "installing cask xquartz..."
	casks_pre=(
	xquartz
	)
	#brew cask install --force ${casks[@]}
	for caskstoinstall_pre in "${casks_pre[@]}"
	do
        sudo -v
		${USE_PASSWORD} | brew cask install --force "$caskstoinstall_pre"
		sudo -K
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
#imagemagick
# ffmpeg
qtfaststart
fdk-aac
sdl2
freetype
libass
libquvi
libvorbis
libvpx
opus
x265
)

${USE_PASSWORD} | brew install "${homebrewpackages[@]}"

# installing casks
if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then

    echo ''
	echo "uninstalling and cleaning some casks..."
    # without this install of flash failed (2016-09)
    sudo brew cask zap --force flash-npapi
    
    echo ''
	echo "installing casks..."
	
	casks=(
	### needed casks
	flash-npapi
	java
	silverlight
	paragon-extfs
	#osxfuse
	adobe-reader
	teamviewer
	virtualbox
	virtualbox-extension-pack
	#totalfinder
	xtrafinder
	owncloud
	the-unarchiver
	### casks only installed for update monitoring via brew cu
	alfred
	angry-ip-scanner
	appcleaner
	audiobookbinder
	bartender
	burn
	chromium
	coconutbattery
	cog
	coteditor
	cyberduck
	deluge
	disk-inventory-x
	eaglefiler
	easyfind
	filezilla
	firefox
	github-desktop
	google-earth-pro
	google-earth-web-plugin
	handbrake
	ibackup
	insomniax
	#imazing
	istat-menus
	iterm2
	itweax
	jameica
	jdownloader
	keepassx
	keepingyouawake
	keka
	libreoffice
	liteicon
	macdown
	macpass
	macupdate-desktop
	namechanger
	onyx
	openoffice
	oversight
	owncloud
	#plex-media-server
	progressive-downloader
	remote-buddy
	skype
	telegram
	textwrangler
	the-archive-browser
	tnefs-enough
	transmission
	trolcommander
	#tunnelblick
	unified-remote
	videomonkey
	vlc
	vlc-webplugin
	vnc-viewer
	vox
	whatsapp
	x-lite
	xnconvert
	zipeg
	)
	
	#brew cask install --force ${casks[@]}
	for caskstoinstall in "${casks[@]}"
	do
	    sudo -v
		${USE_PASSWORD} | brew cask install --force $caskstoinstall
		sudo -K
	done
	
	#open "/opt/homebrew-cask/Caskroom/paragon-extfs/latest/FSinstaller.app" &
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
for homebrewpackage in "${homebrewpackages[@]}"; do
    if [[ $(brew info "$homebrewpackage" | grep "Not installed") == "" ]]
    #if [[ $(brew list | grep "$homebrewpackage") != "" ]]
    then
        printf "%-50s\e[1;32mok\e[0m%-10s\n" "$homebrewpackage"
    else
        printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$homebrewpackage"
    fi
done

# casks
if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
	echo ''
	echo checking casks installation...
    for caskstoinstall in "${casks[@]}"; do
        if [[ $(brew cask info "$caskstoinstall" | grep "Not installed") == "" ]]
        #if [[ $(brew cask list | grep "$caskstoinstall") != "" ]]
        then
        	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$caskstoinstall"
        else
        	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$caskstoinstall"
        fi
    done
else
	:
fi

# done
echo ''
echo "homebrew script done ;)"
echo ''



###
### unsetting password
###

unset SUDOPASSWORD
