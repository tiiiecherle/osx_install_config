#!/bin/bash

# ln -s original symlink

symbolic_links=(
/Users/$USER/Desktop/backup_macos
/Users/$USER/Desktop/backup
/Users/$USER/Desktop/archive
/Users/$USER/Desktop/files
/Users/$USER/Desktop/backup_file.rtf
/Users/$USER/github
/Users/$USER/virtualbox
)

VOLUME1=macintosh_hd
VOLUME2=macintosh_hd2

for i in "${symbolic_links[@]}"; 
do
	if [ -e /Volumes/"$VOLUME2""$i" ]
	then
		echo "symlink "$i" already exists..."
	else
		echo "creating symlink "$i"..."
		ln -s /Volumes/"$VOLUME1""$i" /Volumes/"$VOLUME2""$i"
	fi
done