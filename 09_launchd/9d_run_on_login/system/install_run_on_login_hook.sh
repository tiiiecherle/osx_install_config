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
### script to do things on every login
###

### installation can be done via restore script after first install
cp -a "$SCRIPT_DIR"/install_files/run_on_login.sh /Users/"$USER"/Library/Scripts/run_on_login.sh
chown "$USER":staff /Users/"$USER"/Library/Scripts/run_on_login.sh
chmod 700 /Users/"$USER"/Library/Scripts/run_on_login.sh

# the actual command that are run on boot are included in "$SCRIPT_DIR"/run_on_login.sh

### enable script
#sudo defaults write com.apple.loginwindow LogoutHook /Users/"$USER"/Library/Scripts/run_on_logout.sh
sudo defaults write com.apple.loginwindow LoginHook /Users/"$USER"/Library/Scripts/run_on_login.sh


### uninstall hook
uninstall_hook() {
	sudo defaults delete com.apple.loginwindow LoginHook
	rm -f ~/Library/Scripts/run_on_login.sh
}
#uninstall_hook


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''
