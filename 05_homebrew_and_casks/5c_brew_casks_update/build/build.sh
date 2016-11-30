#!/bin/bash

BREW_CASKS_UPDATE_VERSIONS=(
"brew_casks_update"
)

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
SCRIPTS_FINAL_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && cd .. && pwd)")

for BREW_CASKS_UPDATE_VERSION in "${BREW_CASKS_UPDATE_VERSIONS[@]}";
do

	echo ''
	printf "\033[1m%s\033[00m %s\n" "processing $BREW_CASKS_UPDATE_VERSION"
	# setting icons
	chmod 770 "$SCRIPT_DIR"/icons/icon_set.py
	"$SCRIPT_DIR"/icons/icon_set.py "$SCRIPT_DIR"/icons/brew_casks_update.icns "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app
	cp -a "$SCRIPT_DIR"/icons/brew_casks_update.icns "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app/Contents/Resources/applet.icns
	
	echo copying content to app and setting permissions...
	# .app final configuration
	mkdir -p "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app/custom_files
	cp -a "$SCRIPT_DIR"/bash/"$BREW_CASKS_UPDATE_VERSION".sh "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app/custom_files/
	cp -a "$SCRIPT_DIR"/icons/brew_casks_update.icns "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app/custom_files/
	chown 501:admin "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app
	chown -R 501:admin "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app/custom_files/
	chmod 755 "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app
	chmod 770 "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app/custom_files/"$BREW_CASKS_UPDATE_VERSION".sh
	chmod 770 "$SCRIPT_DIR"/dmg/"$BREW_CASKS_UPDATE_VERSION"/run_to_install
	
	# this is to suppress warning on first start
	#echo opening app...
	#open "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app
		
	echo copying app to dmg...
	#cp -a "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app /Applications/
	mkdir -p "$SCRIPT_DIR"/dmg/"$BREW_CASKS_UPDATE_VERSION"/
	if [ -e "$SCRIPT_DIR"/dmg/"$BREW_CASKS_UPDATE_VERSION"/app/"$BREW_CASKS_UPDATE_VERSION".app ]
	then
		rm -rf "$SCRIPT_DIR"/dmg/"$BREW_CASKS_UPDATE_VERSION"/app/"$BREW_CASKS_UPDATE_VERSION".app
	else
		:
	fi
	cp -a "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app "$SCRIPT_DIR"/dmg/"$BREW_CASKS_UPDATE_VERSION"/app/"$BREW_CASKS_UPDATE_VERSION".app
	
	echo copying app to backup script dir...
	mkdir -p "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_homebrew
	cp -a "$SCRIPT_DIR"/app/"$BREW_CASKS_UPDATE_VERSION".app "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_homebrew/"$BREW_CASKS_UPDATE_VERSION".app
	
	echo building dmg...
	if [ -e "$SCRIPT_DIR"/"$BREW_CASKS_UPDATE_VERSION".dmg ]
	then
		rm "$SCRIPT_DIR"/"$BREW_CASKS_UPDATE_VERSION".dmg
	else
		:
	fi
	
	# non writable dmg
	hdiutil create -volname "$BREW_CASKS_UPDATE_VERSION" -srcfolder "$SCRIPT_DIR"/dmg/"$BREW_CASKS_UPDATE_VERSION"/ -ov -format UDZO "$SCRIPT_DIR"/"$BREW_CASKS_UPDATE_VERSION".dmg


done

echo ''
echo "done ;)"
echo ''
