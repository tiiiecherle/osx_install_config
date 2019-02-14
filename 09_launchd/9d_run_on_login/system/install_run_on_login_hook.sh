#!/bin/bash

###
### script to do things on every login
###

### installation can be done via restore script after first install

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

cp -a "$SCRIPT_DIR"/install_files/run_on_login.sh /Users/"$USER"/Library/Scripts/run_on_login.sh
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_login.sh
chmod 700 /Users/"$USER"/Library/Scripts/run_on_login.sh

# the actual command that are run on boot are included in "$SCRIPT_DIR"/run_on_login.sh

### enable script
#sudo defaults write com.apple.loginwindow LogoutHook /Users/"$USER"/Library/Scripts/run_on_logout.sh
sudo defaults write com.apple.loginwindow LoginHook /Users/"$USER"/Library/Scripts/run_on_login.sh


### uninstall hook
uninstall_hook() {
	sudo defaults delete com.apple.loginwindow LoginHook
	rm -f ~/Library/Scripts/run_on_login.sh
}
#uninstall_hook

echo "done ;)"
