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
### defaults with
###

# credit to
# http://superuser.com/questions/273756/how-to-change-default-app-for-all-files-of-particular-file-type-through-terminal
#
# brew install duti
# read
# duti -x html
# write
# duti -s com.apple.Safari html all
# UTI hierarchy
# https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html#//apple_ref/doc/uid/TP40009259-SW1
#
# defaults read com.apple.LaunchServices/com.apple.launchservices.secure
#
# defaults read com.apple.LaunchServices/com.apple.launchservices.secure | grep -B 1 -A 5 public.html
#
# open /Users/$USER/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist


### functions




###

# option for cleaning launchservices index
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]
then
    :
else
    echo ''
fi
VARIABLE_TO_CHECK="$CLEAN_SERVICES_CACHE"
QUESTION_TO_ASK="do you want to clean the launchservices (open with) index and the icon cache after setting the new defaults for open with (y/N)? "
env_ask_for_variable
CLEAN_SERVICES_CACHE="$VARIABLE_TO_CHECK"

sleep 0.1
echo ''

if [[ "$CLEAN_SERVICES_CACHE" =~ ^(yes|y)$ ]]
then
    env_enter_sudo_password
    echo ''
else
    :
fi

###

PLIST="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
BUDDY=/usr/libexec/PlistBuddy

if [ -e "$PLIST" ]
then
    :
else
    $BUDDY -c "Add LSHandlers:0 dict" $PLIST
    $BUDDY -c "Delete LSHandlers" $PLIST
fi

default_open_with=(
"LSHandlerURLScheme             http                                        com.apple.safari"
"LSHandlerURLScheme             https                                       com.apple.safari"
"LSHandlerContentType           public.html                                 com.apple.safari"
"LSHandlerContentType           public.xhtml                                com.apple.safari"
"LSHandlerContentType           public.comma-separated-values-text          org.libreoffice.script"         # .csv
"LSHandlerContentType           org.oasis-open.opendocument.text            org.libreoffice.script"         # .odt
"LSHandlerContentType           public.shell-script                         com.coteditor.coteditor"        # .sh
"LSHandlerContentType           public.php-script                           com.coteditor.coteditor"        # .php
"LSHandlerContentType           public.css                                  com.coteditor.coteditor"        # .css
"LSHandlerContentType           public.yaml                                 com.coteditor.coteditor"        # .css
"LSHandlerContentTagClass       public.filename-extension                   com.coteditor.coteditor LSHandlerContentTag     conf"       # .conf
"LSHandlerContentTagClass       public.filename-extension                   com.coteditor.coteditor LSHandlerContentTag     env"       # .conf
"LSHandlerContentType           com.adobe.pdf                               com.apple.preview"              # .pdf
"LSHandlerContentType           public.zip-archive                          cx.c3.theunarchiver"            # .zip
"LSHandlerContentType           org.gnu.gnu-zip-archive                     cx.c3.theunarchiver"            # .tar.gz
"LSHandlerContentType           org.7-zip.7-zip-archive                     cx.c3.theunarchiver"            # .7z
"LSHandlerContentType           public.tar-archive                          cx.c3.theunarchiver"            # .tar
"LSHandlerContentType           net.daringfireball.markdown                 com.uranusjr.macdown"           # .md
"LSHandlerContentTagClass       public.filename-extension                   com.apple.automator.unarchive_finder_input_gpg_progress     LSHandlerContentTag    gpg" # .gpg
"LSHandlerContentType           com.apple.property-list                     org.tempel.prefseditor"         # .plist
"LSHandlerContentType           public.mpeg-4                               com.colliderli.iina"            # .mp4
"LSHandlerContentType           com.sun.java-web-start                      com.install4j.9615-4721-3936-4657.313"            # .jnlp
)

# libreoffice
#"LSHandlerContentType           public.comma-separated-values-text          org.libreoffice.script"        # .csv
# openoffice
#"LSHandlerContentType           public.comma-separated-values-text          org.openoffice.script"          # .csv

for entry in "${default_open_with[@]}"
do
    echo $entry
    KEY=$(echo $entry | awk '{print $1}')
    VALUE=$(echo $entry | awk '{print $2}')
    HANDLER=$(echo $entry | awk '{print $3}')
    KEY2=$(echo $entry | awk '{print $4}')
    VALUE2=$(echo $entry | awk '{print $5}')
    #echo $KEY
    #echo $VALUE
    #echo $HANDLER

    $BUDDY -c 'Print "LSHandlers"' $PLIST >/dev/null 2>&1
