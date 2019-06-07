#!/bin/bash

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

ask_for_variable() {
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
    trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "kill_subprocesses >/dev/null 2>&1; exit" EXIT
else
    # script is not session master and run from another script (S+ on mac and linux) 
    trap "printf '\n'; kill_main_process" SIGHUP SIGINT SIGTERM
    trap "exit" EXIT
fi
#set -e

# checking and defining some variables
DATE=$(date +%F)
VBOXDIRECTORY="/Users/$USER/virtualbox"
VBOXMACHINES=$(ls "$VBOXDIRECTORY")
NUMBER_OF_VBOX_MACHINES=$(ls -l $VBOXDIRECTORY | grep -c ^d)
MACHINE_COUNTER=0

for VBOXMACHINE in "$VBOXDIRECTORY"/*
do
	echo ''
	MACHINE_COUNTER=$(($MACHINE_COUNTER+1))
	echo "vbox $MACHINE_COUNTER / $NUMBER_OF_VBOX_MACHINES"
    #echo "$VBOXMACHINE"
    
    #VBOXTARGZSAVEDIR="$VBOXTARGZSAVEDIR"/$"DATE"
    VBOXTARGZFILE="$VBOXTARGZSAVEDIR"/"$(basename "$VBOXMACHINE")"_"$DATE".tar.gz
    
    #echo ''
    #echo "VBOXTARGZSAVEDIR is "$VBOXTARGZSAVEDIR""
    #echo "VBOXAPPLESCRIPTDIR "$VBOXAPPLESCRIPTDIR""
    #echo "VBOXMACHINES "$VBOXMACHINE""
    #echo "VBOXTARGZFILE is "$VBOXTARGZFILE""
    
    # compressing and checking integrity of backup folder on desktop
    function archiving_tar_gz {
        
        # calculating backup folder size
        PVSIZE=$(gdu -scb "$VBOXMACHINE" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1.0 | bc | cut -d'.' -f1  ) ; done)
        #echo "PVSIZE is "$PVSIZE""
        
        # compressing and checking integrity of backup folder on desktop
        #echo ''
        echo "archiving "$(dirname "$VBOXMACHINE")"/"$(basename "$VBOXMACHINE")"/"
        printf "%-10s" "to" "$VBOXTARGZFILE" && echo
        #echo "to "$(echo "$VBOXTARGZFILE")""
        pushd "$(dirname "$VBOXMACHINE")" 1> /dev/null; gtar -cpf - "$(basename "$VBOXMACHINE")" | pv -s "$PVSIZE" | pigz > "$VBOXTARGZFILE"; popd 1> /dev/null
    
    }
    
    if [[ -e "$VBOXTARGZFILE" ]]
    then
        VARIABLE_TO_CHECK="$OVERWRITE_VBOX_BACKUP_FILE"
        QUESTION_TO_ASK="file \"$VBOXTARGZFILE\" already exist, overwrite it (y/N)? "
        ask_for_variable
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
echo "testing integrity of file(s) in "$VBOXTARGZSAVEDIR"/..."
#echo ""
#
#
NUMBER_OF_CORES=$(parallel --number-of-cores)
NUMBER_OF_MAX_JOBS=$(echo "$NUMBER_OF_CORES * 1.0" | bc -l)
#echo $NUMBER_OF_MAX_JOBS
NUMBER_OF_MAX_JOBS_ROUNDED=$(awk 'BEGIN { printf("%.0f\n", '"$NUMBER_OF_MAX_JOBS"'); }')
#echo $NUMBER_OF_MAX_JOBS_ROUNDED
#
parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k -q "$SHELL" -c '
    if [[ -f "{}" ]];
    then
        printf "%-45s" """$(basename "{}")""... " && unpigz -c "{}" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
    else
        :
    fi
' ::: "$(find "$VBOXTARGZSAVEDIR" -type f -name "*.tar.gz")"
wait

# done
echo ''
echo 'virtualbox backup done ;)'

exit