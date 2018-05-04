#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")
FILENAME_INSTALL_SCRIPT=$(basename "$BASH_SOURCE")
export FILENAME_INSTALL_SCRIPT


###
### script frame
###

if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
then
    . "$SCRIPT_DIR"/1_script_frame.sh
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi


###
### script
###

#echo ''
echo "installing homebrew and homebrew casks..."
echo ''

# casks
read -p "do you want to install casks apps? select no when using restore script on clean install (Y/n)? " CONT2_BREW
CONT2_BREW="$(echo "$CONT2_BREW" | tr '[:upper:]' '[:lower:]')"    # tolower
echo ''

if [[ "$CONT2_BREW" =~ ^(y|yes|n|no)$ || "$CONT2_BREW" == "" ]]
then
    :
else
    #echo ''
    echo "wrong input, exiting script..."
    echo ''
    exit
fi

### scripts
. "$SCRIPT_DIR"/2_command_line_tools.sh
. "$SCRIPT_DIR"/3_homebrew_caskbrew.sh
. "$SCRIPT_DIR"/4_homebrew_formulae.sh

if [[ "$CONT2_BREW" == "y" || "$CONT2_BREW" == "yes" || "$CONT2_BREW" == "" ]]
then
    . "$SCRIPT_DIR"/5_casks.sh
else 
    CHECK_IF_CASKS_INSTALLED="no"
fi

. "$SCRIPT_DIR"/6_formulae_and_casks_install_check.sh

