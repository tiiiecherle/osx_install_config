#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### install
###


### traps
#trap_function_exit_middle() { COMMAND1; COMMAND2; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"


### installation
echo ''

# getting app name from install script
while IFS= read -r line || [[ -n "$line" ]]
do
	if [[ "$line" == "" ]]; then continue; fi
    [[ "$line" =~ "APP_NAME=" ]] && declare -x "$line" && break
done <<< "$(cat "$SCRIPT_DIR"/install_script/install.sh)"

APP_NAME=$(echo "$APP_NAME" | sed 's/^"//g' | sed 's/"$//g')
echo "app to be installed is "$APP_NAME".app..."

if [[ "$APP_NAME" == "" ]]
then
	echo "app name is empty, exiting..."
	exit
else
	:
fi

install_using_tmp() {
	# copy to tmp and install from there
	# needed on some macs to detect app id for setting security and/or automating permissions
	echo "copying files to /tmp for installation..."
	if [[ -e /tmp/"$APP_NAME" ]]; then rm -rf /tmp/"$APP_NAME"; fi
	mkdir -p /tmp/"$APP_NAME"
	cp -a "$SCRIPT_DIR"/* /tmp/"$APP_NAME"
	
	# installation
	echo "installing..."
	/tmp/"$APP_NAME"/install_script/install.sh
	#wait
	
	# cleaning up
	echo "cleaning up..."
	if [[ -e /tmp/"$APP_NAME" ]]; then rm -rf /tmp/"$APP_NAME"; fi
}
#install_using_tmp

direct_install() {
	"$SCRIPT_DIR"/install_script/install.sh
	#wait
}
direct_install

echo ''
echo "done ;)"
echo ''
