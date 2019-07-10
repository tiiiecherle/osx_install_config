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
        [[ $ZSH_EVAL_CONTEXT =~ ^toplevel:file ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        # eval alternative
        # use eval "$CHECK_IF_SOURCED" in other script to call it
        #CHECK_IF_SOURCED='[[ $ZSH_EVAL_CONTEXT =~ ':file$' ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
        #eval "$CHECK_IF_SOURCED"
        
        # traps
        # for more detailed explanation about traps see topic traps below 
        #trapSIG runs when the specific SIG is triggered
        TRAPINT() {
          #echo "Caught SIGINT, aborting."
          sleep 0.1 && printf '\n' && env_trap_function_exit
          return $(( 128 + $1 ))
        }
        
        TRAPHUP() {
          #echo "Caught SIGHUP, aborting."
          sleep 0.1 && printf '\n' && env_trap_function_exit
          return $(( 128 + $1 ))
        }
        
        TRAPTERM() {
          #echo "Caught SIGTERM, aborting."
          sleep 0.1 && printf '\n' && env_trap_function_exit
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
        ENV_SET_TRAP_EXIT=(trap "exit_code=\$?; trap - EXIT; sleep 0.1 && env_trap_function_exit" EXIT)
    fi
    
    ### script path, name and directory
    # script path
    #echo $SCRIPT_PATH
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
    # script dir four back
    SCRIPT_DIR_FOUR_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && cd .. && cd .. && cd .. && pwd)"
    #echo $SCRIPT_DIR_THREE_BACK
    # script dir five back
    SCRIPT_DIR_FIVE_BACK="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && cd .. && cd .. && cd .. && cd .. && cd .. && pwd)"
    #echo $SCRIPT_DIR_THREE_BACK
    
}
env_get_shell_specific_variables


### text output
bold_text=$(tput bold)
red_text=$(tput setaf 1)
green_text=$(tput setaf 2)
blue_text=$(tput setaf 4)
default_text=$(tput sgr0)


### checking if online
env_check_if_online_old() {
    echo ''
    echo "checking internet connection..."
    ping -c 3 google.com > /dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        ping -c 3 duckduckgo.com > /dev/null 2>&1
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
    PINGTARGET1=google.com
    PINGTARGET2=duckduckgo.com
    # check 1
    # ping -c 3 "$PINGTARGET1" > /dev/null 2>&1'
    # check 2
    # resolving dns (dig +short xxx 80 or resolveip -s xxx) even work when connection (e.g. dhcp) is established but security confirmation is required to go online, e.g. public wifis
    # during testing dig +short xxx 80 seemed more reliable to work within timeout
    # timeout 3 dig +short -4 "$PINGTARGET1" 80 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1'
    #
    echo ''
    echo "checking internet connection..."
    timeout() { perl -e '; alarm shift; exec @ARGV' "$@"; }
    if [[ $(timeout 2 2>/dev/null dig +short -4 "$PINGTARGET1" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
    then
        ONLINE_STATUS="online"
        echo "we are online..."
    else
        if [[ $(timeout 2 2>/dev/null dig +short -4 "$PINGTARGET2" 443 | grep -Eo "[0-9\.]{7,15}" | head -1 2>&1) != "" ]]
        then
            ONLINE_STATUS="online"
            echo "we are online..."
        else
            ONLINE_STATUS="offline"
            echo "not online..."
        fi
    fi
}

#check_if_online
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

#echo ''
#VARIABLE_TO_CHECK="$PHP_TESTFILES"
# single line
#QUESTION_TO_ASK="do you want to install php testfiles? (y/N) "
# multi line
#QUESTION_TO_ASK="$(echo -e 'found a backup of cask specifications in /tmp/Caskroom \ndo you wanto to restore /tmp/Caskroom/* to /usr/local/Caskroom/' '(Y/n)? ')"
#env_ask_for_variable
#PHP_TESTFILES="$VARIABLE_TO_CHECK"

#if [[ "$PHP_TESTFILES" =~ ^(yes|y)$ ]]
#then
#	"echo do it"
#else
#	echo "do NOT do it"
#fi


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
                QUESTION_TO_ASK="script config file is outdated, update to the latest version (Y/n)? "
                printf "%s" "${bold_text}${blue_text}"
                env_ask_for_variable
                printf "%s" "${default_text}"
                UPDATE_CONFIG_FILE="$VARIABLE_TO_CHECK"
                sleep 0.1
                
                if [[ "$UPDATE_CONFIG_FILE" =~ ^(yes|y)$ ]]
                then
                    # updating
                    echo "installing config file from github..."
                    echo ''
                    curl https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/"$SHELL_SCRIPTS_CONFIG_FILE".sh -o "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
                    if [[ $? -eq 0 ]]; then SUCCESSFULLY_INSTALLED="yes"; else SUCCESSFULLY_INSTALLED="no"; fi
                
                    # ownership and permissions
                    chown 501:staff "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
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


### session master
# a sourced script does not exit, it ends with return
# if used for traps subprocesses will not be killed on return, only on exit
# a script sourced by the session master also returns session master = yes
# a script that is run from another script without sourcing returns session master = no
[[ $(echo $(ps -o stat= -p $PPID)) == "S+" ]] && SCRIPT_SESSION_MASTER="no" || SCRIPT_SESSION_MASTER="yes"


### macos version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_VERSION_MAJOR=$(echo "$MACOS_VERSION" | cut -f1,2 -d'.')
env_convert_version_comparable() { echo "$@" | awk -F. '{ printf("%d%02d%02d\n", $1,$2,$3); }'; }


### logged in user and unique user id
#echo "LOGNAME is $(logname)..."
#/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }'
#stat -f%Su /dev/console
#defaults read /Library/Preferences/com.apple.loginwindow.plist lastUserName
# recommended way
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
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
    	    if [[ "$line" == "" ]]; then break; fi
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
    	    if [[ "$line" == "" ]]; then break; fi
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
    #
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
    #
    # kills subprocesses but does not kill grandchildren
    # trap - SIGTERM && pkill -P $$
    #
    # kills subprocesses without parent shell of own process
    # this even works for a script that is run from another script
    # env_kill_subprocesses_sequentially
    #
    # kills complete process tree including parent shell
    # do not use wihtout "trap - SIGTERM &&" due to trap recursion
    # kill 0
    # also do not use in subshell parantheses due to trap recursion
    # ( (kill 0 &> /dev/null) & )
    # only use like this
    #trap - SIGTERM && kill 0
    
    # checking if $$ is a process group id
    if [[ $(ps -e -o pgid,pid,command | awk -v p=$$ '$1 == p {print $2}') != "" ]]
    then
    	#echo "$$ is a pgid..."
        trap - SIGTERM && kill -- -$$                                                                                                                                         
    else
    	#echo "$$ is NOT a pgid..."
    	#if [[ $(jobs -pr) != "" ]]; then kill $(jobs -pr); fi
    	env_kill_subprocesses_sequentially
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
		echo "terminal not identified, setting automating permissions to apple terminal..."
	fi
}


### apps security permissions
env_set_apps_security_permissions() {
    
    # setting databases
    env_databases_apps_security_permissions
    
    #for APP_ENTRY in "${APPS_SECURITY_ARRAY[@]}"
    while IFS= read -r line || [[ -n "$line" ]]
	do
	    if [[ "$line" == "" ]]; then break; fi
        local APP_ENTRY="$line"
        #echo "$APP_ENTRY"
        
        # app name
        #local APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/   */:/g' | cut -d':' -f1)
        #local APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/ \{2,\}/:/g' | cut -d':' -f2)
       	#local APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | awk -F '  +' '{print $1}')
       	#local APP_NAME=$(echo "$app_entry" | sed $'s/\t/|/g' | sed 's/   */:/g' | cut -d':' -f1)
       	local APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
       	#local APP_NAME_NO_SPACES=$(echo "$APP_NAME" | sed 's/ /_/g' | sed 's/^ //g' | sed 's/ $//g')
       	#echo "APP_NAME is "$APP_NAME""
       	
       	# app path
        local NUM1=0
        local FIND_APP_PATH_TIMEOUT=2
        local PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$APP_NAME.app$" | sort -n | head -1)
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
                local PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$APP_NAME.app$" | sort -n | head -1)
        	else
        	    #printf '\n'
                echo "PATH_TO_APP is empty, skipping entry..."
        		break
        	fi
        done
        if [[ "$PATH_TO_APP" == "" ]]; then continue; fi
        #echo "PATH_TO_APP is "$PATH_TO_APP"..."

        # app id
        #local APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
        #local APP_ID=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
        #local APP_ID=$(osascript -e "id of app \"$APP_NAME\"")
        #echo "PATH_TO_APP is "$PATH_TO_APP""
        local APP_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APP/Contents/Info.plist")
        #local APP_ID=$(APP_NAME2="${APP_NAME//\'/\'}.app"; APP_NAME2=${APP_NAME2//"/\\"}; APP_NAME2=${APP_NAME2//\\/\\\\}; mdls -name kMDItemCFBundleIdentifier -raw "$(mdfind 'kMDItemContentType==com.apple.application-bundle&&kMDItemFSName=="'"$APP_NAME2"'"' | sort -n | head -n1)")
        #echo "$APP_ID"
        if [[ "$APP_ID" == "" ]]
        then
            echo "APP_ID is empty, skipping entry..."
            continue
        else
            :
        fi
        
        # app csreq
        #local APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')    
        #echo "$APP_CSREQ"
        
        # input service
        local INPUT_SERVICE=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
        #echo "$INPUT_SERVICE"
        
        # permissions allowed
        # 0 = no
        # 1 = yes
        local PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^ //g' | sed 's/ $//g')
        #echo "$PERMISSION_GRANTED"
        
        # setting permissions
        if [[ "$INPUT_SERVICE" == "kTCCServiceAccessibility" ]]
        then
            # delete entry before resetting
            sudo sqlite3 "$DATABASE_SYSTEM" "delete from access where client='$APP_ID';"
            # working, but no csreq
            sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,?,NULL,0,?);"
            # working with csreq
            #sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,$APP_CSREQ,NULL,0,?);"
        else
            # delete entry before resetting
            sqlite3 "$DATABASE_USER" "delete from access where (service='$INPUT_SERVICE' and client='$APP_ID');"
            # working, but no csreq
            sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('$INPUT_SERVICE','$APP_ID',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);"
            # working with csreq
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('"$INPUT_SERVICE"','"$APP_ID"',0,$PERMISSION_GRANTED,1,$APP_CSREQ,NULL,NULL,?,NULL,NULL,?);"
        fi
        
        # app name print
        local APP_NAME_PRINT=$(echo "$APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        
        # print line
        if [[ "$PRINT_SECURITY_PERMISSIONS_ENTRYS" == "yes" ]]
        then
            printf "%-33s %-33s %-5s\n" "$APP_NAME_PRINT" "$INPUT_SERVICE" "$PERMISSION_GRANTED"
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
            if [[ "$line" == "" ]]; then break; fi
            local APP_ENTRY="$line"
            #echo "APP_ENTRY is "$APP_ENTRY""
            
            ### source app
            # source app name
            local SOURCE_APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
            #echo "SOURCE_APP_NAME is "$SOURCE_APP_NAME""
            
            # source app path
            local NUM1=0
            local FIND_APP_PATH_TIMEOUT=2
            local PATH_TO_SOURCE_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$SOURCE_APP_NAME.app$" | sort -n | head -1)
            while [[ "$PATH_TO_SOURCE_APP" == "" ]]
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
                    local PATH_TO_SOURCE_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$SOURCE_APP_NAME.app$" | sort -n | head -1)
            	else
            	    #printf '\n'
                    echo "PATH_TO_SOURCE_APP is empty, skipping entry..."
            		break
            	fi
            done
            if [[ "$PATH_TO_SOURCE_APP" == "" ]]; then continue; fi
            #echo "PATH_TO_SOURCE_APP is "$PATH_TO_SOURCE_APP"..."
            
            # source app id
            #local SOURCE_APP_ID=$(osascript -e "id of app \"$SOURCE_APP_NAME\"")
            #local SOURCE_APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
            #echo "PATH_TO_SOURCE_APP is "$PATH_TO_SOURCE_APP""
            local SOURCE_APP_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_SOURCE_APP/Contents/Info.plist")
            #echo "$SOURCE_APP_ID"
            if [[ "$SOURCE_APP_ID" == "" ]]
            then
                echo "SOURCE_APP_ID is empty, skipping entry..."
                continue
            else
                :
            fi
            
            # source app csreq
            if [[ -e "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt ]]
            then
                local SOURCE_APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$SOURCE_APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
                #echo "$SOURCE_APP_CSREQ"
            else
                local SOURCE_APP_CSREQ='?'
            fi
            
            
            ### automated app
            # automated app name
            local AUTOMATED_APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
            #echo "$AUTOMATED_APP_NAME"
            
            # automated app path
            local NUM1=0
            local FIND_APP_PATH_TIMEOUT=2
            local PATH_TO_AUTOMATED_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$AUTOMATED_APP_NAME.app$" | sort -n | head -1)
            while [[ "$PATH_TO_AUTOMATED_APP" == "" ]]
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
                    local PATH_TO_AUTOMATED_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$AUTOMATED_APP_NAME.app$" | sort -n | head -1)
            	else
            	    #printf '\n'
                    echo "PATH_TO_AUTOMATED_APP is empty, skipping entry..."
            		break
            	fi
            done
            if [[ "$PATH_TO_AUTOMATED_APP" == "" ]]; then continue; fi
            #echo "PATH_TO_AUTOMATED_APP is "$PATH_TO_AUTOMATED_APP"..."
            
            # automated app id
            #local AUTOMATED_APP_ID=$(osascript -e "id of app \"$AUTOMATED_APP_NAME\"")
            #local AUTOMATED_APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
            local AUTOMATED_APP_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_AUTOMATED_APP/Contents/Info.plist")
            #echo "$AUTOMATED_APP_ID"
            if [[ "$AUTOMATED_APP_ID" == "" ]]
            then
                echo "AUTOMATED_APP_ID is empty, skipping entry..."
                continue
            else
                :
            fi
            #echo "$AUTOMATED_APP_ID"
            
            # automated app csreq
            if [[ -e "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt ]]
            then
                local AUTOMATED_APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$AUTOMATED_APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
                #echo "$SOURCE_APP_CSREQ"
            else
                local AUTOMATED_APP_CSREQ='?'
            fi
            #echo "$AUTOMATED_APP_CSREQ"
            
            
            ### permissions allowed
            # 0 = no
            # 1 = yes
            local PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^ //g' | sed 's/ $//g')
            #echo "$PERMISSION_GRANTED"
            
            
            ### setting permissions
            # working, but does not show in gui of system preferences, use csreq for the entry to make it work and show
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,?,NULL,0,'$AUTOMATED_APP_ID',?,NULL,?);"
            # not working, but shows correct entry in gui of system preferences, use csreq to make it work and show
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,'UNUSED',NULL,0,'$AUTOMATED_APP_ID','UNUSED',NULL,?);"
            # working and showing in gui of system preferences when using correct values in CSREQ variables
            #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,$SOURCE_APP_CSREQ,NULL,0,'$AUTOMATED_APP_ID',$AUTOMATED_APP_CSREQ,NULL,?);"
            
            # delete entry before resetting
            sqlite3 "$DATABASE_USER" "delete from access where (service='kTCCServiceAppleEvents' and client='$SOURCE_APP_ID' and indirect_object_identifier='$AUTOMATED_APP_ID');"
            # working and showing in gui of system preferences if csreq is not '?'
            sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','$SOURCE_APP_ID',0,$PERMISSION_GRANTED,1,$SOURCE_APP_CSREQ,NULL,0,'$AUTOMATED_APP_ID',$AUTOMATED_APP_CSREQ,NULL,?);"
            
            
            ### print line
            local SOURCE_APP_NAME_PRINT=$(echo "$SOURCE_APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
            local AUTOMATED_APP_NAME_PRINT=$(echo "$AUTOMATED_APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
            if [[ "$PRINT_AUTOMATING_PERMISSIONS_ENTRYS" == "yes" ]]
            then
                printf "%-33s %-33s %-5s\n" "$SOURCE_APP_NAME_PRINT" "$AUTOMATED_APP_NAME_PRINT" "$PERMISSION_GRANTED"
            else
                :
            fi
            
            # unset variables for next entry
            unset SOURCE_APP_NAME
            unset SOURCE_APP_NAME_PRINT
            unset PATH_TO_SOURCE_APP
            unset SOURCE_APP_ID
            unset SOURCE_APP_CSREQ   
            unset AUTOMATED_APP_NAME
            unset AUTOMATED_APP_NAME_PRINT
            unset PATH_TO_AUTOMATED_APP
            unset AUTOMATED_APP_ID
            unset AUTOMATED_APP_CSREQ
            unset PERMISSION_GRANTED
            unset NUM1
            unset FIND_APP_PATH_TIMEOUT  
        
        #done
        done <<< "$(printf "%s\n" "${AUTOMATION_APPS[@]}")"
    fi
}

env_remove_apps_security_permissions_stop() {
    :
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
        trap 'stty echo' EXIT
        # asking for password
        printf "Password: "
        # reading secret
        read -r "$@" SUDOPASSWORD
        # reanabling echo
        stty echo
        trap - EXIT
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
            enter_password_secret
            env_use_password | sudo -k -S echo "" > /dev/null 2>&1
            if [[ $? -eq 0 ]]
            then 
                break
            else
                echo "Sorry, try again."
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
    sudo () {
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
    ( while true; do env_use_password | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID="$!"
    #echo "SUDO PID is $SUDO_PID..." 
}

env_stop_sudo() {
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
}


### homebrew
env_get_current_command_line_tools_version() {
    CURRENT_COMMANDLINETOOLVERSION=""
    VERSION_TO_CHECK_AGAINST=10.14
    if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]    
    then
        #COMMANDLINETOOLVERSION=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools" | grep $(echo "$MACOS_VERSION_MAJOR" | cut -f1,2 -d'.' | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//'))
        CURRENT_COMMANDLINETOOLVERSION=$(softwareupdate --list 2>&1 | grep -B 1 -E 'Command Line (Developer|Tools)' | awk -F'*' '/^ +\\*/ {print $2}' | grep "$MACOS_VERSION_MAJOR" | sed 's/^ *//' | tail -n1)  
    elif [[ "$MACOS_VERSION_MAJOR" == "10.15" ]]
    then
        CURRENT_COMMANDLINETOOLVERSION=$(softwareupdate --list 2>&1 | grep -B 1 -E 'Command Line (Developer|Tools)' | grep '* Label:' | awk -F':' '{print $2}' | sed 's/^ *//' | tail -n 1)
    else
        :
    fi   
}


env_command_line_tools_install_shell() {
    # installing command line tools (command line)
    #if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ "$(ls -A "$(xcode-select -print-path)")" ]]
    if xcode-select -print-path >/dev/null 2>&1 && [[ -e "$(xcode-select -print-path)" ]] && [[ -n "$(ls -A "$(xcode-select -print-path)")" ]]
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
        else
            :
        fi
        
        # choosing command line tools as default
        sudo xcode-select --switch /Library/Developer/CommandLineTools
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
        
        # working around a --json=v1 bug until it`s fixed
        # https://github.com/Homebrew/homebrew-cask/issues/52427
        #sed -i '' '/"conflicts_with" =>/s/.to_a//g' "$(brew --repository)"/Library/Homebrew/cask/cask.rb
        #sed -i '' '/"conflicts_with" =>/s/.to_a//g' "$BREW_PATH"/Library/Homebrew/cask/cask.rb
        # fixed 2019-01-28
        # https://github.com/Homebrew/brew/pull/5597
    
        echo 'updating homebrew finished ;)'
    fi
}

env_cleanup_all_homebrew() {

    # old, no longer needed fixes
    # brew cask style >/dev/null
    # brew vendor-install ruby
    
    # making sure brew cache exists
    HOMEBREW_CACHE_DIR=$(brew --cache)
    mkdir -p "$HOMEBREW_CACHE_DIR"
    chown "$USER":staff "$HOMEBREW_CACHE_DIR"/
    chmod 755 "$HOMEBREW_CACHE_DIR"/
    
    #brew cleanup 1> /dev/null
    # also seems to clear cleans hidden files and folders
    brew cleanup --prune=0 1> /dev/null
    
    if [[ "$HOMEBREW_CACHE_DIR" != "" ]] && [[ -e "$HOMEBREW_CACHE_DIR" ]]
    then
        find "$HOMEBREW_CACHE_DIR" -mindepth 1 -print0 | xargs -0 rm -rf
    else
        :
    fi
    # brew cask cleanup is deprecated from 2018-09
    #brew cask cleanup
    #brew cask cleanup 1> /dev/null
    
    # brew cleanup has to be run after the rm -rf "$HOMEBREW_CACHE_DIR"/{,.[!.],..?}* again
    # if not it will delete a file /Users/$USER/Library/Caches/Homebrew/.cleaned
    # this file is produced by brew cleanup and is checked if brew cleanup was run in the last x days
    # without the file brew thinks brew cleanup was not run and complains about it
    # https://github.com/Homebrew/brew/issues/5644
    brew cleanup 1> /dev/null
    
    # fixing red dots before confirming commit to cask-repair that prevent the commit from being made
    # https://github.com/vitorgalvao/tiny-scripts/issues/88
    #sudo gem uninstall -ax rubocop rubocop-cask 1> /dev/null
    #brew cask style 1> /dev/null
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
    env_kill_subprocesses & disown
    #nohup env_kill_subprocesses 2>&1 >/dev/null
    #eval_function env_kill_subprocesses
    #env_kill_subprocesses
    #eval_function env_kill_main_process
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
        
                RENAMINGS=(
                # ä, Ä, ö, Ö, ü, Ü, ß first
                # https://www.utf8-zeichentabelle.de/unicode-utf8-table.pl?start=64&number=1024&names=-&utf8=string-literal
                "export SUBSTITUTIONCHARACTERS='ä'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --force 's/ä/ae/g;s/ö/oe/g;s/ü/ue/g;s/Ä/Ae/g;s/Ö/Oe/g;s/Ü/Ue/g;s/ß/ss/g;s/\x61\xcc\x88/ae/g;s/\x6f\xcc\x88/oe/g;s/\x75\xcc\x88/ue/g;s/\x41\xcc\x88/AE/g;s/\x4f\xcc\x88/OE/g;s/\x55\xcc\x88/UE/g;'"
                # sanitizing (problematic if whitespace in path to file or folder)
                #"export SUBSTITUTIONCHARACTERS='sanitize'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --sanitize --keep-extension"
                # all ocurrences of é
                "export SUBSTITUTIONCHARACTERS='é'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all 'é' 'e'"
                # all ocurrences of commas
                "export SUBSTITUTIONCHARACTERS=','; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all ',' '_'"
                # all ocurrences of \
                "export SUBSTITUTIONCHARACTERS='\'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '\' '_'"
                # all ocurrences of »
                "export SUBSTITUTIONCHARACTERS='»'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '»' '_'"
                # all ocurrences of «
                "export SUBSTITUTIONCHARACTERS='«'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '«' '_'"
                # all ocurrences of [
                "export SUBSTITUTIONCHARACTERS='['; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '[' '_'"
                # all ocurrences of ]
                "export SUBSTITUTIONCHARACTERS=']'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all ']' '_'"
                # all ocurrences of +
                "export SUBSTITUTIONCHARACTERS='+'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '+' '_'"
                # all ocurrences of %
                "export SUBSTITUTIONCHARACTERS='%'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '%' '_'"
                # all ocurrences of @
                "export SUBSTITUTIONCHARACTERS='@'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '@' '_'"
                # all ocurrences of #
                "export SUBSTITUTIONCHARACTERS='#'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '#' '_'"
                # all ocurrences of ®
                "export SUBSTITUTIONCHARACTERS='®'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '®' '_'"
                # all ocurrences of ø
                "export SUBSTITUTIONCHARACTERS='ø'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all 'ø' '_'"
                # all ocurrences of ~
                "export SUBSTITUTIONCHARACTERS='~'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '~' '_'"
                # all ocurrences of ·
                "export SUBSTITUTIONCHARACTERS='·'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '·' '_'"
                # all ocurrences of •
                "export SUBSTITUTIONCHARACTERS='•'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '•' '_'"
                # all ocurrences of |
                "export SUBSTITUTIONCHARACTERS='|'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '|' '_'"
                # all ocurrences of ï
                "export SUBSTITUTIONCHARACTERS='ï'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all 'ï' '_'"
                # all ocurrences of ›
                "export SUBSTITUTIONCHARACTERS='›'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '›' '_'"
                # all ocurrences of …
                "export SUBSTITUTIONCHARACTERS='…'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '…' '_'"
                # all ocurrences of –
                "export SUBSTITUTIONCHARACTERS='–'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '–' '_'"
                # all ocurrences of — # is not the same - than before
                "export SUBSTITUTIONCHARACTERS='—'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '—' '_'"
                # all ocurrences of ’
                "export SUBSTITUTIONCHARACTERS='’'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '’' '_'"
                # all ocurrences of ‘
                "export SUBSTITUTIONCHARACTERS='‘'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '‘' '_'"
                # all ocurrences of ?
                "export SUBSTITUTIONCHARACTERS='?'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '?' '_'"
                # all ocurrences of two or more __ substituted to a single _
                "export SUBSTITUTIONCHARACTERS='__'; find "'"$RENAME_DIR"'" -print0 | xargs -0 rename --subst-all '__' '_'"
                )
        
                for i in "${RENAMINGS[@]}"; do
                    NUM1=0
                    NUM1=$((NUM1+1))
                    while [[ $(eval $i 2>&1 | tee) != "" ]]
                    do
                        NUM1=$((NUM1+1))
                        eval $i 2>&1 | tee
                    done
                    eval $i
                    echo "finished renaming $SUBSTITUTIONCHARACTERS with $NUM1 run(s) ;)"
                done
        
            else
                echo "RENAME_DIR "$RENAME_DIR" does not exist, skipping..."
            fi
        done
    fi
}


### testing
if [[ "$TEST_SOURCING_AND_VARIABLES" == "yes" ]]
then
    echo "config file..."
    echo "script is sourced: $SCRIPT_IS_SOURCED"
    echo "script is session master: $SCRIPT_SESSION_MASTER"
    echo "script name is $SCRIPT_NAME"
    echo "script directory is $SCRIPT_DIR"
    echo "script directory one back is $SCRIPT_DIR_ONE_BACK"
else
    :
fi
