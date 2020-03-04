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
### compatibility
###

# macos 10.15 only
if [[ "$MACOS_VERSION_MAJOR" != "10.15" ]]
then
    echo ''
    echo "this script is only compatible with macos 10.15, exiting..."
    echo ''
    exit
else
    :
fi



###
### apps notifications
###

### apps to set notifications for
APPLICATIONS_TO_SET_NOTIFICATIONS=(
""$PATH_TO_APPS"/WhatsApp.app																41943375"
""$PATH_TO_APPS"/Signal.app																	41943375"
""$PATH_TO_APPS"/pdf_200dpi_shrink.app/Contents/custom_files/pdf_shrink_done.app			41943375"
""$PATH_TO_SYSTEM_APPS"/Reminders.app														41943383"
""$PATH_TO_SYSTEM_APPS"/Calendar.app														41943383"
""$PATH_TO_SYSTEM_APPS"/Notes.app															41943375"
""$PATH_TO_SYSTEM_APPS"/Photos.app															41943375"
""$PATH_TO_APPS"/EagleFiler.app																41943375"
""$PATH_TO_APPS"/VirusScannerPlus.app														41943375"
""$PATH_TO_APPS"/MacPass.app																41943375"
""$PATH_TO_APPS"/Microsoft Word.app															41943375"
""$PATH_TO_APPS"/Microsoft Excel.app														41943375"
""$PATH_TO_APPS"/Microsoft PowerPoint.app													41943375"
""$PATH_TO_APPS"/Microsoft Remote Desktop.app												41943375"
""$PATH_TO_APPS"/Alfred 4.app																41943375"
""$PATH_TO_APPS"/Better.app																	41943375"
""$PATH_TO_APPS"/BresinkSoftwareUpdater.app													41943375"
""$PATH_TO_APPS"/Commander One.app															41943375"
""$PATH_TO_APPS"/iTerm.app																	41943375"
""$PATH_TO_APPS"/KeepingYouAwake.app														41943375"
""$PATH_TO_APPS"/PrefEdit.app																41943375"
""$PATH_TO_APPS"/TextMate.app																41943375"
""$PATH_TO_APPS"/Keka.app																	41943375"
""$PATH_TO_APPS"/Burn.app																	41943375"
""$PATH_TO_APPS"/2Do.app																	41943375"
""$PATH_TO_APPS"/Cyberduck.app																41943375"
""$PATH_TO_APPS"/HandBrake.app																41943375"
""$PATH_TO_APPS"/nextcloud.app																41943375"
""$PATH_TO_APPS"/Progressive Downloader.app													41943375"
""$PATH_TO_APPS"/Spotify.app																41943375"
""$PATH_TO_APPS"/Transmission.app															41943375"
""$PATH_TO_APPS"/Tunnelblick.app															41943375"
""$PATH_TO_APPS"/TinkerTool.app																41943375"
""$PATH_TO_APPS"/Vox.app																	41943375"
""$PATH_TO_APPS"/X-Lite.app																	41943375"
""$PATH_TO_APPS"/TotalFinder.app															41943375"
""$PATH_TO_APPS"/Firefox.app																41943375"
""$PATH_TO_APPS"/iStat Menus.app															41943375"
""$PATH_TO_APPS"/AdGuard for Safari.app														41943375"
""$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_found.app				41943383"
""$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_done.app					41943383"
""$PATH_TO_APPS"/clamav_scan.app/Contents/custom_files/clamav_scan_stopped.app				41943383"
)


### setting notification preferences
SET_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications
CHECK_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
echo ''
