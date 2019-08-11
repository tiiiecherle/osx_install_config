#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### script to do things on every logout / shutdown / reboot
###

### installation can be done via restore script after first install
cp -a "$SCRIPT_DIR"/install_files/run_on_logout.sh /Users/"$USER"/Library/Scripts/run_on_logout.sh
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_logout.sh
chmod 700 /Users/"$USER"/Library/Scripts/run_on_logout.sh

# the actual command that are run on boot are included in "$SCRIPT_DIR"/run_on_logout.sh

### enable script
sudo defaults write com.apple.loginwindow LogoutHook /Users/"$USER"/Library/Scripts/run_on_logout.sh
#sudo defaults write com.apple.loginwindow LoginHook /Users/"$USER"/Library/Scripts/run_on_login.sh


### uninstall hook
uninstall_hook() {
	sudo defaults delete com.apple.loginwindow LogoutHook
	rm -f ~/Library/Scripts/run_on_logout.sh
}
#uninstall_hook

echo ''
echo "done ;)"
echo ''
