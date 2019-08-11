#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### java 6
###

# before running download and install the latest version of java or adoptopenjdk from the respective websites or via homebrew cask

VERSION_TO_CHECK_AGAINST=10.14
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.14
    # restoring functionality of apps that need java 6 without installing apple java
	sudo mkdir -p /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
	sudo ln -s '/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents' /System/Library/Java/JavaVirtualMachines/1.6.0.jdk/Contents
	sudo mkdir -p /System/Library/Java/Support/Deploy.bundle
	
	# to undo
	#sudo rm -rf /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
	#sudo rm -rf /System/Library/Java/Support/Deploy.bundle
	
else
    # macos versions 10.15 and up
    echo ''
    echo "linking java6 is no longer needed on macos newer than "$VERSION_TO_CHECK_AGAINST", exiting..."
    #echo ''
fi

echo ''
echo 'done ;)'
echo ''



###
### unsetting password
###

unset SUDOPASSWORD
