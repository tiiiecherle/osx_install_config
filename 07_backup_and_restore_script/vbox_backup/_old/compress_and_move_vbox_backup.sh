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
VBOXMACHINES="/Users/$USER/virtualbox"
#VBOXTARGZSAVEDIR="$VBOXTARGZSAVEDIR"/$"DATE"
VBOXTARGZFILE="$VBOXTARGZSAVEDIR"/"$(basename "$VBOXMACHINES")"_"$DATE".tar.gz

#echo ''
#echo "VBOXTARGZSAVEDIR is "$VBOXTARGZSAVEDIR""
#echo "VBOXAPPLESCRIPTDIR "$VBOXAPPLESCRIPTDIR""
#echo "VBOXMACHINES "$VBOXMACHINES""
#echo "VBOXTARGZFILE is "$VBOXTARGZFILE""

# compressing and checking integrity of backup folder on desktop
function archiving_tar_gz {
    
    # calculating backup folder size
    PVSIZE=$(gdu -scb "$VBOXMACHINES" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1.0 | bc | cut -d'.' -f1  ) ; done)
    #echo "PVSIZE is "$PVSIZE""
    
    # compressing and checking integrity of backup folder on desktop
    echo ''
    echo "archiving "$(dirname "$VBOXMACHINES")"/"$(basename "$VBOXMACHINES")"/"
    printf "%-10s" "to" "$VBOXTARGZFILE" && echo
    #echo "to "$(echo "$VBOXTARGZFILE")""
    pushd "$(dirname "$VBOXMACHINES")" 1> /dev/null; gtar -cpf - "$(basename "$VBOXMACHINES")" | pv -s "$PVSIZE" | pigz > "$VBOXTARGZFILE"; popd 1> /dev/null && echo '' && echo 'testing integrity of file(s)' && printf "%-45s" "$(basename "$VBOXTARGZFILE")... " && unpigz -c "$VBOXTARGZFILE" | gtar -tvv >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'

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

# done
echo ''
echo 'virtualbox backup done ;)'

exit