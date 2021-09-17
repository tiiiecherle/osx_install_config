#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### running backup script
###


### traps
#trap_function_exit_middle() { COMMAND1; COMMAND2; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"


### backup
while IFS= read -r line || [[ -n "$line" ]] 
do
    if [[ "$line" == "" ]]; then continue; fi
    i="$line"
    if [[ $(xattr -l "$i" | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$i"
    else
        :
    fi
done <<< "$(find "$SCRIPT_DIR" -mindepth 1 ! -path "*/*.app/*" -name "*.app")"

while IFS= read -r line || [[ -n "$line" ]] 
do
    if [[ "$line" == "" ]]; then continue; fi
    i="$line"
    if [[ $(xattr -l "$i" | grep com.apple.quarantine) != "" ]]
    then
        xattr -d com.apple.quarantine "$i"
    else
        :
    fi
done <<< "$(find "$SCRIPT_DIR" -mindepth 1 ! -path "*/*.app/*" -name "*.sh")"

# to read the output file including formats do
# cat ~/Desktop/backup_restore_log.txt
#export OPTION=RESTORE; time script -q ~/Desktop/backup_restore_log.txt "$SCRIPT_DIR"/backup_restore_script/backup_restore_script_mac.sh

# this needs tee in the backup script which does not capture the output format, so e.g. you couldn`t see the download progress of casks
export OPTION=BACKUP; time "$SCRIPT_DIR"/backup_restore_script/backup_restore_script_mac.sh

echo ''

exit
