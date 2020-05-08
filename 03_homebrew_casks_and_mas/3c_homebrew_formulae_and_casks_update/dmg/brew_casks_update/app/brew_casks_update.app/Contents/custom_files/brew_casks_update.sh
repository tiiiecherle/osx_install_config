#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

if [[ -e /tmp/tmp_backup_script_fifo2 ]]
then
    delete_tmp_backup_script_fifo2() {
        if [[ -e "/tmp/tmp_backup_script_fifo2" ]]
        then
            rm "/tmp/tmp_backup_script_fifo2"
        else
            :
        fi
    }
    unset SUDOPASSWORD
    SUDOPASSWORD=$(cat "/tmp/tmp_backup_script_fifo2" | head -n 1)
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    delete_tmp_backup_script_fifo2
    set +a
    env_sudo
else
    env_enter_sudo_password
fi



###
### functions
###

number_of_parallel_processes() {
    NUMBER_OF_CORES=$(parallel --number-of-cores)
    NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 2.5" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
    NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED=$(echo "$NUMBER_OF_MAX_JOBS_ROUNDED * 2.0" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED
    NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED_ROUNDED
}

cleanup_formulae() { 
    if [[ ! -s "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS" ]]
    then
    	# file is empty or does not exist
    	:
    else
    	# file exists and is not empty
        sort "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS" -o "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
    
        while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
            FORMULA=$(echo "$line" | awk '{print $2}')
            #echo ''
        	#echo "$(echo "$line" | awk '{print $1}') versions of $FORMULA are installed..."
        	#echo "uninstalling all outdated versions..."
        	if [[ -e "$BREW_FORMULAE_PATH"/"$FORMULA" ]]
        	then
        	    # uninstall old versions
                local FORMULA_INFO=$(brew info --json=v1 "$FORMULA" | jq '.[]')
                local FORMULA_NAME=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.name')
                local FORMULA_REVISION=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.revision')
                if [[ "$FORMULA_REVISION" == "0" ]]
                then
                    #local NEW_VERSION=$(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')
                    local NEW_VERSION=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.versions.stable')
                else
                    #local NEW_VERSION=$(echo $(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')_"$FORMULA_REVISION")
                    local NEW_VERSION=$(echo $(printf '%s\n' "$FORMULA_INFO" | jq -r '.versions.stable')_"$FORMULA_REVISION")
                fi
        	    local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
        	    local NEWEST_INSTALLED_VERSION=$(printf '%s\n' "$INSTALLED_VERSIONS" | tail -n 1)
        	    #local VERSIONS_TO_UNINSTALL=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -v "$NEW_VERSION")
        	    # alternatively always keep latest version installed and not the latest version from homebrew
        	    local VERSIONS_TO_UNINSTALL=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -v "$NEWEST_INSTALLED_VERSION")
        	    for i in $VERSIONS_TO_UNINSTALL
                do
                    #echo $i
                    # deleting version entry
                    if [[ -e "$BREW_FORMULAE_PATH"/"$FORMULA"/"$i" && $(printf '%s\n' "$i") != "" ]]
                    then
                        rm -rf "$BREW_FORMULAE_PATH"/"$FORMULA"/"$i"
                    else
                        :
                    fi
                    # deleting metadata version entry
                    if [[ -e "$BREW_FORMULAE_PATH"/"$FORMULA"/.metadata/"$i" && $(printf '%s\n' "$i") != "" ]]
                    then
                        rm -rf "$BREW_FORMULAE_PATH"/"$FORMULA"/.metadata/"$i"
                    else
                        :
                    fi
                done
        	else
        	    :
        	fi
        done <<< "$(cat "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS")"
    fi

    # checking if more than version is installed by using
    # brew list --versions

}

