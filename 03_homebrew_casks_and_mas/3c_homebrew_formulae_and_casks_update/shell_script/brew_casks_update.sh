#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### env_parallel session
###

# needed for env_paralell using parallel version 20200822 and newer
# http://savannah.gnu.org/bugs/index.php?59010
# no longer needed after fix in version 20200922
#env_parallel --session 



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
        	    local FORMULA_INFO=$(brew info --formula --json=v2 "$FORMULA" | jq -r '.formulae | .[]')
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
    # brew list --formula --versions

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
                local CASK_INFO=$(brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[]')
                #local CASK_INFO=$(brew info --cask "$CASK")
                local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
                #local CASK_NAME=$(printf '%s\n' "$CASK" | cut -d ":" -f1 | xargs)
                local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | jq -r '.version')
                #local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | head -1 | sed 's|(auto_updates)||g' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
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
    # brew list --cask --versions
    
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
        #local FORMULA_INFO=$(brew info --formula $FORMULA)
        FORMULA_INFO=$(brew info --formula --json=v2 "$FORMULA" | jq -r '.formulae | .[]')
        #echo FORMULA_INFO is $FORMULA_INFO
        #local FORMULA_NAME=$(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f1 | sed 's/://g')
        local FORMULA_NAME=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.name')
        # getting value directly
        #local FORMULA_NAME=$(brew info --formula --json=v2 $FORMULA | jq -r '.formulae | .[] | .name')
        #echo FORMULA_NAME is $FORMULA_NAME
        # make sure you have jq installed via brew
        #local FORMULA_REVISION=$(brew info --formula "$FORMULA" --json=v2 | jq -r '.formulae | .[]' | grep revision | grep -o '[0-9]')
        local FORMULA_REVISION=$(printf '%s\n' "$FORMULA_INFO" | jq -r '.revision')
        #echo FORMULA_REVISION is $FORMULA_REVISION
        if [[ $(echo "$FORMULA" | grep "python@3.*") != "" ]]
        then
            OTHER_FORMULA_VERSION="python3"
            NEW_FORMULA_INFO=$(brew info --formula --json=v2 "$OTHER_FORMULA_VERSION" | jq -r '.formulae | .[]')
        else
            :
        fi
        if [[ "$NEW_FORMULA_INFO" == "" ]]
        then
            NEW_FORMULA_INFO="$FORMULA_INFO"
        else
            :
        fi
        if [[ "$FORMULA_REVISION" == "0" ]]
        then
            #local NEW_VERSION=$(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')
            local NEW_VERSION=$(printf '%s\n' "$NEW_FORMULA_INFO" | jq -r '.versions.stable')
        else
            #local NEW_VERSION=$(echo $(printf '%s\n' "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')_"$FORMULA_REVISION")
            local NEW_VERSION=$(echo $(printf '%s\n' "$NEW_FORMULA_INFO" | jq -r '.versions.stable')_"$FORMULA_REVISION")
        fi
        FORMULA_INFO=$(brew info --formula --json=v2 "$FORMULA" | jq -r '.formulae | .[]')
        #echo NEW_VERSION is $NEW_VERSION
        local NUMBER_OF_INSTALLED_FORMULAE=$(printf '%s\n' "$INSTALLED_FORMULAE" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        local NUMBER_OF_FORMULA=$(printf '%s\n' "$INSTALLED_FORMULAE" | grep -n "^$FORMULA$" | awk -F: '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
        #echo INSTALLED_VERSIONS is "$INSTALLED_VERSIONS"
        local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
        #echo NUMBER_OF_INSTALLED_VERSIONS is "$NUMBER_OF_INSTALLED_VERSIONS"
        local NEWEST_INSTALLED_VERSION=$(printf '%s\n' "$INSTALLED_VERSIONS" | tail -n 1)
        #echo NEWEST_INSTALLED_VERSION is "$NEWEST_INSTALLED_VERSION"
        local CHECK_RESULT=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -q "^$NEW_VERSION$" 2>&1 && echo ok || echo outdated)
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
        if [[ "$CHECK_RESULT" == "outdated" ]] && [[ $(printf '%s\n' "${FORMULA_EXCLUDES[@]}" | grep "^$FORMULA$") == "" ]]
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
    if [[ "$(brew list --formula)" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "formulae_show_updates_parallel_inside {}" ::: "$(brew list --formula)"; fi
        
    #echo "listing brew formulae updates finished ;)"
}

formulae_install_updates_parallel() {
    echo "installing brew formulae updates..."
    
    if [[ ! -s "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" ]]
    then
    	# file is empty or does not exist
    	echo "no formulae updates available..."
    else
    	# file exists and is not empty
        
        # sorting the outdated casks file after using parallel which can change output order
        sort "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" -o "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE"
            
        formulae_install_updates_parallel_inside() {
            FORMULA="$1"
            echo 'updating '"$FORMULA"'...'            
            #if [[ $(brew outdated --quiet | grep "^$FORMULA$") == "" ]] && [[ $(brew outdated --quiet | grep "/$FORMULA$") == "" ]]
            #[[ $(brew outdated --verbose | grep "^$FORMULA[[:space:]]") == "" ]]
            #then
            #    echo "$FORMULA"" already up-to-date..."
            #else
                if [[ "$FORMULA" == "qtfaststart" ]]
                then
                    if [[ $(brew list --formula | grep "^ffmpeg$") != "" ]]
                    then
                        brew unlink qtfaststart
                        brew unlink ffmpeg && brew link ffmpeg
                        brew link --overwrite qtfaststart
                    else
                        :
                    fi
                elif [[ "$FORMULA" == "^ffmpeg$" ]]
                then
                    if [[ $(brew list --formula | grep "^qtfaststart$") != "" ]]
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
                
                # preserver colored output using script
                if [[ "$FORMULA" =~ "^python@3.*" ]]
                then
                    FORMULA_CLEANUP_NEEDED="no"
                    script -q /dev/null brew uninstall "$FORMULA"
                    script -q /dev/null brew install --formula python3
                else
                    script -q /dev/null brew upgrade --formula "$FORMULA"
                    #brew upgrade --formula "$FORMULA"
                fi
                
            #fi
            echo 'removing old installed versions of '"$FORMULA"'...'
            env_use_password | brew cleanup "$FORMULA"
            echo ''
            
            # cleanup entries
            if [[ "$FORMULA_CLEANUP_NEEDED" == "no" ]]
            then
                :
            else   
                local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
                local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
                if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
                then
                    echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$FORMULA" >> "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
                else
                    :
                	#echo "only one version installed..."
                fi
            fi
        }
        
        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
        # it is not neccessary to export variables or functions when using env_parallel
        # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
        if [[ "$(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE")" != "" ]]; then env_parallel --will-cite -j"1" --line-buffer -k "formulae_install_updates_parallel_inside {}" ::: "$(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE")"; fi
        
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
    
    #DATE_LIST_FILE_CASKS_AUTOSTART=$(echo "casks_update_autostart"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    #export DATE_LIST_FILE_CASKS_AUTOSTART
    #touch "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS_AUTOSTART"
    
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
        local CASK_INFO=$(brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[]')
        #local CASK_INFO=$(brew info --cask "$CASK")
        local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
        #brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[]|(.artifacts|map(.[]?|select(type=="string")|select(test(".app$"))))|.[]'
        #local CASK_ARTIFACT_APP=$(printf '%s\n' "$CASK_INFO" | jq -r '.artifacts|map(.[]?|select(type=="string")|select(test(".app$")))|.[]')
        #brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[] | .artifacts | .[] | .app | .[]?'
        local CASK_ARTIFACT_APP=$(printf '%s\n' "$CASK_INFO" | jq -r '.artifacts | .[] | .app | .[]?')
        #echo "$CASK_ARTIFACT_APP"
        if [[ "$CASK_ARTIFACT_APP" != "" ]]
        then
            local CASK_ARTIFACT_APP_NO_EXTENSION=$(echo ${$(basename $CASK_ARTIFACT_APP)%.*})
        else
            :
        fi
        #local CASK_ARTIFACT_APP_NO_EXTENSION=$(echo "${CASK_ARTIFACT_APP##*/}" | cut -d '.' -f 1)
        #echo CASK_ARTIFACT_APP_NO_EXTENSION is "$CASK_ARTIFACT_APP_NO_EXTENSION"
        #local CASK_NAME=$(printf '%s\n' "$CASK" | cut -d ":" -f1 | xargs)
        local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | jq -r '.version')
        #local NEW_VERSION=$(printf '%s\n' "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | head -1 | sed 's|(auto_updates)||g' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        local NUMBER_OF_INSTALLED_CASKS=$(printf '%s\n' "$INSTALLED_CASKS" | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        local NUMBER_OF_CASK=$(printf '%s\n' "$INSTALLED_CASKS" | grep -n "^$CASK$" | awk -F: '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
        #echo INSTALLED_VERSIONS is "$INSTALLED_VERSIONS"
        local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
        #echo NUMBER_OF_INSTALLED_VERSIONS is "$NUMBER_OF_INSTALLED_VERSIONS"
        local NEWEST_INSTALLED_VERSION=$(printf '%s\n' "$INSTALLED_VERSIONS" | head -n 1)
        #local NEWEST_INSTALLED_VERSION="$NEW_VERSION"
        #echo NEWEST_INSTALLED_VERSION is "$NEWEST_INSTALLED_VERSION"
        local CHECK_RESULT=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -q "^$NEW_VERSION$" 2>&1 && echo ok || echo outdated)
        if [[ "$CHECK_RESULT" == "outdated" ]]
        then
            local CHECK_RESULT=$(printf '%s\n' "$INSTALLED_VERSIONS" | grep -q "^$NEW_VERSION,.*$" 2>&1 && echo ok || echo outdated)
            if [[ "$CHECK_RESULT" == "ok" ]]
            then
                #local NEW_VERSION="$NEWEST_INSTALLED_VERSION"
                 local NEWEST_INSTALLED_VERSION="$NEW_VERSION"
            else
                :
            fi
        else
            :
        fi
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
        if [[ "$CHECK_RESULT" == "outdated" ]] && [[ $(printf '%s\n' "${CASK_EXCLUDES[@]}" | grep "^$CASK$") == "" ]]
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
        
        # autostart
        # 10.15 is not opening autostart apps on next boot after install/update without explicitly granting permissions or opening manually before autostart
        add_cask_to_autostart_list() {
            env_get_autostart_items
            if [[ "$AUTOSTART_ITEMS" != "" ]] && [[ "$CHECK_RESULT" == "outdated" ]] && [[ "$CASK_ARTIFACT_APP_NO_EXTENSION" != "" ]]
            then
                if [[ $(printf '%s\n' "$AUTOSTART_ITEMS" | grep -i "$CASK") != "" ]] || [[ $(printf '%s\n' "$AUTOSTART_ITEMS" | grep -i "$CASK_ARTIFACT_APP_NO_EXTENSION") != "" ]]
                then
                    echo -e "$CASK\t\t$CASK_ARTIFACT_APP_NO_EXTENSION" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS_AUTOSTART"
                else
                    :
                fi
            else
                :
            fi
        }
        #add_cask_to_autostart_list
    	
    	if [[ "$CONT_LATEST" =~ ^(yes|y)$ ]]
        then
            if [[ "$NEW_VERSION" == "latest" ]] && [[ $(printf '%s\n' "${CASK_EXCLUDES[@]}" | grep "^$CASK$") == "" ]]
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
                env_use_password | brew reinstall --cask "$i"
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
            #sudo brew uninstall --cask "$line" --force
            #env_use_password | brew uninstall --cask "$line" --force 1> /dev/null
            #sudo brew install --cask "$line" --force
            # reinstall deletes autostart entries as it runs uninstall and then install
            #env_use_password | brew reinstall --cask "$line" --force
            env_use_password | brew install --cask "$CASK" --force
            #echo ''
            
            # cleanup entries
            echo "searching for old "$CASK" versions..."
            local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
            local NUMBER_OF_INSTALLED_VERSIONS=$(printf '%s\n' "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
            if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
            then
                echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$CASK" >> "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
            else
                :
            	#echo "only one version installed..."
            fi
            
            # no longer needed as it is integrated in the cask to quit the app
            # https://github.com/Homebrew/homebrew-cask/blob/master/Casks/teamviewer.rb
            #if [[ "$CASK" == "teamviewer" ]]
            #then 
            #	sleep 2
            #	osascript -e "tell app \"TeamViewer.app\" to quit" >/dev/null 2>&1
            #	#pkill -15 "TeamViewer"
            #	sleep 2
            #    env_active_source_app
            #fi
            
            # no longer needed
            #if [[ "$CASK" == "libreoffice" ]]
            #then
            #    SKIP_ENV_GET_PATH_TO_APP="yes"
            #    PATH_TO_APP=""$PATH_TO_APPS"/LibreOffice.app"
            #    env_set_open_on_first_run_permissions
            #    unset SKIP_ENV_GET_PATH_TO_APP
            #else
            #    :
            #fi
            
            #if [[ "$CASK" == "libreoffice-language-pack" ]]
            #then
            #    SKIP_ENV_GET_PATH_TO_APP="yes"
            #    LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK=$(ls -1 "$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack | sort -V | head -n 1)
            #    PATH_TO_APP=""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app"
            #    env_set_open_on_first_run_permissions
            #    PATH_TO_APP=""$PATH_TO_APPS"/LibreOffice.app"
            #    env_set_open_on_first_run_permissions
            #    unset SKIP_ENV_GET_PATH_TO_APP
            #else
            #    :
            #fi
            
            # no longer needed as it is integrated in the cask to quit the app
            # https://github.com/Homebrew/homebrew-cask/blob/master/Casks/zoom.rb
            #if [[ "$CASK" == "zoom" ]]
            #then 
            #	sleep 2
            #	osascript -e "tell app \"zoom.us.app\" to quit" >/dev/null 2>&1
            #	#pkill -15 "zoom.us"
            #	sleep 2
            #    env_active_source_app
            #fi
            
            # allow opening app
            allow_opening_casks_inside() {
                line="$1"
                if [[ "$line" == "" ]]
                then
                    line="$CASK"
                fi
                if [[ $(brew list --cask | tr "," "\n" | grep "^$line$") != "" ]]
                then
                    echo "$line"
                    local CASK_INFO=$(brew info --cask --json=v2 "$line" | jq -r '.casks | .[]')
                    #local CASK_INFO=$(brew info --cask "$CASK")
                    local CASK_NAME=$(printf '%s\n' "$CASK_INFO" | jq -r '.name | .[]')
                    #echo "$CASK_NAME"
                    #brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[]|(.artifacts|map(.[]?|select(type=="string")|select(test(".app$"))))|.[]'
                    #local CASK_ARTIFACT_APP=$(printf '%s\n' "$CASK_INFO" | jq -r '.artifacts|map(.[]?|select(type=="string")|select(test(".app$")))|.[]')
                    #brew info --cask --json=v2 "$CASK" | jq -r '.casks | .[] | .artifacts | .[] | .app | .[]?'
                    local CASK_ARTIFACT_APP=$(printf '%s\n' "$CASK_INFO" | jq -r '.artifacts | .[] | .app | .[]?')
                    #echo "$CASK_ARTIFACT_APP"
                    if [[ "$CASK_ARTIFACT_APP" != "" ]]
                    then
                        local CASK_ARTIFACT_APP_NO_EXTENSION=$(echo ${$(basename $CASK_ARTIFACT_APP)%.*})
                    else
                        local CASK_ARTIFACT_APP_NO_EXTENSION="$CASK_NAME"
                    fi
                    local APP_NAME="$CASK_ARTIFACT_APP_NO_EXTENSION"
                    #echo "$APP_NAME"
                    env_set_open_on_first_run_permissions
                    # allow additional apps inside of other apps
                    if [[ "$line" == "bettertouchtool" ]]
                    then
                        local APP_NAME="BTTRelaunch"
                        env_set_open_on_first_run_permissions
                    else
                        :
                    fi
                    if [[ "$line" == "alfred" ]]
                    then
                        local APP_NAME="Alfred Preferences"
                        env_set_open_on_first_run_permissions
                    else
                        :
                    fi
                    if [[ "$line" == "bartender" ]]
                    then
                        local APP_NAME="BartenderStartAtLoginHelper"
                        env_set_open_on_first_run_permissions
                    else
                        :
                    fi
                else
                    :
                fi
            }
            echo "allowing "$CASK" to open..."
            allow_opening_casks_inside
            
            echo ''
            
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
    #    env_use_password | brew reinstall --cask virtualbox --force
    #    echo ''
    #    echo 'updating virtualbox-extension-pack...'
    #    env_use_password | brew reinstall --cask virtualbox-extension-pack --force
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
        env_use_password | brew install --cask --force macfuse
    else
        :
    fi
	    
    if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep "^libreoffice-language-pack$") != "" ]]
	then
        LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK=$(ls -1 "$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack | sort -V | head -n 1)
        if [[ $(xattr -l ""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app" | grep com.apple.quarantine) == "" ]]
        then
            :
        else
            echo ''
            echo "installing libreoffice language pack..."
            open ""$BREW_PATH_PREFIX"/Caskroom/libreoffice-language-pack/$LATEST_INSTALLED_LIBREOFFICE_LANGUAGE_PACK/LibreOffice Language Pack.app"	
        fi
        
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
    
    # as it is not possible to get the full name of all apps from the cask take the safer way and ensure all autostart apps
    autostart_permissions_cask_specific() {
        if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS_AUTOSTART") != "" ]]
        then
        	echo ''
            echo "allowing autostart of updated apps..."
            while IFS= read -r line || [[ -n "$line" ]]
    		do
    		    if [[ "$line" == "" ]]; then continue; fi
    	        local CASK=$(echo "$line" | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    	        local CASK_ARTIFACT_APP_NO_EXTENSION=$(echo "$line" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    	        #echo "$CASK_ARTIFACT_APP_NO_EXTENSION"
    	        if [[ "$CASK_ARTIFACT_APP_NO_EXTENSION" != "" ]]
    	        then
    	            APP_NAME="$CASK_ARTIFACT_APP_NO_EXTENSION"
                    env_set_open_on_first_run_permissions
                else
                    echo "${bold_text}app artifact for updated autostart cask "$CASK" not found...${default_text}"
                    echo "open app manually to make autostart work again..." 
                fi
            done <<< "$(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS_AUTOSTART")"
        else
            :
        fi
    }
    #autostart_permissions_cask_specific
    
    # if casks were updated ensure permissions for all autostart apps
    set_permissions_autostart_apps() {
        if [[ ! -s "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" ]]
        then
        	# file is empty or does not exist
            :
        else
        	# file exists and is not empty
            echo ''
            echo "setting permissions for autostart apps..."
            env_get_autostart_items
            env_check_if_parallel_is_installed 1>/dev/null
            #echo ''
            if [[ "${AUTOSTART_ITEMS[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "env_set_permissions_autostart_apps {}" ::: "${AUTOSTART_ITEMS[@]}"; fi 1>/dev/null
        fi
    }
    #set_permissions_autostart_apps
    
}

allow_opening_casks() {
    # allow opening apps
    echo ''
    echo "allowing casks to open..."
    
    if [[ "$WHICH_CASKS_TO_ALLOW" == "list" ]]
    then
        # only updated casks
        ALLOWED_CASKS_LIST=$(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS")
        # list
        #ALLOWED_CASKS_LIST=(
        #jitsi-meet
        #chromium
        #)
    else
        # all installed casks
        ALLOWED_CASKS_LIST=$(brew list --cask | tr "," "\n" | uniq)
    fi
    ALLOWED_CASKS=$(printf "%s\n" "${ALLOWED_CASKS_LIST[@]}")
    
    # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
    # it is not neccessary to export variables or functions when using env_parallel
    # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
    
    if [[ "${ALLOWED_CASKS[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "allow_opening_casks_inside {}" ::: "${ALLOWED_CASKS[@]}"; fi
    
    echo ''

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
    #unset SUDOPASSWORD		# done in trap
    #unset USE_PASSWORD		# done in trap
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

# checking if homebrew is installed
if command -v brew &> /dev/null
then
    # installed
    echo "homebrew is installed..."
    BREW_PATH_PREFIX=$(brew --prefix)
else
    # not installed
    echo "homebrew not installed, exiting script..."
    exit
fi

if [[ ! -d "$BREW_PATH_PREFIX" ]]; 
then
    sudo mkdir "$BREW_PATH_PREFIX"
fi
#sudo chown -R "$USER":staff "$BREW_PATH_PREFIX"
sudo chown -R $(whoami) "$BREW_PATH_PREFIX"

if [[ $(brew tap | grep homebrew/cask) != "" ]]
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
    # use the exact formula/cask name and separate names with a new line
    FORMULA_EXCLUDES=(
    #formula1
    )
    CASK_EXCLUDES=(
    #cask1
    )
    
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
    BREW_CASKS_PATH=$(brew doctor --verbose 2>/dev/null | grep -A1 -B1 "Cask Staging Location" | tail -1)
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
    
    echo ''
    export INSTALLED_FORMULAE=$(brew list --formula | cat)
    formulae_show_updates_parallel
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        echo ''
        export INSTALLED_CASKS=$(brew list --cask | cat)
        casks_show_updates_parallel
    else
        :
    fi
    
    echo ''
    # workaround for issue with brew upgrade command
    # https://github.com/Homebrew/brew/issues/12034#issuecomment-917261527
    formulae_install_updates_parallel
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        echo ''
        casks_install_updates
    else
        :
    fi
    
    # allowing casks to open
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        WHICH_CASKS_TO_ALLOW=list allow_opening_casks
    else
        echo ''
    fi
    
    # cleaning up
    #echo ''
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
    
    # done in trap additionally, but it seems the sudo function is killed somewhere after this, so this is needed here to use sudo inside of env_stop_sudo
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
# pid
#ps -o pgid= $$ | grep -o '[0-9]*'
# process details belonging to pid
#ps -p $(ps -o pgid= $$ | grep -o '[0-9]*')
# kill processes
#kill -9 -$(ps -o pgid= $$ | grep -o '[0-9]*')

exit
