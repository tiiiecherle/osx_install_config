# This config file contains variales, functions and comments to avoid redundant code in shell scripts
# and make maintanance easier and scripts cleaner. For easy identification in scripts all functions in this file start with env_*.
# To make it available in a script add this after the shebang. It works with #!/bin/zsh and #!/bin/bash.
# Do not put these lines in a function or some things may not work as expected.
#
#if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/___config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
#eval_function() { function_to_eval="$@"; eval "$(typeset -f $function_to_eval)" && "$function_to_eval" ; }
#eval_function env_get_shell_specific_variables


### shell specific varibales
env_get_shell_specific_variables() {

    ### shell specific
    if [[ -n "$BASH_SOURCE" ]]
    then
        #echo "script is run with bash interpreter..."
        
        # sourcing env_parallel to use variables and functions in parallels
        #source $(which env_parallel.bash)
        if [[ $(command -v parallel) == "" ]]; then :; else . $(which env_parallel.bash); fi
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
        env_read_from_command_line() { $COMMAND_TO_READ_FROM_COMMAND_LINE "$QUESTION_TO_ASK" VARIABLE_TO_CHECK ; }
        
        # use password for sudo input
        env_use_password() { ${USE_PASSWORD}; }
        
        # check if script is sourced
        [[ "${BASH_SOURCE[0]}" != "${0}" ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        # eval alternative (does not work inside function because of subshell)
        # use eval "$CHECK_IF_SOURCED" in other script to call it
        #CHECK_IF_SOURCED='(return 0 2>/dev/null) && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
        #(return 0 2>/dev/null) && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        #eval "$CHECK_IF_SOURCED"
    elif [[ -n "$ZSH_VERSION" ]]
    then
        #echo "script is run with zsh interpreter..."
        
        # sourcing env_parallel to use variables and functions in parallels
        #source =env_parallel.zsh
        if [[ $(command -v parallel) == "" ]]; then :; else . $(which env_parallel.zsh); fi
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
        env_read_from_command_line() { ${=COMMAND_TO_READ_FROM_COMMAND_LINE} "$QUESTION_TO_ASK" VARIABLE_TO_CHECK ; }
        
        # use password for sudo input    
        env_use_password() { ${=USE_PASSWORD}; }
        
        # check if script is sourced
        [[ $ZSH_EVAL_CONTEXT =~ ^toplevel:file ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"
        # eval alternative
        # use eval "$CHECK_IF_SOURCED" in other script to call it
        #CHECK_IF_SOURCED='[[ $ZSH_EVAL_CONTEXT =~ ':file$' ]] && SCRIPT_IS_SOURCED="yes" || SCRIPT_IS_SOURCED="no"'
        #eval "$CHECK_IF_SOURCED"
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
    
}
env_get_shell_specific_variables


### text output
bold_text=$(tput bold)
red_text=$(tput setaf 1)
green_text=$(tput setaf 2)
blue_text=$(tput setaf 4)
default_text=$(tput sgr0)


### checking if online
env_check_if_online() {
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

env_check_if_online_silent() {
    #echo ''
    #echo "checking internet connection..."
    ping -c 3 google.com > /dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
        ONLINE_STATUS="online"
        #echo "we are online..."
    else
        ping -c 3 duckduckgo.com > /dev/null 2>&1
        if [[ $? -eq 0 ]]
        then
            ONLINE_STATUS="online"
            #echo "we are online..."
        else
            ONLINE_STATUS="offline"
            #echo "not online..."
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
        
        env_check_if_online_silent
        if [[ "$ONLINE_STATUS" == "online" ]] && [[ -e "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH" ]]
        then
            # online
    
            # checking if up-to-date
            if [[ "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/___config_file/shellscriptsrc.sh)" != "$(cat $SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH)" ]]
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
                    curl https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/___config_file/"$SHELL_SCRIPTS_CONFIG_FILE".sh -o "$SHELL_SCRIPTS_CONFIG_FILE_INSTALL_PATH"
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
    SUBPROCESSES_PID_TEXT=$(pgrep -lg $(ps -o pgid= $$) | grep -v $$ | grep -v grep)
    SCRIPT_COMMAND=$(ps -o comm= $$)
	PARENT_SCRIPT_COMMAND=$(ps -o comm= $PPID)
	if [[ $PARENT_SCRIPT_COMMAND == "$(basename $SCRIPT_INTERPRETER)" ]] || [[ $PARENT_SCRIPT_COMMAND == "-$(basename $SCRIPT_INTERPRETER)" ]] || [[ $PARENT_SCRIPT_COMMAND == "" ]]
	then
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | awk '{print $1}')
    else
        RUNNING_SUBPROCESSES=$(echo "$SUBPROCESSES_PID_TEXT" | grep -v "$SCRIPT_COMMAND" | grep -v "^$PARENT_SCRIPT_COMMAND$" | awk '{print $1}')
    fi
    #echo $RUNNING_SUBPROCESSES
}

env_kill_subprocesses_v1() {
    # kills only subprocesses of the current process
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    #echo "killing processes..."
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # giving subprocesses the chance to terminate cleanly kill -15
    env_get_running_subprocesses    
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -15 $RUNNING_SUBPROCESSES
        # do not wait here if a process can not terminate cleanly
        #wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # waiting for clean subprocess termination
    TIME_OUT=0
    while [[ $RUNNING_SUBPROCESSES != "" ]] && [[ $TIME_OUT -lt 3 ]]
    do
        env_get_running_subprocesses        
        sleep 1
        TIME_OUT=$((TIME_OUT+1))
    done
    # killing the rest of the processes kill -9
    env_get_running_subprocesses    
    if [[ $RUNNING_SUBPROCESSES != "" ]]
    then
        kill -9 $RUNNING_SUBPROCESSES
        wait $RUNNING_SUBPROCESSES 2>/dev/null
    else
        :
    fi
    # unsetting variable
    unset RUNNING_SUBPROCESSES
}

env_kill_subprocesses() {
    trap - SIGTERM && kill -- -$$
    #kill $(jobs -pr)
}

env_kill_subprocesses_and_parent_shell() {
    trap - SIGTERM && kill 0
}

#trap "trap - SIGTERM && ( (kill -- -$$ &> /dev/null) & )" EXIT
#trap 'trap - SIGTERM && ( (kill 0 &> /dev/null) & )' EXIT
#trap 'kill $(jobs -pr)' EXIT
#trap "((eval_function env_kill_subprocesses) & )" EXIT

env_kill_main_process() {
    # kills processes itself
    #kill $$
    kill -13 $$
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
        APP_ENTRY="$line"
        #echo "$APP_ENTRY"
        
        # app name
        #APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/   */:/g' | cut -d':' -f1)
        #APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | sed 's/ \{2,\}/:/g' | cut -d':' -f2)
       	#APP_NAME=$(echo "$app_entry" | awk '{gsub("\t","  ",$0); print;}' | awk -F '  +' '{print $1}')
       	#APP_NAME=$(echo "$app_entry" | sed $'s/\t/|/g' | sed 's/   */:/g' | cut -d':' -f1)
       	APP_NAME=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $1}' | sed 's/^ //g' | sed 's/ $//g')
       	#APP_NAME_NO_SPACES=$(echo "$APP_NAME" | sed 's/ /_/g' | sed 's/^ //g' | sed 's/ $//g')
       	#echo "$APP_NAME"
       	
       	# app id
        #APP_ID=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
        #APP_ID=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
        APP_ID=$(osascript -e "id of app \"$APP_NAME\"")
        #PATH_TO_APP=$(mdfind kMDItemContentTypeTree=com.apple.application | grep -i "/$APP_NAME.app$" | head -1)
        #APP_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$PATH_TO_APP/Contents/Info.plist")
        #APP_ID=$(APP_NAME2="${APP_NAME//\'/\'}.app"; APP_NAME2=${APP_NAME2//"/\\"}; APP_NAME2=${APP_NAME2//\\/\\\\}; mdls -name kMDItemCFBundleIdentifier -raw "$(mdfind 'kMDItemContentType==com.apple.application-bundle&&kMDItemFSName=="'"$APP_NAME2"'"' | head -n1)")
        #echo "$APP_ID"
        if [[ "$APP_ID" == "" ]]
        then
            echo "APP_ID is empty, skipping entry..."
            continue
        else
            :
        fi
        
        # app csreq
        #APP_CSREQ=$(cat "$SCRIPT_DIR_PROFILES"/"$APP_NAME".txt | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')    
        #echo "$APP_CSREQ"
        
        # input service
        INPUT_SERVICE=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $2}' | sed 's/^ //g' | sed 's/ $//g')
        #echo "$INPUT_SERVICE"
        
        # permissions allowed
        # 0 = no
        # 1 = yes
        PERMISSION_GRANTED=$(echo "$APP_ENTRY" | awk '{gsub("\t","  ",$0); print;}' | awk -F ' \{2,\}' '{print $3}' | sed 's/^ //g' | sed 's/ $//g')
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
        APP_NAME_PRINT=$(echo "$APP_NAME" | cut -d ":" -f1 | awk -v len=30 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
        
        # print line
        if [[ "$PRINT_SECURITY_PERMISSIONS_ENTRYS" == "yes" ]]
        then
            printf "%-33s %-33s %-5s\n" "$APP_NAME_PRINT" "$INPUT_SERVICE" "$PERMISSION_GRANTED"
        else
            :
        fi
        
        # unset variables for next entry
        unset APP_NAME
        unset APP_NAME_PRINT
        unset PATH_TO_APP
        unset APP_ID
        unset APP_CSREQ
        unset INPUT_SERVICE
        unset PERMISSION_GRANTED
    
    #done
    done <<< "$(printf "%s\n" "${APPS_SECURITY_ARRAY[@]}")"
}


### sudo password upfront
env_enter_sudo_password() {

    #echo ''
    
    # function for reading secret string (POSIX compliant)
    enter_password_secret() {
        # read -s is not POSIX compliant
        #read -s -p "Password: " SUDOPASSWORD
        #echo ''
        
        # this is POSIX compliant
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
    trap 'unset SUDOPASSWORD' EXIT
    
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
    env_use_password | builtin command sudo -p '' -S -v
    ( while true; do env_use_password | builtin command sudo -p '' -S -v; sleep 60; done; ) &
    SUDO_PID="$!"
}

env_stop_sudo() {
    if [[ $(echo $SUDO_PID) == "" ]]
    then
        :
    else
        if ps -p $SUDO_PID > /dev/null
        then
            sudo kill -9 $SUDO_PID &> /dev/null
            wait $SUDO_PID 2>/dev/null
        else
            :
        fi
    fi
    unset SUDO_PID
    sudo -k
}


### homebrew
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
        VERSION_TO_CHECK_AGAINST=10.14
        if [[ $(env_convert_version_comparable "$MACOS_VERSION_MAJOR") -le $(env_convert_version_comparable "$VERSION_TO_CHECK_AGAINST") ]]    
        then
            #COMMANDLINETOOLVERSION=$(softwareupdate --list | grep "^[[:space:]]\{1,\}\*[[:space:]]\{1,\}Command Line Tools" | grep $(echo "$MACOS_VERSION_MAJOR" | cut -f1,2 -d'.' | sed -e 's/^[ \t]*//' | sed 's/^*//' | sed -e 's/^[ \t]*//'))
            COMMANDLINETOOLVERSION=$(softwareupdate --list | grep -B 1 -E 'Command Line (Developer|Tools)' | awk -F'*' '/^ +\\*/ {print $2}' | grep "$MACOS_VERSION_MAJOR" | sed 's/^ *//' | tail -n1)  
        elif [[ "$MACOS_VERSION_MAJOR" == "10.15" ]]
        then
            COMMANDLINETOOLVERSION=$(softwareupdate --list | grep -B 1 -E 'Command Line (Developer|Tools)' | grep '* Label:' | awk -F':' '{print $2}' | sed 's/^ *//' | tail -n 1)
        else
            :
        fi     
    	echo "installing "$COMMANDLINETOOLVERSION"..."
        softwareupdate -i --verbose "$(echo "$COMMANDLINETOOLVERSION")"
        
        # removing tmp file that forces command line tools to show up
        if [[ -e "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress" ]]
        then
            rm -f "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
        else
            :
        fi
        
        # choosing command line tools as default
        sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi
}

env_homebrew_update() {
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
