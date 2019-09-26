#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### script frame
###

# script is not sourced, run standalone
if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
then
    . "$SCRIPT_DIR"/1_script_frame.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
else
    echo ''
    echo "script for functions and prerequisits is missing, exiting..."
    echo ''
    exit
fi


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### command line tools
###

### starting sudo
env_start_sudo
    
# installing command line tools (graphical)
command_line_tools_install_gui() {
    if xcode-select --install 2>&1 | grep installed >/dev/null
    then
      	echo "command line tools are installed..."
    else
      	echo "command line tools are not installed, installing..."
      	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
      	#sudo xcodebuild -license accept
    fi
}
# does not work without power source connection in 10.13
#command_line_tools_install_gui

# installing command line tools
echo ''
env_command_line_tools_install_shell

# updating command line tools
command_line_tools_update_shell() {
    # updating command line tools and system
    echo ''
    echo "checking for command line tools update..."
    env_get_current_command_line_tools_version
    #echo "COMMANDLINETOOLVERSION is "$COMMANDLINETOOLVERSION"..."

    if [[ "$CURRENT_COMMANDLINETOOLVERSION" == "" ]]
    then
    	echo "no update for command line tools available..."
    else
    	echo "update for command line tools available, updating..."
    	softwareupdate -i --verbose "$(echo "$CURRENT_COMMANDLINETOOLVERSION")"
    fi
}
command_line_tools_update_shell

# check active command line tools version
# pkgutil --pkg-info=com.apple.pkg.CLTools_Executables | grep "^version"

# installing sdk headers on mojave
VERSION_TO_CHECK_AGAINST=10.13
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.13 
    :
else
    # macos versions 10.14 and up
    if [[ $(xcrun --show-sdk-path) == "" ]]
    then
        if [[ "$MACOS_VERSION_MAJOR" == "10.14" ]]
        then
            echo ''
            echo "installing sdk headers..."
            #sudo install -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg
            sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /
        elif [[ "$MACOS_VERSION_MAJOR" == "10.15" ]]
        then
            :
        else
            :
        fi  
    else
        echo ''
        echo "sdk headers already installed..."
        xcrun --show-sdk-path
    fi
fi

echo ''


### stopping sudo
env_stop_sudo


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
