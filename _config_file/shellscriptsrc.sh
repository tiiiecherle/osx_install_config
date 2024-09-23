# This config file contains variales, functions and comments to avoid redundant code in shell scripts
# and make maintanance easier and scripts cleaner. For easy identification in scripts all functions in this file start with env_*.
# To make it available in a script add this after the shebang. It works with #!/bin/zsh and #!/bin/bash.
# Do not put these lines in a function or some things may not work as expected.
#
#if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
#eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables


### shell specific varibales
env_get_shell_specific_variables() {

    ### shell specific
    if [[ -n "$BASH_SOURCE" ]]
    then
        #echo "script is run with bash interpreter..."
        
        # sourcing env_parallel to use variables and functions in parallels
        #source $(which env_parallel.bash)
        if command -v parallel &> /dev/null; then . $(which env_parallel.bash); else :; fi
        #source `which env_parallel.bash`
        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
        # it is not neccessary to export variables or functions when using env_parallel
        # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
        
        # path to script
        SCRIPT_PATH="$BASH_SOURCE"
        # eval alternative
        # use SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH") in other script to call it
        #GET_SCRIPT_PATH='printf "%s\n" $BASH_SOURCE'
        #SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH")
        
        # command to read from command line
        COMMAND_TO_READ_FROM_COMMAND_LINE='read -r -p'
        env_read_from_command_line() { $COMMAND_TO_READ_FROM_COMMAND_LINE "$QUESTION_TO_ASK" VARIABLE_TO_CHECK; }
        
        # use password for sudo input
        env_use_password() { ${USE_PASSWORD}; }
        
        # check if script is sourced
        [[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        # eval alternative (does not work inside function because of subshell)
        # use eval "$CHECK_IF_SOURCED" in other script to call it
        #CHECK_IF_SOURCED='(return 0 2>/dev/null) && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
        #(return 0 2>/dev/null) && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        #eval "$CHECK_IF_SOURCED"
        
        # traps
        # for more detailed explanation about traps see topic traps below        
        ENV_SET_TRAP_SIG=(trap "printf '\n' && exit \$exit_code" SIGHUP SIGINT SIGTERM)
        ENV_SET_TRAP_EXIT=(trap "exit_code=\$?; sleep 0.1 && env_trap_function_exit; " EXIT)
        
    elif [[ -n "$ZSH_VERSION" ]]
    then
        #echo "script is run with zsh interpreter..."
        
        # sourcing env_parallel to use variables and functions in parallels
        #source =env_parallel.zsh
        if command -v parallel &> /dev/null; then . $(which env_parallel.zsh); else :; fi
        #. $(which env_parallel.zsh)
        #. `which env_parallel.zsh`
        # by sourcing the respective env_parallel.SHELL the command itself can be used cross-shell
        # it is not neccessary to export variables or functions when using env_parallel
        # zsh does not support exporting functions, thats why parallels is prefered over xargs (bash only)
        
        # path to script
        SCRIPT_PATH="${(%):-%x}"
        # eval alternative
        # use SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH") in other script to call it
        #GET_SCRIPT_PATH='printf "%s\n" ${(%):-%x}'
        #SCRIPT_PATH=$(eval "$GET_SCRIPT_PATH")
        
        # command to read from command line   
        COMMAND_TO_READ_FROM_COMMAND_LINE='vared -p'
        env_read_from_command_line() { ${=COMMAND_TO_READ_FROM_COMMAND_LINE} "$QUESTION_TO_ASK" VARIABLE_TO_CHECK; }
        
        # use password for sudo input    
        env_use_password() { ${=USE_PASSWORD}; }
        
        # check if script is sourced
        # ^toplevel:file if script is sourced from outside a function
        # ^toplevel:shfunc:file if script is sourced from inside a function
        [[ $ZSH_EVAL_CONTEXT =~ ^toplevel:file ]] || [[ $ZSH_EVAL_CONTEXT =~ ^toplevel:shfunc:file ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        # eval alternative
        # use eval "$CHECK_IF_SOURCED" in other script to call it
        #CHECK_IF_SOURCED='[[ $ZSH_EVAL_CONTEXT =~ ':file$' ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
        #eval "$CHECK_IF_SOURCED"
        
        # traps
        # for more detailed explanation about traps see topic traps below 
        #trapSIG runs when the specific SIG is triggered
        TRAPINT() {
          #echo "Caught SIGINT, aborting."
          exit_code=$1
          printf '\n'
          #echo "exit_code is "$exit_code""
          sleep 0.1
          env_trap_function_exit
          return $(( 128 + $1 ))
        }
        
        TRAPHUP() {
          #echo "Caught SIGHUP, aborting."
          exit_code=$1
          printf '\n'
          #echo "exit_code is "$exit_code""
          sleep 0.1
          env_trap_function_exit
          return $(( 128 + $1 ))
        }
        
        TRAPTERM() {
          #echo "Caught SIGTERM, aborting."
          exit_code=$1
          printf '\n'
          #echo "exit_code is "$exit_code""
          sleep 0.1
          env_trap_function_exit
          return $(( 128 + $1 ))
        }
        
        env_set_trap_sig() {
            :;
        }
        
        # zshexit runs on each zsh shell exit
        # be careful, runs after each env_parallel process
        zshexit() { :; }
        
        # TRAPEXIT runs on each EXIT signal
        # a trap on EXIT set inside a function is executed after the function completes
        TRAPEXIT() { :; }
        
        # bash like traps
        ENV_SET_TRAP_SIG=":"
        ENV_SET_TRAP_EXIT=(trap "exit_code=\$?; trap - EXIT; sleep 0.1; env_trap_function_exit" EXIT)
        #ENV_SET_TRAP_EXIT=(trap "exit_code=\$?; trap - 1 2 3 15; sleep 0.1; env_trap_function_exit" EXIT)
    fi
    
    ### script path, name and directory
    # script path
    #echo $SCRIPT_PATH
    # script name
    SCRIPT_NAME="$(basename -- "$SCRIPT_PATH")"
    SCRIPT_NAME_WITHOUT_EXTENSION=$(echo ${SCRIPT_NAME%%.*})
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
    # script dir four back
    SCRIPT_DIR_FOUR_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && cd .. && cd .. && cd .. && pwd)"
    #echo $SCRIPT_DIR_THREE_BACK
    # script dir five back
    SCRIPT_DIR_FIVE_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && cd .. && cd .. && cd .. && cd .. && pwd)"
    #echo $SCRIPT_DIR_THREE_BACK
    
    
    ### session master
    # a sourced script does not exit, it ends with return
    # if used for traps subprocesses will not be killed on return, only on exit
    # a script sourced by the session master also returns session master = yes
    # a script that is run from another script without sourcing returns session master = no
    [[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_IS_SESSION_MASTER="no" || SCRIPT_IS_SESSION_MASTER="yes"

    if [[ "$SCRIPT_IS_SESSION_MASTER" == "yes" ]] && [[ "$SCRIPT_IS_SOURCED" == "no" ]]
    then
        SCRIPT_IS_SESSION_MASTER_AND_NOT_SOURCED="yes"
        if [[ "$SCRIPT_NAME" =~ .*.command$ ]]
        then
            #echo "session master $SCRIPT_NAME is a command file..."
            SESSION_MASTER_IS_COMMAND_FILE="yes"
        else
            :
        fi
    else
        SCRIPT_IS_SESSION_MASTER_AND_NOT_SOURCED="no"
    fi
    #echo "SCRIPT_IS_SESSION_MASTER_AND_NOT_SOURCED is $SCRIPT_IS_SESSION_MASTER_AND_NOT_SOURCED..."
    
}
env_get_shell_specific_variables


### text output
if [[ "$TERM" != "" ]]
#if [[ $- == *i* ]]
then
    # interactive shell
    bold_text=$(tput bold)
    red_text=$(tput setaf 1)
    green_text=$(tput setaf 2)
    blue_text=$(tput setaf 4)
    default_text=$(tput sgr0)
else
    # non interactive shell
    # using tput in non interactive shell output
    # tput: No value for $TERM and no -T specified
    :
fi


### timeout
if command -v gtimeout &> /dev/null
then
	# installed
	env_timeout() { gtimeout "$@"; }
else
    # not installed
    # this does not work in a pipe	
    env_timeout() { perl -e '; alarm shift; exec @ARGV' "$@"; }
fi


### checking if online
env_check_if_online_old() {
    echo ''
    echo "checking internet connection..."
    ping -c 3 google.com >/dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        ping -c 3 duckduckgo.com >/dev/null 2>&1
        if [[ $? -eq 0 ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
}

env_check_if_online() {
    ONLINECHECK1=google.com
    ONLINECHECK2=duckduckgo.com
    # check 1
    # ping -c 3 "$PINGTARGET1" >/dev/null 2>&1'
    # check 2
    # resolving dns (dig +short xxx 80 or resolveip -s xxx) even work when connection (e.g. dhcp) is established but security confirmation is required to go online, e.g. public wifis
    # during testing dig +short xxx 80 seemed more reliable to work within timeout
    # timeout 3 dig +short -4 "$PINGTARGET1" 80 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1'
    #
    echo ''
    echo "checking internet connection..."
    if [[ $(env_timeout 3 2>/dev/null dig +short -4 "$ONLINECHECK1" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        if [[ $(env_timeout 3 2>/dev/null dig +short -4 "$ONLINECHECK2" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
}

#env_check_if_online
#if [[ "$ONLINE_STATUS" == "online" ]]
#then
#    # online
#    :
#else
#    # offline
#    :
#fi


### ask for variable
env_ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(printf "%s" "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	if [[ "$ANSWER_WHEN_EMPTY" == "" ]]
	then
	    # without the </dev/tty it will not work in while [...] done <<< "$(input command)"
	    env_read_from_command_line </dev/tty
	    VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	else
    	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
    	do
    	    # without the </dev/tty it will not work in while [...] done <<< "$(input command)"
            env_read_from_command_line </dev/tty
    		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
    		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
    	done
    fi
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}


### updating config file
env_config_file_self_update() {

    if [[ "$UPDATE_CONFIG_FILE_ON_NEXT_RUN" == "no" ]]
    then
        :
    else
        SHELL_SCRIPTS_CONFIG_FILE="shellscriptsrc"
        SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH=~/."$SHELL_SCRIPTS_CONFIG_FILE"
        
        env_check_if_online &> /dev/null
        if [[ "$ONLINE_STATUS" == "online" ]] && [[ -e "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH" ]]
        then
            # online
    
            # checking if up-to-date
            if [[ "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/"$SHELL_SCRIPTS_CONFIG_FILE".sh)" != "$(cat $SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH)" ]]
            then
                echo ''
                VARIABLE_TO_CHECK="$UPDATE_CONFIG_FILE"
                QUESTION_TO_ASK="${bold_text}${blue_text}script config file is outdated, update to the latest version (Y/n)? "
                env_ask_for_variable
                printf "%s" "${default_text}"
                UPDATE_CONFIG_FILE="$VARIABLE_TO_CHECK"
                sleep 0.1
                
                if [[ "$UPDATE_CONFIG_FILE" =~ ^(yes|y)$ ]]
                then
                    # updating
                    echo ''
                    echo "installing config file from github..."
                    echo ''
                    curl https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/"$SHELL_SCRIPTS_CONFIG_FILE".sh -o "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
                    if [[ $? -eq 0 ]]; then SUCCESSFULLY_INSTALLED="yes"; else SUCCESSFULLY_INSTALLED="no"; fi
                
                    # ownership and permissions
                    chown $(id -u "$USER"):staff "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
                    chmod 600 "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
                    
                    # checking if installation was successful
                    echo ''
                    if [[ -f "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH" ]] && [[ "$SUCCESSFULLY_INSTALLED" == "yes" ]]
                    then
                        echo -e "config file was \033[1;32msuccessfully\033[0m installed to $SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH..."
                        echo ''
                        echo "###"
                    else
                        echo -e "\033[1;31merror installing config file to $SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH, please update it manually...\033[0m"
                    fi
                    echo ''
                    
                    # sourcing new file
                    unset UPDATE_CONFIG_FILE
                    UPDATE_CONFIG_FILE_ON_NEXT_RUN="no" . "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
                else
                    :
                fi
                unset UPDATE_CONFIG_FILE
            else
                # config file up-to-date
                :
            fi
        else
            # not online or file does not exist
            :
        fi
    fi
}
env_config_file_self_update


### shebang interpreter
# script shebang interpreter
SCRIPT_INTERPRETER=$(ps h -p $$ -o args='' | cut -f1 -d' ')
# the following does not work when sourced
#SCRIPT_INTERPRETER=$(cat $script | head -n1 | awk -F'!' '{print $NF}')
#echo $SCRIPT_INTERPRETER
# be careful when using $SHELL instead
# if a script with #!/bin/bash shebang interpreter will be started in zsh shell, $SHELL will be /bin/zsh, not /bin/bash
# when a script is sourced the shebang interpreter will be taken from the parent script and the shebang from the sourced script will be ignored
# the above variable reflects that correctly


### macos version
MACOS_VERSION=$(sw_vers -productVersion)
#MACOS_VERSION=$(defaults read loginwindow SystemVersionStampAsString)
#MACOS_VERSION=$(/usr/libexec/PlistBuddy -c "Print:ProductVersion" /System/Library/CoreServices/SystemVersion.plist)
if [[ $(echo "$MACOS_VERSION" | cut -f1 -d'.') == "10" ]]
then
    MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
else
    MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1 -d'.')
fi
#MACOS_VERSION_MAJOR_UNDERSCORE=$(echo "$MACOS_VERSION_MAJOR" | sed 's|\.|_|g')
MACOS_VERSION_MAJOR_UNDERSCORE=$(echo "$MACOS_VERSION_MAJOR" | tr '.' '_')
MACOS_MARKETING_NAME=$(awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | awk -F 'macOS ' '{print $NF}' | sed 's|\\$||g')
if [[ "$MACOS_MARKETING_NAME" == "" ]]
then
    if [[ "$MACOS_VERSION_MAJOR" == 10.14 ]]
    then
        MACOS_MARKETING_NAME="Mojave"
    elif [[ "$MACOS_VERSION_MAJOR" == 10.15 ]]
    then
        MACOS_MARKETING_NAME="Catalina"
    elif [[ "$MACOS_VERSION_MAJOR" == 11 ]]
    then
        MACOS_MARKETING_NAME="Big Sur"
    else
        :
    fi
else
    :
fi
#MACOS_CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | awk '{print $3}')
MACOS_CURRENTLY_BOOTED_VOLUME=$(diskutil info / | grep "Volume Name:" | sed 's/^.*Volume Name: //' | awk '{$1=$1};1')
env_get_mounted_disks() {
    MACOS_CURRENTLY_BOOTED_DISK_IDENTIFIER_MAJOR=$(diskutil info "$MACOS_CURRENTLY_BOOTED_VOLUME" | grep "Part of Whole:" | sed 's/^.*Part of Whole: //' | awk '{$1=$1};1')
    LIST_OF_ALL_MOUNTED_VOLUMES=$(for i in $(df -Hl | tail -n +2 | awk '{print $1}'); do diskutil info "$i" | grep "Mount Point:" | sed 's/^.*Mount Point: //' | awk '{$1=$1};1'; done)
    LIST_OF_ALL_MOUNTED_VOLUMES_ON_BOOT_VOLUME=$(for i in $(df -Hl | tail -n +2 | awk '{print $1}' | grep "/dev/"$MACOS_CURRENTLY_BOOTED_DISK_IDENTIFIER_MAJOR""); do diskutil info "$i" | grep "Mount Point:" | sed 's/^.*Mount Point: //' | awk '{$1=$1};1'; done)
    LIST_OF_ALL_MOUNTED_VOLUMES_OUTSIDE_OF_BOOT_VOLUME=$(for i in $(df -Hl | tail -n +2 | awk '{print $1}' | grep -v "/dev/"$MACOS_CURRENTLY_BOOTED_DISK_IDENTIFIER_MAJOR""); do diskutil info "$i" | grep "Mount Point:" | sed 's/^.*Mount Point: //' | awk '{$1=$1};1'; done)
}

env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }


### system gui settings app
VERSION_TO_CHECK_AGAINST=12
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 12
    SYSTEM_GUI_SETTINGS_APP="System Preferences"
else
    # macos versions 13 and up
    SYSTEM_GUI_SETTINGS_APP="System Settings"
fi

### paths to applications
VERSION_TO_CHECK_AGAINST=10.14
if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
then
    # macos versions until and including 10.14
    PATH_TO_SYSTEM_APPS="/Applications"
    PATH_TO_APPS="/Applications"
else
    # macos versions 10.15 and up
    PATH_TO_SYSTEM_APPS="/System/Applications"
    PATH_TO_APPS="/System/Volumes/Data/Applications"
    PATH_TO_PREBOOT_APPS="/System/Volumes/Preboot/Cryptexes/App/System/Applications/"
fi


### logged in user and unique user id
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName

# recommended way, but it seems apple deprecated python2 in macOS 12.3.0
# to keep on using the python command, a python module is needed
#pip3 install pyobjc-framework-SystemConfiguration
#loggedInUser=$(python3 -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')

#UNIQUE_USER_ID="$(dscl . -read /Users/$loggedInUser UniqueID | awk '{print $2;}')"
UNIQUE_USER_ID=$(id -u "$loggedInUser")


### subprocesses
# kill can only be silenced when 
# wrapped into function >/dev/null 2>&1 
# or with wait 
# or with kill -13

env_get_running_subprocesses() {
    if ps -o pgid= $$ &> /dev/null
    then
        RUNNING_SUBPROCESSES=$(pgrep -P $(ps -o pgid= $$))
        #echo "RUNNING_SUBPROCESSES are $RUNNING_SUBPROCESSES"
    else
        :
    fi
}

env_kill_subprocesses_sequentially() {
    # kills only subprocesses of the current process (without grandchildren)
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    #echo "killing processes..."
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # giving subprocesses the chance to terminate cleanly kill -15
    env_get_running_subprocesses    
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        while IFS= read -r line || [[ -n "$line" ]]
    	do
    	    if [[ "$line" == "" ]]; then continue; fi
    	    i="$line"
            #echo "subprocess for TERM is "$i""
            kill -15 $i
            # do not wait here if a process can not terminate cleanly
            #wait $RUNNING_SUBPROCESSES 2>/dev/null
        done <<< "$(printf "%s\n" "${RUNNING_SUBPROCESSES[@]}")"
    else
        :
    fi
    # waiting for clean subprocess termination
    TIME_OUT=0
    while [[ $RUNNING_SUBPROCESSES != "" ]] && [[ $TIME_OUT -le 3 ]]
    do
        env_get_running_subprocesses        
        sleep 1
        TIME_OUT=$((TIME_OUT+1))
    done
    # killing the rest of the processes kill -9
    env_get_running_subprocesses    
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        while IFS= read -r line || [[ -n "$line" ]]
    	do
    	    if [[ "$line" == "" ]]; then continue; fi
    	    i="$line"
    	    #echo "subprocess for KILL is "$i""
            kill -9 $i
            #wait $i 2>/dev/null
        done <<< "$(printf "%s\n" "${RUNNING_SUBPROCESSES[@]}")"
    else
        :
    fi
    # unsetting variable
    unset RUNNING_SUBPROCESSES
}

env_kill_subprocesses() {
    # left running processes in tests
    #kill $(jobs -pr)
    #kill $(jobs -pr); wait $(jobs -pr) 2>/dev/null
    
    # kills process and subprocesses without parent shell of process leader/session master by killing -$pgid
    # but only works if the shell is the process group leader
    # do not use wihtout "trap - SIGTERM &&" due to trap recursion
    # kill -- -$$
    # also do not use in subshell parantheses due to trap recursion
    # ( (kill -- -$$ &> /dev/null) & )
    # only use like this
    # TERM signal (-15)
    # trap - SIGTERM && kill -- -$$
    # KILL signal (-9)
    # trap - SIGTERM && kill -9 -$$
    
    # kills subprocesses but does not kill grandchildren
    # trap - SIGTERM && pkill -P $$
    
    # kills subprocesses without parent shell of own process
    # this even works for a script that is run from another script
    # env_kill_subprocesses_sequentially
    
    # kills complete process tree including parent shell
    # do not use without "trap - SIGTERM &&" due to trap recursion
    # kill 0
    # also do not use in subshell parantheses due to trap recursion
    # ( (kill 0 &> /dev/null) & )
    # only use like this
    # trap - SIGTERM && kill 0
    
    # checking if $$ is a process group id
    #kill -15 $(ps -p $PPID -o ppid=)
    if [[ $(ps -e -o pgid,pid,command | awk -v p=$$ '$1 == p {print $2}') != "" ]]
    then
    	#echo "$$ is a pgid..."
    	#trap - SIGTERM && kill -- -$$
    	# for command files in zsh there is an issue which makes the script not exit correctly without using env_kill_shell_if_command_file to kill the shell
    	# sending it to env_kill_shell_if_command_file also solved the output problem for "terminated" messages
        trap "env_kill_shell_if_command_file" SIGTERM && kill -- -$$
        # alternatively (should also work, but a bit slower)
        #env_kill_subprocesses_sequentially
        #env_kill_shell_if_command_file
    else
    	#echo "$$ is NOT a pgid..."
    	#if [[ $(jobs -pr) != "" ]]; then kill $(jobs -pr); fi
    	env_kill_subprocesses_sequentially
    	env_kill_shell_if_command_file
    fi
}

env_kill_shell_if_command_file() {
    if [[ "$SESSION_MASTER_IS_COMMAND_FILE" == "yes" ]]
    then
        #echo "session master $SCRIPT_NAME is a command file..."
        # the printf is needed for exiting cleanly for .command files
        tput cuu1
        printf '\n' && kill $(ps -p $PPID -o ppid=)
        #printf '\n' && kill -15 $(ps -p $PPID -o ppid=)
        #printf '\n' && kill -9 $(ps -p $PPID -o ppid=)
    else
        #echo "session master $SCRIPT_NAME is NOT a command file..."
        #kill -13 $$
        :
    fi
}

env_kill_main_process() {
    # kills processes itself
    #kill $$
    #kill -13 $$
    ((kill -13 $$) & ) >/dev/null 2>&1
}


### databases and permissions for apps to write to them
env_databases_apps_security_permissions() {
    DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_SYSTEM"
	DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
    #echo "$DATABASE_USER"
}


### identify terminal
env_identify_terminal() {
    if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]
    then
    	export SOURCE_APP=com.apple.Terminal
    	export SOURCE_APP_NAME="Terminal"
    elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]
    then
        export SOURCE_APP=com.googlecode.iterm2
        export SOURCE_APP_NAME="iTerm"
	else
		export SOURCE_APP=com.apple.Terminal
		export SOURCE_APP_NAME="Terminal"
		echo "terminal not identified, setting automating permissions to apple terminal..."
	fi
	export SOURCE_APP_NAME_FULL=""$SOURCE_APP_NAME".app"
}


### activating identified terminal
env_active_source_app() {
	sleep 0.5
	osascript -e "tell application \"$SOURCE_APP_NAME\" to activate"
	#osascript -e "tell application \"$SOURCE_APP_NAME.app\" to activate"
	sleep 0.5
}


### path to app
env_get_path_to_app() {

    if [[ "$SKIP_ENV_GET_PATH_TO_APP" == "yes" ]]
    then
        :
    else
        # app path
        local NUM1=0
        local FIND_APP_PATH_TIMEOUT=4
        unset PATH_TO_APP
        
        # app name
        APP_NAME_EXTENSION=$([[ "$APP_NAME" = *.* ]] && echo "${APP_NAME##*.}" || echo '')
        if [[ "$APP_NAME_EXTENSION" == "" ]]
        then
            APP_NAME_WITH_EXTENSION=""$APP_NAME".app"
        else
            # extension exists
            APP_NAME_WITH_EXTENSION="$APP_NAME"
        fi
        
        # apps, system apps, core apps, user apps
        for i in "$PATH_TO_APPS" "$PATH_TO_SYSTEM_APPS" "/System/Library/CoreServices" "/Users/"$USER"/Library/Scripts/" "/Users/"$USER"/Applications"
        do
            if [[ -e "$i" ]] && [[ "$PATH_TO_APP" == "" ]]
            then
                PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin "$i" | grep -i "/$APP_NAME_WITH_EXTENSION$" | sort -n | tail -1)
            fi
            if [[ -e "$i" ]] && [[ "$PATH_TO_APP" == "" ]]
            then
                PATH_TO_APP=$(find "$i" -mindepth 1 -maxdepth 2 -name "$APP_NAME_WITH_EXTENSION" | sort -n | tail -1)
            fi
        done
        # pref panes, apps in other apps, homebrew apps
        #echo ''
        if command -v brew &> /dev/null
        then
            # installed
            #echo "homebrew already installed..."
            for i in "/Users/"$USER"/Library/PreferencePanes" "$PATH_TO_APPS" "$(brew --prefix)/Caskroom"
            do
                if [[ -e "$i" ]] && [[ "$PATH_TO_APP" == "" ]]
                then
                    PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin "$i" | grep -i "/$APP_NAME_WITH_EXTENSION$" | sort -n | tail -1)
                fi
                if [[ -e "$i" ]] && [[ "$PATH_TO_APP" == "" ]]
                then
                    PATH_TO_APP=$(find "$i" -mindepth 2 -name "$APP_NAME_WITH_EXTENSION" | sort -n | tail -1)
                fi
            done  
        else
            # not installed
            #echo "homebrew is not installed, skipping search in homebrew directory..."
            for i in "/Users/"$USER"/Library/PreferencePanes" "$PATH_TO_APPS"
            do
                if [[ -e "$i" ]] && [[ "$PATH_TO_APP" == "" ]]
                then
                    PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin "$i" | grep -i "/$APP_NAME_WITH_EXTENSION$" | sort -n | tail -1)
                fi
                if [[ -e "$i" ]] && [[ "$PATH_TO_APP" == "" ]]
                then
                    PATH_TO_APP=$(find "$i" -mindepth 2 -name "$APP_NAME_WITH_EXTENSION" | sort -n | tail -1)
                fi
            done
        fi
        

        while [[ "$PATH_TO_APP" == "" ]]
        do
            # bash builtin printf can not print floating numbers
        	#perl -e 'printf "%.2f\n",'$NUM1''
    	    #echo $NUM1 | awk '{printf "%.2f", $1; print $2}' | sed s/,/./g
        	local NUM1=$(bc<<<$NUM1+0.5)
        	if (( $(echo "$NUM1 <= $FIND_APP_PATH_TIMEOUT" | bc -l) ))
        	then
        	    # bash builtin printf can not print floating numbers
        		#perl -e 'printf "%.2f\n",'$NUM1''
    	        #echo $NUM1 | awk '{printf "%.2f", $1; print $2}' | sed s/,/./g
        		sleep 0.5
                PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application -onlyin / | grep -i "/$APP_NAME_WITH_EXTENSION$" | sort -n | head -1)
        	else
        	    #printf '\n'
        		break
        	fi
        done
        if [[ "$APP_NAME" == "PVGuard" ]] && [[ -e ~/.cache/icedtea-web/jvm-cache/cache.json ]] && [[ -e "$PATH_TO_APPS"/"$APP_NAME".app ]]
        then 
            JAVA_VERSION=$(jq -r '.runtimes | .[] | .version' ~/.cache/icedtea-web/jvm-cache/cache.json)
            PATH_TO_APP=/Users/"$USER"/.cache/icedtea-web/jvm-cache/adopt_"$JAVA_VERSION"/bin/java
        fi
    fi
}


### app id / bundle identifier
env_get_app_id() {
    
    # app id
    #if [[ -e "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt ]]
    #then
    #    local APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '2p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
    #else
    #    :
    #fi
    
    if [[ "$APP_NAME" == "com.apple.screensharing.agent" ]]
    then
        APP_ID="com.apple.screensharing.agent"
    else
        env_get_path_to_app
        if [[ "$PATH_TO_APP" == "" ]]
        then
            # trying another way to get the app id without knowing the path to the .app
            APP_ID=$(osascript -e "id of app \"$APP_NAME\"") &> /dev/null
            if [[ "$APP_ID" == "" ]];then echo "PATH_TO_APP of "$APP_NAME" is empty, skipping entry..." && continue; fi
        else  
            if [[ "$APP_NAME" == "PVGuard" ]] && [[ -e ~/.cache/icedtea-web/jvm-cache/cache.json ]] && [[ -e "$PATH_TO_APPS"/"$APP_NAME".app ]]
            then 
                JAVA_VERSION=$(jq -r '.runtimes | .[] | .version' ~/.cache/icedtea-web/jvm-cache/cache.json)
                APP_ID=net.java.openjdk."$JAVA_VERSION".java
            else       
                APP_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' ""$PATH_TO_APP"/Contents/Info.plist")
                #local APP_ID=$(APP_NAME2="${APP_NAME//\'/\'}.app"; APP_NAME2=${APP_NAME2//"/\\"}; APP_NAME2=${APP_NAME2//\\/\\\\}; mdls -name kMDItemCFBundleIdentifier -raw "$(mdfind 'kMDItemContentType==com.apple.application-bundle&&kMDItemFSName=="'"$APP_NAME2"'"' | sort -n | head -n1)")
                # specifying app id in array
                #local APP_ID=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            fi
        fi
        #echo "PATH_TO_APP is "$PATH_TO_APP"..."
        #echo "APP_ID is "$APP_ID""
        if [[ "$APP_ID" == "" ]];then echo "APP_ID of "$APP_NAME" is empty, skipping entry..." && continue; fi
    fi
}


### startup-items
env_get_autostart_items() {
    AUTOSTART_ITEMS=$(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
}

env_delete_all_startup_items() {
    if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g') != "" ]]
    then
        while IFS= read -r line || [[ -n "$line" ]]        
		do
		    if [[ "$line" == "" ]]; then continue; fi
            autostartapp="$line"
        	echo "deleting autostartentry for $autostartapp..."
        	osascript -e "tell application \"System Events\" to delete login item \"$autostartapp\""
        done <<< "$(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')"
    else
        :
    fi
}

env_add_startup_items() {
    while IFS= read -r line || [[ -n "$line" ]] 
	do
	    if [[ "$line" == "" ]]; then continue; fi
        i="$line"
        #echo "APP_PATH is "$APP_PATH"..."
        local APP_NAME=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
       	#echo "APP_NAME is "$APP_NAME"..."
		local START_HIDDEN=$(echo "$i" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
       	#echo "START_HIDDEN is "$START_HIDDEN"..."
       	env_get_path_to_app
       	if [[ $(osascript -e 'tell application "System Events" to get the name of every login item' | tr "," "\n" | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | grep -w "$APP_NAME") == "" ]]
       	then
           	if [[ "$PATH_TO_APP" != "" ]]
    		then
    		    # osascript -e 'tell application "System Events" to make login item at end with properties {name:"name", path:"/path/to/itemname", hidden:false}'
                osascript -e 'tell application "System Events" to make login item at end with properties {name:"'$APP_NAME'", path:"'$PATH_TO_APP'", hidden:"'$START_HIDDEN'"}'
            else
            	echo ""$APP_NAME" not found, skipping..."
            fi
       	else
       	    echo ""$APP_NAME" already in autostart entries, skipping..."
       	fi       	     
	done <<< "$(printf "%s\n" "${AUTOSTART_ITEMS[@]}")"
}


### apps security permissions
env_set_apps_security_permissions() {
    
    # setting databases
    env_databases_apps_security_permissions
    
    #for APP_ENTRY in "${APPS_SECURITY_ARRAY[@]}"
    while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then continue; fi
        local APP_ENTRY="$line"
        #echo "$APP_ENTRY"
        
        # app name
        #local APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/   */:/g' | cut -d':' -f1)
        #local APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/ \{2,\}/:/g' | cut -d':' -f2)
       	#local APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | awk -F '  +' '{print $1}')
       	#local APP_NAME=$(echo "$app_entry" | sed $'s/\t/|/g' | sed 's/   */:/g' | cut -d':' -f1)
       	local APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
       	#local APP_NAME_NO_SPACES=$(echo "$APP_NAME" | sed 's/ /_/g' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
       	#echo "APP_NAME is "$APP_NAME""

        APP_NAME="$APP_NAME"
        env_get_app_id
            
        # app csreq
        #local APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '3p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')    
        #echo "$APP_CSREQ"
        
        # input service
        local INPUT_SERVICE=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        #echo "$INPUT_SERVICE"
        
        # permissions allowed
        # 0 = no
        # 1 = yes
        local PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
        #echo "$PERMISSION_GRANTED"

        # setting permissions
        if [[ "$INPUT_SERVICE" == "kTCCServiceAccessibility" ]] || [[ "$INPUT_SERVICE" == "kTCCServiceScreenCapture" ]] || [[ "$INPUT_SERVICE" == "kTCCServiceSystemPolicyAllFiles" ]] || [[ "$INPUT_SERVICE" == "kTCCServiceDeveloperTool" ]] || [[ "$INPUT_SERVICE" == "kTCCServicePostEvent" ]]
        then
            # delete entry before resetting
            sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where (service='$INPUT_SERVICE' and client='$APP_ID');" 2>&1 | grep -v '^$'
            sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where (service='kTCCServicePostEvent' and client='$APP_ID');" 2>&1 | grep -v '^$'
            sleep 0.1
            if [[ "$MACOS_VERSION_MAJOR" == "10.13" ]]
            then
                # macos 10.13
                sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,1,NULL,NULL);" 2>&1 | grep -v '^$'
            elif [[ "$MACOS_VERSION_MAJOR" == "10.14" ]] || [[ "$MACOS_VERSION_MAJOR" == "10.15" ]]
            then
                # macos 10.14 and 10.15
                # working, but no csreq
                sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,?,NULL,0,?);" 2>&1 | grep -v '^$'
                # working with csreq
                #sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,$APP_CSREQ,NULL,0,?);"
            elif [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable 11) ]] && [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable 13) ]]
            then
                # macos 11 to 13
                if [[ $PERMISSION_GRANTED == "0" ]]
                then
                    :
                elif [[ $PERMISSION_GRANTED == "1" ]]
                then
                    PERMISSION_GRANTED=2
                fi
                # working, but no csreq
                sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,4,1,NULL,NULL,NULL,?,NULL,0,?);" 2>&1 | grep -v '^$'
                # working with csreq
                #sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,4,1,NULL,NULL,NULL,$APP_CSREQ,NULL,0,?);"
            elif VERSION_TO_CHECK_AGAINST=14; [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
            then
                # macos 14 and higher
                if [[ $PERMISSION_GRANTED == "0" ]]
                then
                    :
                elif [[ $PERMISSION_GRANTED == "1" ]]
                then
                    PERMISSION_GRANTED=2
                fi
                sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,4,1,?,NULL,0,'UNUSED',NULL,0,?,NULL,NULL,'UNUSED',?);"
            else
                echo ''
                echo "setting security permissions for this version of macos is not supported, skipping..."
                echo ''
            fi
        else
            # delete entry before resetting
            sqlite3 "$DATABASE_USER" "delete from access where (service='$INPUT_SERVICE' and client='$APP_ID');" 2>&1 | grep -v '^$'
            sleep 0.1
            if [[ "$MACOS_VERSION_MAJOR" == "10.13" ]]
            then
                # macos 10.13
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,1,NULL,NULL);"
            elif [[ "$MACOS_VERSION_MAJOR" == "10.14" ]] || [[ "$MACOS_VERSION_MAJOR" == "10.15" ]]
            then
                # macos 10.14 and 10.15
                # working, but no csreq
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);" 2>&1 | grep -v '^$'
                # working with csreq
                #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,$APP_CSREQ,NULL,NULL,?,NULL,NULL,?);"
            elif [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable 11) ]] && [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable 13) ]]
            then
                # macos 11 and higher
                if [[ $PERMISSION_GRANTED == "0" ]]
                then
                    :
                elif [[ $PERMISSION_GRANTED == "1" ]]
                then
                    PERMISSION_GRANTED=2
                fi
                # working, but no csreq
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,4,1,?,NULL,NULL,?,NULL,NULL,?);" 2>&1 | grep -v '^$'
                # working with csreq
                #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,4,1,$APP_CSREQ,NULL,NULL,?,NULL,NULL,?);"
            elif VERSION_TO_CHECK_AGAINST=14; [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
            then
                # macos 14 and higher
                if [[ $PERMISSION_GRANTED == "0" ]]
                then
                    :
                elif [[ $PERMISSION_GRANTED == "1" ]]
                then
                    PERMISSION_GRANTED=2
                fi
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,4,1,?,NULL,0,'UNUSED',NULL,0,?,NULL,NULL,'UNUSED',?);" 2>&1 | grep -v '^$'
            else
                echo ''
                echo "setting security permissions for this version of macos is not supported, skipping..."
                echo ''
            fi
        fi

        # app name print
        local APP_NAME_PRINT=$(echo "$APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        local INPUT_SERVICE_PRINT=$(echo "$INPUT_SERVICE" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        
        # print line
        if [[ "$PRINT_SECURITY_PERMISSIONS_ENTRIES" == "yes" ]]
        then
            printf "%-33s %-33s %4s\n" "$APP_NAME_PRINT" "$INPUT_SERVICE_PRINT" "$PERMISSION_GRANTED"
        else
            :
        fi
        
        # unset variables for next entry
        unset APP_ENTRY
        unset APP_NAME
        unset APP_NAME_PRINT
        unset PATH_TO_APP
        unset APP_ID
        unset APP_CSREQ
        unset INPUT_SERVICE
        unset PERMISSION_GRANTED
        unset NUM1
        unset FIND_APP_PATH_TIMEOUT        
    
    #done
    done <<< "$(printf "%s\n" "${APPS_SECURITY_ARRAY[@]}")"
    
    sleep 0.1
}


