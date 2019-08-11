#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
 


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
    	# setting empty variable as it is not needed in this script and if not set it would be asked
    	SUDOPASSWORD="   " 
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
###
### homebrew
###

checking_homebrew


### parallel
echo ''
env_check_if_parallel_is_installed


### variables
casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
homebrew_formulae=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_formulae.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
mas_apps=$(cat "$SCRIPT_DIR"/_lists/04_mas_apps.txt | sed '/^#/ d' | sed '/^$/d' | sort -k 2 -t $'\t' --ignore-case)


###
### mas appstore apps
###

check_mas_apps() {
# always use _ instead of - because some sh commands called by parallel would give errors
	#echo doing it for $1
	if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# if parallels is used i needs to redefined
		i="$1"
	else
		:
	fi
	#echo ''
	#echo "$i"
	MAS_NUMBER=$(echo "$i" | awk '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
	#echo $MAS_NUMBER
	MAS_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
	#echo $MAS_NAME
	if [[ $(mas list | grep "$MAS_NUMBER") != "" ]]
	then
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$MAS_NAME";
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$MAS_NAME"
	fi
}

# xargs is not capable of sorting the output, use parallels instead if keeping output order is needed
if [[ $(echo "$CHECK_IF_MASAPPS_INSTALLED") == "no" ]]
then
	:
else
    echo "checking mas appstore apps installation..."
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
	if [[ $(brew list | grep "^$i$") != "" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$i"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$i"; 
	fi
}


# listing installed homebrew packages
#echo "the following top-level homebrew packages incl. dependencies are installed..."
#brew leaves | tr "," "\n"
# echo "the following homebrew packages are installed..."
#brew list | tr "," "\n"
#echo ""

# listing installed casks
#echo "the following casks are installed..."
#brew cask list | tr "," "\n"
    
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
	if [[ $(brew cask list | grep "^$i$") != "" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$i"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$i"; 
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
    	if [[ "$USER" == "tom" ]]
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
        if [[ "$USER" == "tom" ]]
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
	if [[ -e "/Applications/XtraFinder.app" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "xtrafinder"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "xtrafinder"; 
	fi
	#echo ''

fi

#echo ''
