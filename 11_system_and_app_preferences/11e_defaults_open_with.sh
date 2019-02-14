#!/usr/bin/env bash

# credit to
# http://superuser.com/questions/273756/how-to-change-default-app-for-all-files-of-particular-file-type-through-terminal
#
# brew install duti
# read
# duti -x html
# write
# duti -s com.apple.Safari html all
#
# defaults read com.apple.LaunchServices/com.apple.launchservices.secure
#
# defaults read com.apple.LaunchServices/com.apple.launchservices.secure | grep -B 1 -A 5 public.html
#
# open /Users/$USER/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist


### functions

ask_for_variable() {
	ANSWER_WHEN_EMPTY=$(echo "$QUESTION_TO_ASK" | awk 'NR > 1 {print $1}' RS='(' FS=')' | tail -n 1 | tr -dc '[[:upper:]]\n')
	VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	while [[ ! "$VARIABLE_TO_CHECK" =~ ^(yes|y|no|n)$ ]] || [[ -z "$VARIABLE_TO_CHECK" ]]
	do
		read -r -p "$QUESTION_TO_ASK" VARIABLE_TO_CHECK
		if [[ "$VARIABLE_TO_CHECK" == "" ]]; then VARIABLE_TO_CHECK="$ANSWER_WHEN_EMPTY"; else :; fi
		VARIABLE_TO_CHECK=$(echo "$VARIABLE_TO_CHECK" | tr '[:upper:]' '[:lower:]') # to lower
	done
	#echo VARIABLE_TO_CHECK is "$VARIABLE_TO_CHECK"...
}


###

# option for cleaning launchservices index
echo ''
VARIABLE_TO_CHECK="$CLEAN_SERVICES_CACHE"
QUESTION_TO_ASK="do you want to clean the launchservices (open with) index and the icon cache after setting the new defaults for open with (y/N)? "
ask_for_variable
CLEAN_SERVICES_CACHE="$VARIABLE_TO_CHECK"

sleep 0.1
echo ''

if [[ "$CLEAN_SERVICES_CACHE" =~ ^(yes|y)$ ]]
then

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
"LSHandlerContentType           public.comma-separated-values-text          org.libreoffice.script"        # .csv
"LSHandlerContentType           org.oasis-open.opendocument.text            org.libreoffice.script"        # .odt
"LSHandlerContentType           public.shell-script                         com.coteditor.coteditor"        # .sh
"LSHandlerContentType           public.php-script                           com.coteditor.coteditor"        # .php
"LSHandlerContentType           public.css                                 com.coteditor.coteditor"        # .css
"LSHandlerContentTagClass       public.filename-extension                   com.coteditor.coteditor LSHandlerContentTag     conf"       # .conf
"LSHandlerContentType           com.adobe.pdf                               com.apple.preview"              # .pdf
"LSHandlerContentType           public.zip-archive                          cx.c3.theunarchiver"            # .zip
"LSHandlerContentType           org.gnu.gnu-zip-archive                     cx.c3.theunarchiver"            # .tar.gz
"LSHandlerContentType           org.7-zip.7-zip-archive                     cx.c3.theunarchiver"            # .7z
"LSHandlerContentType           public.tar-archive                          cx.c3.theunarchiver"            # .tar
"LSHandlerContentType           net.daringfireball.markdown                 com.uranusjr.macdown"           # .md
"LSHandlerContentTagClass       public.filename-extension                   com.apple.automator.unarchive_finder_input_gpg_progress     LSHandlerContentTag    gpg" # .gpg
"LSHandlerContentType           com.apple.property-list                     org.tempel.prefseditor"           # .plist
"LSHandlerContentType           public.mpeg-4                               com.colliderli.iina"           # .mp4
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

    function create_entry {
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
    #sudo touch /Applications/*
    #sleep 3
    killall Dock
    #killall Finder
    echo ''

else
    :
fi

echo "done ;)"
echo "the changes need a reboot to take effect..."
#echo "initializing reboot"
echo ""

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


