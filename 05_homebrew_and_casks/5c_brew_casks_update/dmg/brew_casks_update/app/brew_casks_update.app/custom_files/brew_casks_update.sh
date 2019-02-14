#!/bin/bash

# http://brew.sh
# http://braumeister.org
# http://caskroom.io
# http://caskroom.io/search



###
### asking password upfront
###

if [[ -e /tmp/run_from_backup_script2 ]] && [[ $(cat /tmp/run_from_backup_script2) == 1 ]]
then
    function delete_tmp_backup_script_fifo2() {
        if [ -e "/tmp/tmp_backup_script_fifo2" ]
        then
            rm "/tmp/tmp_backup_script_fifo2"
        else
            :
        fi
        if [ -e "/tmp/run_from_backup_script2" ]
        then
            rm "/tmp/run_from_backup_script2"
        else
            :
        fi
    }
    unset SUDOPASSWORD
    SUDOPASSWORD=$(cat "/tmp/tmp_backup_script_fifo2" | head -n 1)
    USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    delete_tmp_backup_script_fifo2
    set +a
else
    
    # function for reading secret string (POSIX compliant)
    enter_password_secret()
    {
        # read -s is not POSIX compliant
        #read -s -p "Password: " SUDOPASSWORD
        #echo ''
        
        # this is POSIX compliant
        # disabling echo, this will prevent showing output
        stty -echo
        # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
        trap 'stty echo' EXIT
        # asking for password
        printf "Password: "
        # reading secret
        read -r "$@" SUDOPASSWORD
        # reanabling echo
        stty echo
        trap - EXIT
        # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
        printf "\n"
        # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
        # has to be part of the function or it wouldn`t be updated during the maximum three tries
        #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    }
    
    # unset the password if the variable was already set
    unset SUDOPASSWORD
    
    # making sure no variables are exported
    set +a
    
    # asking for the SUDOPASSWORD upfront
    # typing and reading SUDOPASSWORD from command line without displaying it and
    # checking if entered password is the sudo password with a set maximum of tries
    NUMBER_OF_TRIES=0
    MAX_TRIES=3
    while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    do
        NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
        #echo "$NUMBER_OF_TRIES"
        if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
        then
            enter_password_secret
            ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
            if [ $? -eq 0 ]
            then 
                break
            else
                echo "Sorry, try again."
            fi
        else
            echo ""$MAX_TRIES" incorrect password attempts"
            exit
        fi
    done
fi

# setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
trap 'unset SUDOPASSWORD' EXIT

# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}


###
### functions
###

homebrew_update() {
    echo ''
    echo "updating homebrew..."
    # brew prune deprecated as of 2019-01, using brew cleanup at the end of the script instead
    brew update-reset 1> /dev/null 2> >(grep -v "Reset branch" 1>&2) && brew analytics off 1> /dev/null && brew update 1> /dev/null && brew doctor 1> /dev/null
    
    # working around a --json=v1 bug until it`s fixed
    # https://github.com/Homebrew/homebrew-cask/issues/52427
    #sed -i '' '/"conflicts_with" =>/s/.to_a//g' "$(brew --repository)"/Library/Homebrew/cask/cask.rb
    #sed -i '' '/"conflicts_with" =>/s/.to_a//g' "$BREW_PATH"/Library/Homebrew/cask/cask.rb
    # fixed 2019-01-28
    # https://github.com/Homebrew/brew/pull/5597

    echo 'updating homebrew finished ;)'
}

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

cleanup_all_homebrew() {
    # making sure brew cache exists
    HOMEBREW_CACHE_DIR=$(brew --cache)
    mkdir -p "$HOMEBREW_CACHE_DIR"
    chown "$USER":staff "$HOMEBREW_CACHE_DIR"/
    chmod 755 "$HOMEBREW_CACHE_DIR"/
    
    brew cleanup 1> /dev/null
    # also seems to clear cleans hidden files and folders
    brew cleanup --prune=0 1> /dev/null
    
    rm -rf "$HOMEBREW_CACHE_DIR"/{,.[!.],..?}*
    # brew cask cleanup is deprecated from 2018-09
    #brew cask cleanup
    #brew cask cleanup 1> /dev/null
    
    # brew cleanup has to be run after the rm -rf "$HOMEBREW_CACHE_DIR"/{,.[!.],..?}* again
    # if not it will delete a file /Users/$USER/Library/Caches/Homebrew/.cleaned
    # this file is produced by brew cleanup and is checked if brew cleanup was run in the last x days
    # without the file brew thinks brew cleanup was not run and complains about it
    # https://github.com/Homebrew/brew/issues/5644
    brew cleanup 1> /dev/null
    
    # fixing red dots before confirming commit to cask-repair that prevent the commit from being made
    # https://github.com/vitorgalvao/tiny-scripts/issues/88
    #sudo gem uninstall -ax rubocop rubocop-cask 1> /dev/null
    #brew cask style 1> /dev/null
}

cleanup_formulae() { 
    if [[ ! -s "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS" ]]
    then
    	# file is empty or does not exist
    	:
    else
    	# file exists and is not empty
        sort "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS" -o "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
    
        while IFS='' read -r line || [[ -n "$line" ]]
        do
                FORMULA=$(echo "$line" | awk '{print $2}')
                #echo ''
            	#echo "$(echo "$line" | awk '{print $1}') versions of $FORMULA are installed..."
            	#echo "uninstalling all outdated versions..."
            	if [[ -e "$BREW_FORMULAE_PATH"/"$FORMULA" ]]
            	then
            	    # uninstall old versions
                    local FORMULA_INFO=$(brew info --json=v1 "$FORMULA" | jq .[])
                    local FORMULA_NAME=$(echo "$FORMULA_INFO" | jq -r '.name')
                    local FORMULA_REVISION=$(echo "$FORMULA_INFO" | jq -r '.revision')
                    if [[ "$FORMULA_REVISION" == "0" ]]
                    then
                        #local NEW_VERSION=$(echo "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')
                        local NEW_VERSION=$(echo "$FORMULA_INFO" | jq -r '.versions.stable')
                    else
                        #local NEW_VERSION=$(echo $(echo "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')_"$FORMULA_REVISION")
                        local NEW_VERSION=$(echo $(echo "$FORMULA_INFO" | jq -r '.versions.stable')_"$FORMULA_REVISION")
                    fi
            	    local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
            	    local NEWEST_INSTALLED_VERSION=$(echo "$INSTALLED_VERSIONS" | tail -n 1)
            	    #local VERSIONS_TO_UNINSTALL=$(echo "$INSTALLED_VERSIONS" | grep -v "$NEW_VERSION")
            	    # alternatively always keep latest version installed and not the latest version from homebrew
            	    local VERSIONS_TO_UNINSTALL=$(echo "$INSTALLED_VERSIONS" | grep -v "$NEWEST_INSTALLED_VERSION")
            	    for i in $VERSIONS_TO_UNINSTALL
                    do
                        #echo $i
                        # deleting version entry
                        if [[ -e "$BREW_FORMULAE_PATH"/"$FORMULA"/"$i" && $(echo "$i") != "" ]]
                        then
                            rm -rf "$BREW_FORMULAE_PATH"/"$FORMULA"/"$i"
                        else
                            :
                        fi
                        # deleting metadata version entry
                        if [[ -e "$BREW_FORMULAE_PATH"/"$FORMULA"/.metadata/"$i" && $(echo "$i") != "" ]]
                        then
                            rm -rf "$BREW_FORMULAE_PATH"/"$FORMULA"/.metadata/"$i"
                        else
                            :
                        fi
                    done
            	else
            	    :
            	fi
        done <"$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
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
    
        while IFS='' read -r line || [[ -n "$line" ]]
        do
                CASK=$(echo "$line" | awk '{print $2}')
                #echo ''
            	#echo "$(echo "$line" | awk '{print $1}') versions of $CASK are installed..."
            	#echo "uninstalling all outdated versions..."
            	if [[ -e "$BREW_CASKS_PATH"/"$CASK" ]]
            	then
            	    # uninstall old versions
                    local CASK_INFO=$(brew cask info --json=v1 "$CASK" | jq .[])
                    #local CASK_INFO=$(brew cask info "$CASK")
                    local CASK_NAME=$(echo "$CASK_INFO" | jq -r '.name | .[]')
                    #local CASK_NAME=$(echo "$CASK" | cut -d ":" -f1 | xargs)
                    local NEW_VERSION=$(echo "$CASK_INFO" | jq -r '.version')
                    #local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | head -1 | sed 's|(auto_updates)||g' | sed 's/^ *//' | sed 's/ *$//')
            	    local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
            	    local NEWEST_INSTALLED_VERSION=$(echo "$INSTALLED_VERSIONS" | head -n 1)
            	    #local NEWEST_INSTALLED_VERSION="$NEW_VERSION"
            	    # alternatively always keep latest version installed and not the latest version from homebrew
            	    local VERSIONS_TO_UNINSTALL=$(echo "$INSTALLED_VERSIONS" | grep -v "$NEWEST_INSTALLED_VERSION")
            	    for i in $VERSIONS_TO_UNINSTALL
                    do
                        #echo $i
                        # deleting version entry
                        if [[ -e "$BREW_CASKS_PATH"/"$CASK"/"$i" && $(echo "$i") != "" ]]
                        then
                            rm -rf "$BREW_CASKS_PATH"/"$CASK"/"$i"
                        else
                            :
                        fi
                        # deleting metadata version entry
                        if [[ -e "$BREW_CASKS_PATH"/"$CASK"/.metadata/"$i" && $(echo "$i") != "" ]]
                        then
                            rm -rf "$BREW_CASKS_PATH"/"$CASK"/.metadata/"$i"
                        else
                            :
                        fi
                    done
            	else
            	    :
            	fi
        done <"$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
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
    if [ -e "$TMP_DIR_FORMULAE" ]
    then
        if [ "$(ls -A $TMP_DIR_FORMULAE/)" ]
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
    if [ -e "$TMP_DIR_FORMULAE_VERSIONS" ]
    then
        if [ "$(ls -A $TMP_DIR_FORMULAE_VERSIONS/)" ]
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
        FORMULA_INFO=$(brew info --json=v1 "$FORMULA" | jq .[])
        #echo FORMULA_INFO is $FORMULA_INFO
        #local FORMULA_NAME=$(echo "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f1 | sed 's/://g')
        local FORMULA_NAME=$(echo "$FORMULA_INFO" | jq -r '.name')
        # getting value directly
        #local FORMULA_NAME=$(brew info --json=v1 $FORMULA | jq -r '.[].name')
        #echo FORMULA_NAME is $FORMULA_NAME
        # make sure you have jq installed via brew
        #local FORMULA_REVISION=$(brew info "$FORMULA" --json=v1 | jq . | grep revision | grep -o '[0-9]')
        local FORMULA_REVISION=$(echo "$FORMULA_INFO" | jq -r '.revision')
        #echo FORMULA_REVISION is $FORMULA_REVISION
        if [[ "$FORMULA_REVISION" == "0" ]]
        then
            #local NEW_VERSION=$(echo "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')
            local NEW_VERSION=$(echo "$FORMULA_INFO" | jq -r '.versions.stable')
        else
            #local NEW_VERSION=$(echo $(echo "$FORMULA_INFO" | grep -e "$FORMULA: .*" | cut -d" " -f3 | sed 's/,//g')_"$FORMULA_REVISION")
            local NEW_VERSION=$(echo $(echo "$FORMULA_INFO" | jq -r '.versions.stable')_"$FORMULA_REVISION")
        fi
        #echo NEW_VERSION is $NEW_VERSION
        local NUMBER_OF_INSTALLED_FORMULAE=$(echo "$INSTALLED_FORMULAE" | wc -l | sed 's/^ *//' | sed 's/ *$//')
        local NUMBER_OF_FORMULA=$(echo "$INSTALLED_FORMULAE" | grep -n "^$FORMULA$" | awk -F: '{print $1}' | sed 's/^ *//' | sed 's/ *$//')
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
        #echo INSTALLED_VERSIONS is "$INSTALLED_VERSIONS"
        local NUMBER_OF_INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
        #echo NUMBER_OF_INSTALLED_VERSIONS is "$NUMBER_OF_INSTALLED_VERSIONS"
        local NEWEST_INSTALLED_VERSION=$(echo "$INSTALLED_VERSIONS" | tail -n 1)
        #echo NEWEST_INSTALLED_VERSION is "$NEWEST_INSTALLED_VERSION"
        local CHECK_RESULT=$(echo "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo ok || echo outdated)
        #echo CHECK_RESULT is $CHECK_RESULT
        local NAME_PRINT=$(echo "$FORMULA" | awk -v len=20 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local CURRENT_INSTALLED_VERSION_PRINT=$(echo "$NEWEST_INSTALLED_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        #local CURRENT_INSTALLED_VERSION_PRINT=$(echo "$NEWEST_INSTALLED_VERSION" | cut -d ":" -f1 | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local NEW_VERSION_PRINT=$(echo "$NEW_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
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
    export -f formulae_show_updates_parallel_inside
    
    parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k formulae_show_updates_parallel_inside ::: "$(brew list)"
    wait
        
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
            
        while IFS='' read -r line || [[ -n "$line" ]]
        do
            FORMULA="$line"
            
            echo 'updating '"$FORMULA"'...'            
            if [[ $(brew outdated --quiet | grep "^$FORMULA$") == "" ]] && [[ $(brew outdated --quiet | grep "/$FORMULA$") == "" ]]
            #[[ $(brew outdated --verbose | grep "^$FORMULA[[:space:]]") == "" ]]
            then
                echo "$FORMULA"" already up-to-date..."
            else
                if [[ "$FORMULA" == "qtfaststart" ]]
                then
                    if [[ $(brew list | grep ffmpeg) != "" ]]
                    then
                        brew unlink qtfaststart
                        brew unlink ffmpeg && brew link ffmpeg
                        brew link --overwrite qtfaststart
                    else
                        :
                    fi
                elif [[ "$FORMULA" == "ffmpeg" ]]
                then
                    if [[ $(brew list | grep qtfaststart) != "" ]]
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
                ${USE_PASSWORD} | brew upgrade "$FORMULA"
                #
            fi
            echo 'removing old installed versions of '"$FORMULA"'...'
            ${USE_PASSWORD} | brew cleanup "$FORMULA"
            echo ''
            
            # cleanup entries
            local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAE_PATH"/"$FORMULA" | sort -V)
            local NUMBER_OF_INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//')
            if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
            then
                echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$FORMULA" >> "$TMP_DIR_FORMULAE_VERSIONS"/"$DATE_LIST_FILE_FORMULAE_VERSIONS"
            else
                :
            	#echo "only one version installed..."
            fi
        done <"$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE"
        
        # special ffmpeg
        # versions > 4.0.2_1 include h265 by default, so rebuilding does not seem to be needed any more
        if [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "ffmpeg") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "fdk-aac") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "sdl2") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "freetype") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "libass") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "libvorbis") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "libvpx") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "opus") != "" ]] || [[ $(cat "$TMP_DIR_FORMULAE"/"$DATE_LIST_FILE_FORMULAE" | grep "x265") != "" ]]
        then
            #${USE_PASSWORD} | brew reinstall ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
            if [[ $(ffmpeg -codecs 2>&1 | grep "\-\-enable-libx265") == "" ]]
            then
                #echo "rebuilding ffmpeg due to components updates..."
                #${USE_PASSWORD} | HOMEBREW_DEVELOPER=1 brew reinstall --build-from-source ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
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
    if [ -e "$TMP_DIR_CASK" ]
    then
        if [ "$(ls -A $TMP_DIR_CASK/)" ]
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
    if [ -e "$TMP_DIR_CASK_VERSIONS" ]
    then
        if [ "$(ls -A $TMP_DIR_CASK_VERSIONS/)" ]
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
        local CASK_INFO=$(brew cask info --json=v1 "$CASK" | jq .[])
        #local CASK_INFO=$(brew cask info "$CASK")
        local CASK_NAME=$(echo "$CASK_INFO" | jq -r '.name | .[]')
        #local CASK_NAME=$(echo "$CASK" | cut -d ":" -f1 | xargs)
        local NEW_VERSION=$(echo "$CASK_INFO" | jq -r '.version')
        #local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | head -1 | sed 's|(auto_updates)||g' | sed 's/^ *//' | sed 's/ *$//')
        local NUMBER_OF_INSTALLED_CASKS=$(echo "$INSTALLED_CASKS" | wc -l | sed 's/^ *//' | sed 's/ *$//')
        local NUMBER_OF_CASK=$(echo "$INSTALLED_CASKS" | grep -n "^$CASK$" | awk -F: '{print $1}' | sed 's/^ *//' | sed 's/ *$//')
        local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
        #echo INSTALLED_VERSIONS is "$INSTALLED_VERSIONS"
        local NUMBER_OF_INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
        #echo NUMBER_OF_INSTALLED_VERSIONS is "$NUMBER_OF_INSTALLED_VERSIONS"
        local NEWEST_INSTALLED_VERSION=$(echo "$INSTALLED_VERSIONS" | head -n 1)
        #local NEWEST_INSTALLED_VERSION="$NEW_VERSION"
        #echo NEWEST_INSTALLED_VERSION is "$NEWEST_INSTALLED_VERSION"
        local CHECK_RESULT=$(echo "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo ok || echo outdated)
        #echo CHECK_RESULT is $CHECK_RESULT
        local CASK_NAME_PRINT=$(echo "$CASK" | awk -v len=20 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local CURRENT_INSTALLED_VERSION_PRINT=$(echo "$NEWEST_INSTALLED_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        #local CURRENT_INSTALLED_VERSION_PRINT=$(echo "$NEWEST_INSTALLED_VERSION" | cut -d ":" -f1 | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local NEW_VERSION_PRINT=$(echo "$NEW_VERSION" | awk -v len=15 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
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
    export -f casks_show_updates_parallel_inside

    parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k casks_show_updates_parallel_inside ::: "$(echo "$INSTALLED_CASKS")"
    wait

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
        
        start_sudo
        applications_to_reinstall=(
        "adobe-acrobat-reader"
        )
        for i in "${applications_to_reinstall[@]}"
        do
        	if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS" | grep "$i") != "" ]]
        	then
                echo 'updating '"$i"'...'
                ${USE_PASSWORD} | brew cask reinstall "$i"
                #sed -i "" "/""$i""/d" "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
                sed -i '' '/'"$i"'/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
                echo ''
        	else
        		:
        	fi
        done
    
        # updating all casks that are out of date
        while IFS='' read -r line || [[ -n "$line" ]]
        do
            CASK="$line"
            
            echo 'updating '"$CASK"'...'
            # uninstall deletes autostart entries
            #sudo brew cask uninstall "$line" --force
            #${USE_PASSWORD} | brew cask uninstall "$line" --force 1> /dev/null
            #sudo brew cask install "$line" --force
            # reinstall deletes autostart entries as it runs uninstall and then install
            #${USE_PASSWORD} | brew cask reinstall "$line" --force
            ${USE_PASSWORD} | brew cask install "$CASK" --force
            echo ''
            
            # cleanup entries
            local INSTALLED_VERSIONS=$(ls -1tc "$BREW_CASKS_PATH"/"$CASK")
            local NUMBER_OF_INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
            if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
            then
                echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$CASK" >> "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASKS_VERSIONS"
            else
                :
            	#echo "only one version installed..."
            fi
        done <"$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASKS"
        stop_sudo
    
        echo "installing casks updates finished ;)"

    fi

}

post_cask_installations() {
    
    ### manual installations after install
    
    #if [[ "$VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE" == "yes" ]]
    #then
    #    start_sudo
    #    echo 'updating virtualbox...'
    #    ${USE_PASSWORD} | brew cask reinstall virtualbox --force
    #    echo ''
    #    echo 'updating virtualbox-extension-pack...'
    #    ${USE_PASSWORD} | brew cask reinstall virtualbox-extension-pack --force
    #    stop_sudo
    #    echo ''
    #else
    #    :
    #fi
    
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
    
}

###
### running script
###

#printf "\033c"
printf "\ec"

echo ''
#echo "updating homebrew, formulae and casks..."
echo -e "\033[1mupdating homebrew, formulae and casks...\033[0m"
echo ''

function get_running_subprocesses()
{
    SUBPROCESSES_PID_TEXT=$(pgrep -lg $(ps -o pgid= $$) | grep -v $$ | grep -v grep)
    SCRIPT_COMMAND=$(ps -o comm= $$)
	PARENT_SCRIPT_COMMAND=$(ps -o comm= $PPID)
	if [[ $PARENT_SCRIPT_COMMAND == "bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "-bash" ]] || [[ $PARENT_SCRIPT_COMMAND == "" ]]
	then
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | awk '{print $1}')
    else
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | grep -v "$PARENT_SCRIPT_COMMAND" | awk '{print $1}')
    fi
}

function kill_subprocesses() {
    # kills only subprocesses of the current process
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    #echo "killing processes..."
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # giving subprocesses the chance to terminate cleanly kill -15
    get_running_subprocesses
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -15 $RUNNING_SUBPROCESSES
        # do not wait here if a process can not terminate cleanly
        #wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # waiting for clean subprocess termination
    TIME_OUT=0
    while [[ $RUNNING_SUBPROCESSES != "" ]] && [[ $TIME_OUT -lt 3 ]]
    do
        get_running_subprocesses
        sleep 1
        TIME_OUT=$((TIME_OUT+1))
    done
    # killing the rest of the processes kill -9
    get_running_subprocesses
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -9 $RUNNING_SUBPROCESSES
        wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # unsetting variable
    unset RUNNING_SUBPROCESSES
}

function kill_main_process() {
    # kills processes itself
    #kill $$
    kill -13 $$
}

function unset_variables() {
    unset SUDOPASSWORD
    unset USE_PASSWORD
    unset TMP_DIR_FORMULAE
    unset TMP_DIR_CASK
    unset DATE_LIST_FILE_FORMULAE
    unset DATE_LIST_FILE_CASKS
    unset BREW_FORMULAE_PATH
    unset BREW_CASKS_PATH  
}

function start_sudo() {
    ${USE_PASSWORD} | builtin command sudo -p '' -S -v
    ( while true; do ${USE_PASSWORD} | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID="$!"
}

function stop_sudo() {
    if [[ $(echo $SUDO_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then
            sudo kill -9 $SUDO_PID &> /dev/null
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}

ask_for_variable () {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}


### trapping
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_SOURCED="yes" || SCRIPT_SOURCED="no"
[[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"
# a sourced script does not exit, it ends with return, so checking for session master is sufficent
# subprocesses will not be killed on return, only on exit
#if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_SOURCED" == "no" ]]
if [[ "$SCRIPT_SESSION_MASTER" == "yes" ]]
then
    # script is session master and not run from another script (S on mac Ss on linux)
    trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "kill_subprocesses >/dev/null 2>&1; unset SUDOPASSWORD; exit" EXIT
else
    # script is not session master and run from another script (S+ on mac and linux)
    trap "printf '\n'; unset SUDOPASSWORD; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "unset SUDOPASSWORD; exit" EXIT
fi
#set -e

# creating directory and adjusting permissions
echo "checking directory structure and permissions..."
echo ''

if [[ ! -d /usr/local ]]; 
then
    sudo mkdir /usr/local
fi
#sudo chown -R $USER:staff /usr/local
sudo chown -R $(whoami) /usr/local

# checking if homebrew is installed
if [[ $(which brew) == "" ]]
then
    echo "homebrew not installed, exiting script..."
    exit
else
    echo "homebrew is installed..."
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
echo ''

# checking if online
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [[ $? -eq 0 ]]
then
    echo "we are online, running script..."
    echo ''

    # installing command line tools (command line)
    #if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ "$(ls -A "$(xcode-select -print-path)")" ]]
    if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -nz "$(ls -A "$(xcode-select -print-path)")" ]]
    then
      	echo "command line tools are installed..."
    else
    	echo "command line tools are not installed, installing..."
    	# prompting the softwareupdate utility to list the command line tools
        touch "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
        sleep 3
        softwareupdate --list >/dev/null 2>&1
        COMMANDLINETOOLVERSION=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools" | grep $(echo $MACOS_VERSION | cut -f1,2 -d'.'))
        softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLVERSION" | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//')"
        # removing tmp file that forces command line tools to show up
        if [[ -e "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress" ]]
        then
            rm -f "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
        else
            :
        fi
    fi
    
    sudo xcode-select --switch /Library/Developer/CommandLineTools
    
    # keeping homebrew from updating each time "brew" is used
    export HOMEBREW_NO_AUTO_UPDATE=1
    
    # checking if all script dependencies are installed
    echo ''
    echo "checking for script dependencies..."
    if [[ $(brew list | grep jq) == '' ]] || [[ $(brew list | grep parallel) == '' ]]
    then
        echo "not all script dependencies installed, installing..."
        ${USE_PASSWORD} | brew install jq parallel
    else
        echo "all script dependencies installed..."
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
    BREW_CASKS_PATH=$(brew cask doctor | grep -A1 -B1 "Cask Staging Location" | tail -1)
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
    
    sudo()
    {
        ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
    }
    
    #VARIABLE_TO_CHECK="$CONT_LATEST"
    #QUESTION_TO_ASK='do you want to update all installed casks that show "latest" as version (y/N)? '
    #ask_for_variable
    #CONT_LATEST="$VARIABLE_TO_CHECK"
    CONT_LATEST="no"
    
    homebrew_update
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
    cleanup_all_homebrew & pids+=($!)
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

else
    echo "not online, skipping updates..."
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
