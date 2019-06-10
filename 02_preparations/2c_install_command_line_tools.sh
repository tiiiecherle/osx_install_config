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
        echo "${bold_text}please install command line tools before continuing...${default_text}"
        echo ''
    fi
fi