cleanup_casks() {
    if [[ ! -s "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS" ]]
    then
    	# file is empty or does not exist
    	:
    else
    	# file exists and is not empty    
        sort "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS" -o "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
    
        while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
            CASK=$(echo "$line" | awk '{print $2}')
            #echo ''
        	#printf '%s\n' "$(printf '%s\n' "$line" | awk '{print $1}') versions of $CASK are installed..."
        	#echo "uninstalling all outdated versions..."
        	if [[ -e "$BREW_CASKS_PATH"/"$CASK" ]]
        	then
        	    # uninstall old versions
                local CASK_INFO=$(brew cask info --json=v1 "$CASK" | jq '.[]')
                #local CASK_INFO=$(brew cask info "$CASK")
                local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
                #local CASK_NAME=$(printf '%s\n' "$CASK" | cut -d ":" -f1 | xargs)
                local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | jq -r '.version')
                #local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | head -1 | sed 's|(auto_updates)||g' | sed 's/^ *//' | sed 's/ *$//')
        	    local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
        	    local NEWEST_INSTALLED_VERSION=$(printf '%s\n' "$INSTALLED_VERSIONS" | head -n 1)
        	    #local NEWEST_INSTALLED_VERSION="$NEW_VERSION"
        	    # alternatively always keep latest version installed and not the latest version from homebrew
        	    local VERSIONS_TO_UNINSTALL=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -v "$NEWEST_INSTALLED_VERSION")
                while IFS= read -r line || [[ -n "$line" ]]
				do
				    if [[ "$line" == "" ]]; then continue; fi
                    i="$line"
                    #echo $i
                    # deleting version entry
                    if [[ -e "$BREW_CASKS_PATH"/"$CASK"/"$i" && $(printf '%s\n' "$i") != "" ]]
                    then
                        rm -rf "$BREW_CASKS_PATH"/"$CASK"/"$i"
                    else
                        :
                    fi
                    # deleting metadata version entry
                    if [[ -e "$BREW_CASKS_PATH"/"$CASK"/.metadata/"$i" && $(printf '%s\n' "$i") != "" ]]
                    then
                        rm -rf "$BREW_CASKS_PATH"/"$CASK"/.metadata/"$i"
                    else
                        :
                    fi
                done <<< "$(printf "%s\n" "${VERSIONS_TO_UNINSTALL[@]}")"
                
                # special actions on some casks
                if [[ "$CASK" == "adoptopenjdk" ]] || [[ "$CASK" == "java" ]]
                then
                    JAVA_CHECK_DIR="/Library/Java/JavaVirtualMachines"
                    LATEST_INSTALLED_JAVA_VERSION=$(ls -1 "$JAVA_CHECK_DIR" | sort -V | tail -n 1)
                    JAVA_VERSIONS_TO_UNINSTALL=$(ls -1 "$JAVA_CHECK_DIR" | grep -v "$LATEST_INSTALLED_JAVA_VERSION")
                    NUMBER_OF_JAVA_VERSIONS_TO_UNINSTALL=$(echo $JAVA_VERSIONS_TO_UNINSTALL | wc -l | awk '{print $1}')
                    #printf '%s\n' "$NUMBER_OF_JAVA_VERSIONS_TO_UNINSTALL"
                    if [[ "$NUMBER_OF_JAVA_VERSIONS_TO_UNINSTALL" -ge "1" ]]
                    then
                        echo "cleaning old java versions..."
                        while IFS= read -r line || [[ -n "$line" ]]
						do
						    if [[ "$line" == "" ]]; then continue; fi
                            OLD_JAVA_VERSION="$line"
                            if [[ -e "$JAVA_CHECK_DIR"/"$OLD_JAVA_VERSION" ]]
                            then
                                #printf '%s\n' "$OLD_JAVA_VERSION"
                                sudo rm -rf "$JAVA_CHECK_DIR"/"$OLD_JAVA_VERSION"
                            else
                                :
                            fi
                        done <<< "$(printf "%s\n" "${JAVA_VERSIONS_TO_UNINSTALL[@]}")"
                    else
                        :
                        #echo "no entries..."
                    fi
                else
                    :
                fi

        	else
        	    :
        	fi
        done <<< "$(cat "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS")"
    fi

    # checking if more than version is installed by using
    # brew cask list --versions
    
}

