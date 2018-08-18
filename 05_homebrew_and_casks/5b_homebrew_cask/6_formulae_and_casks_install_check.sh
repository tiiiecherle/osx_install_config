#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")


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
### homebrew
###

checking_homebrew


### starting sudo
start_sudo

# variables
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')
homebrewpackages=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_packages.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')
casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')
casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g')

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
if [[ $(echo "$CHECK_IF_FORMULAE_INSTALLED") == "no" ]]
then
	:
else
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
fi

echo ''

if [[ $(echo "$CHECK_IF_CASKS_INSTALLED") == "no" ]]
then
	:
else   
	# casks
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
	echo ''

fi

### stopping sudo
stop_sudo
