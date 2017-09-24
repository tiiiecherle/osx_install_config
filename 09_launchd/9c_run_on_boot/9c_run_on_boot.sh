#!/bin/bash

###
### launchd & applescript to do things on every boot after user login
###

### installation should be done via restore script after first install

# copy to /Users/"$USER"/Library/LaunchAgents/com.run_script_on_boot.plist
# chown "$USER":staff /Users/"$USER"/Library/LaunchAgents/com.run_script_on_boot.plist
# chmod 600 /Users/"$USER"/Library/LaunchAgents/com.run_script_on_boot.plist

# the actual command that is run on boot is included in the respective .plist file

### enable script

# launchctl unload ~/Library/LaunchAgents/com.run_script_on_network_change.plist
launchctl load /Users/"$USER"/Library/LaunchAgents/com.run_script_on_boot.plist

echo "done"