formulae_show_updates_parallel() {
    # always use _ instead of - because some sh commands called by parallel would give errors

    echo "listing brew formulae updates..."
    
    printf '\n'
    #printf '=%.0s' {1..80}
    # this does not work as printf does not know about the escape characters and interprets wrong column sizes
    # use tput instead
    # HEAD_COLUMN1=$(echo -e "\033[1mcask\033[0m")
    HEAD_COLUMN1=$(echo "formula")
    HEAD_COLUMN2=$(echo "installed")
    HEAD_COLUMN3=$(echo "latest")
    HEAD_COLUMN4=$(echo '  result')
    tput bold; printf "%+7s %-2s %-22s %-17s %-17s %-10s\n" "" "" "$HEAD_COLUMN1" "$HEAD_COLUMN2" "$HEAD_COLUMN3" "$HEAD_COLUMN4"; tput sgr0
    #printf '=%.0s' {1..80}
    #printf '\n'
    
    TMP_DIR_FORMULAE=/tmp/formulae_updates
    export TMP_DIR_FORMULAE

    # update formulae preparation
    if [[ -e "$TMP_DIR_FORMULAE" ]]
    then
        if [[ "$(ls -A $TMP_DIR_FORMULAE/)" ]]
        then
            rm "$TMP_DIR_FORMULAE"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p "$TMP_DIR_FORMULAE"/
    DATE_LIST_FILE_FORMULAE=$(echo "brew_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_FORMULAE
    touch "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE"

    # cleanup formulae preparation
    TMP_DIR_FORMULAE_VERSIONS=/tmp/formulae_versions
    export TMP_DIR_FORMULAE_VERSIONS
    if [[ -e "$TMP_DIR_FORMULAE_VERSIONS" ]]
    then
        if [[ "$(ls -A $TMP_DIR_FORMULAE_VERSIONS/)" ]]
        then
            rm "$TMP_DIR_FORMULAE_VERSIONS"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p "$TMP_DIR_FORMULAE_VERSIONS"/
    DATE_LIST_FILE_FORMULAE_VERSIONS=$(echo "formulae_versions"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_FORMULAE_VERSIONS
    touch "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"

    formulae_show_updates_parallel_inside() {
        # always use _ instead of - because some sh commands called by parallel would give errors
        local FORMULA="$1"
        #echo FORMULA is "$FORMULA"
        #local FORMULA_INFO=$(brew info $FORMULA)
        FORMULA_INFO=$(brew info --json=v1 "$FORMULA" | jq '.[]')
        #echo FORMULA_INFO is $FORMULA_INFO
        #local FORMULA_NAME=$(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f1 | sed 's/://g')
        local FORMULA_NAME=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.name')
        # getting value directly
        #local FORMULA_NAME=$(brew info --json=v1 $FORMULA | jq -r '.[].name')
        #echo FORMULA_NAME is $FORMULA_NAME
        # make sure you have jq installed via brew
        #local FORMULA_REVISION=$(brew info "$FORMULA" --json=v1 | jq . | grep revision | grep -o '[0-9]')
        local FORMULA_REVISION=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.revision')
        #echo FORMULA_REVISION is $FORMULA_REVISION
        if [[ "$FORMULA_REVISION" == "0" ]]
        then
            #local NEW_VERSION=$(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')
            local NEW_VERSION=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.versions.stable')
        else
            #local NEW_VERSION=$(echo $(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')_"$FORMULA_REVISION")
            local NEW_VERSION=$(echo $(printf '%s\n' "$FORMULA_INFO" | jq -r '.versions.stable')_"$FORMULA_REVISION")
        fi
        #echo NEW_VERSION is $NEW_VERSION
        local NUMBER_OF_INSTALLED_FORMULAE=$(printf '%s\n' "$INSTALLED_FORMULAE" | wc -l | sed 's/^ *//' | sed 's/ *$//')
        local NUMBER_OF_FORMULA=$(printf '%s\n' "$INSTALLED_FORMULAE" | grep -n "^$FORMULA$" | awk -F: '{print $1}' | sed 's/^ *//' | sed 's/ *$//')
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
        #echo INSTALLED_VERSIONS is "$INSTALLED_VERSIONS"
        local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
        #echo NUMBER_OF_INSTALLED_VERSIONS is "$NUMBER_OF_INSTALLED_VERSIONS"
        local NEWEST_INSTALLED_VERSION=$(printf '%s\n' "$INSTALLED_VERSIONS" | tail -n 1)
        #echo NEWEST_INSTALLED_VERSION is "$NEWEST_INSTALLED_VERSION"
        local CHECK_RESULT=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo ok || echo outdated)
        #echo CHECK_RESULT is $CHECK_RESULT
        local NAME_PRINT=$(printf '%s\n' "$FORMULA" | awk -v len=20 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local CURRENT_INSTALLED_VERSION_PRINT=$(printf '%s\n' "$NEWEST_INSTALLED_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        #local CURRENT_INSTALLED_VERSION_PRINT=$(printf '%s\n' "$NEWEST_INSTALLED_VERSION" | cut -d ":" -f1 | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local NEW_VERSION_PRINT=$(printf '%s\n' "$NEW_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        if [[ $CHECK_RESULT == "ok" ]]
        then
            CHECK_RESULT_PRINT=$(echo -e '\033[1;32m    ok\033[0m')
            #CHECK_RESULT_PRINT=$(echo -e '\033[1;31m outdated\033[0m')
        elif
            [[ $CHECK_RESULT == "outdated" ]]
        then
            CHECK_RESULT_PRINT=$(echo -e '\033[1;31m outdated\033[0m')
        else
            :
        fi
        # output
        printf "%+7s %-2s %-22s %-17s %-17s %-10s\n" "$NUMBER_OF_FORMULA/$NUMBER_OF_INSTALLED_FORMULAE" "  " "$NAME_PRINT" "$CURRENT_INSTALLED_VERSION_PRINT" "$NEW_VERSION_PRINT" "$CHECK_RESULT_PRINT"
                
        # installing if not up-to-date and not excluded
        if [[ "$CHECK_RESULT" == "outdated" ]] && [[ ${CASK_EXCLUDES} != *"$FORMULA"* ]]
        then
            echo "$FORMULA" >> "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE"
        fi
        
        # cleanup entries
        if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
        then
            echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$FORMULA" >> "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
        else
            :
        	#echo "only one version installed..."
        fi
        
    }
	# by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
    # it is not neccessary to export variables or functions when using env_parallel
    # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
    if [[ "$(brew list)" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "formulae_show_updates_parallel_inside {}" ::: "$(brew list)"; fi
        
    #echo "listing brew formulae updates finished ;)"
}

formulae_install_updates() {
    echo "installing brew formulae updates..."
    
    if [[ ! -s "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" ]]
    then
    	# file is empty or does not exist
    	echo "no formulae updates available..."
    else
    	# file exists and is not empty
        
        # sorting the outdated casks file after using parallel which can change output order
        sort "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" -o "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE"
            
        while IFS= read -r line || [[ -n "$line" ]]
		do
		    if [[ "$line" == "" ]]; then continue; fi
            FORMULA="$line"
            
            echo 'updating '"$FORMULA"'...'            
            if [[ $(brew outdated --quiet | grep "^$FORMULA$") == "" ]] && [[ $(brew outdated --quiet | grep "/$FORMULA$") == "" ]]
            #[[ $(brew outdated --verbose | grep "^$FORMULA[[:space:]]") == "" ]]
            then
                echo "$FORMULA"" already up-to-date..."
            else
                if [[ "$FORMULA" == "qtfaststart" ]]
                then
                    if [[ $(brew list | grep "^ffmpeg$") != "" ]]
                    then
                        brew unlink qtfaststart
                        brew unlink ffmpeg && brew link ffmpeg
                        brew link --overwrite qtfaststart
                    else
                        :
                    fi
                elif [[ "$FORMULA" == "^ffmpeg$" ]]
                then
                    if [[ $(brew list | grep "^qtfaststart$") != "" ]]
                    then
                        brew unlink ffmpeg
                        brew unlink qtfaststart && brew link qtfaststart
                        brew link --overwrite ffmpeg
                    else
                        :
                    fi
                else
                    :
                fi
                env_use_password | brew upgrade "$FORMULA"
                #
            fi
            echo 'removing old installed versions of '"$FORMULA"'...'
            env_use_password | brew cleanup "$FORMULA"
            echo ''
            
            # cleanup entries
            local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
            local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
            if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
            then
                echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$FORMULA" >> "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
            else
                :
            	#echo "only one version installed..."
            fi
        done <<< "$(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE")"
        
        # special ffmpeg
        # versions > 4.0.2_1 include h265 by default, so rebuilding does not seem to be needed any more
        if [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "ffmpeg") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "fdk-aac") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "sdl2") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "freetype") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "libass") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "libvorbis") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "libvpx") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "opus") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "x265") != "" ]]
        then
            #env_use_password | brew reinstall ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
            if [[ $(ffmpeg -codecs 2>&1 | grep "\-\-enable-libx265") == "" ]]
            then
                #echo "rebuilding ffmpeg due to components updates..."
                #env_use_password | HOMEBREW_DEVELOPER=1 brew reinstall --build-from-source ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
                :
            else
                :
            fi
        else
            :
        fi
        
        echo "installing formulae updates finished ;)"
        
    fi
}

