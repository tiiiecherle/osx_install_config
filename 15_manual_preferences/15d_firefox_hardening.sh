#!/bin/bash

read -p "do you want to Harden only or completely Reset and then harden firefox (H/r)? " CONT1
CONT1="$(echo "$CONT1" | tr '[:upper:]' '[:lower:]')"    # tolower

if [[ "$CONT1" == "r" || "$CONT1" == "reset" ]]
then
	FIREFOX_PROFILE_PATH=$(find "/Users/""$USER""/Library/Application Support/Firefox/" -name "*.default")
	# bookmarks
	if [[ -e "$FIREFOX_PROFILE_PATH" ]]
	then
		# bookmarks
		mv "$FIREFOX_PROFILE_PATH"/places.sqlite /tmp/places.sqlite
		# show bookmark bar
		mv "$FIREFOX_PROFILE_PATH"/xulstore.json /tmp/xulstore.json
		# extensions
		mv "$FIREFOX_PROFILE_PATH"/extensions /tmp/extensions
		mv "$FIREFOX_PROFILE_PATH"/extensions.json /tmp/extensions.json
		mv "$FIREFOX_PROFILE_PATH"/browser-extension-data /tmp/browser-extension-data
	else
		:
	fi
	if [[ -e "/Users/""$USER""/Library/Application Support/Firefox" ]]
	then
		rm -rf "/Users/""$USER""/Library/Application Support/Firefox"
	else
		:
	fi
	#
	/Applications/Firefox.app/Contents/MacOS/firefox -CreateProfile default
	FIREFOX_PROFILE_PATH=$(find "/Users/""$USER""/Library/Application Support/Firefox" -name "*.default")
	if [[ -e /tmp/places.sqlite ]]
	then
		mv /tmp/places.sqlite "$FIREFOX_PROFILE_PATH"/places.sqlite
		# clear history
		sqlite3 "$FIREFOX_PROFILE_PATH"/places.sqlite "DELETE FROM moz_historyvisits;"
		#
		mv /tmp/xulstore.json "$FIREFOX_PROFILE_PATH"/xulstore.json
		mv /tmp/extensions "$FIREFOX_PROFILE_PATH"/extensions
		mv /tmp/extensions.json "$FIREFOX_PROFILE_PATH"/extensions.json
		mv /tmp/browser-extension-data "$FIREFOX_PROFILE_PATH"/browser-extension-data
	    find "$FIREFOX_PROFILE_PATH" -type f -print0 | xargs -0 chmod 644
		find "$FIREFOX_PROFILE_PATH" -type d -print0 | xargs -0 chmod 700
		chown -R $USER:staff "$FIREFOX_PROFILE_PATH"/*
	else
		:
	fi
else
    :
fi

# hardening
FIREFOX_PROFILE_PATH=$(find "/Users/""$USER""/Library/Application Support/Firefox" -name "*.default")
curl https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js > "$FIREFOX_PROFILE_PATH"/user.js
chown $USER:staff "$FIREFOX_PROFILE_PATH"/user.js
chmod 644 "$FIREFOX_PROFILE_PATH"/user.js

# custom options
echo '' >> "$FIREFOX_PROFILE_PATH"/user.js
# start with default:blank
echo "// more custom options" >> "$FIREFOX_PROFILE_PATH"/user.js
if [[ $(cat "$FIREFOX_PROFILE_PATH"/user.js | grep "^user_pref.*browser.startup.page.*") == "" ]]
then
	echo 'user_pref("browser.startup.page", 0);' >> "$FIREFOX_PROFILE_PATH"/user.js
else
	sed -i '' 's|^user_pref.*browser.startup.page.*|user_pref("browser.startup.page", 0);|' "$FIREFOX_PROFILE_PATH"/user.js
fi
# theme light
if [[ $(cat "$FIREFOX_PROFILE_PATH"/user.js | grep "^user_pref.*lightweightThemes.selectedThemeID.*") == "" ]]
then
	echo 'user_pref("lightweightThemes.selectedThemeID", "firefox-compact-light@mozilla.org");' >> "$FIREFOX_PROFILE_PATH"/user.js
else
	sed -i '' 's|^user_pref.*lightweightThemes.selectedThemeID.*|user_pref("lightweightThemes.selectedThemeID", "firefox-compact-light@mozilla.org");|' "$FIREFOX_PROFILE_PATH"/user.js
fi
# enabling using extensions
# otherwise the extension gallery thinks the brwoser has a lower version and some extensions won`t work
if [[ $(cat "$FIREFOX_PROFILE_PATH"/user.js | grep "^user_pref.*privacy.resistFingerprinting.*") == "" ]]
then
	echo 'user_pref("privacy.resistFingerprinting", false);' >> "$FIREFOX_PROFILE_PATH"/user.js
else
	sed -i '' 's|^user_pref.*privacy.resistFingerprinting.*|user_pref("privacy.resistFingerprinting", false);|' "$FIREFOX_PROFILE_PATH"/user.js
fi

# user_pref("privacy.donottrackheader.enabled", true);



echo ''
echo "done ;)"
