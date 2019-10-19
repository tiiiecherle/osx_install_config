#!/bin/zsh

#FILESTARGZSAVEDIR=/Users/"$USER"/Desktop/backup_test
#FILESAPPLESCRIPTDIR=/Users/$USER/Desktop/backup_macos/defaults_write/_scripts_final/07_backup_and_restore_script
#SELECTEDUSER="$USER"

    # compressing backup files
    # sleep 2
    # echo "compressing and backing up files..."

    # checking and defining some variables
	#echo "FILESTARGZSAVEDIR is "$FILESTARGZSAVEDIR""
    #echo "FILESAPPLESCRIPTDIR is "$FILESAPPLESCRIPTDIR""

	# compressing backup files in new terminal tab
	# EOF part is not allowed to be indented       
	compress_and_move_files() {
#osascript 2>/dev/null <<EOF
osascript <<EOF
tell application "Terminal"
	if it is running then
		#if not (exists window 1) then
		if (count of every window) is 0 then
			reopen
			activate
			set Window1 to front window
			set runWindow to front window
		else
			activate
			delay 2
			set Window1 to front window
			#
			tell application "System Events" to keystroke "t" using command down
			delay 2
			set Window2 to front window
			set runWindow to front window
		end if
	else
		activate
		set Window1 to front window
		set runWindow to front window
	end if
	#delay 2
	#
	do script "export SELECTEDUSER=\"$SELECTEDUSER\"; export FILESTARGZSAVEDIR=\"$FILESTARGZSAVEDIR\"; export FILESAPPLESCRIPTDIR=\"$FILESAPPLESCRIPTDIR\"; time \"$FILESAPPLESCRIPTDIR/files/backup_files.sh\"; echo ''" in runWindow
	#
	delay 10
	set frontmost of Window1 to true
end tell
EOF
}
	compress_and_move_files
	# exit
