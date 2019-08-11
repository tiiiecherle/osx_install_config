#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### restoring files
###

if [[ "$USER" == "tom" ]];
then

    BACKUPDIRS=(
    "/Users/$USER/Pictures"
    "/Users/$USER/Music"
    "/Users/$USER/Desktop/desktop"
    "/Users/$USER/Desktop/backup"
    "/Users/$USER/github"
    "/Users/$USER/Desktop/files"
    "/Users/$USER/Documents"
    "/Users/$USER/Library/Application Support/MobileSync"
    )

else
    :
fi

if [[ "$USER" == "bobby" ]];
then

    BACKUPDIRS=(
    "/Users/$USER/Pictures"
    "/Users/$USER/Music"
    "/Users/$USER/Desktop/desktop"
    "/Users/$USER/_WS_IMAC"
    "/Users/$USER/Eigene_Dateien_wsmac"
    "/Users/$USER/Documents"
    "/Users/$USER/Downloads"
    "/Users/$USER/Library/Application Support/MobileSync"
    )

else
    :
fi

while IFS= read -r line || [[ -n "$line" ]]
do
    LINENUMBER=$((LINENUMBER+1))
    if [[ "$line" == "" ]]; then continue; fi
    line="$line"
    #echo "$line"
    DIRNAME_LINE=$(dirname "$line")
    #echo DIRNAME_LINE is "$DIRNAME_LINE"
    BASENAME_LINE=$(basename "$line")
    #echo BASENAME_LINE is "$BASENAME_LINE"
    echo "$BASENAME_LINE"
    if [[ -L "$line" ]]
    then
    	# is symlink
    	echo ""$line" is a symlink, skipping restore..."
    else
    	# not a symlink
    	mkdir -p "$line"
    	if [[ -e "$line" ]] && [[ -e "$SCRIPT_DIR"/"$BASENAME_LINE" ]]
    	then
    		echo "restoring "$line"..."
    		if find "$line" -mindepth 1 -maxdepth 1 ! -name ".localized" ! -name ".DS_Store" | read
            then
                # not empy
                rm -rf "$line"/*
            else
                # empty
                :
            fi
    		mv -f /"$SCRIPT_DIR"/"$BASENAME_LINE"/* "$line"/
    		#cp -a /"$SCRIPT_DIR"/"$BASENAME_LINE"/* "$line"/
    	else
    		echo "source or destination does not exist, skipping..."
    	fi
    fi
	# cleaning up
    if [[ -e "$SCRIPT_DIR"/"$BASENAME_LINE" ]]
	then
	    echo "cleaning up "$SCRIPT_DIR"/"$BASENAME_LINE"..."
	    rm -rf "$SCRIPT_DIR"/"$BASENAME_LINE"
	else
	    :
	fi
    echo ''
done <<< "$(printf "%s\n" "${BACKUPDIRS[@]}")"

# moving old desktop
if [[ -e "/Users/"$USER"/Desktop/desktop/_current" ]]
then
    if [[ -e "/Users/"$USER"/Desktop/desktop_old" ]]; then rm -rf "/Users/"$USER"/Desktop/desktop_old"; fi
    mv "/Users/"$USER"/Desktop/desktop/_current" "/Users/"$USER"/Desktop/desktop_old"
else
    :
fi

#echo ''
echo "done ;)"
echo ''