#    ret=$?
 #   if [[ $ret -ne 0 ]] ; then
   #         echo "There is no LSHandlers entry in $PLIST" >&2
     #       break
    #fi

    create_entry() {
            if [[ "$KEY2" != "" ]] && [[ "$VALUE2" != "" ]]
            then
                $BUDDY -c "Add LSHandlers:$I dict" $PLIST
                $BUDDY -c "Add LSHandlers:$I:$KEY2 string $VALUE2" $PLIST
                $BUDDY -c "Add LSHandlers:$I:$KEY string $VALUE" $PLIST
                $BUDDY -c "Add LSHandlers:$I:LSHandlerRoleAll string $HANDLER" $PLIST
            else
                :
                $BUDDY -c "Add LSHandlers:$I dict" $PLIST
                $BUDDY -c "Add LSHandlers:$I:$KEY string $VALUE" $PLIST
                $BUDDY -c "Add LSHandlers:$I:LSHandlerRoleAll string $HANDLER" $PLIST
            fi
    }

    declare -i I=0
    while [ true ] ; do
            $BUDDY -c "Print LSHandlers:$I" $PLIST >/dev/null 2>&1
            [[ $? -eq 0 ]] || { echo "Finished, no $VALUE found, setting it to $HANDLER" ; echo "" ; create_entry ; break ; }

            OUT="$( $BUDDY -c "Print 'LSHandlers:$I:$KEY'" $PLIST 2>/dev/null )"
            CONTENT=$( echo "$OUT" )
            if [[ $? -ne 0 ]] ; then 
                    I=$I+1
                    continue
            fi

            OUT2="$( $BUDDY -c "Print 'LSHandlers:$I:$KEY2'" $PLIST 2>/dev/null )"
            CONTENT2=$( echo "$OUT2" )
            
            if [[ "$KEY2" != "" ]] && [[ "$VALUE2" != "" ]]
            then
                if [[ $CONTENT = $VALUE ]] && [[ $CONTENT2 = $VALUE2 ]]
                then
                    echo "Replacing $CONTENT handler with $HANDLER"
                    echo ""
                    $BUDDY -c "Delete 'LSHandlers:$I'" $PLIST
                    #$BUDDY -c "Delete 'LSHandlers:LSHandlerContentTag'" $PLIST
                    #$BUDDY -c "Delete 'LSHandlers:LSHandlerContentTagClass'" $PLIST  
                    #$BUDDY -c "Delete 'LSHandlers:$I'" $PLIST
                    create_entry
                    break
                else
                    I=$I+1 
                fi            
            else
                if [[ $CONTENT = $VALUE ]]
                then
                    echo "Replacing $CONTENT handler with $HANDLER"
                    echo ""
                    $BUDDY -c "Delete 'LSHandlers:$I'" $PLIST
                    create_entry
                    break
                else
                    I=$I+1 
                fi  
            fi
    done
done

if [[ "$CLEAN_SERVICES_CACHE" =~ ^(yes|y)$ ]]
then

    #echo ''
    echo "cleaning launchservices (open with) index..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
    echo "rebuilding launchservices (open with) index..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -seed -r -domain local -domain system -domain user 2>&1 | grep -v "registered plugin"
    sleep 3
    echo ''
    
    # it seems to be necessary to clean the icon cache after cleaning the launchservices (open with) index
    # cleaning icon cache
    echo "cleaning icon cache..."
    sudo rm -rf /Library/Caches/com.apple.iconservices.store
    sudo find /private/var/folders/ -name com.apple.dock.iconcache -exec rm -rf {} \; 2>/dev/null
    sudo find /private/var/folders/ -name com.apple.iconservices -exec rm -rf {} \; 2>/dev/null
    sleep 3
    #sudo touch "$PATH_TO_APPS"/*
    #sleep 3
    killall Dock
    #killall Finder
    echo ''

else
    :
fi


### stopping the error output redirecting
if [[ "$RUN_FROM_BATCH_SCRIPT" == "yes" ]]; then env_stop_error_log; else :; fi


echo "done ;)"
echo ''
echo "the changes need a reboot to take effect..."
#echo "initializing reboot"
echo ''

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


