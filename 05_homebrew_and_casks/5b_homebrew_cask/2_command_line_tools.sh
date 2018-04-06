#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")


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


### starting sudo
start_sudo

# installing command line tools (graphical)
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

# installing command line tools (command line)
#if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ "$(ls -A "$(xcode-select -print-path)")" ]]
if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -nz "$(ls -A "$(xcode-select -print-path)")" ]]
then
  	echo command line tools are installed...
else
	echo command line tools are not installed, installing...
	# prompting the softwareupdate utility to list the command line tools
    touch "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    COMMANDLINETOOLVERSION=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools" | grep $(defaults read loginwindow SystemVersionStampAsString | cut -f1,2 -d'.'))
    softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLVERSION" | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//')"
fi

# removing tmp file that forces command line tools to show up
if [[ -e "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress" ]]
then
    rm -f "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
else
    :
fi

# choosing command line tools as default
sudo xcode-select --switch /Library/Developer/CommandLineTools

function command_line_tools_update () {
    # updating command line tools and system
    echo ''
    echo "checking for command line tools update..."
    COMMANDLINETOOLUPDATE=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools" | grep $(defaults read loginwindow SystemVersionStampAsString | cut -f1,2 -d'.'))
    # or sw_vers | awk 'BEGIN { FS = ":[ \t]*" } /ProductVersion/ { print $2 }' | cut -f1,2 -d'.'
    # or sw_vers -productVersion | cut -f1,2 -d'.'
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

echo ''

### stopping sudo
stop_sudo
