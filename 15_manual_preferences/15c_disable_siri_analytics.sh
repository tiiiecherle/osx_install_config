#!/bin/bash

# disable all siri analytics
# already done in system preferences script before but some apps seam to appear here later
for i in $(/usr/libexec/PlistBuddy -c "Print CSReceiverBundleIdentifierState" /Users/$USER/Library/Preferences/com.apple.corespotlightui.plist | grep " = " | sed -e 's/^[ \t]*//' | awk '{print $1}')
do
        #echo $i
	    /usr/libexec/PlistBuddy -c "Set CSReceiverBundleIdentifierState:$i false" /Users/$USER/Library/Preferences/com.apple.corespotlightui.plist
done

echo ''
echo "the changes need a reboot to take effect"
echo ''
echo "done ;)"
