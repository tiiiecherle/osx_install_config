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
### script
###

# ln -s original symlink

symbolic_links=(
/Users/$USER/Desktop/macos
/Users/$USER/Desktop/backup
/Users/$USER/Desktop/files
/Users/$USER/Desktop/backup_file.rtf
/Users/$USER/github
/Users/$USER/virtualbox
)

VOLUME1=macintosh_hd
VOLUME2=macintosh_hd2

echo ''

if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "$VOLUME2" ]]
then
	for i in "${symbolic_links[@]}"; 
	do
		if [[ -e /Volumes/"$VOLUME1""$i" ]]
		then
			if [[ -e /Volumes/"$VOLUME2""$i" ]]
			then
				echo "/Volumes/"$VOLUME2""$i" already exists, skipping..."
			else
				echo "creating symlink "$i"..."
				ln -s /Volumes/"$VOLUME1""$i" /Volumes/"$VOLUME2""$i"
			fi
		else
			echo "/Volumes/"$VOLUME1""$i" does not exist, skipping..."
		fi
	done
else
	echo "MACOS_CURRENTLY_BOOTED_VOLUME is not "$VOLUME2", skipping..."
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo "done ;)"
echo ''