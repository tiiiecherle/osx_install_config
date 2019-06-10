#!/bin/bash

### variables
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
SCRIPT_DIR_FINAL=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
echo $SCRIPT_DIR_FINAL


### text output
bold_text=$(tput bold)
red_text=$(tput setaf 1)
default_text=$(tput sgr0)


### script
# starting with version 10.15 macos uses zsh as default login shell
# for assuring maximum compatibility setting zsh as default on 10.14

### default login shell
echo ''
if [[ $(dscl . -read ~/ UserShell | sed 's/UserShell: //' | grep zsh) == "" ]]
then
	# checking if zsh is installed
	if [[ $(command -v zsh) == "" ]]
	then
	    #echo ''
	    echo "zsh is not installed, exiting..."
	    exit
	else
		#echo ''
		echo "zsh is installed..."
	fi
	
	# checking if zsh definded as possible default shell
	if [[ $(cat /etc/shells | grep zsh) == "" ]]
	then
	    echo ''
	    echo "setting zsh as default shell is not yet possible..."
	    echo "adding entry to /etc/shells..."
	    sudo echo "/bin/zsh" >> /etc/shells
	else
		echo ''
	    echo "setting zsh as default shell is possible..."
	fi
	
	# setting default login shell to zsh
    echo ''
    echo "zsh is not the default login shell, setting it default..."
    chsh -s $(which zsh) $USER
else
	echo "zsh is already the default login shell..."
fi

### customization
echo ''
echo "customizing zsh shell..."

# git is part of command line tools and needed for the customization
echo ''
if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -nz "$(ls -A "$(xcode-select -print-path)")" ]]
then
  	echo "command line tools are installed..."
    echo ''
else
	echo "command line tools are not installed, installing..."
    if [[ -e "$SCRIPT_DIR_FINAL"/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/2_command_line_tools.sh ]]
    then
        "$SCRIPT_DIR_FINAL"/03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/2_command_line_tools.sh
    else
        echo ''
        echo "${bold_text}${red_text}.../03_homebrew_casks_and_mas/3b_homebrew_casks_and_mas_install/2_command_line_tools.sh not found, skipping...${default_text}"
        echo ''
        echo "${bold_text}please install command line tools and run this script again, exiting...${default_text}"
        echo ''
        exit
    fi
fi

# https://github.com/robbyrussell/oh-my-zsh
# starting with a clean install
for FILE_TO_CHECK in ".oh-my-zsh" ".zshrc" ".zshrc.pre-oh-my-zsh-*"
do
	if [[ -e /Users/"$USER"/"$FILE_TO_CHECK" ]]
	then
		rm -rf /Users/"$USER"/"$FILE_TO_CHECK"
	else
		:
	fi
done

# installing
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" &
wait

# making sure config file exists
if [[ ! -e ~/.zshrc ]]
then
	touch ~/.zshrc
	chown 501:staff ~/.zshrc
	chmod 600 ~/.zshrc
else
	:
fi

# customization (no if needed as the script always starts with a clean config)
# changes
sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME=""|' ~/.zshrc
sed -i '' 's|^plugins=.*|plugins=()|' ~/.zshrc
sed -i '' '/DISABLE_AUTO_TITLE=/s/^#*//g' ~/.zshrc
sed -i '' '/DISABLE_AUTO_TITLE=/s/^ *//g' ~/.zshrc
# additions
echo '' >> ~/.zshrc
echo "# customized prompt" >> ~/.zshrc
echo "PROMPT='%n%f %1~ %# '" >> ~/.zshrc
echo '' >> ~/.zshrc
echo "# default editor" >> ~/.zshrc
echo "export EDITOR=nano" >> ~/.zshrc

# setting path if homebrew is installed
if [[ $(command -v brew) == "" ]]
then
	:
else
	# including homebrew commands in PATH
	add_path_to_shell() {
	    echo "# homebrew PATH" >> "$SHELL_CONFIG"
	    echo 'export PATH="/usr/local/bin:/usr/local/sbin:$PATH"' >> "$SHELL_CONFIG"
	}
	
	set_path_for_shell() {
		if [[ $(command -v "$SHELL_TO_CHECK") == "" ]]
		then
		    #echo ''
		    echo "$SHELL_TO_CHECK is not installed, skipping to set path..."
		else
		    echo "setting path for $SHELL_TO_CHECK..."
	        if [[ ! -e "$SHELL_CONFIG" ]]
	        then
	            touch "$SHELL_CONFIG"
	            chown 501:staff "$SHELL_CONFIG"
	            chmod 600 "$SHELL_CONFIG"
	            add_path_to_shell
	        elif [[ $(cat "$SHELL_CONFIG" | grep "^export PATH=") != "" ]]
	        then
	            sed -i '' 's|^export PATH=.*|export PATH="/usr/local/bin:/usr/local/sbin:$PATH"|' "$SHELL_CONFIG"
	        else
	            echo '' >> "$SHELL_CONFIG"
	            add_path_to_shell
	        fi
	        # sourcing changes for currently used shell
	        if [[ $(echo "$SHELL") == "$SHELL_TO_CHECK" ]]
	        then
	            "$SHELL" -c "source "$SHELL_CONFIG""
	        else
	            :
	        fi
		fi
	}
	
	SHELL_TO_CHECK="/bin/bash"
	SHELL_CONFIG="/Users/$(logname)/.bashrc"
	set_path_for_shell
	
	SHELL_TO_CHECK="/bin/zsh"
	SHELL_CONFIG="/Users/$(logname)/.zshrc"
	set_path_for_shell
fi

# sourcing config file if script is run from zsh for changes to take effect
# will be sourced when opening a new terminal session automatically
if [[ $(echo "$SHELL") == "/bin/zsh" ]]
then
	"$SHELL" -c "source "/Users/$(logname)/.zshrc""
else
    :
fi

# starting zsh shell in current terminal
echo ''
echo "switching to zsh shell..."
echo ''
exec zsh -l

### documentation
# currently used shell
#echo "$SHELL"

# default login shell for current user
#dscl . -read ~/ UserShell | sed 's/UserShell: //'

# .zprofile is equivalent to .bash_profile and runs at login, including over SSH
# .zshrc is equivalent to .bashrc and runs for each new Terminal session

# if the latest zsh homebrew version shall be used follow these steps
# install homebrew
# install zsh via homebrew
# set path in ~/.zshrc
# source ~/.zshrc
# sudo "$SHELL" -c "echo $(which zsh) >> /etc/shells"
# chsh -s $(which zsh) $USER