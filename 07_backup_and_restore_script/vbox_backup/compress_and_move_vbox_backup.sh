#!/bin/bash

# trapping script to kill subprocesses when script is stopped
# kill -9 can only be silenced with >/dev/null 2>&1 when wrappt into function
function kill_subprocesses() 
{
# kills subprocesses only
pkill -9 -P $$
}

function kill_main_process() 
{
# kills subprocesses and process itself
exec pkill -9 -P $$
}

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "kill_subprocesses >/dev/null 2>&1; exit; kill_main_process" EXIT
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
    
    if [ -e "$VBOXTARGZFILE" ]
    then
        read -p "file \"$VBOXTARGZFILE\" already exist, overwrite it (y/N)?" CONT1
        if [ "$CONT1" == "y" ]
        then
            rm "$VBOXTARGZFILE"
            archiving_tar_gz
        else
            :
        fi
    else
        archiving_tar_gz
    fi
    
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
parallel --will-cite -P "$NUMBER_OF_MAX_JOBS_ROUNDED" -k -q bash -c '
    if [[ -f "{}" ]];
    then
        printf "%-45s" ""$(basename "{}")"... " && unpigz -c "{}" | gtar -tvv >/dev/null 2>&1 && echo -e "\033[1;32mOK\033[0m" || echo -e "\033[1;31mINVALID\033[0m"
    else
        :
    fi
' ::: "$(find "$VBOXTARGZSAVEDIR" -type f -name "*.tar.gz")"
wait

# done
echo ''
echo 'virtualbox backup done ;)'

exit