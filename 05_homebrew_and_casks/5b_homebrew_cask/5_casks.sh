#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)


###
### script frame
###

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
        . "$SCRIPT_DIR"/1_script_frame.sh
    else
        echo ''
        echo "script for functions and prerequisits is missing, exiting..."
        echo ''
        exit
    fi
fi


###
### command line tools
###

checking_command_line_tools


###
### functions
###

function databases_apps_security_permissions() {
    DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_SYSTEM"
	DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_USER"
}
    
function identify_terminal() {
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]
    then
    	export SOURCE_APP=com.apple.Terminal
    	export SOURCE_APP_NAME="Terminal"
    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]
    then
        export SOURCE_APP=com.googlecode.iterm2
        export SOURCE_APP_NAME="iTerm"
	else
		export SOURCE_APP=com.apple.Terminal
		echo "terminal not identified, setting automating permissions to apple terminal..."
	fi
}

function give_apps_security_permissions() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        # working, but does not show in gui of system preferences, use csreq for the entry to show
	    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP"',0,1,1,?,NULL,0,'"$AUTOMATED_APP"',?,NULL,?);"
    fi
    sleep 1
}

function remove_apps_security_permissions_start() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        AUTOMATED_APP=com.apple.finder
        sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"');"
    fi
    sleep 1
}

function remove_apps_security_permissions_stop() {
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        AUTOMATED_APP=com.apple.finder
        # macos versions 10.14 and up
        if [[ $SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1 == "yes" ]]
        then
            # source app was already allowed to control app before running this script, so don`t delete the permission
            :
        else
            sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"');"
        fi
    fi
}


###
### homebrew
###

checking_homebrew


### keepingyouawake
if [[ "$KEEPINGYOUAWAKE" != "active" ]]
then
    echo ''
    activating_keepingyouawake
    echo ''
else
    echo ''
fi


### parallel
checking_parallel


### starting sudo
start_sudo

###

databases_apps_security_permissions
identify_terminal

if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
then
    # macos versions until and including 10.13 
	:
