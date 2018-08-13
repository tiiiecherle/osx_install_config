#!/bin/bash

###
### launchd & applescript to do things on every boot after user login
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

### installation should be done via restore script after first install
rm -f /Users/"$USER"/Library/LaunchAgents/com.run_script_on_boot.plist
cp -a "$SCRIPT_DIR"/install_files/com.run_script_on_boot.plist /Users/"$USER"/Library/LaunchAgents/com.run_script_on_boot.plist
chown "$USER":staff ~/Library/LaunchAgents/com.run_script_on_boot.plist
chmod 640 ~/Library/LaunchAgents/com.run_script_on_boot.plist

# the actual command that is run on boot is included in the respective .plist file

### enable launchd agent
launchctl unload -F ~/Library/LaunchAgents/com.run_script_on_boot.plist
launchctl load -F ~/Library/LaunchAgents/com.run_script_on_boot.plist

### uninstall
uninstall_run_on_boot() {
	launchctl unload -F ~/Library/LaunchAgents/com.run_script_on_boot.plist
	rm -f ~/Library/LaunchAgents/com.run_script_on_boot.plist
}
#uninstall_run_on_boot

echo "done"