# selectively upgrade casks
casks_show_updates_parallel() {
    # always use _ instead of - because some sh commands called by parallel would give errors
    echo "listing casks updates..."

    #printf '=%.0s' {1..80}
    printf '\n'
    # this does not work as printf does not know about the escape characters and interprets wrong column sizes
    # use tput instead
    # HEAD_COLUMN1=$(echo -e "\033[1mcask\033[0m")
    HEAD_COLUMN1=$(echo "cask")
    HEAD_COLUMN2=$(echo "installed")
    HEAD_COLUMN3=$(echo "latest")
    HEAD_COLUMN4=$(echo '  result')
    tput bold; printf "%+7s %-2s %-22s %-17s %-17s %-10s\n" "" "" "$HEAD_COLUMN1" "$HEAD_COLUMN2" "$HEAD_COLUMN3" "$HEAD_COLUMN4"; tput sgr0
    #printf '=%.0s' {1..80}
    #printf '\n'
    
    # update casks preparation
    TMP_DIR_CASK=/tmp/cask_updates
    export TMP_DIR_CASK
    if [[ -e "$TMP_DIR_CASK" ]]
    then
        if [[ "$(ls -A $TMP_DIR_CASK/)" ]]
        then
            rm "$TMP_DIR_CASK"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p "$TMP_DIR_CASK"/
    DATE_LIST_FILE_CASKS=$(echo "casks_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_CASKS
    touch "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
    
    # cleanup formulae preparation
    TMP_DIR_CASK_VERSIONS=/tmp/cask_versions
    export TMP_DIR_CASK_VERSIONS
    if [[ -e "$TMP_DIR_CASK_VERSIONS" ]]
    then
        if [[ "$(ls -A $TMP_DIR_CASK_VERSIONS/)" ]]
        then
            rm "$TMP_DIR_CASK_VERSIONS"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p "$TMP_DIR_CASK_VERSIONS"/
    DATE_LIST_FILE_CASKS_VERSIONS=$(echo "casks_versions"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_CASKS_VERSIONS
    touch "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
    
    casks_show_updates_parallel_inside() {
        # always use _ instead of - because some sh commands called by parallel would give errors
        local CASK="$1"
        local CASK_INFO=$(brew cask info --json=v1 "$CASK" | jq '.[]')
        #local CASK_INFO=$(brew cask info "$CASK")
        local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
        #local CASK_NAME=$(printf '%s\n' "$CASK" | cut -d ":" -f1 | xargs)
        local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | jq -r '.version')
        #local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | head -1 | sed 's|(auto_updates)||g' | sed 's/^ *//' | sed 's/ *$//')
        local NUMBER_OF_INSTALLED_CASKS=$(printf '%s\n' "$INSTALLED_CASKS" | wc -l | sed 's/^ *//' | sed 's/ *$//')
        local NUMBER_OF_CASK=$(printf '%s\n' "$INSTALLED_CASKS" | grep -n "^$CASK$" | awk -F: '{print $1}' | sed 's/^ *//' | sed 's/ *$//')
        local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
        #echo INSTALLED_VERSIONS is "$INSTALLED_VERSIONS"
        local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
        #echo NUMBER_OF_INSTALLED_VERSIONS is "$NUMBER_OF_INSTALLED_VERSIONS"
        local NEWEST_INSTALLED_VERSION=$(printf '%s\n' "$INSTALLED_VERSIONS" | head -n 1)
        #local NEWEST_INSTALLED_VERSION="$NEW_VERSION"
        #echo NEWEST_INSTALLED_VERSION is "$NEWEST_INSTALLED_VERSION"
        local CHECK_RESULT=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo ok || echo outdated)
        #echo CHECK_RESULT is $CHECK_RESULT
        local CASK_NAME_PRINT=$(printf '%s\n' "$CASK" | awk -v len=20 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local CURRENT_INSTALLED_VERSION_PRINT=$(printf '%s\n' "$NEWEST_INSTALLED_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        #local CURRENT_INSTALLED_VERSION_PRINT=$(printf '%s\n' "$NEWEST_INSTALLED_VERSION" | cut -d ":" -f1 | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local NEW_VERSION_PRINT=$(printf '%s\n' "$NEW_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        if [[ $CHECK_RESULT == "ok" ]]
        then
            CHECK_RESULT_PRINT=$(echo -e '\033[1;32m    ok\033[0m')
            #CHECK_RESULT_PRINT=$(echo -e '\033[1;31m outdated\033[0m')
        elif
            [[ $CHECK_RESULT == "outdated" ]]
        then
            CHECK_RESULT_PRINT=$(echo -e '\033[1;31m outdated\033[0m')
        else
            :
        fi
        printf "%+7s %-2s %-22s %-17s %-17s %-10s\n" "$NUMBER_OF_CASK/$NUMBER_OF_INSTALLED_CASKS" "  " "$CASK_NAME_PRINT" "$CURRENT_INSTALLED_VERSION_PRINT" "$NEW_VERSION_PRINT" "$CHECK_RESULT_PRINT"

        # installing if not up-to-date and not excluded
        if [[ "$CHECK_RESULT" == "outdated" ]] && [[ ${CASK_EXCLUDES} != *"$CASK"* ]]
        then
            echo "$CASK" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
        fi
        
        # cleanup entries
        if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
        then
            echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$CASK" >> "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
        else
            :
        	#echo "only one version installed..."
        fi
    	
    	if [[ "$CONT_LATEST" =~ ^(yes|y)$ ]]
        then
            if [[ "$NEW_VERSION" == "latest" ]] && [[ ${CASK_EXCLUDES} != *"$CASK"* ]]
            then
                echo "$CASK" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
            fi
        else
            :
        fi
                    
    }
	# by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
    # it is not neccessary to export variables or functions when using env_parallel
    # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
    if [[ "$(echo "$INSTALLED_CASKS")" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "casks_show_updates_parallel_inside {}" ::: "$(echo "$INSTALLED_CASKS")"; fi

    #echo "listing casks updates finished ;)"  
}

casks_install_updates() {
    echo "installing casks updates..."
    
    if [[ ! -s "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" ]]
    then
    	# file is empty or does not exist
        echo "no casks updates available..."
    else
    	# file exists and is not empty
    
        # virtualbox has to be updated before virtualbox-extension-pack
        # checking if there is an update for virtualbox-extension-pack available, deleting the line in the file and install it manually later
        # done by sorting the file after using parallel which can change output order
        #if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep virtualbox-extension-pack) == "" ]]
        #then
        #    VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE=no
        #else
        #    VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE=yes
        #    sed -i '' '/virtualbox-extension-pack/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
        #    sed -i '' '/virtualbox/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
        #fi
        #echo "$VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE"
        
        # sorting the outdated casks file after using parallel which can change output order
        sort "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" -o "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
        
        applications_to_reinstall=(
        "adobe-acrobat-reader"
        )
        for i in "${applications_to_reinstall[@]}"
		do
		    if [[ "$line" == "" ]]; then continue; fi
        	if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep "$i") != "" ]]
        	then
                echo 'updating '"$i"'...'
                env_use_password | brew cask reinstall "$i"
                #sed -i "" "/""$i""/d" "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
                sed -i '' '/'"$i"'/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
                echo ''
        	else
        		:
        	fi
        done
    
        # updating all casks that are out of date
        while IFS= read -r line || [[ -n "$line" ]]
        do
            CASK="$line"
            
            echo 'updating '"$CASK"'...'
            
            # uninstall deletes autostart entries and resets all preferences of the uninstalled app
            #sudo brew cask uninstall "$line" --force
            #env_use_password | brew cask uninstall "$line" --force 1> /dev/null
            #sudo brew cask install "$line" --force
            # reinstall deletes autostart entries as it runs uninstall and then install
            #env_use_password | brew cask reinstall "$line" --force
            env_use_password | brew cask install "$CASK" --force
            echo ''
            
            if [[ "$CASK" == "teamviewer" ]]
            then 
            	sleep 2
            	osascript -e "tell app \""$PATH_TO_APPS"/TeamViewer.app\" to quit" >/dev/null 2>&1
            	sleep 2
                env_active_source_app
            fi
            if [[ "$CASK" == "libreoffice" ]]
            then
                PATH_TO_FIRST_RUN_APP=""$PATH_TO_APPS"/LibreOffice.app"
                env_set_open_on_first_run_permissions
            else
                :
            fi
            if [[ "$CASK" == "libreoffice-language-pack" ]]
            then
                LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK=$(ls -1 /usr/local/Caskroom/libreoffice-language-pack | sort -V | head -n 1)
                PATH_TO_FIRST_RUN_APP="/usr/local/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app"
                env_set_open_on_first_run_permissions
                PATH_TO_FIRST_RUN_APP=""$PATH_TO_APPS"/LibreOffice.app"
                env_set_open_on_first_run_permissions
            else
                :
            fi
            if [[ "$CASK" == "zoomus" ]]
            then 
            	sleep 2
            	osascript -e "tell app \""$PATH_TO_APPS"/zoom.us.app\" to quit" >/dev/null 2>&1
            	sleep 2
                env_active_source_app
            fi
            
            # cleanup entries
            local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
            local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
            if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
            then
                echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$CASK" >> "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
            else
                :
            	#echo "only one version installed..."
            fi
        done <<< "$(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS")"
    
        echo "installing casks updates finished ;)"

    fi

}

