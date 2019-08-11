#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### reset mail index
###


### rebuilding mail index on next run
echo ''
echo "deleting files to rebuild the mailindex at next start of mail..."
if ls ~/Library/Mail/V*/MailData/ &> /dev/null
#if find ~/Library/Mail/V* -type d -name "MailData" -maxdepth 1 &> /dev/null
then
	find ~/Library/Mail/V*/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm -f
	find ~/Library/Mail/V*/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm -f
else
	:
fi

# macos 10.15 only
if [[ "$MACOS_VERSION_MAJOR" != "10.15" ]]
then
	:
else
    echo ''
	echo "${bold_text}${blue_text}if this was the first run of this script after a restore please repair all needed mail rules...${default_text}"
    #echo ''
fi

echo ''
echo "done ;)"
echo ''
