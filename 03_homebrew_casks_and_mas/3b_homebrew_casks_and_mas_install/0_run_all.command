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


### traps
#trap_function_exit_middle() { COMMAND1; COMMAND2; }
"${ENV_SET_TRAP_SIG[@]}"
"${ENV_SET_TRAP_EXIT[@]}"


### wrap in function for getting time
run_all() {
    
    
    ###
    ### script frame
    ###
    
    if [[ -e "$SCRIPT_DIR"/1_script_frame.sh ]]
    then
        . "$SCRIPT_DIR"/1_script_frame.sh
        trap_function_exit_start() { env_delete_tmp_mas_script_fifo; env_delete_tmp_casks_script_fifo; }
        eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables
    else
        echo ''
        echo "script for functions and prerequisits is missing, exiting..."
        echo ''
        exit
    fi
    
    ### appstore password
    if [[ "$MAS_APPSTORE_PASSWORD" != "" ]]
    then
        :
    else
        if [[ -e /tmp/tmp_appstore_mas_script_fifo ]]
        then
            unset MAS_APPSTORE_PASSWORD
            MAS_APPSTORE_PASSWORD=$(cat "/tmp/tmp_appstore_mas_script_fifo" | head -n 1)
            env_delete_tmp_appstore_mas_script_fifo
        else
            :
        fi
    fi
    
        
    ###
    ### script
    ###
    
    echo ''
    echo "installing homebrew and homebrew casks..."
    echo ''

    
    
    ### sourcing some variables
    if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
    then
        SCRIPT_DIR_DEFAULTS_WRITE="$SCRIPT_DIR_THREE_BACK"
        if [[ -e "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/homebrew_cask_mas_data.sh ]]
        then
            . "$SCRIPT_DIR_DEFAULTS_WRITE"/_scripts_input_keep/homebrew_cask_mas_data.sh
        else
            :
        fi
    else
        :
    fi
    
    
    ### killing possible old processes
    ps aux | grep -ie /5_casks.sh | grep -v grep | awk '{print $2}' | xargs kill -9
    ps aux | grep -ie /6_mas_appstore.sh | grep -v grep | awk '{print $2}' | xargs kill -9
    
    
    ### asking for mas apps
    if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
    then
        :
    else
        echo ''
    fi
    VARIABLE_TO_CHECK="$CONT3_BREW"
    QUESTION_TO_ASK="do you want to install appstore apps via mas? (Y/n)? "
    env_ask_for_variable
    CONT3_BREW="$VARIABLE_TO_CHECK"
        
    if [[ "$CONT3_BREW" =~ ^(yes|y)$ ]]
    then
        env_check_if_second_macos_volume_is_mounted
        if [[ "$MAS_APPLE_ID" == "" ]]
        then
            #echo ''
            MAS_APPLE_ID=""
            VARIABLE_TO_CHECK="$MAS_APPLE_ID"
            QUESTION_TO_ASK="please enter apple id to log into appstore: "
            env_ask_for_variable
            MAS_APPLE_ID="$VARIABLE_TO_CHECK"
            #echo $MAS_APPLE_ID
        else
            #echo ''
            echo "MAS_APPLE_ID is "$MAS_APPLE_ID"..."
            #echo ''
        fi
        
        if [[ "$MAS_APPSTORE_PASSWORD" == "" ]]
        then
            echo ''
            #echo "please enter appstore password..."
            MAS_APPSTORE_PASSWORD=""
        
            # ask for password twice
            # ask for password twice
            while [[ $MAS_APPSTORE_PASSWORD != $MAS_APPSTORE_PASSWORD2 ]] || [[ $MAS_APPSTORE_PASSWORD == "" ]]; do stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && printf "re-enter appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD2 && stty echo && printf "\n" && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''; done
        
            # only ask for password once
            #stty -echo && printf "appstore password: " && read -r "$@" MAS_APPSTORE_PASSWORD && printf "\n" && stty echo && USE_MAS_APPSTORE_PASSWORD='builtin printf '"$MAS_APPSTORE_PASSWORD\n"''
            if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
            then
                :
            else
                echo ''
            fi
        else
            :
        fi
    else
        #echo ''
        :
    fi
    
    
    ### asking for casks
    VARIABLE_TO_CHECK="$CONT2_BREW"
    QUESTION_TO_ASK="do you want to install casks apps? (Y/n)? "
    env_ask_for_variable
    CONT2_BREW="$VARIABLE_TO_CHECK"
    
    if [[ -e "/tmp/Caskroom" ]] && [[ "$CONT2_BREW" =~ ^(y|yes)$ ]]
    then
        VARIABLE_TO_CHECK="$CONT_CASKROOM"
        QUESTION_TO_ASK="$(echo -e 'found a backup of cask specifications in /tmp/Caskroom \ndo you wanto to restore /tmp/Caskroom/* to $(brew --prefix)/Caskroom/' '(Y/n)? ')"
        env_ask_for_variable
        CONT_CASKROOM="$VARIABLE_TO_CHECK"
        
        if [[ "$CONT_CASKROOM" =~ ^(y|yes|n|no)$ || "$CONT_CASKROOM" == "" ]]
        then
            :
        else
            #echo ''
            echo "wrong input, exiting script..."
            echo ''
            exit
        fi
    else
        :
    fi
    
    
    ### command line tools
    RUN_FROM_RUN_ALL_SCRIPT="yes" . "$SCRIPT_DIR"/2_command_line_tools.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables

    
    ### homebrew, homebrew-cask and other taps
    RUN_FROM_RUN_ALL_SCRIPT="yes" . "$SCRIPT_DIR"/3_homebrew_cask.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables

    
    ### updating homebrew
    UPDATE_HOMEBREW="yes"
    env_homebrew_update


    ### casks
    if [[ "$CONT2_BREW" =~ ^(yes|y)$ ]]
    then
        sleep 5
        env_create_tmp_casks_script_fifo
        env_identify_terminal
        UPDATE_HOMEBREW="no"
        RUN_FROM_RUN_ALL_SCRIPT="yes"
    
        #osascript 2>/dev/null <<EOF
        osascript <<EOF
        tell application "Terminal"
        	if it is running then
        		#if not (exists window 1) then
        		if (count of every window) is 0 then
        			reopen
        			activate
        			set Window1 to front window
        			set runWindow to front window
        		else
        			activate
        			delay 2
        			set Window1 to front window
        			#
        			tell application "System Events" to keystroke "t" using command down
        			delay 2
        			set Window2 to front window
        			set runWindow to front window
        		end if
        	else
        		activate
        		set Window1 to front window
        		set runWindow to front window
        	end if
        	#delay 2
        	#
        	do script "export SCRIPT_DIR=\"$SCRIPT_DIR\"; export UPDATE_HOMEBREW=\"$UPDATE_HOMEBREW\"; export CONT_CASKROOM=\"$CONT_CASKROOM\"; export RUN_FROM_RUN_ALL_SCRIPT=\"$RUN_FROM_RUN_ALL_SCRIPT\"; (time \"$SCRIPT_DIR/5_casks.sh\"; echo '')" in runWindow
        	#
        	delay 10
            set frontmost of Window1 to true
        end tell
EOF
    
    else 
        CHECK_IF_CASKS_INSTALLED="no"
    fi    
    
    
    ### mas
    if [[ "$CONT3_BREW" == "y" || "$CONT3_BREW" == "yes" || "$CONT3_BREW" == "" ]]
    then
    
        env_create_tmp_mas_script_fifo
        env_identify_terminal
        UPDATE_HOMEBREW="no"
        RUN_FROM_RUN_ALL_SCRIPT="yes"
    
        #osascript 2>/dev/null <<EOF
        osascript <<EOF
        tell application "Terminal"
        	if it is running then
        		#if not (exists window 1) then
        		if (count of every window) is 0 then
        			reopen
        			activate
        			set Window1 to front window
        			set runWindow to front window
        		else
        			activate
        			delay 2
        			set Window1 to front window
        			#
        			tell application "System Events" to keystroke "t" using command down
        			delay 2
        			set Window2 to front window
        			set runWindow to front window
        		end if
        	else
        		activate
        		set Window1 to front window
        		set runWindow to front window
        	end if
        	#delay 2
            #    	
            do script "export SCRIPT_DIR=\"$SCRIPT_DIR\"; export UPDATE_HOMEBREW=\"$UPDATE_HOMEBREW\"; export MAS_APPLE_ID=\"$MAS_APPLE_ID\"; export RUN_FROM_RUN_ALL_SCRIPT=\"$RUN_FROM_RUN_ALL_SCRIPT\"; echo ''; (time \"$SCRIPT_DIR/6_mas_appstore.sh\"; echo '')" in runWindow
        	#
        	delay 120
            set frontmost of Window1 to true
        end tell
EOF
    
    else 
        CHECK_IF_MASAPPS_INSTALLED="no"
    fi
    
    
    ### homebrew formulae
    UPDATE_HOMEBREW="no"
    RUN_FROM_RUN_ALL_SCRIPT="yes" . "$SCRIPT_DIR"/4_homebrew_formulae.sh
    eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables

    
    ### waiting for the scripts in the separate tabs to finish
    #echo ''
    echo "waiting for casks and mas scripts..."
    # grep space S+ space
    
    WAIT_PIDS=()
    WAIT_PIDS+=$(ps aux | grep /5_casks.sh | grep -v grep | awk '{print $2;}')
    WAIT_PIDS+=$(ps aux | grep /6_mas_appstore.sh | grep -v grep | awk '{print $2;}')
    #WAIT_PIDS=$(ps -A | grep -m1 /6_mas_appstore.sh | awk '{print $1}')
    #echo "$WAIT_PIDS"
    #if [[ "$WAIT_PIDS" == "" ]]; then :; else lsof -p "$WAIT_PIDS" +r 1 &> /dev/null; fi
    while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == "" ]]; then continue; fi; lsof -p "$line" +r 1 &> /dev/null; done <<< "$(printf "%s\n" "${WAIT_PIDS[@]}")"   
    
    
    ### cleaning up
    echo ''
    echo "cleaning up..."
    env_cleanup_all_homebrew
    
    
    ### checking success of installations
    #echo ''
    CHECK_IF_CASKS_INSTALLED="$CHECK_IF_CASKS_INSTALLED" CHECK_IF_MASAPPS_INSTALLED="$CHECK_IF_MASAPPS_INSTALLED" RUN_FROM_ALL_SCRIPT="yes" . "$SCRIPT_DIR"/7_formulae_casks_and_mas_install_check.sh
    
    sleep 0.5
    echo ''
}
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then ( run_all ); else time ( run_all ); fi
sleep 0.5

echo ''
echo "done ;)"
#echo ''


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi
