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
    else
        env_enter_sudo_password
    fi
else
    :
fi



###
### user config profile
###

SCRIPTS_DIR_USER_PROFILES="$SCRIPT_DIR_ONE_BACK"/_user_profiles
env_check_for_user_profile



###
### script
###

# starting with version 10.15 macos uses zsh as default login shell
# for assuring maximum compatibility setting zsh as default on 10.14


### default login shell
echo ''
if [[ $(dscl . -read ~/ UserShell | sed 's/UserShell: //' | grep zsh) == "" ]]
then
	# checking if zsh is installed
	if command -v zsh &> /dev/null
    then
        # installed
		echo "zsh is installed..."        
	else
	    # not installed
	    echo "zsh is not installed, exiting..."
	    exit
	fi
	
	# checking if zsh definded as possible default shell
	if [[ $(cat /etc/shells | grep zsh) == "" ]]
	then
	    echo ''
	    echo "setting zsh as default shell is not yet possible..."
	    echo "adding entry to /etc/shells..."
	    sudo echo "/bin/zsh" >> /etc/shells
	else
		echo ''
	    echo "setting zsh as default shell is possible..."
	fi
	
	# setting default login shell to zsh
    echo ''
    echo "zsh is not the default login shell, setting it default..."
    chsh -s $(which zsh) $USER
else
	echo "zsh is already the default login shell..."
fi


### customization
echo ''
echo "customizing zsh shell..."

# git is part of command line tools and needed for the customization
SCRIPT_DIR_FINAL="$SCRIPT_DIR_TWO_BACK"
echo ''
trap_function_exit_middle() { env_stop_sudo; unset SUDOPASSWORD; unset USE_PASSWORD }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"
env_start_sudo
env_command_line_tools_install_shell
#env_stop_sudo			# done in trap

# https://github.com/robbyrussell/oh-my-zsh
# starting with a clean install
for FILE_TO_CHECK in ".oh-my-zsh" ".zshrc" ".zshrc.pre-oh-my-zsh-*"
do
	if [[ -e /Users/"$USER"/"$FILE_TO_CHECK" ]]
	then
		rm -rf /Users/"$USER"/"$FILE_TO_CHECK"
	else
		:
	fi
done


### installing/updating
echo ''
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" &
WAIT_PID=$!
wait "$WAIT_PID"

# making sure config file exists
if [[ ! -e ~/.zshrc ]]
then
	touch ~/.zshrc
	chown 501:staff ~/.zshrc
	chmod 600 ~/.zshrc
else
	:
fi


### customization (no if needed as the script always starts with a clean config)
echo ''
echo "customizing ~/.zshrc..."
# changes
sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME=""|' ~/.zshrc
sed -i '' 's|^plugins=.*|plugins=()|' ~/.zshrc
sed -i '' '/DISABLE_AUTO_TITLE=/s/^#*//g' ~/.zshrc
sed -i '' '/DISABLE_AUTO_TITLE=/s/^ *//g' ~/.zshrc
sed -i '' '/DISABLE_AUTO_UPDATE=/s/^#*//g' ~/.zshrc
sed -i '' '/DISABLE_AUTO_UPDATE=/s/^ *//g' ~/.zshrc
# additions
# promtp
echo '' >> ~/.zshrc
echo "# customized prompt" >> ~/.zshrc
echo "PROMPT='%n%f %1~ %# '" >> ~/.zshrc
# default editor
echo '' >> ~/.zshrc
echo "# default editor" >> ~/.zshrc
echo "export EDITOR=nano" >> ~/.zshrc
# format output of time command
# http://zsh.sourceforge.net/Doc/Release/Parameters.html#index-TIMEFMT
# posix
# in hours, minutes, seconds, only printed if not zero
#TIMEFMT=$'\nreal\t%*E\nuser\t%*U\nsys\t%*S'
# in seconds
#TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'
# default
#TIMEFMT=$'%J %U user %S system %P cpu %*E total'
# default without printing job name, e.g. if run for a function in a subshell
echo '' >> ~/.zshrc
echo "# time command output format" >> ~/.zshrc
echo "export TIMEFMT=$'%U user %S system %P cpu %*E total'" >> ~/.zshrc


