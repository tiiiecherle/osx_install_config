#!/bin/bash

###
### variables
###

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")


###
### script frame
###

# if script is run standalone, not sourced from another script, load script frame
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
then
    # script is sourced
    :
else
    # script is not sourced, run standalone
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
        . "$SCRIPT_DIR"/1_script_frame.sh
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
checking_parallel


### starting sudo
start_sudo


###


### variables
SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
homebrewpackages=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_packages.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d' | awk '{print $1}' | sed 's/ //g' | sed '/^$/d')
mas_apps=$(cat "$SCRIPT_DIR"/_lists/04_mas_apps.txt | sed '/^#/ d' | sed '/^$/d' | sort -k 2 -t $'\t' --ignore-case)


###
### mas appstore apps
###

check_mas_apps() {
# always use _ instead of - because some sh commands called by parallel would give errors
	#echo doing it for $1
	if [[ "$USE_PARALLELS" == "yes" ]]
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
export -f check_mas_apps

# xargs is not capable of sorting the output, use parallels instead if keeping output order is needed
if [[ $(echo "$CHECK_IF_MASAPPS_INSTALLED") == "no" ]]
then
	:
else
	#export USE_PARALLELS="no"
	echo checking mas appstore apps installation...
	printf '%s\n' "${mas_apps[@]}" | tr "\n" "\0" | xargs -0 -n1 -L1 -P4 -I{} bash -c ' 
	i="{}"
	check_mas_apps
	'
	unset parallels
fi



###
### homebrew packages
###

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
	echo ''
	echo checking homebrew package installation...
	printf '%s\n' "${homebrewpackages[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
	item="{}"
	#if [[ $(brew info "$item" | grep "Not installed") == "" ]];
	if [[ $(brew list | grep "^$item$") != "" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
	fi
	'
fi



###
### casks
###

if [[ $(echo "$CHECK_IF_CASKS_INSTALLED") == "no" ]]
then
	:
else   
	# casks
	echo ''
	echo checking casks installation...
	# casks_pre
	#if [[ $(brew cask info "$item" | grep "Not installed") == "" ]];
	printf '%s\n' "${casks_pre[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
	item="{}"
	if [[ $(brew cask list | grep "^$item$") != "" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
	fi
	'
	# casks
	#if [[ $(brew cask info "$item" | grep "Not installed") == "" ]];
	printf '%s\n' "${casks[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
	item="{}"
	if [[ $(brew cask list | grep "^$item$") != "" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
	fi
	'
	
	# casks specific1
	#if [[ $(brew cask info "$item" | grep "Not installed") == "" ]];
	if [[ "$USER" == "tom" ]]
	then
	    echo ''
	    echo checking casks specific1 installation...
	    printf '%s\n' "${casks_specific1[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
		item="{}"
		if [[ $(brew cask list | grep "^$item$") != "" ]]; 
		then 
			printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
		else 
			printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
		fi
	    '
	else
	    :
	fi
	
	# additonal apps / xtrafinder
	echo ''
	echo checking additional apps installation...
	if [[ -e "/Applications/XtraFinder.app" ]]; 
	then 
		printf "%-50s\e[1;32mok\e[0m%-10s\n" "xtrafinder"; 
	else 
		printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "xtrafinder"; 
	fi
	#echo ''

fi

echo ''


### stopping sudo
stop_sudo
