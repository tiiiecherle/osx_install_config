#!/bin/bash

###
### asking password upfront
###

# function for reading secret string (POSIX compliant)
enter_password_secret()
{
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
while [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
do
    NUMBER_OF_TRIES=$((NUMBER_OF_TRIES+1))
    #echo "$NUMBER_OF_TRIES"
    if [ "$NUMBER_OF_TRIES" -le "$MAX_TRIES" ]
    then
        enter_password_secret
        ${USE_PASSWORD} | sudo -k -S echo "" > /dev/null 2>&1
        if [ $? -eq 0 ]
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
sudo()
{
    ${USE_PASSWORD} | builtin command sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin command -p sudo -p '' -k -S "$@"
    #${USE_PASSWORD} | builtin exec sudo -p '' -k -S "$@"
}


###
### general
###

# sqlite database for accessibility
#  /Library/Application Support/com.apple.TCC/TCC.db

# sqlite database for calendar, contacts, reminders, ...
#  ~/Library/Application Support/com.apple.TCC/TCC.db

DATABASE_SYSTEM="/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_SYSTEM"
DATABASE_USER="/Users/"$USER"/Library/Application Support/com.apple.TCC/TCC.db"
#echo "$DATABASE_USER"

# reading database
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db
# and
# sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db
# .dump access
# .schema access

# quit database
# .quit

# getting entries from database
# examples
# sqlite3 "$DATABASE_USER" "select * from access where service='kTCCServiceAppleEvents';"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and indirect_object_identifier='com.apple.systempreferences');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and indirect_object_identifier='com.apple.finder');"
# sqlite3 "$DATABASE_USER" "select * from access where (service='kTCCServiceAppleEvents' and client='com.apple.Terminal' and indirect_object_identifier='com.apple.finder' and allowed='1');"

# getting application identifier
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/enterapplicaitonnamehere.app/Contents/Info.plist
# example
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/Overflow.app/Contents/Info.plist
# com.stuntsoftware.Overflow
# example2
# /usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "/Applications/System Preferences.app/Contents/Info.plist"
# com.apple.systempreferences



###
### app list
###

Finder_DATA=(
Finder
com.apple.finder
fade0c000000002c00000001000000060000000200000010636f6d2e6170706c652e66696e64657200000003
)

iTerm_DATA=(
iTerm
com.googlecode.iterm2
fade0c00000000c40000000100000006000000060000000f0000000200000015636f6d2e676f6f676c65636f64652e697465726d32000000000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a483756375859565137440000
)
#
XtraFinder_DATA=(
XtraFinder
com.trankynam.XtraFinder
fade0c00000000a000000001000000060000000200000018636f6d2e7472616e6b796e616d2e5874726146696e646572000000060000000f000000060000000b000000000000000a7375626a6563742e434e000000000001000000274d616320446576656c6f7065723a205472616e204b79204e616d202850594e3545554748363629000000000e000000010000000a2a864886f76364060201000000000000
)
#
brew_casks_update_DATA=(
brew_casks_update
com.apple.ScriptEditor.id.brew-casks-update
fade0c000000008800000001000000070000000700000007000000080000001489c166168420f58cbc7dacbeb67f06b0c0035f7800000008000000141c9f822797b07af6cab3f5f3989464b6809b3d09000000080000001474871daae8da5574a7cc95c1f39c2c62dbf646fd00000008000000142cb58b2c33d3799b2c9c24540204c279a22b6101
)
#
video_720p_h265_aac_shrink_DATA=(
video_720p_h265_aac_shrink
com.apple.ScriptEditor.id.video-720p-h265-aac-shrink
fade0c0000000088000000010000000700000007000000070000000800000014c78454887c8c53fb6555c995d223c3dd78c5d1080000000800000014c4fe25417cf0c55fb3118208d7adc3c37346509e00000008000000145da93fff7bbb0282a8ec7be8fdd6950fd009e41f0000000800000014d3cc584ddb356f91b58a788d72c0d801889b76a7
)
#
video_1080p_h265_aac_shrink_DATA=(
video_1080p_h265_aac_shrink
com.apple.ScriptEditor.id.video-1080p-h265-aac-shrink
fade0c0000000088000000010000000700000007000000070000000800000014575bb3e4b097903aabe500304e8f1f825658850c00000008000000140d2de46834ffc48a63fe257b26ddc9eb503e90f000000008000000148fc2445c417388d60d242fff645c5cc6e743c23300000008000000143d7aea7f504e8e29bdf263d96f2bee80f5d0edb7
)
#
gui_apps_backup_DATA=(
gui_apps_backup
com.apple.ScriptEditor.id.gui-apps-backup
fade0c0000000088000000010000000700000007000000070000000800000014e43dec7360bc1b544188834584f6a3b4758dfb8d000000080000001439b81765fcba42b1ea2e099c1481b7febd3d77700000000800000014cc3463bde9f0bc4f1b1d7fa9eecf3b98185d84d30000000800000014c64a17a392d67f30ab4ec30e0c7b2517a0939818
)
#
BL_Banking_Launcher_DATA=(
"BL Banking Launcher"
com.apple.ScriptEditor.id.BL-Banking-Launcher
fade0c0000000088000000010000000700000007000000070000000800000014312a201d7800dce42bc2cdbe25b56f0c233f46c20000000800000014b48f17cadbeacf14422aec4f0881296fc412375800000008000000146316a0c053626555e43f3f13849fe942f8a4d56000000008000000145e22d05b311b734163d3aa09cc87e091f949fc37
)
#
decrypt_finder_input_gpg_progress_DATA=(
decrypt_finder_input_gpg_progress
com.apple.automator.decrypt_finder_input_gpg_progress
fade0c000000004800000001000000070000000800000014530057cbab37c28598d6ad03dd64c5da1ca25a5b0000000800000014acf03654b2a0b98c1273191f7400aa0e5599d998
)
#
unarchive_finder_input_progress_DATA=(
unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress
com.apple.automator.unarchive_finder_input_tar_gz_gpg_preserve_permissions_progress
fade0c000000004800000001000000070000000800000014e3bdc4447ac5d4c3498f1f790fc2f6e0100dc4f4000000080000001412d067f9608bd6f19d5ad215a058cb3b7b92b44b
)
#
Overflow_DATA=(
Overflow
com.stuntsoftware.Overflow
fade0c00000000c80000000100000006000000060000000f000000020000001a636f6d2e7374756e74736f6674776172652e4f766572666c6f770000000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a57334c4a5734553733320000
)
#
Script_Editor_DATA=(
"Script Editor"
com.apple.ScriptEditor2
fade0c000000003400000001000000060000000200000017636f6d2e6170706c652e536372697074456469746f72320000000003
)
#
System_Preferences_DATA=(
"System Preferences"
com.apple.systempreferences
fade0c00000000380000000100000006000000020000001b636f6d2e6170706c652e73797374656d707265666572656e6365730000000003
)
#
witchdaemon_DATA=(
witchdaemon
com.manytricks.witchdaemon
fade0c00000000c80000000100000006000000060000000f000000020000001a636f6d2e6d616e79747269636b732e77697463686461656d6f6e0000000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a4d45544b3436374757320000
)
#
Terminal_DATA=(
Terminal
com.apple.Terminal
fade0c000000003000000001000000060000000200000012636f6d2e6170706c652e5465726d696e616c000000000003
)
#
VirtualBox_DATA=(
VirtualBox
org.virtualbox.app.VirtualBox
fade0c00000000ac0000000100000006000000020000001d6f72672e7669727475616c626f782e6170702e5669727475616c426f78000000000000060000000f000000060000000e000000010000000a2a864886f76364060206000000000000000000060000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a564235453254563936330000
)
#
PasswordWallet_DATA=(
PasswordWallet
com.selznick.PasswordWallet
fade0c00000000c80000000100000006000000060000000f000000020000001b636f6d2e73656c7a6e69636b2e50617373776f726457616c6c657400000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a35373354454e465058390000
)
#
VirtualBox_Menulet_DATA=(
"VirtualBox Menulet"
com.kiwifruitware.VirtualBox_Menulet
fade0c0000000088000000010000000700000007000000070000000800000014b731aeefaeb64844710e1a5773f402dc36e4aa2c0000000800000014b8a9ccc2b0ecce9b55cc48d81a8843e0339487e4000000080000001461b6d15f592d5c3155052bdf197fcfdc94b2d70f0000000800000014309a5404b0133d909a68e55a1a52d08db9aa59ad
)
#
Bartender_3_DATA=(
"Bartender 3"
com.surteesstudios.Bartender
fade0c00000000c80000000100000006000000060000000f000000020000001c636f6d2e7375727465657373747564696f732e42617274656e646572000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a384444363633574458340000
)
#
Ondesoft_AudioBook_Converter_DATA=(
"Ondesoft AudioBook Converter"
com.ondesoft.audiobookconverter
fade0c00000000ac0000000100000006000000020000001f636f6d2e6f6e6465736f66742e617564696f626f6f6b636f6e76657274657200000000060000000f000000060000000e000000010000000a2a864886f76364060206000000000000000000060000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a543848365037363751550000
)
#
VNC_Viewer_DATA=(
"VNC Viewer"
com.realvnc.vncviewer
fade0c000000003400000001000000060000000200000015636f6d2e7265616c766e632e766e637669657765720000000000000f
)
#
Commander_One_DATA=(
"Commander One"
com.eltima.cmd1
fade0c00000000bc0000000100000006000000060000000f000000020000000f636f6d2e656c74696d612e636d643100000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a4e3755344847503235340000
)
#
Dialectic_DATA=(
Dialectic
com.jen.dialectic
fade0c00000000c00000000100000006000000060000000f0000000200000011636f6d2e6a656e2e6469616c6563746963000000000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a513838393736484334420000
)
#
Alfred_3_DATA=(
"Alfred 3"
com.runningwithcrayons.Alfred-3
fade0c00000000ac0000000100000006000000020000001f636f6d2e72756e6e696e6777697468637261796f6e732e416c667265642d3300000000060000000f000000060000000e000000010000000a2a864886f76364060206000000000000000000060000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a585a5a584539534544340000
)
#
GeburtstagsChecker_DATA=(
GeburtstagsChecker
earthlingsoft.GeburtstagsChecker
fade0c000000004800000001000000070000000800000014fa96375e124ea80d0821516239b2f2b50da8dacf0000000800000014cf03bff9ad3b1c979b7fe72033a9a0138fa596be
)
#
pdf_200dpi_shrink_DATA=(
pdf_200dpi_shrink
com.apple.ScriptEditor.id.pdf-200dpi-shrink
fade0c000000008800000001000000070000000700000007000000080000001448346d7bc2dceb225d2476f4fb8b6dc5267de9f300000008000000143d868dfbeb132f2bc82b23084dcab880be2e0eac0000000800000014775e6860f1e22e33e8c8334495b061270fe81ee10000000800000014f791baf151bc5bf624c3da6be4a7009e874c6290
)
#
System_Events_DATA=(
"System Events"
com.apple.systemevents
fade0c000000003400000001000000060000000200000016636f6d2e6170706c652e73797374656d6576656e7473000000000003
)
#
iTunes_DATA=(
iTunes
com.apple.iTunes
fade0c000000002c00000001000000060000000200000010636f6d2e6170706c652e6954756e657300000003
)
#
Mail_DATA=(
Mail
com.apple.mail
fade0c000000002c0000000100000006000000020000000e636f6d2e6170706c652e6d61696c000000000003
)
#
backup_files_tar_gz_DATA=(
backup_files_tar_gz
com.apple.ScriptEditor.id.backup-files-tar-gz
fade0c0000000088000000010000000700000007000000070000000800000014a4d091ccc76deb4d5dd693636b5afe695f76b1800000000800000014213d8e0e0b2647216d848e8055aa8be8fac3c24e0000000800000014dd79fd40577ca435a566b5520b4b7f70abda9a9600000008000000141fe17f9b3e72add183cd9e883efe3c271e8ead29
)
#
virtualbox_backup_DATA=(
virtualbox_backup
com.apple.ScriptEditor.id.virtualbox-backup
fade0c00000000880000000100000007000000070000000700000008000000141aec9bc75dc632cdc8620a2b8cd0f16ea316bfa100000008000000148561f20d21562c32d8bacd0589674285650b4813000000080000001488f10346ad60599113ea323511eea456841f20b40000000800000014b12dce1598de0573966b393c1020ca64b19702c5
)
#
run_on_login_signal_DATA=(
run_on_login_signal
com.apple.ScriptEditor.id.run-on-login-signal
fade0c0000000088000000010000000700000007000000070000000800000014c488b0270d8e740a0d1f2f6e787a49c248f7c0680000000800000014725ebf499e9ca54b6a065c70ff3de63e0a66ad3f0000000800000014dfef4b208fbd404d0be5f479708a26c3f5847560000000080000001460f786f1da2b21a6095288d7a3680deb8bf4d325
)
#
run_on_login_whatsapp_DATA=(
run_on_login_whatsapp
com.apple.ScriptEditor.id.run-on-login-whatsapp
fade0c00000000880000000100000007000000070000000700000008000000146968d5bc627400d010c529d3c0bc89b361c3f5e5000000080000001477ecfad045ed786b3416b9a69d25cdfd24b14e6e00000008000000140b850927f375cf7a7e0af088fd0a782cf356ae7d00000008000000140ce2ed64979dd0cb4f2fc0881f6382611a9b4eca
)
#
EagleFiler_DATA=(
EagleFiler
com.c-command.EagleFiler
fade0c00000000a400000001000000060000000200000018636f6d2e632d636f6d6d616e642e4561676c6546696c6572000000060000000f000000060000000e000000010000000a2a864886f76364060206000000000000000000060000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a32584e485958595434350000
)

iStat_Menus_DATA=(
"iStat Menus"
com.bjango.istatmenus.status
fade0c00000000c40000000100000006000000060000000f0000000200000015636f6d2e626a616e676f2e69737461746d656e7573000000000000070000000e000000000000000a2a864886f7636406010900000000000000000006000000060000000e000000010000000a2a864886f763640602060000000000000000000e000000000000000a2a864886f7636406010d0000000000000000000b000000000000000a7375626a6563742e4f550000000000010000000a593933544b39373441540000
)

#echo ''
#APP_NAME=Finder
#echo $APP_NAME
#ARRAY_NAME="$APP_NAME""_DATA"[@]

### getting identifier
# APP_IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' /Applications/"$APP_NAME".app/Contents/Info.plist)
#APP_IDENTIFIER=$(printf '%s\n' "${!ARRAY_NAME}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
#echo $APP_IDENTIFIER
#CSREQ_BLOB=$(printf '%s\n' "${!ARRAY_NAME}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
#echo $CSREQ_BLOB

### getting csreq_blob
# tccutil reset AppleEvents
# osascript -e "tell application \"Appname\" to «event BATFinit»"
# osascript -e "tell application \"Finder\" to «event BATFinit»"
# sqlite3 "$DATABASE_USER"
# .dump access

#echo ''
#SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")
#SCRIPT_NAME=$(basename -- "$0")
#echo "$SCRIPT_DIR"/"$SCRIPT_NAME"

#sudo tccutil reset AppleEvents
#tccutil reset AppleEvents
#for APP_ARRAY_NAME in $(cat "$SCRIPT_DIR"/"$SCRIPT_NAME" | sed 's/^ //g' | sed 's/ $//g' | grep "_DATA=($" | sed 's/_DATA.*//')
#do
#    APP_ARRAY="$APP_ARRAY_NAME""_DATA"[@]
#    APP_NAME=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '1p' | sed 's/^ //g' | sed 's/ $//g')
#    echo "$APP_NAME"
#    osascript -e "tell application \"$APP_NAME\" to «event BATFinit»"
#done
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db 'select quote(csreq) from access'
#exit



###
### privacy settings
###


### privacy - accessibility

echo ''
tput bold; echo "accessibility..." ; tput sgr0

# add application to accessibility
#terminal
#INSERT INTO access VALUES('kTCCServiceAccessibility','com.apple.Terminal',0,1,1,NULL,NULL,NULL,?,NULL,0,1533680610);
#overflow
#'IDENTIFIER',0,0,1     # added, but not enabled
#'IDENTIFIER',0,1,1     # added and enabled
#sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "REPLACE INTO access VALUES('kTCCServiceAccessibility','com.stuntsoftware.Overflow',0,1,1,NULL,NULL,NULL,?,NULL,0,1533680686);" 

# remove application from accessibility
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='IDENTIFIER';"
# example
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "delete from access where client='com.stuntsoftware.Overflow';"

# clearing complete access table
# sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "DELETE FROM access"

# permission on for all apps listed
# sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'UPDATE access SET allowed = "1";'

# permission off for all apps listed
# sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" 'UPDATE access SET allowed = "0";'

# getting entries from database
# sudo sqlite3 "$DATABASE_SYSTEM" "select * from access where service='kTCCServiceAccessibility';"

sudo sqlite3 "$DATABASE_SYSTEM" "DELETE FROM access"

ACCESSIBILITYAPPS=(
"brew_casks_update                                                      1"
"video_720p_h265_aac_shrink                                             1"
"video_1080p_h265_aac_shrink                                            1"
"gui_apps_backup                                                        1"
"BL_Banking_Launcher                                                    1"
"decrypt_finder_input_gpg_progress                                      1"
"unarchive_finder_input_progress                                        1"
"Overflow                                                               1"
"Script_Editor                                                          1"
"System_Preferences                                                     1"
"witchdaemon                                                            1"
"Terminal                                                               1"
"iTerm                                                                  1"
"VirtualBox                                                             1"
"PasswordWallet                                                         1"
"VirtualBox_Menulet                                                     1"
"Bartender_3                                                            1"
"Ondesoft_AudioBook_Converter                                           1"
"VNC_Viewer                                                             1"
"Commander_One                                                          0"
)

for app_entry in "${ACCESSIBILITYAPPS[@]}"
do
    echo "$app_entry"
    APP_NAME=$(echo "$app_entry" | awk '{print $1}' | sed 's/ //g')
    APP_ARRAY="$APP_NAME""_DATA"[@]
    APP_ID=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    APP_CSREQ=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$APP_NAME"
    #echo "$APP_ARRAY"
    #echo "$APP_ID"
    #echo "$APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$app_entry" | awk '{print $2}' | sed 's/ //g')
    #
    # working, but no csreq
    #sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','"$APP_ID"',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,?,NULL,0,?);"
    # working with csreq
    sudo sqlite3 "$DATABASE_SYSTEM" "REPLACE INTO access VALUES('kTCCServiceAccessibility','"$APP_ID"',0,$PERMISSION_GRANTED,1,NULL,NULL,NULL,X'"$APP_CSREQ"',NULL,0,?);"
    #
    unset APP_NAME
    unset APP_ARRAY
    unset APP_ID
    unset APP_CSREQ   
    unset PERMISSION_GRANTED
done


### privacy - contacts

echo ''
tput bold; echo "contacs..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAddressBook';"

CONTACTSAPPS=(
"gui_apps_backup                                                        1"
"Dialectic                                                              1"
"Alfred_3                                                               1"
"GeburtstagsChecker                                                     1"
)

for app_entry in "${CONTACTSAPPS[@]}"
do
    echo "$app_entry"
    APP_NAME=$(echo "$app_entry" | awk '{print $1}' | sed 's/ //g')
    APP_ARRAY="$APP_NAME""_DATA"[@]
    APP_ID=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    APP_CSREQ=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$APP_NAME"
    #echo "$APP_ARRAY"
    #echo "$APP_ID"
    #echo "$APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$app_entry" | awk '{print $2}' | sed 's/ //g')
    #
    # working, but no csreq
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','"$APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);"
    # working with csreq
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAddressBook','"$APP_ID"',0,$PERMISSION_GRANTED,1,X'"$APP_CSREQ"',NULL,NULL,?,NULL,NULL,?);"
    #
    unset APP_NAME
    unset APP_ARRAY
    unset APP_ID
    unset APP_CSREQ   
    unset PERMISSION_GRANTED
done


### privacy - calendar

echo ''
tput bold; echo "calendar..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceCalendar';"

CALENDARAPPS=(
"gui_apps_backup                                                        1"
"iStat_Menus                                                            1"
)

for app_entry in "${CALENDARAPPS[@]}"
do
    echo "$app_entry"
    APP_NAME=$(echo "$app_entry" | awk '{print $1}' | sed 's/ //g')
    APP_ARRAY="$APP_NAME""_DATA"[@]
    APP_ID=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    APP_CSREQ=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$APP_NAME"
    #echo "$APP_ARRAY"
    #echo "$APP_ID"
    #echo "$APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$app_entry" | awk '{print $2}' | sed 's/ //g')
    #
    # working, but no csreq
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','"$APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);"
    # working with csreq
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceCalendar','"$APP_ID"',0,$PERMISSION_GRANTED,1,X'"$APP_CSREQ"',NULL,NULL,?,NULL,NULL,?);"
    #
    unset APP_NAME
    unset APP_ARRAY
    unset APP_ID
    unset APP_CSREQ   
    unset PERMISSION_GRANTED
done


### privacy - reminders

echo ''
tput bold; echo "reminders..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceReminders';"

REMINDERAPPS=(
"gui_apps_backup                                                        1"
)

for app_entry in "${REMINDERAPPS[@]}"
do
    echo "$app_entry"
    APP_NAME=$(echo "$app_entry" | awk '{print $1}' | sed 's/ //g')
    APP_ARRAY="$APP_NAME""_DATA"[@]
    APP_ID=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    APP_CSREQ=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$APP_NAME"
    #echo "$APP_ARRAY"
    #echo "$APP_ID"
    #echo "$APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$app_entry" | awk '{print $2}' | sed 's/ //g')
    #
    # working, but no csreq
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceReminders','"$APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);"
    # working with csreq
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceReminders','"$APP_ID"',0,$PERMISSION_GRANTED,1,X'"$APP_CSREQ"',NULL,NULL,?,NULL,NULL,?);"
    #
    unset APP_NAME
    unset APP_ARRAY
    unset APP_ID
    unset APP_CSREQ   
    unset PERMISSION_GRANTED
done


### privacy - microphone

echo ''
tput bold; echo "microphone..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceMicrophone';"

MICROPHONEAPPS=(
"VirtualBox                                                             1"
)

for app_entry in "${MICROPHONEAPPS[@]}"
do
    echo "$app_entry"
    APP_NAME=$(echo "$app_entry" | awk '{print $1}' | sed 's/ //g')
    APP_ARRAY="$APP_NAME""_DATA"[@]
    APP_ID=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    APP_CSREQ=$(printf '%s\n' "${!APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$APP_NAME"
    #echo "$APP_ARRAY"
    #echo "$APP_ID"
    #echo "$APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$app_entry" | awk '{print $2}' | sed 's/ //g')
    #
    # working, but no csreq
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceMicrophone','"$APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,NULL,?,NULL,NULL,?);"
    # working with csreq
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceMicrophone','"$APP_ID"',0,$PERMISSION_GRANTED,1,X'"$APP_CSREQ"',NULL,NULL,?,NULL,NULL,?);"
    #
    unset APP_NAME
    unset APP_ARRAY
    unset APP_ID
    unset APP_CSREQ   
    unset PERMISSION_GRANTED
done


### privacy - automation
# does not show in system preferences window, but works

# asking for permission to use terminal to automate the finder
# osascript -e "tell application \"Finder\" to «event BATFinit»"

echo ''
tput bold; echo "automation..." ; tput sgr0

sqlite3 "$DATABASE_USER" "delete from access where service='kTCCServiceAppleEvents';"
#sudo tccutil reset AppleEvents   

AUTOMATIONAPPS=(
"brew_casks_update                      System_Events                   1"
"brew_casks_update                      Terminal                        1"
"pdf_200dpi_shrink                      System_Events                   1"
"pdf_200dpi_shrink                      Terminal                        1"
"decrypt_finder_input_gpg_progress      System_Events                   1"
"decrypt_finder_input_gpg_progress      Terminal                        1"
"unarchive_finder_input_progress        System_Events                   1"
"unarchive_finder_input_progress        Terminal                        1"
"video_720p_h265_aac_shrink             System_Events                   1"
"video_720p_h265_aac_shrink             Terminal                        1"
"video_1080p_h265_aac_shrink            System_Events                   1"
"video_1080p_h265_aac_shrink            Terminal                        1"
"BL_Banking_Launcher                    System_Events                   1"
"BL_Banking_Launcher                    Terminal                        1"
"backup_files_tar_gz                    System_Events                   1"
"backup_files_tar_gz                    Terminal                        1"
"gui_apps_backup                        System_Events                   1"
"gui_apps_backup                        Terminal                        1"
"virtualbox_backup                      System_Events                   1"
"run_on_login_signal                    System_Events                   1"
"run_on_login_whatsapp                  System_Events                   1"
"iTerm                                  System_Events                   1"
"XtraFinder                             Finder                          1"
"Ondesoft_AudioBook_Converter           iTunes                          1"
"EagleFiler                             Mail                            1"
"EagleFiler                             Finder                          1"
"witchdaemon                            Mail                            0"
)

for app_entry in "${AUTOMATIONAPPS[@]}"
do
    echo "$app_entry"
    SOURCE_APP_NAME=$(echo "$app_entry" | awk '{print $1}' | sed 's/ //g')
    SOURCE_APP_ARRAY="$SOURCE_APP_NAME""_DATA"[@]
    SOURCE_APP_ID=$(printf '%s\n' "${!SOURCE_APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    SOURCE_APP_CSREQ=$(printf '%s\n' "${!SOURCE_APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$SOURCE_APP"
    #echo "$SOURCE_APP_ARRAY"
    #echo "$SOURCE_APP_ID"
    #echo "$SOURCE_APP_CSREQ"
    #
    AUTOMATED_APP_NAME=$(echo "$app_entry" | awk '{print $2}' | sed 's/ //g')
    AUTOMATED_APP_ARRAY="$AUTOMATED_APP_NAME""_DATA"[@]
    AUTOMATED_APP_ID=$(printf '%s\n' "${!AUTOMATED_APP_ARRAY}" | sed -n '2p' | sed 's/^ //g' | sed 's/ $//g')
    AUTOMATED_APP_CSREQ=$(printf '%s\n' "${!AUTOMATED_APP_ARRAY}" | sed -n '3p' | sed 's/^ //g' | sed 's/ $//g')
    #echo "$AUTOMATED_APP"
    #echo "$AUTOMATED_APP_ARRAY"
    #echo "$AUTOMATED_APP_ID"
    #echo "$AUTOMATED_APP_CSREQ"
    #
    PERMISSION_GRANTED=$(echo "$app_entry" | awk '{print $3}' | sed 's/ //g')
    #
    # working, but does not show in gui of system preferences, use csreq for the entry to make it work and show
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP_ID"',0,$PERMISSION_GRANTED,1,?,NULL,0,'"$AUTOMATED_APP_ID"',?,NULL,?);"
    # not working, but shows correct entry in gui of system preferences, use csreq to make it work and show
    #sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP_ID"',0,$PERMISSION_GRANTED,1,'UNUSED',NULL,0,'"$AUTOMATED_APP_ID"','UNUSED',NULL,?);"
    # working and showing in gui of system preferences with csreq
    sqlite3 "$DATABASE_USER" "REPLACE INTO access VALUES('kTCCServiceAppleEvents','"$SOURCE_APP_ID"',0,$PERMISSION_GRANTED,1,X'"$SOURCE_APP_CSREQ"',NULL,0,'"$AUTOMATED_APP_ID"',X'"$AUTOMATED_APP_CSREQ"',NULL,?);"
    #
    unset SOURCE_APP_NAME
    unset SOURCE_APP_ARRAY
    unset SOURCE_APP_ID
    unset SOURCE_APP_CSREQ   
    unset AUTOMATED_APP_NAME
    unset AUTOMATED_APP_ARRAY
    unset AUTOMATED_APP_ID
    unset AUTOMATED_APP_CSREQ
    unset PERMISSION_GRANTED
done


###

echo ''
echo "done ;)"
echo ''

#echo "the changes need a reboot or logout to take effect"
#echo "please logout or reboot"
#echo "initializing loggin out"

#sleep 2

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout



###
### unsetting password
###

unset SUDOPASSWORD



