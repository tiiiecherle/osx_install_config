#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### safari extensions
###

# as apple changed the format of extensions for 10.14 and up it is no longer necessary to restore the "*.safariextz" files
# "/$HOMEFOLDER/Library/Safari/Extensions/Extensions.plist"
# "/$HOMEFOLDER/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.Extensions.plist"
# are restored by the restore script if they were present at backup

echo ''
echo "opening safari apps that include extensions..."
# should already be enabled by restoring ~/Library/Containers/com.apple.Safari/Data/Library/WebKit/ContentExtensions
open "/Applications/Better.app"
open "/Applications/GhosteryLite.app"
open "/Applications/AdGuard for Safari.app"
open "/Applications/Google Analytics Opt Out.app"


### accepting self signed sever certificate
# opening safari to test if certificate for syncing calendar, contacts and reminders on local network via https is installed
# install via 09_launchd/9f_cert_install_update/install_cert_and_launchdservice.sh
echo ''
#echo "please accept certificate by showing details, opening the website and entering the password..."
echo "checking if certificate is installed correctly by opening the website..."

SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_TWO_BACK"
if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh ]]
then
    SERVER_IP=$(cat "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/cert_install_update_data.sh | grep "^SERVER_IP" | awk -F '"' '{print $2}')
    #echo "SERVER_IP_VARIABLE is $SERVER_IP_VARIABLE..."
else
    echo "script with variables not found, exiting..."
    exit
fi

open -a /Applications/Safari.app https://"$SERVER_IP"
echo "safari has to be quit before continuing..."
while ps aux | grep '/Safari.app/' | grep -v grep > /dev/null; do sleep 1; done

echo ''
echo 'done ;)'
echo ''
