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

# specific macos version only
if [[ "$MACOS_VERSION_MAJOR" != "14" ]]
then
    echo ''
    echo "this script is only compatible with macos 14, exiting..."
    echo ''
    exit
else
    :
fi



###
### apps notifications
###

# reminders
# notification center will ask for urgent notifications to be allowed        310911319
# urgent notifications allowed                                              1921524055
# urgent notifications not allowed                                          1384653143

# calendar
# notification center will ask for urgent notifications to be allowed         41951575
# urgent notifications allowed                                              1652564311
# urgent notifications not allowed                                          1115693399

# check values for reminders and calendar
# set wanted settings in the gui and enable the following function
check_values_for_specific_apps() {
    APPLICATIONS_TO_SET_NOTIFICATIONS=(
    "Reminders														        10511458647"
    "Calendar														        10511458647"
    )
    CHECK_APPS_NOTIFICATIONS="yes" PRINT_NOTIFICATION_CHECK_TO_ERROR_LOG="no" env_set_check_apps_notifications
    exit
}
#check_values_for_specific_apps

### apps to set notifications for
APPLICATIONS_TO_SET_NOTIFICATIONS=(
"WhatsApp																41943375"
"Signal																	41951575"
"Script Editor                                                          41943375"
"pdf_shrink_done			                                            41943375"
"Reminders														        10511458647"
"Calendar														        10511458647"
"Notes															        41943375"
"Photos															        41943375"
"EagleFiler															    41943375"
"VirusScannerPlus														41943375"
"MacPass																41943375"
"Microsoft Word														    41943375"
"Microsoft Excel														41943375"
"Microsoft PowerPoint													41943375"
"Microsoft Remote Desktop												41943375"
"Alfred 5																41943375"
#"Better																    41943375"
"BresinkSoftwareUpdater												    41943375"
"Commander One															41943375"
"iTerm																	41943375"
"KeepingYouAwake														41943375"
"PrefEdit																41943375"
"TextMate																41943375"
"Keka																	41943375"
"Burn																	41943375"
"2Do																	41943375"
"Cyberduck																41943375"
"HandBrake																41943375"
"nextcloud																41943375"
"Progressive Downloader													41943375"
"Spotify																41943375"
"Transmission															41943375"
"Tunnelblick															41943375"
"TinkerTool																41943375"
"Vox																	41943375"
#"TotalFinder															41943375"
"Firefox																41943375"
"iStat Menus															41943375"
"AdGuard for Safari														41943375"
"clamav_scan_found				                                        41951575"
"clamav_scan_done					                                    41951575"
"clamav_scan_stopped				                                    41951575"
"Telephone  													        41943375"
"PVGuard																41943375"
"Chromium																41943375"
"App Store																41943375"
#"System Settings														41943375"
)


### setting notification preferences
SET_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications
CHECK_APPS_NOTIFICATIONS="yes" env_set_check_apps_notifications


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo ''
echo 'done ;)'
echo ''
