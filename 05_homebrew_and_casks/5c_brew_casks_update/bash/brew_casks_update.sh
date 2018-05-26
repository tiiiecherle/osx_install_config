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

homebrew-update() {
    echo ''
    echo "updating homebrew..."
    brew update-reset 1> /dev/null 2> >(grep -v "Reset branch" 1>&2) && brew analytics off 1> /dev/null && brew update 1> /dev/null && brew prune 1> /dev/null && brew doctor 1> /dev/null
    echo 'updating homebrew finished ;)'
}

cleanup-all-homebrew-only() {
    echo ''
    echo "cleaning up..."
    #brew cleanup
    #brew cask cleanup
    brew cleanup 1> /dev/null
    brew cask cleanup 1> /dev/null
    echo 'cleaning finished ;)'
}

cleanup-all-parallel() {
    echo ''
    echo "cleaning up..."
    #brew cleanup
    #brew cask cleanup
    brew cleanup 1> /dev/null
    brew cask cleanup 1> /dev/null
    
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
    DATE_LIST_FILE_CASK_VERSIONS=$(echo "casks_versions"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_CASK_VERSIONS
    touch "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASK_VERSIONS"
    
    cask_check_for_multiple_installed_versions() {
        local v="$1"
        local CASK_INFO=$(brew cask info "$v")
        local CASK_NAME=$(echo "$v" | cut -d ":" -f1 | xargs)
        local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//')
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_CASKS_PATH"/"$v" | sort -V)
        local NUMBER_OF_INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
        
        if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
        then
            echo -e "$NUMBER_OF_INSTALLED_VERSIONS\t$CASK_NAME" >> "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASK_VERSIONS"
        else
            :
        	#echo "only one version installed..."
        fi 

        CASK_INFO=""
        CASK_NAME=""
        NEW_VERSION=""
        INSTALLED_VERSIONS=""
    }

    #
    local NUMBER_OF_CORES=$(parallel --number-of-cores)
    local NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.5" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    local NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
    local NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED=$(echo "$NUMBER_OF_MAX_JOBS_ROUNDED * 2.0" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED
    local NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED_DOUBLED_ROUNDED
    #
    export -f cask_check_for_multiple_installed_versions
    #
    parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k cask_check_for_multiple_installed_versions ::: "$(brew cask list)"
    wait
    
    sort "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASK_VERSIONS" -o "$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASK_VERSIONS"

    while IFS='' read -r line || [[ -n "$line" ]]
    do
            CASK_TO_CLEAN=$(echo "$line" | awk '{print $2}')
            #echo ''
        	#echo "$(echo "$line" | awk '{print $1}') versions of $CASK_TO_CLEAN are installed..."
        	#echo "uninstalling all outdated versions..."
        	if [[ -e "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN" ]]
        	then
        	    # uninstall old versions
        	    local CASK_INFO=$(brew cask info "$CASK_TO_CLEAN")
                local CASK_NAME=$(echo "$CASK_TO_CLEAN" | cut -d ":" -f1 | xargs)
                local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//')
        	    local INSTALLED_VERSIONS=$(ls -1 "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN" | sort -V)
        	    local VERSIONS_TO_UNINSTALL=$(echo "$INSTALLED_VERSIONS" | grep -v "$NEW_VERSION")
        	    for i in $VERSIONS_TO_UNINSTALL
                do
                    #echo $i
                    # deleting version entry
                    if [[ -e "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/"$i" && $(echo "$i") != "" ]]
                    then
                        rm -rf "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/"$i"
                    else
                        :
                    fi
                    # deleting metadata version entry
                    if [[ -e "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/.metadata/"$i" && $(echo "$i") != "" ]]
                    then
                        rm -rf "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/.metadata/"$i"
                    else
                        :
                    fi
                done
        	else
        	    :
        	fi
        #
        CASK_INFO=""
        CASK_NAME=""
        NEW_VERSION=""
        INSTALLED_VERSIONS=""
        VERSIONS_TO_UNINSTALL=""
        CASK_TO_CLEAN=""
    done <"$TMP_DIR_CASK_VERSIONS"/"$DATE_LIST_FILE_CASK_VERSIONS"

    # checking if more than version is installed by using
    # brew cask list --versions
    
    # fixing red dots before confirming commit to cask-repair that prevent the commit from being made
    # https://github.com/vitorgalvao/tiny-scripts/issues/88
    sudo gem uninstall -ax rubocop rubocop-cask 1> /dev/null
    brew cask style 1> /dev/null
    
    #echo ''
    echo 'cleaning finished ;)'
}

cleanup-all-one-by-one() {
    echo ''
    echo "cleaning up..."
    #brew cleanup
    #brew cask cleanup
    brew cleanup 1> /dev/null
    brew cask cleanup 1> /dev/null
    #
    for i in $(brew cask list)
    do
        local CASK_INFO=$(brew cask info "$i")
        local CASK_NAME=$(echo "$i" | cut -d ":" -f1 | xargs)
        local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//')
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_CASKS_PATH"/"$i" | sort -V)
        local NUMBER_OF_INSTALLED_VERSIONS=$(echo "$INSTALLED_VERSIONS" | wc -l | sed -e 's/^[ \t]*//') 
        local VERSIONS_TO_UNINSTALL=$(echo "$INSTALLED_VERSIONS" | grep -v "$NEW_VERSION")

        if [[ "$NUMBER_OF_INSTALLED_VERSIONS" -gt "1" ]]
        then
            CASK_TO_CLEAN=$(echo "$i")
            #echo ''
        	#echo "$NUMBER_OF_INSTALLED_VERSIONS versions of $CASK_TO_CLEAN are installed..."
        	#echo "uninstalling all outdated versions..."
    	    for i in $VERSIONS_TO_UNINSTALL
            do
                #echo $i
                # deleting version entry
                if [[ -e "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/"$i" && $(echo "$i") != "" ]]
                then
                    rm -rf "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/"$i"
                else
                    :
                fi
                # deleting metadata version entry
                if [[ -e "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/.metadata/"$i" && $(echo "$i") != "" ]]
                then
                    rm -rf "$BREW_CASKS_PATH"/"$CASK_TO_CLEAN"/.metadata/"$i"
                else
                    :
                fi
            done
        else
            :
        	#echo "only one version installed..."
        fi 
            
        CASK_INFO=""
        CASK_NAME=""
        NEW_VERSION=""
        INSTALLED_VERSIONS=""
        VERSIONS_TO_UNINSTALL=""
        CASK_TO_CLEAN=""
    done
    #
    echo 'cleaning finished ;)'
}

# upgrading all homebrew formulas
brew_show_updates_parallel() {
    # always use _ instead of - because some sh commands called by parallel would give errors

    echo "listing brew formulas updates..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "BREW NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'
    
    TMP_DIR_BREW=/tmp/brew_updates
    export TMP_DIR_BREW

    if [ -e "$TMP_DIR_BREW" ]
    then
        if [ "$(ls -A $TMP_DIR_BREW/)" ]
        then
            rm "$TMP_DIR_BREW"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p "$TMP_DIR_BREW"/
    DATE_LIST_FILE_BREW=$(echo "brew_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_BREW
    touch "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW"

    brew_show_updates_parallel_inside() {
        # always use _ instead of - because some sh commands called by parallel would give errors
        local item="$1"
        local BREW_INFO=$(brew info $item)
        #echo BREW_INFO is $BREW_INFO
        local BREW_NAME=$(echo "$BREW_INFO" | grep -e "$item: .*" | cut -d" " -f1 | sed 's/://g')
        #echo BREW_NAME is $BREW_NAME
        # make sure you have jq installed via brew
        local BREW_REVISION=$(brew info "$item" --json=v1 | jq . | grep revision | grep -o '[0-9]')
        #echo BREW_REVISION is $BREW_REVISION
        if [[ "$BREW_REVISION" == "0" ]]
        then
            local NEW_VERSION=$(echo "$BREW_INFO" | grep -e "$item: .*" | cut -d" " -f3 | sed 's/,//g')
        else
            local NEW_VERSION=$(echo $(echo "$BREW_INFO" | grep -e "$item: .*" | cut -d" " -f3 | sed 's/,//g')_"$BREW_REVISION")
        fi
        #echo NEW_VERSION is $NEW_VERSION
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAS_PATH"/"$item" | sort -V)
        #echo INSTALLED_VERSIONS is $INSTALLED_VERSIONS
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo -e '\033[1;32mtrue\033[0m' || echo -e '\033[1;31mfalse\033[0m')
        #echo IS_CURRENT_VERSION_INSTALLED is $IS_CURRENT_VERSION_INSTALLED
        printf "%-35s | %-20s | %-15s\n" "$item" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"
        
        # installing if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == "$(echo -e '\033[1;31mfalse\033[0m')" ]] && [[ ${CASK_EXCLUDES} != *"$BREW_NAME"* ]]
        then
            echo "$BREW_NAME" >> "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW"
        fi
    }
    
    #
    local NUMBER_OF_CORES=$(parallel --number-of-cores)
    local NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.5" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    local NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
    #
    export -f brew_show_updates_parallel_inside
    #
    parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k brew_show_updates_parallel_inside ::: "$(brew list)"
    wait
        
    echo "listing brew formulas updates finished ;)"
}

brew-show-updates-one-by-one() {
    echo "listing brew formulas updates..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "BREW NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'
    
    TMP_DIR_BREW=/tmp/brew_updates
    if [ -e "$TMP_DIR_BREW" ]
    then
        if [ "$(ls -A $TMP_DIR_BREW/)" ]
        then
            rm "$TMP_DIR_BREW"/*    
        else
            :
        fi
    else
        :
    fi
    mkdir -p "$TMP_DIR_BREW"/
    DATE_LIST_FILE_BREW=$(echo "brew_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    touch "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW"

    for item in $(brew list); do
        local BREW_INFO=$(brew info $item)
        #echo BREW_INFO is $BREW_INFO
        local BREW_NAME=$(echo "$BREW_INFO" | grep -e "$item: .*" | cut -d" " -f1 | sed 's/://g')
        #echo BREW_NAME is $BREW_NAME
        # make sure you have jq installed via brew
        local BREW_REVISION=$(brew info "$item" --json=v1 | jq . | grep revision | grep -o '[0-9]')
        #echo BREW_REVISION is $BREW_REVISION
        if [[ "$BREW_REVISION" == "0" ]]
        then
            local NEW_VERSION=$(echo "$BREW_INFO" | grep -e "$item: .*" | cut -d" " -f3 | sed 's/,//g')
        else
            local NEW_VERSION=$(echo $(echo "$BREW_INFO" | grep -e "$item: .*" | cut -d" " -f3 | sed 's/,//g')_"$BREW_REVISION")
        fi
        #echo NEW_VERSION is $NEW_VERSION
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_FORMULAS_PATH"/"$item" | sort -V)
        #echo INSTALLED_VERSIONS is $INSTALLED_VERSIONS
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo -e '\033[1;32mtrue\033[0m' || echo -e '\033[1;31mfalse\033[0m')
        #echo IS_CURRENT_VERSION_INSTALLED is $IS_CURRENT_VERSION_INSTALLED
        printf "%-35s | %-20s | %-15s\n" "$item" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"
        
        # installing if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == "$(echo -e '\033[1;31mfalse\033[0m')" ]] && [[ ${CASK_EXCLUDES} != *"$BREW_NAME"* ]]
        then
            echo "$BREW_NAME" >> "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW"
        fi

        BREW_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done
    
    echo "listing brew formulas updates finished ;)"
}


brew-install-updates() {
    echo "installing brew formulas updates..."
    
    # sorting the outdated casks file after using parallel which can change output order
    sort "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" -o "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW"
        
    while IFS='' read -r line || [[ -n "$line" ]]
    do
        echo 'updating '"$line"'...'
        ${USE_PASSWORD} | brew upgrade "$line"
        echo 'removing old installed versions of '"$line"'...'
        ${USE_PASSWORD} | brew cleanup "$line"
        echo ''
    done <"$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW"
    
    if [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW") == "" ]]
    then
        echo "no brew formula updates available..."
    else
        echo "installing brew formulas updates finished ;)"
    fi
    # special ffmpeg
    if [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "ffmpeg") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "fdk-aac") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "sdl2") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "freetype") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "libass") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "libvorbis") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "libvpx") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "opus") != "" ]] || [[ $(cat "$TMP_DIR_BREW"/"$DATE_LIST_FILE_BREW" | grep "x265") != "" ]]
    then
        echo "rebuilding ffmpeg due to components updates..."
        ${USE_PASSWORD} | brew reinstall ffmpeg --with-fdk-aac --with-sdl2 --with-freetype --with-libass --with-libvorbis --with-libvpx --with-opus --with-x265
    else
        :
    fi
    
}

# selectively upgrade casks
cask_show_updates_parallel () {
    # always use _ instead of - because some sh commands called by parallel would give errors
    echo "listing casks updates..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "CASK NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'
    
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
    DATE_LIST_FILE_CASK=$(echo "casks_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_CASK
    DATE_LIST_FILE_CASK_LATEST=$(echo "casks_update_latest"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    export DATE_LIST_FILE_CASK_LATEST
    touch "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
    touch "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK_LATEST"
    
    cask_show_updates_parallel_inside() {
        # always use _ instead of - because some sh commands called by parallel would give errors
        local c="$1"
        local CASK_INFO=$(brew cask info $c)
        local CASK_NAME=$(echo "$c" | cut -d ":" -f1 | xargs)
        #echo "CASK_NAME is $CASK_NAME"
        #if [[ $(brew cask info $c | tail -1 | grep "(app)") != "" ]]
        #then
        #    APPNAME=$(brew cask info $c | tail -1 | awk '{$(NF--)=""; print}' | sed 's/ *$//')
        #else
        #    APPNAME=$(echo $(brew cask info $c | grep -A 1 "==> Name" | tail -1).app)
        #fi
        #local INSTALLED_VERSIONS=$(plutil -p "/Applications/$APPNAME/Contents/Info.plist" | grep "CFBundleShortVersionString" | awk '{print $NF}' | sed 's/"//g')
        local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//')
        #echo NEW_VERSION is $NEW_VERSION
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_CASKS_PATH"/"$c" | sort -V)
        #echo INSTALLED_VERSIONS is $INSTALLED_VERSIONS
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo -e '\033[1;32mtrue\033[0m' || echo -e '\033[1;31mfalse\033[0m')
        #echo IS_CURRENT_VERSION_INSTALLED is $IS_CURRENT_VERSION_INSTALLED
        printf "%-35s | %-20s | %-15s\n" "$CASK_NAME" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"
        
        # installing if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == "$(echo -e '\033[1;31mfalse\033[0m')" ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            echo "$CASK_NAME" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
        fi
        
        if [[ "$NEW_VERSION" == "latest" ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            echo "$CASK_NAME" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK_LATEST"
        fi
    }
    
    #
    local NUMBER_OF_CORES=$(parallel --number-of-cores)
    local NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.5" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    local NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
    #
    export -f cask_show_updates_parallel_inside
    #
    parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k cask_show_updates_parallel_inside ::: "$(brew cask list)"
    wait
        
    echo "listing casks updates finished ;)"
    
}

cask-show-updates-one-by-one() {
    echo "listing casks updates..."

    printf '=%.0s' {1..80}
    printf '\n'
    printf "%-35s | %-20s | %-5s\n" "CASK NAME" "LATEST VERSION" "LATEST INSTALLED"
    printf '=%.0s' {1..80}
    printf '\n'
    
    TMP_DIR_CASK=/tmp/cask_updates
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
    DATE_LIST_FILE_CASK=$(echo "casks_update"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    DATE_LIST_FILE_CASK_LATEST=$(echo "casks_update_latest"_$(date +%Y-%m-%d_%H-%M-%S).txt)
    touch "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
    touch "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK_LATEST"
    
    for c in $(brew cask list); do
        local CASK_INFO=$(brew cask info $c)
        local CASK_NAME=$(echo "$c" | cut -d ":" -f1 | xargs)
        #if [[ $(brew cask info $c | tail -1 | grep "(app)") != "" ]]
        #then
        #    APPNAME=$(brew cask info $c | tail -1 | awk '{$(NF--)=""; print}' | sed 's/ *$//')
        #else
        #    APPNAME=$(echo $(brew cask info $c | grep -A 1 "==> Name" | tail -1).app)
        #fi
        #local INSTALLED_VERSIONS=$(plutil -p "/Applications/$APPNAME/Contents/Info.plist" | grep "CFBundleShortVersionString" | awk '{print $NF}' | sed 's/"//g')
        local NEW_VERSION=$(echo "$CASK_INFO" | grep -e "$CASK_NAME: .*" | cut -d ":" -f2 | sed 's/ *//' )
        #echo NEW_VERSION is $NEW_VERSION
        local INSTALLED_VERSIONS=$(ls -1 "$BREW_CASKS_PATH"/"$c" | sort -V)
        #echo INSTALLED_VERSIONS is $INSTALLED_VERSIONS
        local IS_CURRENT_VERSION_INSTALLED=$(echo "$INSTALLED_VERSIONS" | grep -q "$NEW_VERSION" 2>&1 && echo -e '\033[1;32mtrue\033[0m' || echo -e '\033[1;31mfalse\033[0m')
        #echo IS_CURRENT_VERSION_INSTALLED is $IS_CURRENT_VERSION_INSTALLED

        printf "%-35s | %-20s | %-15s\n" "$CASK_NAME" "$NEW_VERSION" "$IS_CURRENT_VERSION_INSTALLED"
        
        # installing if not up-to-date and not excluded
        if [[ "$IS_CURRENT_VERSION_INSTALLED" == "$(echo -e '\033[1;31mfalse\033[0m')" ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            echo "$CASK_NAME" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
        fi
        
        if [[ "$NEW_VERSION" == "latest" ]] && [[ ${CASK_EXCLUDES} != *"$CASK_NAME"* ]]
        then
            echo "$CASK_NAME" >> "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK_LATEST"
        fi

        CASK_INFO=""
        NEW_VERSION=""
        IS_CURRENT_VERSION_INSTALLED=""
    done
    
    echo "listing casks updates finished ;)"
}


cask-install-updates() {
    echo "installing casks updates..."
    
    # virtualbox has to be updated before virtualbox-extension-pack
    # checking if there is an update for virtualbox-extension-pack available, deleting the line in the file and install it manually later
    # done by sorting the file after using parallel which can change output order
    #if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK" | grep virtualbox-extension-pack) == "" ]]
    #then
    #    VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE=no
    #else
    #    VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE=yes
    #    sed -i '' '/virtualbox-extension-pack/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
    #    sed -i '' '/virtualbox/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
    #fi
    #echo "$VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE"
    
    # sorting the outdated casks file after using parallel which can change output order
    sort "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK" -o "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
    
    start_sudo
    applications_to_reinstall=(
    "adobe-acrobat-reader"
    )
    for i in "${applications_to_reinstall[@]}"
    do
    	if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK" | grep "$i") != "" ]]
    	then
            echo 'updating '"$i"'...'
            ${USE_PASSWORD} | brew cask reinstall "$i"
            #sed -i "" "/""$i""/d" "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
            sed -i '' '/'"$i"'/d' "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
            echo ''
    	else
    		:
    	fi
    done

    # updating all casks that are out of date
    while IFS='' read -r line || [[ -n "$line" ]]
    do
        echo 'updating '"$line"'...'
        # uninstall deletes autostart entries
        #sudo brew cask uninstall "$line" --force
        #${USE_PASSWORD} | brew cask uninstall "$line" --force 1> /dev/null
        #sudo brew cask install "$line" --force
        # reinstall deletes autostart entries as it runs uninstall and then install
        #${USE_PASSWORD} | brew cask reinstall "$line" --force
        ${USE_PASSWORD} | brew cask install "$line" --force
        echo ''
    done <"$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK"
    stop_sudo
    
    # updating virtualbox-extension-pack if it is outdated
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
    
    #read -p 'do you want to update all installed casks that show "latest" as version (y/N)? ' CONT_LATEST
    #CONT_LATEST="N"
    CONT_LATEST="$(echo "$CONT_LATEST" | tr '[:upper:]' '[:lower:]')"    # tolower
	if [[ "$CONT_LATEST" == "y" || "$CONT_LATEST" == "yes" ]]
    then
        start_sudo
        echo 'updating all installed casks that show "latest" as version...'
        echo ''
        while IFS='' read -r line || [[ -n "$line" ]]
        do
            echo 'updating '"$line"'...'
            # uninstall deletes autostart entries          
            #${USE_PASSWORD} | brew cask uninstall "$line" --force 1> /dev/null
            ${USE_PASSWORD} | brew cask install "$line" --force
            echo ''
        done <"$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK_LATEST"
        stop_sudo
    else
        echo 'skipping all installed casks that show "latest" as version...'
        #echo ''
    fi

    #if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK") == "" ]] && [[ "$VIRTUALBOX_EXTENSION_UPDATE_AVAILABLE" == "no" ]]
    if [[ $(cat "$TMP_DIR_CASK"/"$DATE_LIST_FILE_CASK") == "" ]]
    then
        echo "no cask updates available..."
    else
        echo "installing casks updates finished ;)"
    fi
    
}

###
### running script
###

#printf "\033c"
printf "\ec"

echo ''
#echo "updating homebrew, formulas and casks..."
echo -e "\033[1mupdating homebrew, formulas and casks...\033[0m"
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

function kill_subprocesses() 
{
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

function kill_main_process() 
{
    # kills processes itself
    #kill $$
    kill -13 $$
}

function unset_variables() {
    unset SUDOPASSWORD
    unset USE_PASSWORD
    unset TMP_DIR_BREW
    unset TMP_DIR_CASK
    unset DATE_LIST_FILE_BREW
    unset DATE_LIST_FILE_CASK
    unset DATE_LIST_FILE_CASK_LATEST
    unset BREW_FORMULAS_PATH
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

if [ ! -d /usr/local ]; 
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

# checking if homebrew-cask is installed
#if [[ $(brew cask --version | grep "homebrew-cask") == "" ]]
#then
#    echo "homebrew-cask not installed, exiting script..."
#    exit
#else
#    echo "homebrew-cask is installed..."
#fi
#echo ''

brew cask --version 2>&1 >/dev/null
if [[ $? -eq 0 ]]
then
    echo "homebrew-cask is installed..."
else
    echo "homebrew-cask not installed, exiting script..."
    exit
fi
echo ''

# checking if online
echo "checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1
if [[ $? -eq 0 ]]
then
    echo "we are online, running script..."
    echo ''
    # installing command line tools
    if xcode-select --install 2>&1 | grep installed >/dev/null
    then
      	echo command line tools are installed...
    else
      	echo command line tools are not installed, installing...
      	while ps aux | grep 'Install Command Line Developer Tools.app' | grep -v grep > /dev/null; do sleep 1; done
      	#sudo xcodebuild -license accept
    fi
    
    sudo xcode-select --switch /Library/Developer/CommandLineTools
    
    function command_line_tools_update () {
        # updating command line tools and system
        echo "checking for command line tools update..."
        COMMANDLINETOOLUPDATE=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools")
        if [ "$COMMANDLINETOOLUPDATE" == "" ]
        then
        	echo "no update for command line tools available..."
        else
        	echo "update for command line tools available, updating..."
        	softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLUPDATE" | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//')"
        fi
        #softwareupdate -i --verbose "$(softwareupdate --list | grep "* Command Line" | sed 's/*//' | sed -e 's/^[ \t]*//')"
    }
    #command_line_tools_update
    
    # keeping homebrew from updating each time brew install is used
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
    BREW_EXCLUDES="${1:-}"
    CASK_EXCLUDES="${2:-}"
    
    # more variables
    echo ''
    BREW_FORMULAS_PATH=$(brew --cellar)
    export BREW_FORMULAS_PATH
    if [[ $(echo "$BREW_FORMULAS_PATH") == "" || ! -e "$BREW_FORMULAS_PATH" ]]
    then
        echo "homebrew formulas path is empty or does not exist, exiting script..."
        exit
    else
        :
    fi
    echo "homebrew formulas are located in "$BREW_FORMULAS_PATH""
    #
    BREW_CASKS_PATH=$(brew cask doctor | grep -A1 -B1 "Homebrew-Cask Staging Location" | tail -1)
    export BREW_CASKS_PATH
    if [[ $(echo "$BREW_CASKS_PATH") == "" || ! -e "$BREW_CASKS_PATH" ]]
    then
        echo "homebrew casks path is empty or does not exist, skipping respective script parts..."
        HOMEBREW_CASK_IS_INSTALLED="no"
    else
        HOMEBREW_CASK_IS_INSTALLED="yes"
        :
    fi
    echo "homebrew casks are located in "$BREW_CASKS_PATH""
    #echo ''
    
    sudo()
    {
        ${USE_PASSWORD} | builtin command sudo -p '' -S "$@"
    }
    
    homebrew-update
    #
    echo ''
    brew_show_updates_parallel
    #brew-show-updates-one-by-one
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        echo ''
        cask_show_updates_parallel
        #cask-show-updates-one-by-one
    else
        :
    fi
    #
    echo ''
    brew-install-updates
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        echo ''
        cask-install-updates
    else
        :
    fi
    #
    if [[ $(echo "$HOMEBREW_CASK_IS_INSTALLED") == "yes" ]]
    then
        cleanup-all-parallel
        #cleanup-all-one-by-one
    else
        cleanup-all-homebrew-only
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
