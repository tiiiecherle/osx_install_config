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
osascript -e "tell application \"Mail.app\" to quit"
sleep 2


### rebuilding mail index on next run
if [[ "$MACOS_VERSION" =~ "10.15.(0|1|2)" ]]
then
	# macos 10.15.(0|1|2) only
	# do not delete the mail index on 10.15.(0|1|2) as there seems to be bug that results in loosing mails
	# seems to be fixed in 10.15.3
	:
else
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
fi


### updating rules
if [[ "$MACOS_VERSION_MAJOR" == "10.15" ]]
then
	# macos 10.15 only
	# in 10.15 when using mail rules that include "account" as a criterion the port of this account is added in the rules config file
	# if "automatically manage connection settings" in the account settings (inside mail preferences - accounts - server) is used mail decides (not the provider or mail service) which port to use
	# for pop3 accounts mail sometimes switches between port 110 and 995 tls/ssl without any notification - if this happens the respective mail rules do not work any more
	# solution
	# do not use "automatically manage connection settings", set ports manually for each account (inside mail preferences - accounts - server)
    # and add the corresponding port to the mail rules config file or re-set the account inside the rules in mail
    for i in $(find ~/Library/Mail/V*/MailData/ -type f -name "SyncedRules.plist")
    do
    	# v6 = 10.14
    	# v7 = 10.15
    	#sed -i '' 's|@pop3.strato.de/|@pop3.strato.de:110/|' /Users/"$USER"/Library/Mail/V6/MailData/SyncedRules.plist
    	sed -i '' 's|@pop3.strato.de/|@pop3.strato.de:995/|' "$i"
    	sed -i '' 's|@pop3.strato.de:110/|@pop3.strato.de:995/|' "$i"
    done
else
	:
fi

# opening mail and confirming rebuild
echo ''
echo "opening mail and confirming rebuilding of index..."
open "$PATH_TO_SYSTEM_APPS"/Mail.app
osascript <<EOF
#tell application "Mail.app"
#	reopen
#end tell
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