post_cask_installations() {
    
    ### manual installations after install
    
    #if [[ "$VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE" == "yes" ]]
    #then
    #    env_start_sudo
    #    echo 'updating virtualbox...'
    #    env_use_password | brew cask reinstall virtualbox --force
    #    echo ''
    #    echo 'updating virtualbox-extension-pack...'
    #    env_use_password | brew cask reinstall virtualbox-extension-pack --force
    #    env_stop_sudo
    #    echo ''
    #else
    #    :
    #fi
    
    # making sure to have the latest version of macosfuse after installing virtualbox (which often ships with an outdated version)
    if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep "^virtualbox$") != "" ]]
	then
	    echo ''
        echo "updating macosfuse after virtualbox update..."
        env_use_password | brew cask install --force osxfuse
    else
        :
    fi
	    
    if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep "^libreoffice-language-pack$") != "" ]]
	then
	    echo ''
        echo "installing libreoffice language pack..."
        LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK=$(ls -1 /usr/local/Caskroom/libreoffice-language-pack | sort -V | head -n 1)
        open "/usr/local/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app"	
        #echo ''
    else
	    :
	fi
	
    if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep "^textmate$") != "" ]]
    then
        # removing quicklook syntax highlight
    	if [[ -e "$PATH_TO_APPS"/TextMate.app/Contents/Library/QuickLook/TextMateQL.qlgenerator ]]
    	then
    		rm -rf "$PATH_TO_APPS"/TextMate.app/Contents/Library/QuickLook/TextMateQL.qlgenerator
    	else
    		:
    	fi        
	    # reset quicklook and quicklook cache if neccessary
	    #qlmanage -r
	    #qlmanage -r cache
    else
        :
    fi
    
}

