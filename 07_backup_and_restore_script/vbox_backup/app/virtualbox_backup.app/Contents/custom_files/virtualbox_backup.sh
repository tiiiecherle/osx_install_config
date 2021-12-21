#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### compress and move backup
###


### checking for script dependencies
echo ''
echo "checking for script dependencies..."
if command -v parallel &> /dev/null
then
    # installed
    echo "all script dependencies installed..."
else
    echo "not all script dependencies installed, exiting..."
    echo ''
    exit
fi
#echo ''


### trapping
#trap_function_exit_middle() { COMMAND1; COMMAND2; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"

# checking and defining some variables
DATE=$(date +%F)
VBOXDIRECTORY="/Users/"$USER"/virtualbox"
VBOXMACHINES=$(ls "$VBOXDIRECTORY")
NUMBER_OF_VBOX_MACHINES=$(ls -l "$VBOXDIRECTORY"/ | grep -c ^d)
MACHINE_COUNTER=0

for VBOXMACHINE in "$VBOXDIRECTORY"/*
do
	echo ''
	MACHINE_COUNTER=$((MACHINE_COUNTER+1))
	echo "vbox $MACHINE_COUNTER / $NUMBER_OF_VBOX_MACHINES"
    #echo "$VBOXMACHINE"
    
    #VBOXTARGZSAVEDIR="$VBOXTARGZSAVEDIR"/$"DATE"
    VBOXTARGZFILE="$VBOXTARGZSAVEDIR"/"$(basename "$VBOXMACHINE")"_"$DATE".tar.gz
    
    #echo ''
    #echo "VBOXTARGZSAVEDIR is "$VBOXTARGZSAVEDIR""
    #echo "VBOXAPPLESCRIPTDIR is "$VBOXAPPLESCRIPTDIR""
    #echo "VBOXMACHINES is "$VBOXMACHINE""
    #echo "VBOXTARGZFILE is "$VBOXTARGZFILE""
    
    # compressing and checking integrity of backup folder on desktop
    archiving_tar_gz() {
        
        # calculating backup folder size
        PVSIZE=$(gdu -scb "$VBOXMACHINE" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo "$i*1.0" | bc | cut -d'.' -f1) ; done)
        #echo "PVSIZE is "$PVSIZE""
        
        # compressing and checking integrity of backup folder on desktop
        #echo ''
        echo "archiving "$(dirname "$VBOXMACHINE")"/"$(basename "$VBOXMACHINE")"/"
        printf "%-10s" "to" "$VBOXTARGZFILE" && echo
        #echo "to "$(echo "$VBOXTARGZFILE")""
        pushd "$(dirname "$VBOXMACHINE")" 1> /dev/null; gtar -cpf - "$(basename "$VBOXMACHINE")" | pv -s "$PVSIZE" | pigz > "$VBOXTARGZFILE" && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mFAILED\033[0m" >&2; popd 1> /dev/null
    
    }
    
    if [[ -e "$VBOXTARGZFILE" ]]
    then
        VARIABLE_TO_CHECK="$OVERWRITE_VBOX_BACKUP_FILE"
        QUESTION_TO_ASK="file \"$VBOXTARGZFILE\" already exist, overwrite it (y/N)? "
        env_ask_for_variable
        OVERWRITE_VBOX_BACKUP_FILE="$VARIABLE_TO_CHECK"
        
        if [[ "$OVERWRITE_VBOX_BACKUP_FILE" =~ ^(yes|y)$ ]]
        then
            rm "$VBOXTARGZFILE"
            archiving_tar_gz
        else
            :
        fi
    else
        archiving_tar_gz
    fi
    
    unset OVERWRITE_VBOX_BACKUP_FILE
    
done
echo ''

#echo ""
testing_files_integrity() {
    echo "testing integrity of file(s) in "$VBOXTARGZSAVEDIR"/..."
    #echo ""
    #
        
    NUMBER_OF_CORES=$(parallel --number-of-cores)
    NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
    #echo $NUMBER_OF_MAX_JOBS
    NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
    #echo $NUMBER_OF_MAX_JOBS_ROUNDED
    #
    check_files_parallel() {
        file="$1"
        if [[ -f "$file" ]];
        then
            printf "%-45s" ""$(basename "$file")"..." && unpigz -c "$file" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
        else
            :
        fi
    }
    
    if [[ "$(find "$VBOXTARGZSAVEDIR" -type f -name "*.tar.gz" ! -name "*_utm_*")" != "" ]]; then env_parallel --will-cite -j"$NUMBER_OF_MAX_JOBS_ROUNDED" --line-buffer "check_files_parallel {}" ::: "$(find "$VBOXTARGZSAVEDIR" -type f -name "*.tar.gz" ! -name "*_utm_*")"; fi
    wait
    echo ''
}
#testing_files_integrity

# done
echo 'virtualbox backup done ;)'
echo ''

exit
