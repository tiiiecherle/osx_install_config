#!/bin/bash

###
### launchd & applescript to do things on every boot after user login
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

### installation should be done via restore script after first install
sudo rm -f /Library/LaunchDaemons/com.run_script_on_boot.plist
sudo cp -a "$SCRIPT_DIR"/install_files/com.run_script_on_boot.plist /Library/LaunchDaemons/com.run_script_on_boot.plist
sudo chown root:wheel /Library/LaunchDaemons/com.run_script_on_boot.plist
sudo chmod 644 /Library/LaunchDaemons/com.run_script_on_boot.plist

sudo rm -f /Library/Scripts/run_on_login_as_root.sh
sudo cp -a "$SCRIPT_DIR"/install_files/run_on_login_as_root.sh /Library/Scripts/run_on_login_as_root.sh
sudo chown root:wheel /Library/Scripts/run_on_login_as_root.sh
sudo chmod 755 /Library/Scripts/run_on_login_as_root.sh

# the actual command that is run on boot is included in the respective .plist file

### enable launchd agent
sudo launchctl unload -F /Library/LaunchDaemons/com.run_script_on_boot.plist
sudo launchctl load -F /Library/LaunchDaemons/com.run_script_on_boot.plist

### uninstall
uninstall_run_on_boot() {
	sudo launchctl unload -F /Library/LaunchDaemons/com.run_script_on_boot.plist
	sudo rm -f /Library/LaunchDaemons/com.run_script_on_boot.plist
	sudo rm -f /Library/Scripts/run_on_login_as_root.sh
}
#uninstall_run_on_boot

echo "done"
