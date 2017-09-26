#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



###
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
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
else
    :
fi


###
### starting installation
###

echo ''
echo "installing brew casks..."
echo ''

# casks
if [[ $(which parallel) != "" ]]
then
    CONT0_BREW=y
else
    read -p "do you want to install casks and formulae parallel or sequential (P/s)? " CONT0_BREW
fi
CONT0_BREW="$(echo "$CONT0_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower
if [[ "$CONT0_BREW" == "p" || "$CONT0_BREW" == "parallel" || "$CONT0_BREW" == "" ]]
then
    INSTALLATION_METHOD="parallel"
    echo "running $INSTALLATION_METHOD installation..."
elif [[ "$CONT0_BREW" == "s" || "$CONT0_BREW" == "sequential" ]]
then
    INSTALLATION_METHOD="sequential"
    echo "running $INSTALLATION_METHOD installation..."
else
    echo "no valid entry selected, running parallel installation..."
    INSTALLATION_METHOD="parallel"
fi

# casks
CONT2_BREW=y

# trapping script to kill subprocesses when script is stopped
# kill -9 can only be silenced with >/dev/null 2>&1 when wrappt into function
function kill_subprocesses() 
{
    # kills subprocesses only
    pkill -9 -P $$
}

function kill_main_process() 
{
    # kills subprocesses and process itself
    exec pkill -9 -P $$
}

function unset_variables() {
    unset SUDOPASSWORD
    unset SUDO_PID
}

function start_sudo() {
    #${USE_PASSWORD} | builtin command sudo -p '' -S -v
    sudo -v
    ( while true; do sudo -v; sleep 60; done; ) &
    SUDO_PID="$!"
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then
            kill -9 $SUDO_PID
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}

function activating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
	echo "activating keepingyouawake..."
    #echo ''
	open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///activate
else
        :
fi
}

function deactivating_keepingyouawake() {
if [ -e /Applications/KeepingYouAwake.app ]
then
    echo "deactivating keepingyouawake..."
    open -g /Applications/KeepingYouAwake.app
    open -g keepingyouawake:///deactivate
else
    :
fi
}

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; deactivating_keepingyouawake >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "stop_sudo; unset_variables; printf '\n'; stty sane; pkill ruby; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "stop_sudo; unset_variables; stty sane; kill_subprocesses >/dev/null 2>&1; deactivating_keepingyouawake >/dev/null 2>&1; exit; kill_main_process" EXIT
#set -e

