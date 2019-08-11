#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### asking password upfront
###

env_enter_sudo_password


###
### input sources
###

### without this a few scripts would complain in the terminal
# about missing GetInputSourceEnabledPrefs
# will be done again in 11c_macos_preferences

update_keyboard_layout() {
    while IFS= read -r line || [[ -n "$line" ]]
    do
        if [[ "$line" == "" ]]; then continue; fi
        CONFIG_VALUE="$line"
        ${PERMISSION} ${PLBUDDY} -c "Delete :"${CONFIG_VALUE}"" "$KEYBOARD_CONFIG_FILE" 2> /dev/null
        ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}" array" "$KEYBOARD_CONFIG_FILE"
        ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0 dict" "$KEYBOARD_CONFIG_FILE"
        ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0:InputSourceKind string 'Keyboard Layout'" "$KEYBOARD_CONFIG_FILE"
        ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0:'KeyboardLayout ID' integer "${KEYBOARD_LAYOUT}"" "$KEYBOARD_CONFIG_FILE"
        ${PERMISSION} ${PLBUDDY} -c "Add :"${CONFIG_VALUE}":0:'KeyboardLayout Name' string '"${KEYBOARD_LOCALE}"'" "$KEYBOARD_CONFIG_FILE"
    done <<< "$(printf "%s\n" "${KEYBOARD_CONFIG_VALUES[@]}")"
}

# variables
KEYBOARD_LOCALE="German"
# 3 = QUERTZ
KEYBOARD_LAYOUT="3"

# system
PERMISSION='sudo'
PLBUDDY='/usr/libexec/PlistBuddy'
KEYBOARD_CONFIG_FILE="/Library/Preferences/com.apple.HIToolbox.plist"
KEYBOARD_CONFIG_VALUES=(
"AppleDefaultAsciiInputSource"
"AppleEnabledInputSources"
)
update_keyboard_layout "$KEYBOARD_CONFIG_FILE" "${KEYBOARD_LOCALE}" "${KEYBOARD_LAYOUT}" 2>&1 | grep -v "Will Create"
#sudo chmod 644 "$KEYBOARD_CONFIG_FILE"
#sudo chown root:wheel "$KEYBOARD_CONFIG_FILE"

# user
PERMISSION=''
PLBUDDY='/usr/libexec/PlistBuddy'
KEYBOARD_CONFIG_FILE="/USERS/$USER/Library/Preferences/com.apple.HIToolbox.plist"
KEYBOARD_CONFIG_VALUES=(
"AppleEnabledInputSources" 
"AppleSelectedInputSources"
)
${PERMISSION} ${PLBUDDY} -c "Delete :AppleCurrentKeyboardLayoutInputSourceID" "$KEYBOARD_CONFIG_FILE" 2> /dev/null
${PERMISSION} ${PLBUDDY} -c "Add :AppleCurrentKeyboardLayoutInputSourceID string com.apple.keylayout."${KEYBOARD_LOCALE}"" "$KEYBOARD_CONFIG_FILE"
update_keyboard_layout "$KEYBOARD_CONFIG_FILE" "${KEYBOARD_LOCALE}" "${KEYBOARD_LAYOUT}"
#chmod 644 "$KEYBOARD_CONFIG_FILE"
#chown "$USER":staff "$KEYBOARD_CONFIG_FILE"