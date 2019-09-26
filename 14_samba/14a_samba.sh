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
### asking password upfront
###

if [[ "$SUDOPASSWORD" == "" ]]
then
    if [[ -e /tmp/tmp_batch_script_fifo ]]
    then
        unset SUDOPASSWORD
        SUDOPASSWORD=$(cat "/tmp/tmp_batch_script_fifo" | head -n 1)
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
        env_delete_tmp_batch_script_fifo
        env_sudo
    else
        env_enter_sudo_password
    fi
else
    :
fi



###
### forcing smb3 connection
###

# forcing smb3 for every connection as user do
echo ''
if [[ -f "~/Library/Preferences/nsmb.conf" ]]
then 
	:
	echo ""~/Library/Preferences/nsmb.conf" does not exist, will be created..."
else 
	echo ""~/Library/Preferences/nsmb.conf" exists will be deleted and recreated..."
	rm -f "~/Library/Preferences/nsmb.conf"
fi

if [[ -f "/etc/nsmb.conf" ]]
then 
	:
else
	#echo ''
	sudo rm -f "/etc/nsmb.conf"
fi

# macos 10.13 and newer
VERSION_TO_CHECK_AGAINST=10.12
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.12
    "$SCRIPT_INTERPRETER" -c "cat > ~/Library/Preferences/nsmb.conf" <<'EOL'
[default]
smb_neg=smb3_only
signing_required=no
EOL

else
    # macos versions 10.13 and up
	"$SCRIPT_INTERPRETER" -c "cat > ~/Library/Preferences/nsmb.conf" <<'EOL'
[default]
protocol_vers_map=4
signing_required=no
EOL

fi

chmod 600 ~/Library/Preferences/nsmb.conf
chown 501:staff ~/Library/Preferences/nsmb.conf


### more options and default values
# man nsmb.conf


### allowing unkown servers
# keeps finder from asking an extra question about connecting
# you are trying to connect to server xyz, press connect to connect...
#sudo defaults write /Library/Preferences/com.apple.NetworkAuthorization AllowUnknownServers -bool true

# checking effects while connected to a share
#smbutil statshares -a 


### speed testing
# disconnect from share, logout from macos account and reconnect to smb share after changing nsmb.conf
# creating empty file
#mkfile 4769m /Users/$USER/Desktop/5gb_file1.img
# or
#dd if=/dev/zero of=/Users/$USER/Desktop/5gb_file.img count=5000000 bs=1000
#
#rsync --progress -a /Users/$USER/Desktop/5gb_file.img /Volumes/office/

# macos 10.14
# signing_required=yes 		max 29 MB/s			average 28 MB/s
# signing_required=no 		max 58 MB/s			average 54 MB/s


### restore default as user do
#rm ~/Library/Preferences/nsmb.conf


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
echo ''
