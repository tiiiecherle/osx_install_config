#!/bin/zsh

### documentation
# https://apple.stackexchange.com/questions/344278/how-can-i-disable-the-red-software-update-notification-bubble-on-the-system-pref
# defaults read com.apple.systempreferences AttentionPrefBundleIDs


### delete all entries
#defaults delete com.apple.systempreferences AttentionPrefBundleIDs
#killall Dock


### set value for specific entry
# macos 10.15 displays a red dot notification if icloud is not used
# "com.apple.preferences.AppleIDPrefPane" = 1;
defaults write com.apple.systempreferences AttentionPrefBundleIDs -dict-add com.apple.preferences.AppleIDPrefPane -integer 0

# macos 10.14 displays a red dot notification if 10.15 is available
# reaaperas after search for new software in gui
# "com.apple.preferences.softwareupdate" = 1;
#defaults write com.apple.systempreferences AttentionPrefBundleIDs -dict-add com.apple.preferences.softwareupdate -integer 0
#/usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.systempreferences.plist -c 'Delete AttentionPrefBundleIDs:com.apple.preferences.softwareupdate'
#killall Dock


### activating changes
killall Dock