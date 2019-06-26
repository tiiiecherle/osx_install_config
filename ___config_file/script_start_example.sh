#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/___config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval_function() { function_to_eval="$@"; eval "$(typeset -f $function_to_eval)" && "$function_to_eval" ; }
eval_function env_get_shell_specific_variables



###
### script
###

### testing sourcing and variables
echo ''
TEST_SOURCING_AND_VARIABLES=yes
if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/___config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval_function() { function_to_eval="$@"; eval "$(typeset -f $function_to_eval)" && "$function_to_eval" ; }
eval_function env_get_shell_specific_variables

echo ''
echo "parent shell script..."
echo "script is sourced: $SCRIPT_IS_SOURCED"
echo "script name is $SCRIPT_NAME"
echo "script directory is $SCRIPT_DIR"
echo "script directory one back is $SCRIPT_DIR_ONE_BACK"
echo ''