### path
# documentation
# three different locations/ways to set PATH
#
# 1		/etc/paths
# 		used by all shells, all users and gui applications
#
# 2		shell config file like ~/.zshrc or ~/.bashrc
#		used by all user shells and user launchd scripts 
#		not used by launchd scripts that are run as system/root (source the shell config file of the loggedInUser to make it work)
#		does only work for shells, not for gui applications
#		works to manage the correct order of PATH, even in front of entries from /etc/paths if required
#		example entry
#		export PATH="/usr/local/bin:$PATH"
#		
# 3		sudo launchctl config user/system path
#		user path		used by all user shells, launchdscripts and user gui apps
#		system path		used by all root/system shells, launchdscripts and gui apps
#		does not work for putting entries in order before entries from /etc/paths
#		if this is used solely entries from /etc/paths would have to be commented out to achive the given order		
#		examples	
# 		all system users except root
# 		sudo launchctl config user path "/usr/local/bin:/usr/local/sbin:/usr/local/opt/openssl@1.1/bin:$PATH"
# 		system/root
# 		sudo launchctl config system path "/usr/local/bin:/usr/local/sbin:/usr/local/opt/openssl@1.1/bin:$PATH"
# 		unset
# 		sudo launchctl config user path ''
# 		sudo launchctl config system path ''
#
# working solutions
# 1		set default entries in /etc/paths
#		set customized PATH in shell config for shell commands
#		set/unset PATH for gui apps via launchctl config - needs reboot (will be added in order after entries from /etc/paths)
#
# 2		comment out all entries in /etc/paths
#		comment out all export PATH entries in shell config files
#		set user/system path via launchctl for shell commands and gui apps - needs reboot
#
# testing
# echo "$PATH"

# setting path
echo ''
echo "setting PATH..."

# default value of variable is set in .shellscriptsrc, can be overwritten here, e.g.
# PATH_TO_SET='/usr/local/bin:$PATH'

# setting default paths in /etc/paths
#env_start_sudo			# already started above
#env_set_default_paths
#env_stop_sudo			# done in trap

# setting paths for bash
SHELL_TO_CHECK="/bin/bash"
SHELL_CONFIG="/Users/$(logname)/.bashrc"
env_set_path_for_shell

# setting paths for zsh
SHELL_TO_CHECK="/bin/zsh"
SHELL_CONFIG="/Users/$(logname)/.zshrc"
env_set_path_for_shell

# setting/unsetting path via launchctl
#env_start_sudo			# already started above
sudo launchctl config user path ''
sudo launchctl config system path ''
#env_stop_sudo			# done in trap


### avoiding [oh-my-zsh] Insecure completion-dependent directories detected
sudo chmod 755 /usr/local/share/zsh
sudo chmod 755 /usr/local/share/zsh/site-functions

	
### sourcing config file if script is run from zsh for changes to take effect
# will be sourced when opening a new terminal session automatically
if [[ $(echo "$SHELL") == "/bin/zsh" ]]
then
	"$SHELL" -c "source "/Users/$(logname)/.zshrc""
else
    :
fi


### starting zsh shell in current terminal
#echo ''
#echo "switching to zsh shell..."
#echo ''
#exec zsh -l

### documentation
# currently used shell
#echo "$SHELL"

# default login shell for current user
#dscl . -read ~/ UserShell | sed 's/UserShell: //'

# .zprofile is equivalent to .bash_profile and runs at login, including over SSH
# .zshrc is equivalent to .bashrc and runs for each new Terminal session

# if the latest zsh homebrew version shall be used follow these steps
# install homebrew
# install zsh via homebrew
# set path in ~/.zshrc
# source ~/.zshrc
# sudo "$SHELL" -c "echo $(which zsh) >> /etc/shells"
# chsh -s $(which zsh) $USER

### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi

echo ''
echo "done ;)"
echo ''
