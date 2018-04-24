#!/bin/bash

function kill_subprocesses() 
{
    # kills only subprocesses of the current process
    #pkill -15 -P $$
    #kill -15 $(pgrep -P $$)
    
    # kills all descendant processes incl. process-children and process-grandchildren
    # option 1
    RUNNING_SUBPROCESSES=$(pgrep -g $(ps -o pgid= $$))
    kill -15 $RUNNING_SUBPROCESSES
    wait $RUNNING_SUBPROCESSES 2>/dev/null
    # option 2
    #{ kill -15 $RUNNING_SUBPROCESSES && wait $RUNNING_SUBPROCESSES; } >/dev/null 2>&1
    # option 3
    #kill -13 $RUNNING_SUBPROCESSES
    unset RUNNING_SUBPROCESSES
}

function kill_main_process() 
{
    # kills processes itself
    #kill $$
    kill -13 $$
}

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "kill_subprocesses >/dev/null 2>&1; exit" EXIT
#set -e

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")

find "$SCRIPT_DIR" -mindepth 1 ! -path "*/*.app/*" -name "*.app" -print0 | xargs -0 xattr -dr com.apple.quarantine
time bash "$SCRIPT_DIR"/backup_restore_script/backup_restore_script_mac.sh
echo ''

exit