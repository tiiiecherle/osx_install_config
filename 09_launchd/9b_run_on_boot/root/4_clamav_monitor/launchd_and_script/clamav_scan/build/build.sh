#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### build
###

APP_NAME_VERSIONS=(
"clamav_scan"
)

SCRIPTS_FINAL_DIR="$SCRIPT_DIR_THREE_BACK"
BUILD_DIR="$SCRIPT_DIR_ONE_BACK"
	
for APP_NAME in "${APP_NAME_VERSIONS[@]}"
do

	echo ''
	printf "\033[1m%s\033[00m %s\n" "processing $APP_NAME"
	echo ''
	
	# icon name
	if [[ -e "$BUILD_DIR"/icons/"$APP_NAME".icns ]]
	then
		ICON_NAME="$APP_NAME"
	else
		ICON_NAME=$(find "$BUILD_DIR"/icons -maxdepth 1 -mindepth 1 -type f -name "*.icns")
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
	if [[ -e "$BUILD_DIR"/shell_script/"$APP_NAME".sh ]]
	then
		SCRIPT_NAME="$APP_NAME"
	else
		SCRIPT_NAME=$(find "$BUILD_DIR"/shell_script -maxdepth 1 -mindepth 1 -type f -name "*.sh")
		if [[ $(echo "$SCRIPT_NAME" | wc -l | awk '{print $1}') != "1" ]]
		then
			echo "SCRIPT_NAME is not set correctly, exiting..."
			exit
		else
			SCRIPT_NAME=$(basename "$SCRIPT_NAME" .sh)
		fi
	fi
	echo "SCRIPT_NAME is "$SCRIPT_NAME"..."
	
	# checking dependencies
	for i in brew $(brew --prefix)/bin/python3
	do
		if command -v "$i" &> /dev/null
    	then
    		# installed
    		:
    	else
    		echo ''
    		echo ""$i" is not installed, exiting..."
    		echo ''
    		exit
    	fi
    done
    
	echo ''
	# setting icons
	PATH_TO_ICON="$BUILD_DIR"/icons/"$ICON_NAME".icns
	PATH_TO_OBJECT_TO_SET_ICON_FOR="$BUILD_DIR"/app/"$APP_NAME".app
	echo "$APP_NAME".app
	env_set_custom_icon
	
	# done app
	echo ''
	PATH_TO_OBJECT_TO_SET_ICON_FOR="$BUILD_DIR"/done/"$APP_NAME"_done.app
	echo "$APP_NAME"_done.app
	env_set_custom_icon
	
	# found app
	echo ''
	PATH_TO_OBJECT_TO_SET_ICON_FOR="$BUILD_DIR"/found/"$APP_NAME"_found.app
	echo "$APP_NAME"_found.app
	env_set_custom_icon
	
	# stopped app
	echo ''
	PATH_TO_OBJECT_TO_SET_ICON_FOR="$BUILD_DIR"/stopped/"$APP_NAME"_stopped.app
	echo "$APP_NAME"_stopped.app
	env_set_custom_icon
	
	echo ''
	echo copying content to app and setting permissions...
	# .app final configuration
	mkdir -p "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files
	cp -a "$BUILD_DIR"/shell_script/"$SCRIPT_NAME".sh "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/
	cp -a "$BUILD_DIR"/icons/"$ICON_NAME".icns "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/
	# done, found and stopped app
	cp -a "$BUILD_DIR"/done/"$APP_NAME"_done.app "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/
	cp -a "$BUILD_DIR"/found/"$APP_NAME"_found.app "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/
	cp -a "$BUILD_DIR"/stopped/"$APP_NAME"_stopped.app "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/
	chown $(id -u "$USER"):admin "$BUILD_DIR"/app/"$APP_NAME".app
	chown -R $(id -u "$USER"):admin "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/
	chmod 755 "$BUILD_DIR"/app/"$APP_NAME".app
	chmod 755 "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/"$APP_NAME"_done.app
	chmod 755 "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/"$APP_NAME"_found.app
	chmod 755 "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/"$APP_NAME"_stopped.app
	chmod 770 "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/"$SCRIPT_NAME".sh
	# https://developer.apple.com/library/archive/qa/qa1940/_index.html
	#xattr -cr "$BUILD_DIR"/app/"$APP_NAME".app
	if [[ $(xattr -l "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/"$SCRIPT_NAME".sh | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$BUILD_DIR"/app/"$APP_NAME".app/Contents/custom_files/"$SCRIPT_NAME".sh
    else
        :
    fi
	if [[ $(xattr -l "$BUILD_DIR"/app/"$APP_NAME".app | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$BUILD_DIR"/app/"$APP_NAME".app
    else
        :
    fi
    
	# this is to suppress warning on first start
	#echo opening app...
	#open "$BUILD_DIR"/app/"$APP_NAME".app
	
	echo copying app to dmg...
	#cp -a "$BUILD_DIR"/app/"$APP_NAME".app "$PATH_TO_APPS"/
	mkdir -p "$BUILD_DIR"/dmg/"$APP_NAME"/
	if [[ -e "$BUILD_DIR"/dmg/"$APP_NAME"/app/"$APP_NAME".app ]]
	then
		rm -rf "$BUILD_DIR"/dmg/"$APP_NAME"/app/"$APP_NAME".app
	else
		:
	fi
	cp -a "$BUILD_DIR"/app/"$APP_NAME".app "$BUILD_DIR"/dmg/"$APP_NAME"/app/"$APP_NAME".app
	chmod 770 "$BUILD_DIR"/dmg/"$APP_NAME"/run_to_install.command
	if [[ $(xattr -l "$BUILD_DIR"/dmg/"$APP_NAME"/run_to_install.command | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$BUILD_DIR"/dmg/"$APP_NAME"/run_to_install.command
    else
        :
    fi
    if [[ $(xattr -l "$BUILD_DIR"/dmg/"$APP_NAME"/install_script/install.sh | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$BUILD_DIR"/dmg/"$APP_NAME"/install_script/install.sh
    else
        :
    fi
		
	echo building dmg...
	if [[ -e "$BUILD_DIR"/"$APP_NAME".dmg ]]
	then
		rm "$BUILD_DIR"/"$APP_NAME".dmg
	else
		:
	fi
	
	# non writable dmg
	hdiutil create -volname "$APP_NAME" -srcfolder "$BUILD_DIR"/dmg/"$APP_NAME"/ -ov -format UDZO "$BUILD_DIR"/"$APP_NAME".dmg

done

echo ''
echo "done ;)"
echo ''
