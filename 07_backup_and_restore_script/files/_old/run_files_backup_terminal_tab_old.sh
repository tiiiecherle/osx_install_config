#!/bin/zsh

#FILESTARGZSAVEDIR=~/Desktop/"test test"
#FILESAPPLESCRIPTDIR=~/Desktop/07_backup_and_restore_script
#SELECTEDUSER="$USER"

    # compressing backup files
    # sleep 2
    # echo "compressing and backing up files..."

    # checking and defining some variables
	#echo "FILESTARGZSAVEDIR is "$FILESTARGZSAVEDIR""
    #echo "FILESAPPLESCRIPTDIR is "$FILESAPPLESCRIPTDIR""

	# compressing backup files in new terminal tab
	# EOF part is not allowed to be indented       
	function compress_and_move_files() {
osascript 2>/dev/null <<EOF
#osascript <<EOF
tell application "Terminal"
	if not (exists window 1) then reopen
	activate
	tell application "System Events" to keystroke "t" using command down
	#repeat while contents of selected tab of window 1 starts with linefeed
	delay 2
	#
	#end repeat
	set newTab to selected tab of front window
	#set newTab's selected to true
	do script "export SELECTEDUSER=\"$SELECTEDUSER\"; export FILESTARGZSAVEDIR=\"$FILESTARGZSAVEDIR\"; export FILESAPPLESCRIPTDIR=\"$FILESAPPLESCRIPTDIR\"; time ( \"$FILESAPPLESCRIPTDIR/files/backup_files.sh\" && echo '' )" in newTab
	delay 10
	set firstTab to tab 1 of front window
	set firstTab's selected to true
end tell
EOF
}
	compress_and_move_files
	# exit
