#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### run from batch script
###


### in addition to showing them in terminal write errors to logfile when run from batch script
env_check_if_run_from_batch_script
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi



###
### reset mail index
###


# making sure mail is quit
echo ''
echo "quitting mail..."
osascript -e "tell application \"Mail\" to quit"
sleep 2


### rebuilding mail index on next run
echo ''
echo "deleting files to rebuild the mailindex at next start of mail..."
if ls ~/Library/Mail/V*/MailData/ &> /dev/null
#if find ~/Library/Mail/V* -type d -name "MailData" -maxdepth 1 &> /dev/null
then
	find ~/Library/Mail/V*/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm -f
	find ~/Library/Mail/V*/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm -f
else
	:
fi

# macos 10.15 only
if [[ "$MACOS_VERSION_MAJOR" != "10.15" ]]
then
	:
else
    #echo ''
	#echo "${bold_text}${blue_text}if this was the first run of this script after a restore please repair all needed mail rules...${default_text}"
    #echo ''
    # adding the port behind the mailbox criteria string seems to fix the broken mailrules when upgrading from 10.14 to 10.15
    sed -i '' 's|@pop3.strato.de/|@pop3.strato.de:110/|' /Users/"$USER"/Library/Mail/V6/MailData/SyncedRules.plist
fi

# opening mail and confirming rebuild
echo ''
echo "opening mail and confirming rebuilding of index..."
osascript <<EOF
tell application "Mail"
	activate
end tell
delay 2
try
	tell application "System Events" 
		tell process "Mail" 
			click button 1 of window 1
		end tell
	end tell
end try
EOF


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''
