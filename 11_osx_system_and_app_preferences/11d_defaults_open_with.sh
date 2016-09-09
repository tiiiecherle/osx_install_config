#!/usr/bin/env bash


# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 300; kill -0 "$$" || exit; done 2>/dev/null &


# credit to
# http://superuser.com/questions/273756/how-to-change-default-app-for-all-files-of-particular-file-type-through-terminal
#
# brew install duti
# read
# duti -x html
# write
# duti -s com.apple.Safari html all
#
# defaults read com.apple.LaunchServices/com.apple.launchservices.secure | grep -B 1 -A 3 public.html
#
# open /Users/$USER/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist

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
"LSHandlerContentType           public.comma-separated-values-text          org.openoffice.script"          # .csv
"LSHandlerContentType           public.shell-script                         com.coteditor.coteditor"        # .sh
"LSHandlerContentTagClass       public.filename-extension                   com.coteditor.coteditor     LSHandlerContentTag     conf"       # .conf
"LSHandlerContentType           com.adobe.pdf                               com.apple.preview"              # .pdf
"LSHandlerContentType           public.zip-archive                          cx.c3.theunarchiver"            # .zip
"LSHandlerContentType           org.gnu.gnu-zip-archive                     cx.c3.theunarchiver"            # .tar.gz
"LSHandlerContentType           org.7-zip.7-zip-archive                     cx.c3.theunarchiver"            # .7z
"LSHandlerContentType           public.tar-archive                          cx.c3.theunarchiver"            # .tar
)

# libreoffice instead of openoffice
#"LSHandlerContentType           public.comma-separated-values-text          org.libreoffice.script"        # .csv


echo ""

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
            $BUDDY -c "Add LSHandlers:$I dict" $PLIST
            $BUDDY -c "Add LSHandlers:$I:$KEY string $VALUE" $PLIST
            $BUDDY -c "Add LSHandlers:$I:LSHandlerRoleAll string $HANDLER" $PLIST
            if [[ "$KEY2" != "" ]] && [[ "$VALUE2" != "" ]]
            then
                $BUDDY -c "Add LSHandlers:$I:$KEY2 string $VALUE2" $PLIST
            else
                :
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

echo "done ;)"
echo "the changes need a reboot to take effect..."
#echo "initializing reboot"
echo ""

#osascript -e 'tell app "loginwindow" to «event aevtrrst»'       # reboot
#osascript -e 'tell app "loginwindow" to «event aevtrsdn»'       # shutdown
#osascript -e 'tell app "loginwindow" to «event aevtrlgo»'       # logout