# checking if online
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [ $? -eq 0 ]
then
    echo "we are online, running script..."
    echo ''
    
    # starting sudo keep alive loop
    start_sudo
    
    # installing command line tools
    function command_line_tools_install () {
    if xcode-select --install 2>&1 | grep installed >/dev/null
    then
      	echo command line tools are installed...
    else
      	echo command line tools are not installed, installing...
      	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
      	#sudo xcodebuild -license accept
    fi
    }
    # does not work without power source connection in 10.13
    #command_line_tools_install
    
    #if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ "$(ls -A "$(xcode-select -print-path)")" ]]
    if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -nz "$(ls -A "$(xcode-select -print-path)")" ]]
    then
      	echo command line tools are installed...
    else
    	echo command line tools are not installed, installing...
    	# prompting the softwareupdate utility to list the command line tools
        touch "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    fi
    
    function command_line_tools_update () {
        # updating command line tools and system
        echo "checking for command line tools update..."
        COMMANDLINETOOLUPDATE=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools" | head -n1)
        if [ "$COMMANDLINETOOLUPDATE" == "" ]
        then
        	echo "no update for command line tools available..."
        else
        	echo "update for command line tools available, updating..."
        	softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLUPDATE" | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//')"
        fi
        #softwareupdate -i --verbose "$(softwareupdate --list | grep "* Command Line" | sed 's/*//' | sed -e 's/^[ \t]*//')"
    }
    command_line_tools_update
    
    # removing tmp file that forces command line tools to show up
    if [[ -e "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress" ]]
    then
        rm -f "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    else
        :
    fi
    
    sudo xcode-select --switch /Library/Developer/CommandLineTools
    #stop_sudo
    
    # installing homebrew without pressing enter or entering the password again
    echo ''
    if [[ $(which brew) == "" ]]
    then
        echo "installing homebrew..."
        # homebrew installation
        #start_sudo
        yes | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        #stop_sudo
    else
        echo "homebrew already installed, skipping..."
    fi
        
    # including homebrew commands in PATH
    echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bash_profile
    source ~/.bash_profile
    
    # checking installation and updating homebrew
    brew analytics off
    #cd /usr/local/Library && git stash && git clean -d -f
    brew update
    brew upgrade
    # temporarily updating to the latest git status / commits, git update / upgrade will update to latest stable version when released
    #cd "$(brew --repository)" && git checkout master && git pull origin master && cd -
    brew prune
    brew doctor
    
    # cleaning up
    echo ''
    echo "cleaning up..."
    
    #start_sudo
    brew cleanup
    #stop_sudo
    
    # installing homebrew cask
    echo ''
    echo "installing homebrew cask..."
    
    brew tap caskroom/cask
    
    # activating keepingyouawake
    echo ''
    echo "installing keepingyouawake..."
    builtin printf '"$SUDOPASSWORD\n"' | brew cask install --force keepingyouawake 2> /dev/null | grep "successfully installed"
    activating_keepingyouawake
    
    # installing cask repair to contribute to homebrew casks
    echo ''
    echo "installing cask-repair..."
    brew install vitorgalvao/tiny-scripts/cask-repair
    #cask-repair --help
    
    # cleaning up
    echo ''
    echo "cleaning up..."
    
    # more variables
    # keeping hombrew from updating each time brew install is used
    export HOMEBREW_NO_AUTO_UPDATE=1
    # number of max parallel processes
    NUMBER_OF_CORES=$(sysctl hw.ncpu | awk '{print $NF}')
    NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    #NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    # due to connection issues with too many downloads at the same time limiting the maximum number of jobs for now
    NUMBER_OF_MAX_JOBS_ROUNDED=4
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
        
    # installing casks
    if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" ]]
    then
    
        echo ''
    	echo "uninstalling and cleaning some casks..."
    	# making sure flash gets installed on reinstall
    	if [[ -e "/Library/Internet Plug-Ins/Flash Player.plugin" ]]
    	then
    	    #start_sudo
            ${USE_PASSWORD} | brew cask zap flash-npapi
    	    #stop_sudo
        else
            :
        fi
        echo ''
    	# making sure libreoffice gets installed as a dependency of libreoffice-language-pack
    	if [[ -e "/Applications/LibreOffice.app" ]]
    	then
    	    brew cask uninstall --force libreoffice
    	else
    	    :
    	fi
    	
    	echo "installing casks..."
    	casks=$(cat $SCRIPT_DIR/_lists/02_casks.txt | sed '/^#/ d')
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
    	
    	# as xtrafinder is no longer installable by cask let`s install it that way ;)
        echo ''
    	echo "downloading xtrafinder..."
    	XTRAFINDER_INSTALLER="/Users/$USER/Desktop/XtraFinder.dmg"
    	#wget https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -O "$XTRAFINDER_INSTALLER"
    	curl https://www.trankynam.com/xtrafinder/downloads/XtraFinder.dmg -o "$XTRAFINDER_INSTALLER" --progress-bar
    	#open "$XTRAFINDER_INSTALLER"
    	hdiutil attach "$XTRAFINDER_INSTALLER" -quiet
    	sleep 5
    	echo "installing application..."
    	${USE_PASSWORD} | sudo installer -pkg /Volumes/XtraFinder/XtraFinderInstaller.pkg -target / 1>/dev/null
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
        if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" ]]
        then
            
            echo ''
        	echo "installing casks specific1..."
        	
        	casks_specific1=$(cat $SCRIPT_DIR/_lists/03_casks_specific1.txt | sed '/^#/ d')
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
    
        else
            :
        fi
    else
        :
    fi
    
    if [[ $(echo $CASKS_PRE_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then 
            wait $CASKS_PRE_PID
        else
            :
        fi
    fi
    
    # stopping sudo keep alive loop
    stop_sudo
        
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
    printf '%s\n' "${homebrewpackages[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
        '
    
    # casks
    if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" ]]
    then
    	echo ''
    	echo checking casks installation...
        # casks_pre
    	printf '%s\n' "${casks_pre[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew cask info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
'
        # casks
    	printf '%s\n' "${casks[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew cask info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
'
        # casks specific1
        if [[ "$USER" == "tom" ]]
        then
            echo ''
        	echo checking casks specific1 installation...
        printf '%s\n' "${casks_specific1[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew cask info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
        '
        else
            :
        fi
        
        # additonal apps / xtrafinder
        echo ''
        echo checking additional apps installation...
        if [[ -e "/Applications/XtraFinder.app" ]]; 
        then 
        	printf "%-50s\e[1;32mok\e[0m%-10s\n" "xtrafinder"; 
        else 
        	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "xtrafinder"; 
        fi

    else
    	:
    fi
    
    # done
    echo ''
    echo "homebrew and cask install script done ;)"
    echo ''
    
    # deactivating keepingyouawake
    deactivating_keepingyouawake

else
    echo "not online, skipping installation..."
    echo ''
fi

###
### unsetting password
###

unset SUDOPASSWORD