else
    echo "setting security permissions..."
    AUTOMATED_APP=com.apple.finder
    if [[ $(sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='"$SOURCE_APP"' and indirect_object_identifier='"$AUTOMATED_APP"' and allowed='1');") != "" ]]
	then
	    SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1="yes"
	    #echo "$SOURCE_APP is already allowed to control $AUTOMATED_APP..."
	else
		SOURCE_APP_IS_ALLOWED_TO_CONTROL_APP1="no"
		#echo "$SOURCE_APP is not allowed to control $AUTOMATED_APP..."
		give_apps_security_permissions
	fi
fi

# installing homebrew packages
#echo ''
echo "installing casks..."
echo ''

# xquartz
#read -p "do you want to install xquartz (Y/n)? " CONT1_BREW
#CONT1_BREW="$(echo "$CONT1_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower

# installing some casks that have to go first for compatibility reasons
if [[ "$CONT1_BREW" == "y" || "$CONT1_BREW" == "yes" || "$CONT1_BREW" == "" ]]
then
    ### option 1 for including the list in the script
    #echo ''
	#casks_pre=(
	#xquartz
	#java
	#)
	#for caskstoinstall_pre in "${casks_pre[@]}"
	
	### option 2 for separate list file
    casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')
    if [[ "$casks_pre" == "" ]]
    then
    	:
    else
	    old_IFS=$IFS
	    IFS=$'\n'
		for caskstoinstall_pre in ${casks_pre[@]}
		do
	    IFS=$old_IFS
	        if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	        then
			    # xquartz is a needed dependency for xpdf, so it has to be installed first
			    echo installing cask "$caskstoinstall_pre"...
			    ${USE_PASSWORD} | brew cask install --force "$caskstoinstall_pre"
			    echo ''
			else
			    echo installing cask "$caskstoinstall_pre"...
			    ${USE_PASSWORD} | brew cask install --force "$caskstoinstall_pre"
			    echo ''
	        fi
		done
	fi
	#echo ''
else
	:
fi

if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
    #echo ''
	echo "uninstalling and cleaning some casks..."
	# making sure flash gets installed on reinstall
	if [[ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]]
	then
	    #start_sudo
	    
        if [[ -e "/Library/Internet Plug-Ins/flashplayer.xpt" ]]
        then
            sudo rm -f "/Library/Internet Plug-Ins/flashplayer.xpt"
        else
            :
        fi
        ${USE_PASSWORD} | brew cask zap --force flash-npapi
	    #stop_sudo
	    echo ''
    else
        :
    fi
    
	# making sure libreoffice gets installed as a dependency of libreoffice-language-pack
	# installation would be refused if restored via restore script or already installed otherwise
	if [[ -e "/Applications/LibreOffice.app" ]]
	then
	    ${USE_PASSWORD} | brew cask uninstall --force libreoffice
	    echo ''
	else
	    :
	fi
	
	# making sure adobe-acrobat-reader gets installed on reinstall
	if [[ -e "/Applications/Adobe Acrobat Reader DC.app" ]]
	then
	    if [[ -e /Users/$USER/Library/Preferences/com.adobe.Reader.plist ]]
	    then
	        mv /Users/$USER/Library/Preferences/com.adobe.Reader.plist /tmp/com.adobe.Reader.plist
	        if [[ -e /Library/Preferences/com.adobe.reader.DC.WebResource.plist ]]
	        then
	            sudo rm -f /Library/Preferences/com.adobe.reader.DC.WebResource.plist
	        else
	            :
	        fi
	        ${USE_PASSWORD} | brew cask zap --force adobe-acrobat-reader
	        mv /tmp/com.adobe.Reader.plist /Users/$USER/Library/Preferences/com.adobe.Reader.plist
	    else
	        sudo rm -f /Library/Preferences/com.adobe.reader.DC.WebResource.plist
	        ${USE_PASSWORD} | brew cask zap --force adobe-acrobat-reader
	    fi
	else
	    :
	fi
	echo ''
	
	echo "installing casks..."
	casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')
    if [[ "$casks" == "" ]]
    then
    	:
    else
	    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	    then
	        #start_sudo
	        printf '%s\n' "${casks[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
	            echo installing cask {}...
	            builtin printf '"$SUDOPASSWORD\n"' | brew cask install --force {} 2> /dev/null | grep "successfully installed"
	        '
	        #stop_sudo
	    else
	        old_IFS=$IFS
	        IFS=$'\n'
	        for caskstoinstall in ${casks[@]}
	        do
		        IFS=$old_IFS
	            #start_sudo
	            echo installing cask "$caskstoinstall"...
	        	${USE_PASSWORD} | brew cask install --force "$caskstoinstall"
	        	#stop_sudo
	        done
	    fi
		#open "/opt/homebrew-cask/Caskroom/paragon-extfs/latest/FSinstaller.app" &
	fi
	
	# as xtrafinder is no longer installable by cask let`s install it that way ;)
	# automation permissions
	echo ''
	echo "setting security permissions for xtrafinder..."
    if [[ $(echo $MACOS_VERSION | cut -f1,2 -d'.' | cut -f2 -d'.') -le "13" ]]
    then
        # macos versions until and including 10.13 
		:
    else
        # macos versions 10.14 and up
        # working, but does not show in gui of system preferences, use csreq for the entry to show
	    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','com.trankynam.XtraFinder',0,1,1,?,NULL,0,'com.apple.finder',?,NULL,?);"
	    :
    fi
    # registering xtrafinder
    SCRIPT_DIR_LICENSE=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && cd .. && pwd)")
	if [[ -e "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/xtrafinder_register.sh ]]
	then
	    "$SCRIPT_DIR_LICENSE"/_scripts_input_keep/xtrafinder_register.sh
	else
	    echo "script to register xtrafinder not found..."
	fi
	
	# as xtrafinder is no longer installable by cask let`s install it that way ;)
	echo "downloading xtrafinder..."
	XTRAFINDER_INSTALLER="/Users/$USER/Desktop/XtraFinder.dmg"
	#wget https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -O "$XTRAFINDER_INSTALLER"
	curl https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -o "$XTRAFINDER_INSTALLER" --progress-bar
	#open "$XTRAFINDER_INSTALLER"
	hdiutil attach "$XTRAFINDER_INSTALLER" -quiet
	sleep 5
	echo "installing application..."
	${USE_PASSWORD} | sudo installer -pkg /Volumes/XtraFinder/XtraFinder.pkg -target / 1>/dev/null
	#sudo installer -pkg /Volumes/XtraFinder/XtraFinderInstaller.pkg -target / 1>/dev/null
	sleep 1
	#echo "waiting for installer to finish..."
	#while ps aux | grep 'installer' | grep -v grep > /dev/null; do sleep 1; done
	echo "unmounting and removing installer file..."
	hdiutil detach /Volumes/XtraFinder -quiet
	if [ -e "$XTRAFINDER_INSTALLER" ]; then rm "$XTRAFINDER_INSTALLER"; else :; fi
	
else
	:
fi

# installing user specific casks
if [[ "$USER" == "tom" ]]
then
    if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
    then
        echo ''
    	echo "installing casks specific1..."
    	casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')
    	if [[ "$casks_specific1" == "" ]]
	    then
	    	:
	    else
	        if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	        then
	            #start_sudo
	            printf '%s\n' "${casks_specific1[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
	                echo installing cask {}...
	                builtin printf '"$SUDOPASSWORD\n"' | brew cask install --force {} 2> /dev/null | grep "successfully installed"
	            '
	            #stop_sudo
	        else
	            old_IFS=$IFS
	            IFS=$'\n'
	        	for caskstoinstall_specific1 in ${casks_specific1[@]}
	        	do
		    		IFS=$old_IFS
	        	    #start_sudo
	        	    echo installing cask "$caskstoinstall_specific1"...
	        		${USE_PASSWORD} | brew cask install --force "$caskstoinstall_specific1"
	        		#stop_sudo
	        	done
	        fi
		fi
    else
        :
    fi
else
    :
fi
    
# cleaning up
echo ''
echo "cleaning up..."

brew cleanup
brew cleanup --prune=0
# should do the same withou output, but just to make sure              
rm -rf $(brew --cache)
# brew cask cleanup is deprecated from 2018-09
#brew cask cleanup

# listing installed homebrew packages
#echo "the following top-level homebrew packages incl. dependencies are installed..."
#brew leaves | tr "," "\n"
# echo "the following homebrew packages are installed..."
#brew list | tr "," "\n"
#echo ""

# listing installed casks
#echo "the following casks are installed..."
#brew cask list | tr "," "\n"

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    CHECK_IF_FORMULAE_INSTALLED="no"
    CHECK_IF_MASAPPS_INSTALLED="no"
    echo ''
    . "$SCRIPT_DIR"/7_formulae_and_casks_install_check.sh
fi

# installing user specific casks
if [[ "$USER" == "wolfgang" ]]
then
    echo ''
    ${USE_PASSWORD} | brew cask uninstall java
    ${USE_PASSWORD} | brew cask install caskroom/versions/java8
    echo ''
else
    :
fi

### removing security permissions and stopping sudo
remove_apps_security_permissions_stop

stop_sudo
