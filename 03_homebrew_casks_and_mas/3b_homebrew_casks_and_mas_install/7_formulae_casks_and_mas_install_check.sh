#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### script frame
###

# if script is run standalone, not sourced from another script, load script frame
if [[ "$SCRIPT_IS_SOURCED" == "yes" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
       	. "$SCRIPT_DIR"/1_script_frame.sh
       	eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
    else
        echo ''
        echo "script for functions and prerequisits is missing, exiting..."
        echo ''
        exit
    fi
fi




###
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_TWO_BACK"/_user_profiles
env_check_for_user_profile



###
###
### homebrew
###

checking_homebrew


### parallel
echo ''
env_check_if_parallel_is_installed


### variables
casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
homebrew_formulae=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_formulae.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d' | grep -vi "xtrafinder" | grep -vi "totalfinder")
finder_enhancements=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d' | grep -i -e "xtrafinder" -e "totalfinder")
casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
mas_apps=$(cat "$SCRIPT_DIR"/_lists/04_mas_apps.txt | sed '/^#/ d' | sed '/^$/d' | sort -k 2 -t $'\t' --ignore-case)


###
### mas appstore apps
###

check_mas_apps() {
# always use _ instead of - because some sh commands called by parallel would give errors
	#echo doing it for $1
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# if parallels is used i needs to be redefined
		i="$1"
	else
		:
	fi
	#echo ''
	#echo "$i"
	MAS_NUMBER=$(echo "$i" | awk '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	#echo $MAS_NUMBER
	MAS_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	#echo $MAS_NAME
	#if [[ $(mas list | grep "$MAS_NUMBER") != "" ]]
	# better results when batch installing from appstore as mas takes a while to register the app as installed in mas list
	# checks if installed from appstore
	#if [[ $(find "$PATH_TO_APPS" -path '*Contents/_MASReceipt/receipt' -maxdepth 4 -print | sed 's#.app/Contents/_MASReceipt/receipt#.app#g; s#/Applications/##' | grep "$MAS_NAME") != "" ]]
	if [[ $(find "$PATH_TO_APPS" -path '*Contents/_MASReceipt/receipt' -maxdepth 4 -print | sed 's#.app/Contents/_MASReceipt/receipt#.app#g; s#/Applications/##' | rev | cut -f 1 -d '/' | rev | grep "$MAS_NAME") != "" ]]
	then
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$MAS_NAME"
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$MAS_NAME" >&2
	fi
}

# xargs is not capable of sorting the output, use parallels instead if keeping output order is needed
if [[ $(echo "$CHECK_IF_MASAPPS_INSTALLED") == "no" ]]
then
	:
else
    echo "checking mas appstore apps installation..."
    sleep 1
    # updating index
	mas list >/dev/null
	sleep 2
	mas list >/dev/null
	sleep 2
    #echo "waiting for mas index to get ready..."
    #while [[ $(mas list) == "" ]]
    #do
    #    sleep 1
    #done
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
    then
        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
        # it is not neccessary to export variables or functions when using env_parallel
        # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
    	if [[ "${mas_apps[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "check_mas_apps {}" ::: "${mas_apps[@]}"; fi
    else
        #echo "checking mas apps sequential..."
        if [[ "${mas_apps[@]}" != "" ]]
        then
            while IFS= read -r line || [[ -n "$line" ]] 
			do
			    if [[ "$line" == "" ]]; then continue; fi
                i="$line"
                check_mas_apps "$i"
            done <<< "$(printf "%s\n" "${mas_apps[@]}")"
        else
            :
        fi
    fi
    echo ''
fi


###
### homebrew packages
###

check_homebrew_formulae() {
# always use _ instead of - because some sh commands called by parallel would give errors
	#echo doing it for $1
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# if parallels is used i needs to redefined
		i="$1"
	else
		:
	fi
	#if [[ $(brew info "$item" | grep "Not installed") == "" ]];
	if [[ $(brew list --formula | tr "," "\n" | grep "^$i$") != "" ]] || [[ $(brew list --formula | tr "," "\n" | grep "@" | grep "^$i.*$") != "" ]]
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$i"
	else
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$i" >&2
	fi
}


# listing installed homebrew packages
#echo "the following top-level homebrew packages incl. dependencies are installed..."
#brew leaves | tr "," "\n"
# echo "the following homebrew packages are installed..."
#brew list --formula | tr "," "\n"
#echo ""

# listing installed casks
#echo "the following casks are installed..."
#brew list --cask | tr "," "\n"
    
# checking if successfully installed
# homebrew packages
if [[ $(echo "$CHECK_IF_FORMULAE_INSTALLED") == "no" ]]
then
	:
else
    #echo ''
    echo "checking homebrew formulae installation..."
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
    then
        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
        # it is not neccessary to export variables or functions when using env_parallel
        # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
    	if [[ "${homebrew_formulae[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "check_homebrew_formulae {}" ::: "${homebrew_formulae[@]}"; fi
    else
        #echo "checking formulae sequential..."
        if [[ "${homebrew_formulae[@]}" != "" ]]
        then
            while IFS= read -r line || [[ -n "$line" ]] 
			do
			    if [[ "$line" == "" ]]; then continue; fi
                i="$line"
                check_homebrew_formulae "$i"
            done <<< "$(printf "%s\n" "${homebrew_formulae[@]}")"
        else
            :
        fi
    fi
    echo ''
fi


###
### casks
###

check_casks() {
# always use _ instead of - because some sh commands called by parallel would give errors
	#echo doing it for $1
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# if parallels is used i needs to redefined
		i="$1"
	else
		:
	fi
	if [[ $(brew list --cask | tr "," "\n" | grep "^$i$") != "" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$i"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$i" >&2; 
	fi
}


if [[ $(echo "$CHECK_IF_CASKS_INSTALLED") == "no" ]]
then
	:
else
    #echo ''
    echo "checking casks installation..."
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
    then
    	# by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
        # it is not neccessary to export variables or functions when using env_parallel
        # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
        # casks_pre
        if [[ "${casks_pre[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "check_casks {}" ::: "${casks_pre[@]}"; fi
    	# casks
    	if [[ "${casks[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "check_casks {}" ::: "${casks[@]}"; fi
    	# casks specific1
    	if [[ INSTALL_SPECIFIC_CASKS1 == "yes" ]]
    	then
    	    echo ''
    	    echo checking casks specific1 installation...
    	    if [[ "${casks_specific1[@]}" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer -k "check_casks {}" ::: "${casks_specific1[@]}"; fi
    	else
    	    :
    	fi
    else
        #echo "checking casks sequential..."
        # casks_pre
        if [[ "${casks_pre[@]}" != "" ]]
        then
            while IFS= read -r line || [[ -n "$line" ]] 
			do
			    if [[ "$line" == "" ]]; then continue; fi
                i="$line"
                check_casks "$i"
            done <<< "$(printf "%s\n" "${casks_pre[@]}")"
        else
            :
        fi
        # casks
        if [[ "${casks[@]}" != "" ]]
        then
            while IFS= read -r line || [[ -n "$line" ]] 
			do
			    if [[ "$line" == "" ]]; then continue; fi
                i="$line"
                check_casks "$i"
            done <<< "$(printf "%s\n" "${casks[@]}")"
        else
            :
        fi
        if [[ "$INSTALL_SPECIFIC_CASKS1" == "yes" ]]
    	then
            if [[ "${casks_specific1[@]}" != "" ]]
            then
        	    # casks specific1
        	    while IFS= read -r line || [[ -n "$line" ]] 
				do
				    if [[ "$line" == "" ]]; then continue; fi
                    i="$line"
                    check_casks "$i"
            	done <<< "$(printf "%s\n" "${casks_specific1[@]}")"
            else
                :
            fi
        else
            :
        fi
    fi
    
	# additonal apps / xtrafinder
	echo ''
	echo "checking additional apps installation..."
    if [[ "${finder_enhancements[@]}" != "" ]]
    then
	    # casks specific1
	    while IFS= read -r line || [[ -n "$line" ]] 
		do
		    if [[ "$line" == "" ]]; then continue; fi
            i="$line"
            i=$(echo "$i" | tr '[:upper:]' '[:lower:]')
           	if [[ -e ""$PATH_TO_APPS"/"$i".app" ]]
			then 
				printf "%-50s\e[1;32mok\e[0m%-10s\n" ""$i""
			else 
				printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" ""$i"" >&2
			fi
    	done <<< "$(printf "%s\n" "${finder_enhancements[@]}")"
    else
        :
    fi
fi

#echo ''


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
