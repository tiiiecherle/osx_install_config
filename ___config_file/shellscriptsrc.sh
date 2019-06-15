# This config file contains variales, functions and comments to avoid redundant code in shell scripts
# and make maintanance easier and scripts cleaner. For easy identification in scripts all functions in this file start with env_*.
# To make it available in a script add this after the shebang. It works with #!/bin/zsh and #!/bin/bash.
# Do not put these lines in a function or some things may not work as expected.
#
# if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by using...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/___config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
# SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH")
# env_get_script_path
# eval "$CHECK_IF_SOURCED"


### shell specific
if [[ -n "$BASH_SOURCE" ]]
then
    #echo "script is run with bash interpreter..."
    # sourcing env_parallel to use variables and functions in parallels
    #source $(which env_parallel.bash)
    if [[ $(command -v parallel) == "" ]]; then :; else . $(which env_parallel.bash); fi
    #source `which env_parallel.bash`
    # path to script
    #SCRIPT_PATH="$BASH_SOURCE"
    GET_SCRIPT_PATH='printf "%s\n" $BASH_SOURCE'
    SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH")
    # command to read from command line
    COMMAND_TO_READ_FROM_COMMAND_LINE='read -r -p'
    env_read_from_command_line() { $COMMAND_TO_READ_FROM_COMMAND_LINE "$QUESTION_TO_ASK" VARIABLE_TO_CHECK ; }
    # use password for sudo input
    env_use_password() { ${USE_PASSWORD}; }
    # check if script is sourced
    CHECK_IF_SOURCED='(return 0 2>/dev/null) && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
    #(return 0 2>/dev/null) && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
    eval "$CHECK_IF_SOURCED"
elif [[ -n "$ZSH_VERSION" ]]
then
    #echo "script is run with zsh interpreter..."
    # sourcing env_parallel to use variables and functions in parallels
    #source =env_parallel.zsh
    if [[ $(command -v parallel) == "" ]]; then :; else . $(which env_parallel.zsh); fi
    #. $(which env_parallel.zsh)
    #. `which env_parallel.zsh`
    # path to script
    #SCRIPT_PATH="${(%):-%x}"
    GET_SCRIPT_PATH='printf "%s\n" ${(%):-%x}'
    SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH")
    # command to read from command line   
    COMMAND_TO_READ_FROM_COMMAND_LINE='vared -p'
    env_read_from_command_line() { ${=COMMAND_TO_READ_FROM_COMMAND_LINE} "$QUESTION_TO_ASK" VARIABLE_TO_CHECK ; }
    # use password for sudo input    
    env_use_password() { ${=USE_PASSWORD}; }
    # check if script is sourced
    #CHECK_IF_SOURCED='if [[ $(printf "%s\n" $ZSH_EVAL_CONTEXT | grep "':file$'") != "" ]]; then echo 1; else echo 0; fi'
    CHECK_IF_SOURCED='[[ $ZSH_EVAL_CONTEXT =~ ':file$' ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
    #if [[ $ZSH_EVAL_CONTEXT =~ ':file$' ]]; then echo 1; else echo 0; fi
    eval "$CHECK_IF_SOURCED"
fi


### shebang interpreter
# script shebang interpreter
SCRIPT_INTERPRETER=$(ps h -p $$ -o args='' | cut -f1 -d' ')
# the following does not work when sourced
#SCRIPT_INTERPRETER=$(cat $script | head -n1 | awk -F'!' '{print $NF}')
#echo $SCRIPT_INTERPRETER
# be careful when using $SHELL instead
# if a script with #!/bin/bash shebang interpreter will be started in zsh shell, $SHELL will be /bin/zsh, not /bin/bash
# when a script is sourced the shebang interpreter will be taken from the master script and the shebang from the sourced script will be ignored
# the above variable reflects that correctly


### script path, name and directory
env_get_script_path() {
    # script path
    #echo $SCRIPT_PATH+
    # script name
    SCRIPT_NAME="$(basename -- "$SCRIPT_PATH")"
    #echo $SCRIPT_NAME
    # script dir
    SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
    #echo $SCRIPT_DIR
    # script dir one back
    SCRIPT_DIR_ONE_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && pwd)"
    #echo $SCRIPT_DIR_ONE_BACK
    # script dir two back
    SCRIPT_DIR_TWO_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && cd .. && pwd)"
    #echo $SCRIPT_DIR_TWO_BACK
    # script dir three back
    SCRIPT_DIR_THREE_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && cd .. && cd .. && pwd)"
    #echo $SCRIPT_DIR_THREE_BACK
}
env_get_script_path


### text output
bold_text=$(tput bold)
red_text=$(tput setaf 1)
green_text=$(tput setaf 2)
blue_text=$(tput setaf 4)
default_text=$(tput sgr0)


### macos version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }


### ask for variable
env_ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	if [[ "$ANSWER_WHEN_EMPTY" == "" ]]
	then
	    env_read_from_command_line
	    VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	else
    	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
    	do
            env_read_from_command_line
    		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
    		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
    	done
    fi
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}

#echo ''
#VARIABLE_TO_CHECK="$PHP_TESTFILES"
# single line
#QUESTION_TO_ASK="do you want to install php testfiles? (y/N) "
# multi line
#QUESTION_TO_ASK="$(echo -e 'found a backup of cask specifications in /tmp/Caskroom \ndo you wanto to restore /tmp/Caskroom/* to /usr/local/Caskroom/' '(Y/n)? ')"
#ask_for_variable
#PHP_TESTFILES="$VARIABLE_TO_CHECK"

#if [[ "$PHP_TESTFILES" =~ ^(yes|y)$ ]]
#then
#	"echo do it"
#else
#	echo "do NOT do it"
#fi


### testing
if [[ "$TEST_SOURCING_AND_VARIABLES" == "yes" ]]
then
    echo "config file..."
    echo "script is sourced: $SCRIPT_IS_SOURCED"
    echo "script name is $SCRIPT_NAME"
    echo "script directory is $SCRIPT_DIR"
    echo "script directory one back is $SCRIPT_DIR_ONE_BACK"
else
    :
fi
