#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### privacy app profiles
###

env_databases_apps_security_permissions
env_identify_terminal


### applist
# "System Events" has to be first list entry and has to be confirmed manually
APP_LIST=(
# keep "BL Banking Launcher" and brew_casks_update after "System Events" at the beginning in this order for the clicks to work
"System Events"
"BL Banking Launcher"
"brew_casks_update															"$PATH_TO_APPS"/brew_casks_update.app"
iTerm
Terminal
Finder
XtraFinder
video_720p_h265_aac_shrink
gui_apps_backup
decrypt_finder_input_gpg_progress
unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress
"Overflow 3"
"Script Editor"
"System Preferences"
witchdaemon
VirtualBox
PasswordWallet
"VirtualBox Menulet"
"Bartender 3"
"Ondesoft AudioBook Converter"
"VNC Viewer"
"Commander One"
"Alfred 5"
GeburtstagsChecker
pdf_200dpi_shrink
iTunes
Mail
backup_files_tar_gz
virtualbox_backup
"run_on_login_signal														/Users/$USER/Library/Scripts/run_on_login_signal.app"
"run_on_login_whatsapp														/Users/$USER/Library/Scripts/run_on_login_whatsapp.app"
EagleFiler
"iStat Menus"
MacPass
)

### creating profiles
for APP_LINE in "${APP_LIST[@]}"
do

	sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAppleEvents';"

	if [[ $(echo "$APP_LINE" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') == "" ]]
	then
		APP_ENTRY="$APP_LINE"
		APP_ENTRY_OPEN="$APP_LINE"
	else
		APP_ENTRY=$(echo "$APP_LINE" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
		APP_ENTRY_OPEN=$(echo "$APP_LINE" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	fi
	echo ''	
	echo "$APP_ENTRY"
	#echo "$APP_ENTRY_OPEN"
	
	if [[ "$APP_ENTRY" == "$SOURCE_APP_NAME" ]]
	then
		:
	else
		
		sleep 0.5
		
		if [[ "$APP_ENTRY" == "System Events" ]]
		then
			:
		else
			sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP"',0,1,1,?,NULL,0,'com.apple.systemevents',?,NULL,?);"
		fi
		
		sleep 0.5
		
		osascript -e "tell application \"$APP_ENTRY_OPEN\" to «event BATFinit»" 2>&1 | grep -v "BATFinit" | grep -v "execution error" &
		
		if [[ "$APP_ENTRY" == "BL Banking Launcher" ]]
		then
			:
		else
			sleep 1
		fi
		
		osascript <<EOF
		try
			tell application "System Events" 
				tell process "UserNotificationCenter" 
					click button "OK" of window 1
				end tell
			end tell
		end try
		
		# no delay after first tries needed for "BL Banking Launcher" and brew_casks_update
		#delay 2
		
		try
			tell application "System Events" 
				tell process "UserNotificationCenter" 
					click button "OK" of window 1
				end tell
			end tell
		end try
		
		try
			tell application "System Events" 
				tell process "UserNotificationCenter" 
					click button "OK" of window 1
				end tell
			end tell
		end try
		
		delay 1
		
		try
			tell application "System Events" 
				tell process "UserNotificationCenter" 
					click button "OK" of window 1
				end tell
			end tell
		end try
		
		delay 2
		
		try
			tell application "System Events" 
				tell process "UserNotificationCenter" 
					click button "OK" of window 1
				end tell
			end tell
		end try
		
		delay 3
		
		try
			tell application "System Events" 
				tell process "UserNotificationCenter" 
					click button "OK" of window 1
				end tell
			end tell
		end try
		
EOF
	
	
		# special events after opening the app
		if [[ "$APP_ENTRY" == "Bartender 3" ]] || [[ "$APP_ENTRY" == "Finder" ]] || [[ "$APP_ENTRY" == "Alfred 3" ]] || [[ "$APP_ENTRY" == "GeburtstagsChecker" ]] || [[ "$APP_ENTRY" == "VirtualBox Menulet" ]] || [[ "$APP_ENTRY" == "iTerm" ]] || [[ "$APP_ENTRY" == "Terminal" ]] || [[ "$APP_ENTRY" == "Overflow 3" ]]
		then
			:
		elif [[ "$APP_ENTRY" == "XtraFinder" ]]
		then
			osascript <<EOF
			tell application "System Events"
				tell application "XtraFinder" to activate
				delay 2
				tell application "System Events"
					keystroke "w" using command down
				end tell
			end tell
EOF
		elif [[ "$APP_ENTRY" == "brew_casks_update" ]]
		then
			sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP"',0,1,1,?,NULL,0,'com.apple.Terminal',?,NULL,?);"
			#sleep 3
			while [[ $(ps aux | grep /brew_casks_update.sh | grep -v grep) == "" ]]
			do 
			osascript <<EOF
			try
				tell application "System Events" 
					tell process "UserNotificationCenter" 
						click button "OK" of window 1
					end tell
				end tell
			end try
			delay 1
EOF
			done
			sleep 3
			while ps aux | grep /brew_casks_update.sh | grep -v grep > /dev/null;
			do 
			osascript <<EOF
			try
				tell application "Terminal"
					close (every window whose name contains "brew_casks_update")
					delay 2
					tell application "System Events"
						keystroke return
					end tell
				end tell
			end try
EOF
			done

		elif [[ "$APP_ENTRY" == "BL Banking Launcher" ]]
		then
			sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP',0,1,1,?,NULL,0,'com.apple.Terminal',?,NULL,?);"
			#sleep 3
			while [[ $(ps aux | grep /veracrypt_mount_blbanking.sh | grep -v grep) == "" ]]
			do 
			osascript <<EOF
			try
				tell application "System Events" 
					tell process "UserNotificationCenter" 
						click button "OK" of window 1
					end tell
				end tell
			end try
			delay 1
EOF
			done
			sleep 3
			while ps aux | grep /veracrypt_mount_blbanking.sh | grep -v grep > /dev/null;
			do 
			osascript <<EOF
			try
				tell application "Terminal"
					close (every window whose name contains "_blbanking")
					delay 2
					tell application "System Events"
						keystroke return
					end tell
				end tell
			end try
EOF
			done
			# moving up empty lines from keystroke return thats run before 
			tput cuu1
		
		elif [[ "$APP_ENTRY" == "gui_apps_backup" ]] || [[ "$APP_ENTRY" == "backup_files_tar_gz" ]] || [[ "$APP_ENTRY" == "virtualbox_backup" ]]
		then
			pkill -f "$APP_ENTRY"
			pkill -f "osascript"
		else
			osascript <<EOF
			try
				tell application "$APP_ENTRY"
					quit
				end tell
			end try
EOF
		fi
		
		#sleep 1
			
		# delete entries with NULL value
		sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and indirect_object_code_identity IS NULL);"
		
		# getting values from latest entry in the database
		# client bundle id
		SOURCE_APP_ID=$(sqlite3 "$DATABASE_USER" "select client from access where service='kTCCServiceAppleEvents' order by rowid asc limit 1")
		# client csreq
		SOURCE_APP_CSREQ=$(sqlite3 "$DATABASE_USER" "select quote(csreq) from access where service='kTCCServiceAppleEvents' order by rowid asc limit 1")
		# destination bundle id
		AUTOMATED_APP_ID=$(sqlite3 "$DATABASE_USER" "select indirect_object_identifier from access where service='kTCCServiceAppleEvents' order by rowid asc limit 1")
		# destination csreq
		AUTOMATED_APP_CSREQ=$(sqlite3 "$DATABASE_USER" "select quote(indirect_object_code_identity) from access where service='kTCCServiceAppleEvents' order by rowid asc limit 1")
		
		# writing values to profile file
		# automated app
		touch "$SCRIPT_DIR"/"$APP_ENTRY".txt
		chown "$USER":staff "$SCRIPT_DIR"/"$APP_ENTRY".txt
		chmod 600 "$SCRIPT_DIR"/"$APP_ENTRY".txt
		#
		echo "$APP_ENTRY" > "$SCRIPT_DIR"/"$APP_ENTRY".txt
		echo "$AUTOMATED_APP_ID" >> "$SCRIPT_DIR"/"$APP_ENTRY".txt
		echo "$AUTOMATED_APP_CSREQ" >> "$SCRIPT_DIR"/"$APP_ENTRY".txt
	
	fi
	
	sleep 0.5
	osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
	#osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
	sleep 0.5

done

# writing values to profile file
# source app
touch "$SCRIPT_DIR"/"$SOURCE_APP_NAME".txt
chown "$USER":staff "$SCRIPT_DIR"/"$SOURCE_APP_NAME".txt
chmod 600 "$SCRIPT_DIR"/"$SOURCE_APP_NAME".txt
#
echo "$SOURCE_APP_NAME" > "$SCRIPT_DIR"/"$SOURCE_APP_NAME".txt
echo "$SOURCE_APP_ID" >> "$SCRIPT_DIR"/"$SOURCE_APP_NAME".txt
echo "$SOURCE_APP_CSREQ" >> "$SCRIPT_DIR"/"$SOURCE_APP_NAME".txt