###
### running script
###

#printf "\033c"
printf "\ec"

echo ''
#echo "updating homebrew, formulae and casks..."
#echo -e "\033[1mupdating homebrew, formulae and casks...\033[0m"
echo "${bold_text}updating homebrew, formulae and casks...${default_text}"
echo ''

echo "script is run with $SCRIPT_INTERPRETER interpreter..."
#echo ''

unset_variables() {
    unset SUDOPASSWORD
    unset USE_PASSWORD
    unset TMP_DIR_FORMULAE
    unset TMP_DIR_CASK
    unset DATE_LIST_FILE_FORMULAE
    unset DATE_LIST_FILE_CASKS
    unset BREW_FORMULAE_PATH
    unset BREW_CASKS_PATH
}


### trapping
trap_function_exit_middle() { env_stop_sudo; unset SUDOPASSWORD; unset USE_PASSWORD; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

# creating directory and adjusting permissions
echo "checking directory structure and permissions..."
echo ''

if [[ ! -d /usr/local ]]; 
then
    sudo mkdir /usr/local
fi
#sudo chown -R "$USER":staff /usr/local
sudo chown -R $(whoami) /usr/local

# checking if homebrew is installed
if command -v brew &> /dev/null
then
    # installed
    echo "homebrew is installed..."
else
    # not installed
    echo "homebrew not installed, exiting script..."
    exit
fi

# as of 2018-10-31 brew cask --version is deprecated
#brew cask --version 2>&1 >/dev/null
#if [[ $? -eq 0 ]]
if [[ $(brew --version | grep homebrew-cask) != "" ]]
then
    echo "homebrew-cask is installed..."
else
    echo "homebrew-cask not installed, skipping respective script parts..."
    HOMEBREW_CASK_IS_INSTALLED="no"
fi
#echo ''

# checking if online
env_check_if_online
if [[ "$ONLINE_STATUS" == "online" ]]
then
    # online
    echo ''
    
    env_identify_terminal
    
    env_start_sudo

    env_command_line_tools_install_shell
    
    # keeping homebrew from updating each time "brew" is used
    export HOMEBREW_NO_AUTO_UPDATE=1
    
    # checking if all script dependencies are installed
    echo ''
    echo "checking for script dependencies..."
    if command -v parallel &> /dev/null && command -v jq &> /dev/null
    then
        # installed
        echo "all script dependencies installed..."
    else
        echo "not all script dependencies installed, installing..."
        env_use_password | brew install jq parallel
    fi
    
    # number of parallel processes depending on cpu-cores
    number_of_parallel_processes
    
    # raising ulimit for more allowed parallel processes
    ulimit -n 512 
    
    # checking if all formula dependencies are installed
    #echo ''
    echo "checking for formula dependencies..."
    if [[ $(brew missing) == "" ]]
    then
    	echo "all formula dependencies installed..."
    	:
    else
    	echo "not all formula dependencies installed, installing..."
    	brew install $(brew missing | awk '{print $NF}' | awk '!a[$0]++')
    	# or 
    	#brew install $(brew missing | awk '{print $NF}' | sort | uniq)
    fi
    #echo ''
    
    # will exclude these apps from updating
    # pass in params to fit your needs
    # use the exact brew/cask name and separate names with a pipe |
    FORMULA_EXCLUDES="${1:-}"
    CASK_EXCLUDES="${2:-}"
    
    # more variables
    echo ''
    BREW_PATH=$(brew --repository)
    export BREW_PATH
    if [[ $(echo "$BREW_PATH") == "" || ! -e "$BREW_PATH" ]]
    then
        echo "homebrew path is empty or does not exist, exiting script..."
        exit
    else
        echo "homebrew is located in "$BREW_PATH""
    fi
    
    BREW_FORMULAE_PATH=$(brew --cellar)
    export BREW_FORMULAE_PATH
    if [[ $(echo "$BREW_FORMULAE_PATH") == "" || ! -e "$BREW_FORMULAE_PATH" ]]
    then
        echo "homebrew formulae path is empty or does not exist, exiting script..."
        exit
    else
        echo "homebrew formulae are located in "$BREW_FORMULAE_PATH""
    fi

    #
    BREW_CASKS_PATH=$(brew cask doctor 2>/dev/null | grep -A1 -B1 "Cask Staging Location" | tail -1)
    export BREW_CASKS_PATH
    if [[ $(echo "$BREW_CASKS_PATH") == "" || ! -e "$BREW_CASKS_PATH" ]]
    then
        echo "homebrew casks path is empty or does not exist, skipping respective script parts..."
        HOMEBREW_CASK_IS_INSTALLED="no"
    else
        HOMEBREW_CASK_IS_INSTALLED="yes"
        echo "homebrew casks are located in "$BREW_CASKS_PATH""
    fi
    #echo ''
    
    env_sudo_homebrew
    
    #VARIABLE_TO_CHECK="$CONT_LATEST"
    #QUESTION_TO_ASK='do you want to update all installed casks that show "latest" as version (y/N)? '
    #env_ask_for_variable
    #CONT_LATEST="$VARIABLE_TO_CHECK"
    CONT_LATEST="no"
    
    env_homebrew_update
    #
    echo ''
    export INSTALLED_FORMULAE=$(brew list | cat)
    formulae_show_updates_parallel
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        echo ''
        export INSTALLED_CASKS=$(brew cask list | cat)
        casks_show_updates_parallel
    else
        :
    fi
    #
    echo ''
    formulae_install_updates
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        echo ''
        casks_install_updates
    else
        :
    fi
    #
    echo ''
    echo "cleaning up..."
    env_cleanup_all_homebrew & pids+=($!)
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        cleanup_formulae & pids+=($!)
        cleanup_casks & pids+=($!)
    else
        cleanup_formulae & pids+=($!)
    fi
    wait "${pids[@]}"
    
    echo 'cleaning finished ;)'
    
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        post_cask_installations
    else
        :
    fi
    
    # done in trap
    #env_stop_sudo

else
    # offline
    echo "skipping updates..."
fi


# done
echo ''
echo "script done ;)"
echo ''



###
### unsetting variables
###

unset_variables

# kill all child and grandchild processes
#ps -o pgid= $$ | grep -o '[0-9]*'
#kill -9 -$(ps -o pgid= $$ | grep -o '[0-9]*')

exit
