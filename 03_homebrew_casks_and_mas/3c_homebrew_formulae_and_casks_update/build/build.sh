#!/bin/bash

APP_NAME_VERSIONS=(
"brew_casks_update"
)

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd)")
SCRIPTS_FINAL_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && cd .. && cd .. && cd .. && pwd)")
	
for APP_NAME in "${APP_NAME_VERSIONS[@]}";
do
	echo ''
	printf "\033[1m%s\033[00m %s\n" "processing $APP_NAME"
	echo ''
	
	# icon name
	if [[ -e "$SCRIPT_DIR"/icons/"$APP_NAME".icns ]]
	then
		ICON_NAME="$APP_NAME"
	else
		ICON_NAME=$(find "$SCRIPT_DIR"/icons -maxdepth 1 -mindepth 1 -type f -name "*.icns")
		if [[ $(echo "$ICON_NAME" | wc -l | awk '{print $1}') != "1" ]]
		then
			echo "ICON_NAME is not set correctly, exiting..."
			exit
		else
			ICON_NAME=$(basename "$ICON_NAME" .icns)
		fi
	fi
	echo "ICON_NAME is "$ICON_NAME"..."
	
	# script name
	if [[ -e "$SCRIPT_DIR"/shell_script/"$APP_NAME".sh ]]
	then
		SCRIPT_NAME="$APP_NAME"
	else
		SCRIPT_NAME=$(find "$SCRIPT_DIR"/shell_script -maxdepth 1 -mindepth 1 -type f -name "*.sh")
		if [[ $(echo "$SCRIPT_NAME" | wc -l | awk '{print $1}') != "1" ]]
		then
			echo "SCRIPT_NAME is not set correctly, exiting..."
			exit
		else
			SCRIPT_NAME=$(basename "$SCRIPT_NAME" .sh)
		fi
	fi
	echo "SCRIPT_NAME is "$SCRIPT_NAME"..."
	
	echo ''
	# setting icons
	chmod 770 "$SCRIPT_DIR"/icons/icon_set_python3.py
	#sudo pip install pyobjc
	pip3 install pyobjc-framework-Cocoa
	python3 "$SCRIPT_DIR"/icons/icon_set_python3.py "$SCRIPT_DIR"/icons/"$ICON_NAME".icns "$SCRIPT_DIR"/app/"$APP_NAME".app
	cp -a "$SCRIPT_DIR"/icons/"$ICON_NAME".icns "$SCRIPT_DIR"/app/"$APP_NAME".app/Contents/Resources/applet.icns
	
	echo copying content to app and setting permissions...
	# .app final configuration
	mkdir -p "$SCRIPT_DIR"/app/"$APP_NAME".app/custom_files
	cp -a "$SCRIPT_DIR"/shell_script/"$SCRIPT_NAME".sh "$SCRIPT_DIR"/app/"$APP_NAME".app/custom_files/
	cp -a "$SCRIPT_DIR"/icons/"$ICON_NAME".icns "$SCRIPT_DIR"/app/"$APP_NAME".app/custom_files/
	chown 501:admin "$SCRIPT_DIR"/app/"$APP_NAME".app
	chown -R 501:admin "$SCRIPT_DIR"/app/"$APP_NAME".app/custom_files/
	chmod 755 "$SCRIPT_DIR"/app/"$APP_NAME".app
	chmod 770 "$SCRIPT_DIR"/app/"$APP_NAME".app/custom_files/"$SCRIPT_NAME".sh
	chmod 770 "$SCRIPT_DIR"/dmg/"$APP_NAME"/run_to_install.command
	
	# this is to suppress warning on first start
	#echo opening app...
	#open "$SCRIPT_DIR"/app/"$APP_NAME".app
		
	echo copying app to dmg...
	#cp -a "$SCRIPT_DIR"/app/"$APP_NAME".app /Applications/
	mkdir -p "$SCRIPT_DIR"/dmg/"$APP_NAME"/
	if [ -e "$SCRIPT_DIR"/dmg/"$APP_NAME"/app/"$APP_NAME".app ]
	then
		rm -rf "$SCRIPT_DIR"/dmg/"$APP_NAME"/app/"$APP_NAME".app
	else
		:
	fi
	cp -a "$SCRIPT_DIR"/app/"$APP_NAME".app "$SCRIPT_DIR"/dmg/"$APP_NAME"/app/"$APP_NAME".app
	
	echo "copying app to backup script dir..."
	mkdir -p "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_homebrew
	if [ -e "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_homebrew/"$APP_NAME".app ]
	then
		rm -rf "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_homebrew/"$APP_NAME".app
	else
		:
	fi
	cp -a "$SCRIPT_DIR"/app/"$APP_NAME".app "$SCRIPTS_FINAL_DIR"/07_backup_and_restore_script/update_homebrew/"$APP_NAME".app
	
	echo building dmg...
	if [ -e "$SCRIPT_DIR"/"$APP_NAME".dmg ]
	then
		rm "$SCRIPT_DIR"/"$APP_NAME".dmg
	else
		:
	fi
	
	# non writable dmg
	hdiutil create -volname "$APP_NAME" -srcfolder "$SCRIPT_DIR"/dmg/"$APP_NAME"/ -ov -format UDZO "$SCRIPT_DIR"/"$APP_NAME".dmg


done

echo ''
echo "done ;)"
echo ''