### apps automation permissions
env_set_apps_automation_permissions() {

    VERSION_TO_CHECK_AGAINST=10.13
    if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
    then
        # macos versions until and including 10.13
    	echo "setting automation permissions is not compatible with this version of macos, skipping..."
    else
        # setting databases
        env_databases_apps_security_permissions
    
        #for APP_ENTRY in "${AUTOMATION_APPS[@]}"
        while IFS= read -r line || [[ -n "$line" ]]
        do
            if [[ "$line" == "" ]]; then continue; fi
            local APP_ENTRY="$line"
            #echo "APP_ENTRY is "$APP_ENTRY""
            
            ### source app
            # source app name
            local SOURCE_APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            #echo "SOURCE_APP_NAME is "$SOURCE_APP_NAME""
            
            local APP_NAME="$SOURCE_APP_NAME"
            env_get_app_id
            local SOURCE_APP_ID="$APP_ID"
            local PATH_TO_SOURCE_APP="$PATH_TO_APP"
            
            # source app csreq
            #if [[ -e "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt ]]
            #then
            #    local SOURCE_APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt | sed -n '3p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            #    #echo "$SOURCE_APP_CSREQ"
            #else
            #    local SOURCE_APP_CSREQ='?'
            #fi
            
            # get the requirement string from codesign
            local SOURCE_APP_CSREQ_STRING=$(codesign -d -r- "$PATH_TO_SOURCE_APP"/ 2>&1 | awk -F ' => ' '/designated/{print $2}')
            #if [[ "$SOURCE_APP_CSREQ_STRING" == "" ]]
            #then
            #    codesign --detached "$PATH_TO_SOURCE_APP".sig -s - "$PATH_TO_SOURCE_APP"
            #    local SOURCE_APP_CSREQ_STRING=$(codesign -d -r- --detached "$PATH_TO_SOURCE_APP".sig "$PATH_TO_SOURCE_APP")
            #else
            #    :
            #fi
            if [[ "$SOURCE_APP_CSREQ_STRING" == "" ]]
            then
                #echo "csreq of "$AUTOMATED_APP_ID" not found..."
                local SOURCE_APP_CSREQ='?'
            else
                # convert the requirements string into it's binary representation (sadly it seems csreq requires the output to be a file; so we just throw it in /tmp)
                echo "$SOURCE_APP_CSREQ_STRING" | csreq -r- -b /tmp/csreq.bin
                # convert the binary form to hex, and print it nicely for use in sqlite
                local SOURCE_APP_CSREQ_HEX=$(xxd -p /tmp/csreq.bin  | tr -d '\n')
                local SOURCE_APP_CSREQ=$(echo "X'$SOURCE_APP_CSREQ_HEX'")
                #echo "SOURCE_APP_CSREQ is "$SOURCE_APP_CSREQ""
                if [[ -e /tmp/csreq.bin ]]; then rm -f /tmp/csreq.bin; else :; fi
            fi
            
            ### automated app
            # automated app name
            local AUTOMATED_APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            #echo "$AUTOMATED_APP_NAME"
            
            local APP_NAME="$AUTOMATED_APP_NAME"
            env_get_app_id
            local AUTOMATED_APP_ID="$APP_ID"
            local PATH_TO_AUTOMATED_APP="$PATH_TO_APP"
            
            # automated app csreq
            #if [[ -e "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt ]]
            #then
            #    local AUTOMATED_APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt | sed -n '3p' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
                #echo "$SOURCE_APP_CSREQ"
            #else
            #    local AUTOMATED_APP_CSREQ='?'
            #fi
            #echo "$AUTOMATED_APP_CSREQ"
            
            # get the requirement string from codesign
            local AUTOMATED_APP_CSREQ_STRING=$(codesign -d -r- "$PATH_TO_AUTOMATED_APP"/ 2>&1 | awk -F ' => ' '/designated/{print $2}')
            if [[ "$AUTOMATED_APP_CSREQ_STRING" == "" ]]
            then
                #echo "csreq of "$AUTOMATED_APP_ID" not found..."
                local AUTOMATED_APP_CSREQ='?'
            else
                # convert the requirements string into it's binary representation (sadly it seems csreq requires the output to be a file; so we just throw it in /tmp)
                echo "$AUTOMATED_APP_CSREQ_STRING" | csreq -r- -b /tmp/csreq.bin
                # convert the binary form to hex, and print it nicely for use in sqlite
                local AUTOMATED_APP_CSREQ_HEX=$(xxd -p /tmp/csreq.bin  | tr -d '\n')
                local AUTOMATED_APP_CSREQ=$(echo "X'$AUTOMATED_APP_CSREQ_HEX'")
                #echo "AUTOMATED_APP_CSREQ is "$AUTOMATED_APP_CSREQ""
                if [[ -e /tmp/csreq.bin ]]; then rm -f /tmp/csreq.bin; else :; fi
            fi
            
            ### permissions allowed
            # 0 = no
            # 1 = yes
            local PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
            #echo "$PERMISSION_GRANTED"
            
            ### setting permissions
            # working, but does not show in gui, use csreq for the entry to make it work and show
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,?,NULL,0,'$AUTOMATED_APP_ID',?,NULL,?);"
            # not working, but shows correct entry in gui, use csreq to make it work and show
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,'UNUSED',NULL,0,'$AUTOMATED_APP_ID','UNUSED',NULL,?);"
            # working and showing in gui when using correct values in CSREQ variables
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,$SOURCE_APP_CSREQ,NULL,0,'$AUTOMATED_APP_ID',$AUTOMATED_APP_CSREQ,NULL,?);"
            
            # delete entry before resetting
            sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='$SOURCE_APP_ID' and indirect_object_identifier='$AUTOMATED_APP_ID');"
            sleep 0.1
            
            VERSION_TO_CHECK_AGAINST=10.15
            if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
            then
                # macos versions until and including 10.15
                # working and showing in gui if csreq is not '?'
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,$SOURCE_APP_CSREQ,NULL,0,'$AUTOMATED_APP_ID',$AUTOMATED_APP_CSREQ,NULL,?);"
            elif [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable 11) ]] && [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable 13) ]]
            then
                # macos version 11 to 13
                if [[ $PERMISSION_GRANTED == "0" ]]
                then
                    :
                elif [[ $PERMISSION_GRANTED == "1" ]]
                then
                    PERMISSION_GRANTED=2
                fi
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,4,1,$SOURCE_APP_CSREQ,NULL,0,'$AUTOMATED_APP_ID',$AUTOMATED_APP_CSREQ,NULL,?);"
            elif VERSION_TO_CHECK_AGAINST=14; [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -ge $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]
            then
                # macos version 14 and higher
                if [[ $PERMISSION_GRANTED == "0" ]]
                then
                    :
                elif [[ $PERMISSION_GRANTED == "1" ]]
                then
                    PERMISSION_GRANTED=2
                fi
                sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,4,1,$SOURCE_APP_CSREQ,NULL,0,'$AUTOMATED_APP_ID',$AUTOMATED_APP_CSREQ,NULL,?,NULL,NULL,'UNUSED',?);"
            fi
            
            ### print line
            local SOURCE_APP_NAME_PRINT=$(echo "$SOURCE_APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
            local AUTOMATED_APP_NAME_PRINT=$(echo "$AUTOMATED_APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
            if [[ "$PRINT_AUTOMATING_PERMISSIONS_ENTRIES" == "yes" ]]
            then
                printf "%-33s %-33s %4s\n" "$SOURCE_APP_NAME_PRINT" "$AUTOMATED_APP_NAME_PRINT" "$PERMISSION_GRANTED"
            else
                :
            fi
            
            # unset variables for next entry
            unset SOURCE_APP_NAME
            unset SOURCE_APP_NAME_PRINT
            unset PATH_TO_SOURCE_APP
            unset SOURCE_APP_ID
            unset SOURCE_APP_CSREQ_STRING
            unset SOURCE_APP_CSREQ_HEX
            unset SOURCE_APP_CSREQ
            unset AUTOMATED_APP_NAME
            unset AUTOMATED_APP_NAME_PRINT
            unset PATH_TO_AUTOMATED_APP
            unset AUTOMATED_APP_ID
            unset AUTOMATED_APP_CSREQ_STRING
            unset AUTOMATED_APP_CSREQ_HEX
            unset AUTOMATED_APP_CSREQ
            unset PERMISSION_GRANTED
            unset NUM1
            unset FIND_APP_PATH_TIMEOUT
            unset PATH_TO_APP
            unset APP_ID 
        
        #done
        done <<< "$(printf "%s\n" "${AUTOMATION_APPS[@]}")"
        
        sleep 0.1
    fi
}

env_remove_apps_security_permissions_stop() {
    :
}


### apps notifications
NOTIFICATIONS_PLIST_FILE="/Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist"

env_get_needed_notification_apps_entry() {

	#NUMBER_OF_ENTRIES=$(/usr/libexec/PlistBuddy -c "Print apps" "$NOTIFICATIONS_PLIST_FILE" | grep -a ".*" | awk '/^[[:blank:]]*bundle-id =/' | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
	NUMBER_OF_ENTRIES=$(defaults read "$NOTIFICATIONS_PLIST_FILE" | awk '/^[[:blank:]]*"bundle-id" =/' | wc -l | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g' | sed '/^$/d')
	# -1 because counting of items starts with 0, not with 1
	NUMBER_OF_ENTRIES_TO_LIST=$((NUMBER_OF_ENTRIES-1))
	
	NEEDED_ENTRY=""
	for i in $(seq 0 "$NUMBER_OF_ENTRIES_TO_LIST")
	do 
	   	(/usr/libexec/PlistBuddy -c "Print apps:"$i"" "$NOTIFICATIONS_PLIST_FILE" | grep "$BUNDLE_IDENTIFIER") >/dev/null 2>&1
	   	if [[ "$?" -eq 0 ]]
	    then
	        # checked entry is needed entry
	        NEEDED_ENTRY="$i"
	    else
	    	# checked entry is NOT needed entry
	        :
	    fi
	done
	
}

env_set_check_apps_notifications() {
    
    defaults read "$NOTIFICATIONS_PLIST_FILE" &> /dev/null
    
	### setting flags
	echo ''
	if [[ "$SET_APPS_NOTIFICATIONS" == "yes" ]]
	then
		echo "setting app notifications..."
	elif [[ "$CHECK_APPS_NOTIFICATIONS" == "yes" ]]
	then
		echo "checking app notifications..."
	fi
	
	### setting apps notifications
	for NOTIFICATION_APP in "${APPLICATIONS_TO_SET_NOTIFICATIONS[@]}"
	do
		local APP_NAME=$(echo "$NOTIFICATION_APP" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    local FLAGS_VALUE=$(echo "$NOTIFICATION_APP" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')
	    
        env_get_app_id
        local BUNDLE_IDENTIFIER="$APP_ID"
	    if [[ "$BUNDLE_IDENTIFIER" != "" ]]
	    then
	    			
			env_get_needed_notification_apps_entry
			if [[ "$NEEDED_ENTRY" != "" ]]
			then
				# entry exists
				local ACTIVE_FLAG_VALUE=$(/usr/libexec/PlistBuddy -c "Print apps:"$NEEDED_ENTRY":flags" "$NOTIFICATIONS_PLIST_FILE")
				
			    if [[ "$SET_APPS_NOTIFICATIONS" == "yes" ]]
			    then
			    	if [[ "$FLAGS_VALUE" == "$ACTIVE_FLAG_VALUE" ]]
			    	then
			    		echo "flags for $BUNDLE_IDENTIFIER already set correctly..."
			    	else    
			    		echo "setting flags for $BUNDLE_IDENTIFIER..."
			    		#/usr/libexec/PlistBuddy -c "Set apps:"$NEEDED_ENTRY":flags "$FLAGS_VALUE"" "$NOTIFICATIONS_PLIST_FILE"
			    		plutil -replace apps."$NEEDED_ENTRY".flags -integer "$FLAGS_VALUE" "$NOTIFICATIONS_PLIST_FILE"
			    		local RESTART_NOTIFICATION_CENTER="yes"
			    	fi
			    elif [[ "$CHECK_APPS_NOTIFICATIONS" == "yes" ]]
			    then
			        local BUNDLE_IDENTIFIER_PRINT=$(printf '%s\n' "$BUNDLE_IDENTIFIER" | awk -v len=35 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
				    if [[ "$FLAGS_VALUE" == "$ACTIVE_FLAG_VALUE" ]]
			        then
			            CHECK_RESULT_PRINT=$(echo -e '\033[1;32mok\033[0m')
			            CHECK_RESULT_EXPORT="ok"
			            printf "%-5s %-35s %12s %12s %17s\n" "$NEEDED_ENTRY" "$BUNDLE_IDENTIFIER_PRINT" "$FLAGS_VALUE" "$ACTIVE_FLAG_VALUE" "$CHECK_RESULT_PRINT"
					else
			            CHECK_RESULT_PRINT=$(echo -e '\033[1;31mwrong\033[0m')
			            CHECK_RESULT_EXPORT="wrong"
			            if [[ "$PRINT_NOTIFICATION_CHECK_TO_ERROR_LOG" == "no" ]]
			            then
			                printf "%-5s %-35s %12s %12s %17s\n" "$NEEDED_ENTRY" "$BUNDLE_IDENTIFIER_PRINT" "$FLAGS_VALUE" "$ACTIVE_FLAG_VALUE" "$CHECK_RESULT_PRINT"
			            else
			                printf "%-5s %-35s %12s %12s %20s\n" "$NEEDED_ENTRY" "$BUNDLE_IDENTIFIER_PRINT" "$FLAGS_VALUE" "$ACTIVE_FLAG_VALUE" "$CHECK_RESULT_PRINT" >&2
			            fi
			        fi
				fi 
				
			else
				# entry does not exist
				if [[ "$SET_APPS_NOTIFICATIONS" == "yes" ]]
			    then
					echo "entry for $BUNDLE_IDENTIFIER does not exist, creating it..."
			    	#local NEW_ITEM=$(echo \'Item "$NUMBER_OF_ENTRIES"\')  
			    	local NEW_ITEM=$(echo "$NUMBER_OF_ENTRIES") 
			   		#/usr/libexec/PlistBuddy -c "Add apps:"$NEW_ITEM":bundle-id string "$BUNDLE_IDENTIFIER"" "$NOTIFICATIONS_PLIST_FILE"
			   		plutil -insert apps."$NEW_ITEM" -xml "<dict><key>bundle-id</key><string>"$BUNDLE_IDENTIFIER"</string></dict>" /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist
					env_get_needed_notification_apps_entry
					#/usr/libexec/PlistBuddy -c "Add apps:"$NEEDED_ENTRY":flags integer "$FLAGS_VALUE"" "$NOTIFICATIONS_PLIST_FILE"
					plutil -insert apps."$NEW_ITEM".flags -integer "$FLAGS_VALUE" /Users/"$USER"/Library/Preferences/com.apple.ncprefs.plist
					local RESTART_NOTIFICATION_CENTER="yes"
				elif [[ "$CHECK_APPS_NOTIFICATIONS" == "yes" ]]
			    then
			    	echo "entry for $BUNDLE_IDENTIFIER does not exist..."
			    fi
			    
			fi
			
		else
			echo "BUNDLE_IDENTIFIER is empty, skipping..."
		fi
	
	done

	if [[ "$RESTART_NOTIFICATION_CENTER" == "yes" ]]
	then
		### restarting notification center
		echo ''
		echo "restarting notification center..."
		#open /System/Library/CoreServices/NotificationCenter.app
		# applying changes without having to logout
		#sudo killall usernoted
		#sudo killall NotificationCenter
		#killall sighup usernoted
		#killall sighup NotificationCenter
        PROCESS_LIST=(
        cfprefsd
        usernoted
        #NotificationCenter
        )
        while IFS= read -r line || [[ -n "$line" ]] 
    	do
    	    if [[ "$line" == "" ]]; then continue; fi
            i="$line"
            #echo "$i"
            if [[ $(ps aux | grep "$i" | grep -v grep | awk '{print $2;}') != "" ]]
            then
            	killall "$i" && sleep 0.1 && while [[ $(ps aux | grep "$i" | grep -v grep | awk '{print $2;}') == "" ]]; do sleep 0.5; done
    		else
    			:
    		fi
        done <<< "$(printf "%s\n" "${PROCESS_LIST[@]}")"
        sleep 2
		defaults read "$NOTIFICATIONS_PLIST_FILE" &> /dev/null
		echo ''
		
		if [[ "$SLEEP_AFTER_RESTART_NOTIFICATION_CENTER" == "no" ]]
		then
		    :
		else
    		echo ''
    		SLEEP_TIME=10
    		NUM1=0
    		#echo ''
    		while [[ "$NUM1" -le "$SLEEP_TIME" ]]
    		do 
    			NUM1=$((NUM1+1))
    			if [[ "$NUM1" -le "$SLEEP_TIME" ]]
    			then
    				#echo "$NUM1"
    				sleep 1
    				tput cuu 1 && tput el
    				echo "waiting $((SLEEP_TIME-NUM1)) seconds for the changes to take effect..."
    			else
    				:
    			fi
    		done
    	fi
	else
		:
	fi
	
	unset SET_APPS_NOTIFICATIONS
	unset CHECK_APPS_NOTIFICATIONS
	unset RESTART_NOTIFICATION_CENTER
	unset NOTIFICATION_APP
    unset PATH_TO_APP
    unset APP_ID
    unset BUNDLE_IDENTIFIER
}


### sudo password upfront
env_enter_sudo_password() {

    #echo ''
    
    # function for reading secret string (POSIX compliant)
    enter_password_secret() {
        # POSIX compliant
        # disabling echo, this will prevent showing output
        stty -echo
        # setting up trap to ensure echo is enabled before exiting if the script is terminated while echo is disabled
        #trap 'stty echo' EXIT
        trap_function_exit_middle() { stty echo; }
        # asking for password
        printf "Password: "
        # reading secret
        read -r "$@" SUDOPASSWORD
        # reanabling echo
        stty echo
        #trap - EXIT
        trap_function_exit_middle() { :; }
        #unset -f trap_function_exit_middle
        # print a newline because the newline entered by the user after entering the passcode is not echoed. This ensures that the next line of output begins at a new line.
        printf "\n"
        # making sure builtin bash commands are used for using the SUDOPASSWORD, this will prevent showing it in ps output
        # has to be part of the function or it wouldn`t be updated during the maximum three tries
        #USE_PASSWORD='builtin echo '"$SUDOPASSWORD"''
        USE_PASSWORD='builtin printf '"$SUDOPASSWORD\n"''
    }
    
    # unset the password if the variable was already set
    unset SUDOPASSWORD
    
    # making sure no variables are exported
    set +a
    
    # asking for the SUDOPASSWORD upfront
    # typing and reading SUDOPASSWORD from command line without displaying it and
    # checking if entered password is the sudo password with a set maximum of tries
    NUMBER_OF_TRIES=0
    MAX_TRIES=3
    while [[ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]]
    do
        NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
        #echo "$NUMBER_OF_TRIES"
        if [[ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]]
        then
            if [[ "$USE_PASSWORD" == "" ]] || [[ "$SUDOPASSWORD_CORRECT" == "no" ]]
            then
                enter_password_secret
            else
                :
            fi
            env_use_password | sudo -k -S echo "" > /dev/null 2>&1
            if [[ $? -eq 0 ]]
            then 
                break
            else
                #echo "Sorry, try again."
                SUDOPASSWORD_CORRECT="no"
                unset SUDOPASSWORD
                unset USE_PASSWORD
            fi
        else
            echo ""$MAX_TRIES" incorrect password attempts"
            exit
        fi
    done
    
    # setting up trap to ensure the SUDOPASSWORD is unset if the script is terminated while it is set
    #trap 'unset SUDOPASSWORD' EXIT
    # set the trap after usage of the function in the respective script
 
    # replacing sudo command with a function, so all sudo commands of the script do not have to be changed
    sudo() {
        env_use_password | builtin command sudo -p '' -k -S "$@"
        #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
        #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
    }
}


### using sudo password
# replacing sudo command with a function, so all sudo commands of the script do not have to be changed
env_sudo() {
    sudo () {
        env_use_password | builtin command sudo -p '' -k -S "$@"
        #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
        #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
    }
}

# redefining sudo so it is possible to run homebrew install without entering the password again
env_sudo_homebrew() {
    sudo() {
        env_use_password | builtin command sudo -p '' -S "$@"
    }
}

env_start_sudo() {
    if [[ "$USE_PASSWORD" != "" ]]
    then
        :
    else
        env_enter_sudo_password
    fi
    env_use_password | builtin command sudo -p '' -S -v
    #( while true; do env_use_password | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    #
    #while true; do env_use_password | builtin command sudo -p '' -S -v; sleep 60; done &
    ( while true; do sleep 60; sudo -n true; kill -0 "$$" || exit; done 2>/dev/null ) &
    SUDO_PID="$!"
    #echo "SUDO PID is $SUDO_PID..." 
}

env_stop_sudo() {
    #echo "stopping sudo..."
    if [[ "$SUDO_PID" == "" ]]
    then
        :
    else
        if ps -p "$SUDO_PID" > /dev/null
        then
            sudo kill -9 "$SUDO_PID" &> /dev/null
            wait "$SUDO_PID" 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
    if [[ "$SCRIPT_IS_SESSION_MASTER_AND_NOT_SOURCED" == "yes" ]]
    then
        unset SUDOPASSWORD
        unset USE_PASSWORD
        if typeset -f sudo > /dev/null
    	then
      		unset -f sudo
    	fi
    else
        :
    fi
}


### homebrew
# including homebrew commands in PATH
if [[ $(uname -m | grep arm) != "" ]]
then
	# arm mac
	PATH_TO_SET='/opt/homebrew/bin:/opt/homebrew/sbin:$PATH'
else
	# intel mac
	PATH_TO_SET='/usr/local/bin:/usr/local/sbin:/usr/local/opt/openssl@1.1/bin:$PATH'
fi

env_set_default_paths() { 
    echo "setting default paths in /etc/paths/..."   
    sudo sh -c "cat > /etc/paths << 'EOF'
/usr/bin
/bin
/usr/sbin
/sbin
EOF
"
}

env_add_path_to_shell() {
    echo "# homebrew PATH" >> "$SHELL_CONFIG"
    echo 'export PATH="'"$PATH_TO_SET"'"' >> "$SHELL_CONFIG"
    if [[ "$SET_HOMEBREW_GITHUB_API_TOKEN" == "yes" ]]
    then
        echo 'export HOMEBREW_GITHUB_API_TOKEN=$(security find-generic-password -s "GitHub - https://api.github.com" -w) >/dev/null 2>&1' >> "$SHELL_CONFIG"
    else
        :
    fi
}

env_set_path_for_shell() {
	if command -v "$SHELL_TO_CHECK" &> /dev/null
	then
    	# installed
	    echo "setting path for $SHELL_TO_CHECK..."
        if [[ ! -e "$SHELL_CONFIG" ]]
        then
            touch "$SHELL_CONFIG"
            chown $(id -u "$USER"):staff "$SHELL_CONFIG"
            chmod 600 "$SHELL_CONFIG"
            env_add_path_to_shell
        elif [[ $(cat "$SHELL_CONFIG" | grep "^export PATH=") != "" ]]
        then
            sed -i '' 's|^export PATH=.*|export PATH="'"$PATH_TO_SET"'"|' "$SHELL_CONFIG"
        else
            echo '' >> "$SHELL_CONFIG"
            env_add_path_to_shell
        fi
        # sourcing changes for currently used shell
        if [[ $(echo "$SHELL") == "$SHELL_TO_CHECK" ]]
        then
        	source "$SHELL_CONFIG"
        else
            :
        fi
	else
		# not installed
		echo "$SHELL_TO_CHECK is not installed, skipping to set path..."
	fi
}
	
env_get_current_command_line_tools_version() {
    CURRENT_COMMANDLINETOOLVERSION=""
    # https://github.com/Homebrew/install/blob/master/install.sh
    CURRENT_COMMANDLINETOOLVERSION=$(softwareupdate --list 2>&1 | grep -B 1 -E 'Command Line Tools' | awk -F'*' '/^ *\\*/ {print $2}' | sed -e 's/^ *Label: //' -e 's/^ *//' | sort -V | tail -n 1)
    #CURRENT_COMMANDLINETOOLVERSION=$(softwareupdate --list 2>&1 | grep -B 1 -E 'Command Line Tools' | awk -F'*' '{print $2}' | sed -e 's/^ *Label: //' -e 's/^ *//' | sort -V | tail -n 1)
}

env_check_for_software_updates_gui() {

    open /System/Library/PreferencePanes/SoftwareUpdate.prefPane
    sleep 30
    
    osascript <<EOF
        tell application "System Settings" to quit
EOF
}

env_check_if_command_line_tools_are_installed() {
    #if type xcode-select >&- && xpath=$( xcode-select --print-path ) && test -d "${xpath}" && test -x "${xpath}"
    if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -n "$(ls -A "$(xcode-select -print-path)")" ]]
    then
      	COMMAND_LINE_TOOLS_INSTALLED="yes"
    else
        COMMAND_LINE_TOOLS_INSTALLED="no"
    fi

}

env_command_line_tools_install_shell() {
    # installing command line tools (command line)
    env_check_if_command_line_tools_are_installed
    if [[ "$COMMAND_LINE_TOOLS_INSTALLED" == "yes" ]]
    then
      	echo "command line tools are installed..."
    else
    	echo "command line tools are not installed, installing..."
    	# prompting the softwareupdate utility to list the command line tools
        touch "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
        sleep 3
        softwareupdate --list >/dev/null 2>&1
        env_get_current_command_line_tools_version  
    	echo "installing "$CURRENT_COMMANDLINETOOLVERSION"..."
        softwareupdate -i --verbose "$(echo "$CURRENT_COMMANDLINETOOLVERSION")"
        
        # removing tmp file that forces command line tools to show up
        if [[ -e "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress" ]]
        then
            sudo rm -f "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
            # closing software update notification
            echo ''
            # does not work on fresh batch install
            #echo "closing software update notification..."
            #sleep 1
            #softwareupdate --list >/dev/null 2>&1
            #sleep 1
            #killall SoftwareUpdateNotificationManager
            # works
            env_check_for_software_updates_gui &
            WAITING_TIME=32
            NUM1=0
            echo ''
            while [[ "$NUM1" -le "$WAITING_TIME" ]]
            do 
            	NUM1=$((NUM1+1))
            	if [[ "$NUM1" -le "$WAITING_TIME" ]]
            	then
            		#echo "$NUM1"
            		sleep 1
            		tput cuu 1 && tput el
            		echo "waiting $((WAITING_TIME-NUM1)) seconds for closing software update notification..."
            	else
            		:
            	fi
            done
        else
            :
        fi
        
        # choosing command line tools as default
        sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi
    
    # installing rosetta on arm macs
    if [[ $(uname -m | grep arm) != "" ]]
    then
        # arm mac
        if pgrep oahd >/dev/null 2>&1
        then 
            # installed
            :
        else
            # not installed
            echo ''
            echo "installing rosetta..."
            #sudo rm -rf /Library/Apple/usr/share/rosetta
            #sudo rm -rf /Library/Apple/usr/libexec/oah
            softwareupdate --install-rosetta --agree-to-license
            echo ''
        fi
    else
        # intel mac
        :
    fi
}

env_homebrew_update() {
    if [[ "$UPDATE_HOMEBREW" == "no" ]]
    then
        :
    else
        echo ''
        echo "updating homebrew..."
        # brew prune deprecated as of 2019-01, using brew cleanup at the end of the script instead
        # brew update-reset 1>/dev/null 2> >(grep -v "Reset branch" 1>&2) only works in bash, not posx compliant
        # functions to grep from stderr posix compliant 
        brew_update_reset() {
            brew update-reset 1>/dev/null
        }
        brew_cleanup() {
            brew cleanup 1>/dev/null
        }
        { brew_update_reset 2>&1 1>&3 | grep -v "Reset branch" 1>&2; } 3>&1 && brew analytics on 1>/dev/null && brew update 1>/dev/null && brew doctor 1>/dev/null && { brew_cleanup 2>&1 1>&3 | grep -v "Skipping" 1>&2; } 3>&1
    
        echo 'updating homebrew finished ;)'
    fi
}

env_cleanup_all_homebrew() {
    
    # making sure brew cache exists
    HOMEBREW_CACHE_DIR=$(brew --cache)
    mkdir -p "$HOMEBREW_CACHE_DIR"
    chown "$USER":staff "$HOMEBREW_CACHE_DIR"/
    chmod 755 "$HOMEBREW_CACHE_DIR"/
    
    #brew cleanup 1> /dev/null
    # also seems to clear hidden files and folders
    brew cleanup --prune=0 1> /dev/null
    
    if [[ "$HOMEBREW_CACHE_DIR" != "" ]] && [[ -e "$HOMEBREW_CACHE_DIR" ]]
    then
        find "$HOMEBREW_CACHE_DIR" -mindepth 1 -print0 | xargs -0 rm -rf
    else
        :
    fi
    
    # brew cleanup has to be run after the rm -rf "$HOMEBREW_CACHE_DIR"/{,.[!.],..?}* again
    # if not it will delete a file /Users/$USER/Library/Caches/Homebrew/.cleaned
    # this file is produced by brew cleanup and is checked if brew cleanup was run in the last x days
    # without the file brew thinks brew cleanup was not run and complains about it
    # https://github.com/Homebrew/brew/issues/5644
    brew cleanup 1> /dev/null

}

### check if parallel is installed
env_check_if_parallel_is_installed() {
    if command -v parallel &> /dev/null
    then
        # installed
        INSTALLATION_METHOD="parallel"
    else
        # not installed
        INSTALLATION_METHOD="sequential"
    fi
    #echo ''
    echo "INSTALLATION_METHOD is "$INSTALLATION_METHOD""...
    echo ''
}


### traps
# http://zsh.sourceforge.net/Doc/Release/Functions.html
# in zsh a trap on EXIT set inside a function is executed after the function completes in the environment of the caller
# that`s why the trap has to be in a variable, NOT in a function
# use with
#trap_function_exit_middle() { COMMAND1; COMMAND2; }
#"${ENV_SET_TRAP_SIG[@]}"
#"${ENV_SET_TRAP_EXIT[@]}"

env_trap_function_exit() {
    #echo "exit trap part 1..."
	if typeset -f trap_function_exit_start > /dev/null
	then
  		trap_function_exit_start
	fi
	#echo "exit trap part 2..."
	if typeset -f trap_function_exit_middle > /dev/null
	then
  		trap_function_exit_middle
	fi
	#echo "exit trap part 3..."
	#echo ''
	if typeset -f trap_function_exit_end > /dev/null
	then
  		trap_function_exit_end
	fi
}

trap_function_exit_end() {
    # nohup doesn`t work
    # when nohup is used subprocesses do not get killed
    
    # testing
    #sleep 40 & sleep 50 & sleep 60 & sleep 70 &

    # disown works and helps suppress the output
    #env_kill_subprocesses & disown
    #eval_function env_kill_subprocesses
    env_kill_subprocesses
    #eval "$(typeset -f env_kill_subprocesses)" && env_kill_subprocesses
    #printf '\n'
}

### renaming
env_rename_files_and_directories() {

    # documentation
    # do not use xargs, every run has to be done file by file and directory by directory or it will not work as expected
    
    # checking dependencies
    for i in brew rename
    do
    	if command -v "$i" &> /dev/null
    	then
    		# installed
    		:
    	else
    		echo ''
    		echo ""$i" is not installed, exiting..."
    		echo ''
    		exit
    	fi
    done

    # stop on error (e.g. if script_dir is renamed)
    set -e
    set -o pipefail
    
    if [[ "$RENAME_DIRECTORIES" == "" ]]
    then
        echo ''
        echo "RENAME_DIRECTORIES is empty, skipping..."
        echo ''
    else
    
        for RENAME_DIR in "${RENAME_DIRECTORIES[@]}"; do
        
            echo ''
            echo "renaming in ""$RENAME_DIR..."
            echo ''
        
            if [[ -d "$RENAME_DIR" ]]
            then
                
                # ä, Ä, ö, Ö, ü, Ü, ß first
                # https://www.utf8-zeichentabelle.de/unicode-utf8-table.pl?start=64&number=1024&names=-&utf8=string-literal
                find "$RENAME_DIR" -print0 | xargs -0 rename --force 's/ä/ae/g;s/ö/oe/g;s/ü/ue/g;s/Ä/Ae/g;s/Ö/Oe/g;s/Ü/Ue/g;s/ß/ss/g;s/\x61\xcc\x88/ae/g;s/\x6f\xcc\x88/oe/g;s/\x75\xcc\x88/ue/g;s/\x41\xcc\x88/AE/g;s/\x4f\xcc\x88/OE/g;s/\x55\xcc\x88/UE/g;'
                
                # sanitizing (problematic if whitespace in path to file or folder)
                find "$RENAME_DIR" -print0 | xargs -0 rename --sanitize --keep-extension
                #find "$RENAME_DIR" -print0 | xargs -0 rename --noctrl --nometa --trim --keep-extension
                
                for RENAME_VAR_REGEX in , ' ' '<' '>' » « '(' ')' '\[' '\]' + % @ ® ø · • › … – — ’ ‘ “ ” é ï Ì € Ë â Â ¬ ° ¹ º š Œ ¶ ¼ Æ ƒ ˆ † '\=' '\!' '\|' '\#' '\\~' '\"' '\?' '\¸' '\' '\&' '\§' '\$' '\%' ' ' '\\' ''\''' __
                do
                    NUM1=0
                    #
                    if [[ "$RENAME_VAR_REGEX" == '\\' ]]
                    then
                        RENAME_VAR="$RENAME_VAR_REGEX"
                        RENAME_VAR=\'"$RENAME_VAR"\'
                    elif [[ "$RENAME_VAR_REGEX" == ''\''' ]]
                    then
                        RENAME_VAR="$RENAME_VAR_REGEX"
                        RENAME_VAR=\'\'\\"$RENAME_VAR"\'\'
                    else
                        RENAME_VAR=$(echo "$RENAME_VAR_REGEX" | sed s/\\\\//)
                        RENAME_VAR=\'"$RENAME_VAR"\'
                    fi
                    RENAME_VAR=$(eval echo "$RENAME_VAR")
                    #
                    while [[ $(find "$RENAME_DIR" -regex ".*$RENAME_VAR_REGEX.*") != "" ]]
                    do
                        NUM1=$((NUM1+1))
                        find "$RENAME_DIR" -print0 | xargs -0 rename --subst-all "$RENAME_VAR" '_'
                    done
                    if [[ "$NUM1" == 0 ]]
                    then
                        :
                    else
                        echo "finished renaming $RENAME_VAR with $NUM1 run(s) ;)"
                    fi                
                done
                
                for RENAME_VAR_REGEX in '\.\.\.' '\_\.' '\.\.'
                do
                    NUM1=0
                    #
                    RENAME_VAR=$(echo "$RENAME_VAR_REGEX" | sed s/\\\\//g)
                    RENAME_VAR=\'"$RENAME_VAR"\'
                    RENAME_VAR=$(eval echo "$RENAME_VAR")
                    #
                    while [[ $(find "$RENAME_DIR" -regex ".*$RENAME_VAR_REGEX.*") != "" ]]
                    do
                        NUM1=$((NUM1+1))
                        find "$RENAME_DIR" -print0 | xargs -0 rename --subst-all "$RENAME_VAR" '.'
                    done
                    if [[ "$NUM1" == 0 ]]
                    then
                        :
                    else
                        echo "finished renaming $RENAME_VAR with $NUM1 run(s) ;)"
                    fi
                done
        
            else
                echo "RENAME_DIR "$RENAME_DIR" does not exist, skipping..."
            fi
        done
    fi
}


### batch script fifo
env_delete_tmp_batch_script_fifo() {
    if [[ -e "/tmp/tmp_batch_script_fifo" ]]
    then
        rm -f "/tmp/tmp_batch_script_fifo"
    else
        :
    fi
}

env_delete_tmp_batch_script_gpg_fifo() {
    if [[ -e "/tmp/tmp_batch_script_gpg_fifo" ]]
    then
        rm -f "/tmp/tmp_batch_script_gpg_fifo"
    else
        :
    fi
}


env_delete_tmp_sudo_mas_script_fifo() {
    if [[ -e "/tmp/tmp_sudo_mas_script_fifo" ]]
    then
        rm -f "/tmp/tmp_sudo_mas_script_fifo"
    else
        :
    fi
}

env_delete_tmp_appstore_mas_script_fifo() {
    if [[ -e "/tmp/tmp_appstore_mas_script_fifo" ]]
    then
        rm -f "/tmp/tmp_appstore_mas_script_fifo"
    else
        :
    fi
}

env_delete_tmp_casks_script_fifo() {
    if [[ -e "/tmp/tmp_sudo_cask_script_fifo" ]]
    then
        rm -f "/tmp/tmp_sudo_cask_script_fifo"
    else
        :
    fi
}

env_delete_tmp_mas_script_fifo() {
    env_delete_tmp_sudo_mas_script_fifo
    env_delete_tmp_appstore_mas_script_fifo
}

env_create_tmp_batch_script_fifo() {
    env_delete_tmp_batch_script_fifo
    mkfifo -m 600 "/tmp/tmp_batch_script_fifo"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_batch_script_fifo" &
    #echo "$SUDOPASSWORD" > "/tmp/tmp_sudo_cask_script_fifo" &
}

env_create_tmp_batch_script_gpg_fifo() {
    env_delete_tmp_batch_script_gpg_fifo
    mkfifo -m 600 "/tmp/tmp_batch_script_gpg_fifo"
    builtin printf "$GPG_PASSWORD\n" > "/tmp/tmp_batch_script_gpg_fifo" &
    #echo "$GPG_PASSWORD" > "/tmp/tmp_sudo_cask_script_fifo" &
}

env_create_tmp_mas_script_fifo() {
    env_delete_tmp_mas_script_fifo
    mkfifo -m 600 "/tmp/tmp_sudo_mas_script_fifo"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_sudo_mas_script_fifo" &
    #echo "$SUDOPASSWORD" > "/tmp/tmp_sudo_mas_script_fifo" &
    mkfifo -m 600 "/tmp/tmp_appstore_mas_script_fifo"
    builtin printf "$MAS_APPSTORE_PASSWORD\n" > "/tmp/tmp_appstore_mas_script_fifo" &
    #echo "$MAS_APPSTORE_PASSWORD" > "/tmp/tmp_appstore_mas_script_fifo" &
}

env_create_tmp_casks_script_fifo() {
    env_delete_tmp_casks_script_fifo
    mkfifo -m 600 "/tmp/tmp_sudo_cask_script_fifo"
    builtin printf "$SUDOPASSWORD\n" > "/tmp/tmp_sudo_cask_script_fifo" &
    #echo "$SUDOPASSWORD" > "/tmp/tmp_sudo_cask_script_fifo" &
}


### permissions for opening on first run
env_set_open_on_first_run_permissions() {
    env_get_path_to_app
    echo "$APP_NAME"
    echo "$PATH_TO_APP"
    #echo "PATH_TO_APP is "$PATH_TO_APP""
    APP_NAME_EXTENSION=$([[ "$APP_NAME" = *.* ]] && echo "${APP_NAME##*.}" || echo '')
    if [[ "$APP_NAME_EXTENSION" == "jar" ]]
    then
        :
    else
        if [[ "$PATH_TO_APP" != "" ]]
        then
            if [[ $(xattr -l "$PATH_TO_APP" | grep com.apple.quarantine) != "" ]]
            then
                xattr -d com.apple.quarantine "$PATH_TO_APP" &> /dev/null
                /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -R -f -trusted "$PATH_TO_APP"
            else
                :
            fi
        else
            :
        fi
    fi
}

env_set_permissions_autostart_apps() {
    if [[ "$INSTALLATION_METHOD" == "parallel" ]]
	then
		# if parallels is used $line needs to be redefined
		APP_NAME="$1"
    else
	    APP_NAME="$autostartapp"
    fi
    echo "$APP_NAME"
    env_set_open_on_first_run_permissions
    if [[ "$APP_NAME" == "run_on_login_whatsapp" ]]
    then
        APP_NAME="WhatsApp"
        env_set_open_on_first_run_permissions
    elif [[ "$APP_NAME" == "run_on_login_signal" ]]
    then
        APP_NAME="Signal"
        env_set_open_on_first_run_permissions
    else
        :
    fi
}

env_set_permissions_autostart_apps_sequential() {
    while IFS= read -r line || [[ -n "$line" ]]        
	do
	    if [[ "$line" == "" ]]; then continue; fi
        autostartapp="$line"
        env_set_permissions_autostart_apps "$autostartapp"
    done <<< "$(printf "%s\n" "${AUTOSTART_PERMISSIONS_ITEMS[@]}")"
}


### remove quarantine attribute
env_remove_quarantine_attribute() {
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
	done <<< "$(find "$DIRECTORY_TO_SEARCH_FOR_QUARANTINE" -mindepth 1 ! -path "*/*.app/*" -name "*.command")"
	
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
	done <<< "$(find "$DIRECTORY_TO_SEARCH_FOR_QUARANTINE" -mindepth 1 ! -path "*/*.app/*" -name "*.sh")"
}


### caffeinate
env_deactivating_caffeinate() {
    if [[ -e "$PATH_TO_APPS"/KeepingYouAwake.app ]]
    then
        echo ''
        echo "deactivating keepingyouawake..."
        echo ''
        # also works
        #pkill -15 caffeinate
        open -g keepingyouawake:///deactivate
        sleep 1
    else
        echo ''
        echo "deactivating caffeinate..."
        echo ''
        pkill -15 caffeinate
    fi
}

env_activating_caffeinate() {
    if [[ $(ps aux | grep -ie "caffeinate" | grep -v grep) == "" ]]
    then
        if [[ -e "$PATH_TO_APPS"/KeepingYouAwake.app ]]
        then
            echo ''
        	echo "activating keepingyouawake..."
            APP_NAME="KeepingYouAwake"
            env_set_open_on_first_run_permissions
            open -g keepingyouawake:///activate
            sleep 1
            echo ''
        else
            echo ''
            echo "activating caffeinate..."
            caffeinate -d -i &
            echo ''
        fi
    else
        echo ''
        echo "caffeinate or keepingyouawake already active..."
        echo ''
    fi
}


### checking if run from batch script and error logs
env_check_if_run_from_batch_script() {
    # using ps aux here sometime causes the script to hang when started from a launchd
    # if ps aux is necessary here use
    # timeout 3 env_check_if_run_from_batch_script
    # to run this function
    #BATCH_PIDS=()
    #BATCH_PIDS+=$(ps aux | grep "/batch_script_part.*.command" | grep -v grep | awk '{print $2;}')
    #if [[ "$BATCH_PIDS" != "" ]] && [[ -e "/tmp/batch_script_in_progress" ]]
    if [[ -e "/tmp/batch_script_in_progress" ]]
    then
        RUN_FROM_BATCH_SCRIPT="yes"
    else
        :
    fi
}

env_start_error_log() {
    ERROR_LOG_DIR=/Users/"$USER"/Desktop/batch_error_logs
    if [[ ! -e "$ERROR_LOG_DIR" ]]
    then
        ERROR_LOG_NUM=1
    else
        ERROR_LOG_NUM=$(($(ls -1 "$ERROR_LOG_DIR" | awk -F'_' '{print $1}' | sort -n | tail -1)+1))
    fi
    mkdir -p "$ERROR_LOG_DIR"
    if [[ "$ERROR_LOG_NUM" -le "9" ]]; then ERROR_LOG_NUM="0"$ERROR_LOG_NUM""; else :; fi
    ERROR_LOG="$ERROR_LOG_DIR"/"$ERROR_LOG_NUM"_"$SCRIPT_NAME_WITHOUT_EXTENSION"_errorlog.txt
    echo "### "$SCRIPT_NAME"" >> "$ERROR_LOG"
    #echo "### $(date "+%Y-%m-%d %H:%M:%S")" >> "$ERROR_LOG"
    echo '' >> "$ERROR_LOG"
    # compatible with bash and zsh
    # if running (not sourcing) this file without shebang it will complain about an unexpected token >
    # this is expected and ok, only source this file, do not run it
    exec 2> >(tee -ia "$ERROR_LOG" >&2)
}

env_stop_error_log() {
    exec 2<&-
    exec 2>&1
}

### in addition to showing them in terminal write errors to logfile when run from batch script
env_force_start_error() {
    touch "/tmp/batch_script_in_progress"
    env_check_if_run_from_batch_script
    if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_start_error_log; else :; fi
}


### user profiles
env_check_for_user_profile() {
    if [[ "$SCRIPTS_DIR_USER_PROFILES" == "" ]]
    then
        echo ''
        echo "variable SCRIPTS_DIR_USER_PROFILES is empty, skipping user profile detection..."
        #echo ''
    else
        if [[ -e "$SCRIPTS_DIR_USER_PROFILES"/scripts_profile_"$loggedInUser".conf ]]
        then
            echo ''
            echo "scripts profile found for $loggedInUser..."
            SCRIPTS_USER_PROFILE="$SCRIPTS_DIR_USER_PROFILES"/scripts_profile_"$loggedInUser".conf
            . "$SCRIPTS_USER_PROFILE"
            #echo ''
        else
            echo ''
            echo "no scripts profile found for "$loggedInUser"..."
            #echo ''
        fi
    fi
}

### check if run from boot volume
env_check_if_second_macos_volume_is_mounted() {

    env_get_mounted_disks 
    if [[ "$MACOS_CURRENTLY_BOOTED_VOLUME" == "macintosh_hd2" ]] && [[ $(printf "%s\n" "${LIST_OF_ALL_MOUNTED_VOLUMES_OUTSIDE_OF_BOOT_VOLUME[@]}" | grep -x "/Volumes/macintosh_hd") != "" ]]
    then
        #if [[ -e "/Volumes/macintosh_hd" ]]; then sudo diskutil unmount /Volumes/macintosh_hd; fi
        #if [[ -e "/Volumes/macintosh_hd - Daten" ]]; then sudo diskutil unmount "/Volumes/macintosh_hd - Daten"; fi
        if [[ -e "/Volumes/macintosh_hd" ]]; then sudo umount -f /Volumes/macintosh_hd; fi
        if [[ -e "/Volumes/macintosh_hd - Daten" ]]; then sudo umount -f "/Volumes/macintosh_hd - Daten"; fi
        sleep 5
        env_get_mounted_disks
        if [[ $(printf "%s\n" "${LIST_OF_ALL_MOUNTED_VOLUMES_OUTSIDE_OF_BOOT_VOLUME[@]}" | grep -x "/Volumes/macintosh_hd") != "" ]]
        then
            # second macos volume is mounted
            output_mas_hint() {
                echo ''
                echo "${bold_text}${red_text}important info${default_text}"
                echo "at least one more macos volume is mounted, due to this bug"
                echo "https://github.com/mas-cli/mas/issues/250"
                echo "mas will install appstore apps to first macos partition found, not necessarily to the mounted one..."
                echo "as a workaround follow these steps:"
                echo "1   make sure the scripts are stored on the currently booted macos volume,"
                echo "    if not copy them"
                echo "2   unmount all other macos volumes"
                echo "3   run the script again"
                echo "exiting..."
                echo ''
                exit
            }
            output_mas_hint >&2
        else
            # second macos volume is not mounted
            :
        fi
    else
        :
    fi
}


### services

env_stopping_services() {
	echo ''
	echo "stopping services..."
	
	if [[ "$STOP_CALENDAR_REMINDER_SERVICES" == "yes" ]]
	then
		echo "services calendar & reminders..."
		#osascript -e 'tell application "System Events" to log out'
		#killall Calendar &> /dev/null
		#killall dataaccess.dataaccessd
		#killall remindd
		#killall calaccessd
		# launchctl list
		# already done at the beginnning of the script
		# bootout works, but prints "Boot-out failed: 36: Operation now in progress"
		# if kill is used to stop the service kickstart is needed to restart it, bootstrap will not work
		launchctl bootout gui/"$(id -u "$USER")"/com.apple.dataaccess.dataaccessd 2>&1 | grep -v "in progress" | grep -v "No such process"
		launchctl bootout gui/"$(id -u "$USER")"/com.apple.remindd 2>&1 | grep -v "in progress" | grep -v "No such process"
		launchctl bootout gui/"$(id -u "$USER")"/com.apple.calaccessd 2>&1 | grep -v "in progress" | grep -v "No such process"
		#launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.dataaccess.dataaccessd
		#launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.remindd
		#launchctl kill 15 gui/"$(id -u "$USER")"/com.apple.CalendarAgent
	else
		:
	fi
	
	if [[ "$STOP_ACCOUNTSD" == "yes" ]]
	then
		echo "services accountsd..."
		launchctl bootout gui/"$(id -u "$USER")"/com.apple.accountsd 2>&1 | grep -v "in progress" | grep -v "No such process"
	else
		:
	fi
	
	if [[ "$STOP_CUPSD" == "yes" ]]
	then
		echo "services cupsd..."		
		sudo launchctl bootout system/org.cups.cupsd 2>&1 | grep -v "in progress" | grep -v "No such process"
	else
		:
	fi
	
	sleep 5
}

env_starting_services() {
	echo ''
	echo "starting services..."
	
	if [[ "$START_CALENDAR_REMINDER_SERVICES" == "yes" ]]
	then
		echo "services calendar & reminders..."
		# if kill was used to stop the service kickstart is needed to restart it, bootstrap will not work
		# dataaccessd is needed to be restared for calendar to reconize the internet accounts and re-download the data
		launchctl bootstrap gui/"$(id -u "$USER")" /System/Library/LaunchAgents/com.apple.dataaccess.dataaccessd.plist
		launchctl bootstrap gui/"$(id -u "$USER")" /System/Library/LaunchAgents/com.apple.remindd.plist
		launchctl bootstrap gui/"$(id -u "$USER")" /System/Library/LaunchAgents/com.apple.calaccessd.plist
		#launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.dataaccess.dataaccessd
		#launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.remindd
		launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.calaccessd
	else
		:
	fi

	if [[ "$START_ACCOUNTSD" == "yes" ]]
	then
		echo "services accountsd..."		
		launchctl bootstrap gui/"$(id -u "$USER")" /System/Library/LaunchAgents/com.apple.accountsd.plist
		#launchctl kickstart -k gui/"$(id -u "$USER")"/com.apple.accountsd
	else
		:
	fi

	if [[ "$START_CUPSD" == "yes" ]]
	then
		echo "services cupsd..."		
		sudo launchctl bootstrap system /System/Library/LaunchDaemons/org.cups.cupsd.plist
	else
		:
	fi
	
	sleep 5
}


### calendar - deprectaed for macos 13 and higher
env_collapsing_elements_in_calendar_sidebar() {
    # collapsing (specified) elements in the sidebar
    # delegates
    INFO_PLISTS=$(find "$PATH_TO_CALENDARS" -name "Info.plist" -mindepth 2 -maxdepth 2)
	# leaving DELEGATES_TO_COLLAPSE empty folds all delegates
	DELEGATES_TO_COLLAPSE=(
	""
	)
	while IFS= read -r line || [[ -n "$line" ]]
	do
    	if [[ "$line" == "" ]]; then continue; fi
    	i="$line"
		#echo $i
		if [[ $(/usr/libexec/PlistBuddy -c 'Print Delegate' "$i" 2> /dev/null) == "true" ]]
		then
			#echo "yes"
			DELEGATE_IN_PLIST=$(/usr/libexec/PlistBuddy -c 'Print Title' "$i")
			DELEGATE_KEY=$(/usr/libexec/PlistBuddy -c 'Print Key' "$i")
            add_entry_to_collapsed_elements() {
                #echo "adding "$DELEGATE_IN_PLIST" do collapsed elements ..."
                /usr/libexec/PlistBuddy -c "Add :CollapsedTopLevelNodes dict" "$CALENDAR_PREFERENCES_PLIST" 2>&1 | grep -v "Entry Already Exists$"
			    /usr/libexec/PlistBuddy -c "Add :CollapsedTopLevelNodes:MainWindow array" "$CALENDAR_PREFERENCES_PLIST" 2>&1 | grep -v "Entry Already Exists$"
			    /usr/libexec/PlistBuddy -c "Add :CollapsedTopLevelNodes:MainWindow:0 string "$DELEGATE_KEY"" "$CALENDAR_PREFERENCES_PLIST" 2>&1 | grep -v "Entry Already Exists$"   
            }
			if [[ "$DELEGATES_TO_COLLAPSE" == "" ]]
			then
				# collapse entry
				add_entry_to_collapsed_elements
			else
				# collapse only specified delegates
				while IFS= read -r line || [[ -n "$line" ]]
				do
    				if [[ "$line" == "" ]]; then continue; fi
    				DELEGATE="$line"
					#echo $i	
					if [[ $(/usr/libexec/PlistBuddy -c 'Print Title' "$i" 2> /dev/null) == "$DELEGATE" ]]
					then
						# collapse entry
				        add_entry_to_collapsed_elements
					else
					    :
						#echo "leaving delegate "$DELEGATE_IN_PLIST" uncollapsed..."
					fi
				done <<< "$(printf "%s\n" "${DELEGATES_TO_COLLAPSE[@]}")"
			fi
		else
			#echo "no"
		fi
	done <<< "$(printf "%s\n" "${INFO_PLISTS[@]}")"
	sleep 2
}


### set custom icon
env_set_custom_icon() {
    # http://apple.stackexchange.com/questions/6901/how-can-i-change-a-file-or-folder-icon-using-the-terminal
    
    # check if a needed variable is empty
    if [[ "$PATH_TO_ICON" == "" ]] || [[ "$PATH_TO_OBJECT_TO_SET_ICON_FOR" == "" ]]
    then
        echo "PATH_TO_ICON or PATH_TO_OBJECT_TO_SET_ICON_FOR is empty, skipping..."
        continue
    else
        :
    fi
    
    # check if fileicon is installed, if not try to install via homebrew
    if command -v fileicon &> /dev/null
    then
        # installed
        :
    else
        # not installed
    	if command -v brew &> /dev/null
		then
		    # installed
			echo "installing missing dependency fileicon..."
			brew install fileicon
		else
			# not installed
            :
		fi
    fi
    
    # set icon via fileicon or python
    if command -v fileicon &> /dev/null
    then
        # installed
        echo "using fileicon to set custom icon..."
        fileicon -q set "$PATH_TO_OBJECT_TO_SET_ICON_FOR" "$PATH_TO_ICON"
    else
        # not installed
        echo "using python to set custom icon..."
        pip3 install pyobjc-framework-Cocoa | grep -v "already satisfied"
        python3 -c 'import Cocoa; import sys; Cocoa.NSWorkspace.sharedWorkspace().setIcon_forFile_options_(Cocoa.NSImage.alloc().initWithContentsOfFile_(sys.argv[1]), sys.argv[2], 0) or sys.exit("Unable to set file icon")' "$PATH_TO_ICON" "$PATH_TO_OBJECT_TO_SET_ICON_FOR"
    fi
    for i in applet droplet AutomatorApplet
	do
		if [[ -e "$PATH_TO_OBJECT_TO_SET_ICON_FOR"/Contents/Resources/"$i".icns ]]
		then 
		    cp -a "$PATH_TO_ICON" "$PATH_TO_OBJECT_TO_SET_ICON_FOR"/Contents/Resources/"$i".icns
		else 
		    :
		fi
	done
}


### testing
if [[ "$TEST_SOURCING_AND_VARIABLES" == "yes" ]]
then
    echo "config file..."
    echo "script is sourced: $SCRIPT_IS_SOURCED"
    echo "script is session master: $SCRIPT_IS_SESSION_MASTER"
    echo "script name is $SCRIPT_NAME"
    echo "script directory is $SCRIPT_DIR"
    echo "script directory one back is $SCRIPT_DIR_ONE_BACK"
else
    :
fi