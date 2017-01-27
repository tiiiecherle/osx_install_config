#!/bin/bash

# trapping script to kill subprocesses when script is stopped
# kill -9 can only be silenced with >/dev/null 2>&1 when wrappt into function
function kill_subprocesses() 
{
# kills subprocesses only
pkill -9 -P $$
}

function kill_main_process() 
{
# kills subprocesses and process itself
exec pkill -9 -P $$
}

#trap "unset SUDOPASSWORD; printf '\n'; echo 'killing subprocesses...'; kill_subprocesses >/dev/null 2>&1; echo 'done'; echo 'killing main process...'; kill_main_process" SIGHUP SIGINT SIGTERM
trap "printf '\n'; kill_subprocesses >/dev/null 2>&1; kill_main_process" SIGHUP SIGINT SIGTERM
# kill main process only if it hangs on regular exit
trap "kill_subprocesses >/dev/null 2>&1; exit; kill_main_process" EXIT
#set -e

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")

find "$SCRIPT_DIR" -mindepth 1 ! -path "*/*.app/*" -name "*.app" -print0 | xargs -0 xattr -dr com.apple.quarantine
time bash "$SCRIPT_DIR"/backup_restore_script/backup_restore_script_mac.sh
echo ''

exit