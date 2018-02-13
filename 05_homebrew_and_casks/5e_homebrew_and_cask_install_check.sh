#!/bin/bash

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")
casks_pre=$(cat "$SCRIPT_DIR"/_lists/00_casks_pre.txt | sed '/^#/ d')
homebrewpackages=$(cat "$SCRIPT_DIR"/_lists/01_homebrew_packages.txt | sed '/^#/ d')
casks=$(cat "$SCRIPT_DIR"/_lists/02_casks.txt | sed '/^#/ d')
casks_specific1=$(cat "$SCRIPT_DIR"/_lists/03_casks_specific1.txt | sed '/^#/ d')

# more variables
# keeping hombrew from updating each time brew install is used
export HOMEBREW_NO_AUTO_UPDATE=1
# number of max parallel processes
NUMBER_OF_CORES=$(sysctl hw.ncpu | awk '{print $NF}')
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
#echo $NUMBER_OF_MAX_JOBS_ROUNDED

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
echo ''
echo checking homebrew package installation...
printf '%s\n' "${homebrewpackages[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
'
    
# casks
echo ''
echo checking casks installation...
# casks_pre
printf '%s\n' "${casks_pre[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew cask info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
'
# casks
printf '%s\n' "${casks[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew cask info "$item" | grep "Not installed") == "" ]]; 
then 
	printf "%-50s\e[1;32mok\e[0m%-10s\n" "$item"; 
else 
	printf "%-50s\e[1;31mFAILED\e[0m%-10s\n" "$item"; 
fi
'

# casks specific1
if [[ "$USER" == "tom" ]]
then
    echo ''
    echo checking casks specific1 installation...
    printf '%s\n' "${casks_specific1[@]}" | xargs -n1 -L1 -P"$NUMBER_OF_MAX_JOBS_ROUNDED" -I{} bash -c ' 
item="{}"
if [[ $(brew cask info "$item" | grep "Not installed") == "" ]]; 
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
echo ''