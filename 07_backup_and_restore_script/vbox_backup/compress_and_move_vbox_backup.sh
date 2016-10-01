#!/bin/bash

# checking and defining some variables
DATE=$(date +%F)
VBOXMACHINES="/Users/$USER/virtualbox"
#VBOXTARGZSAVEDIR="$VBOXTARGZSAVEDIR"/$"DATE"
VBOXTARGZFILE="$VBOXTARGZSAVEDIR"/"$(basename "$VBOXMACHINES")"_"$DATE".tar.gz

echo ''
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
    echo "archiving "$(dirname "$VBOXMACHINES")"/"$(basename "$VBOXMACHINES")"/ to "$(echo "$VBOXTARGZFILE")""
    pushd "$(dirname "$VBOXMACHINES")" 1> /dev/null; gtar -cpf - "$(basename "$VBOXMACHINES")" | pv -s "$PVSIZE" | pigz --best > "$VBOXTARGZFILE"; popd 1> /dev/null && echo '' && echo 'testing integrity of file(s)' && echo -n "$(basename "$VBOXTARGZFILE")"'... ' && gtar -tzf "$VBOXTARGZFILE" >/dev/null 2>&1 && echo -e 'file is \033[1;32mOK\033[0m' || echo -e 'file is \033[1;31mINVALID\033[0m'

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
echo 'done ;)'