#!/bin/bash

# clears the dock of all apps, then adds your individual dock config
# config file:
# ~/Library/Preferences/com.apple.dock.plist

# for readability and ease of use
DEF_W="/usr/bin/defaults write"
PLB=/usr/libexec/PlistBuddy
OSA=/usr/bin/osascript

DOCK="com.apple.dock"

# rein in some wooly XML
APP_HEAD="<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>"
APP_TAIL="</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"

function set_dock_apps () {

    $DEF_W $DOCK 'checked-for-launchpad' -bool true
  
    # clear the dock of existing apps
    $DEF_W $DOCK 'persistent-apps' -array ''
    $DEF_W $DOCK 'persistent-others' -array ''
 
    # add some apps

    $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Safari.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Mail.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Contacts.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Calendar.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Messages.app/$APP_TAIL"
 
#    $DEF_W $DOCK 'persistent-apps' \
#    -array-add "$APP_HEAD/Applications/Facetime.app/$APP_TAIL"
 
    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/iTunes.app/$APP_TAIL"
 
    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Preview.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/MonKey Office 2016.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Pages.app/$APP_TAIL"

### office 2016

#    $DEF_W $DOCK 'persistent-apps' \
#    -array-add "$APP_HEAD/Applications/Microsoft Word.app/$APP_TAIL"

#    $DEF_W $DOCK 'persistent-apps' \
#    -array-add "$APP_HEAD/Applications/Microsoft PowerPoint.app/$APP_TAIL"

#    $DEF_W $DOCK 'persistent-apps' \
#    -array-add "$APP_HEAD/Applications/Microsoft Excel.app/$APP_TAIL"

### office 2011

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Microsoft Office 2011/Microsoft Word.app/$APP_TAIL"

#    $DEF_W $DOCK 'persistent-apps' \
#    -array-add "$APP_HEAD/Applications/Microsoft Office 2011/Microsoft PowerPoint.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/Microsoft Office 2011/Microsoft Excel.app/$APP_TAIL"

###

    $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

    $DEF_W $DOCK 'persistent-apps' \
    -array-add "$APP_HEAD/Applications/System Preferences.app/$APP_TAIL"

    $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

  # add a spacer
  # $DEF_W $DOCK 'persistent-apps' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'
  # $DEF_W $DOCK 'persistent-others' -array-add '{ tile-data = {}; tile-type = "spacer-tile"; }'

  # rein in some wooly XML
  FOLDER_HEAD="<dict><key>tile-data</key><dict><key>arrangement</key><integer>0</integer><key>displayas</key><integer>1</integer><key>file-data</key><dict><key>_CFURLString</key><string>"
  FOLDER_TAIL="</string><key>_CFURLStringType</key><integer>0</integer></dict><key>preferreditemsize</key><integer>-1</integer><key>showas</key><integer>3</integer></dict><key>tile-type</key><string>directory-tile</string></dict>"

  # Add some folders
  #$DEF_W $DOCK 'persistent-others' -array-add "$FOLDER_HEAD/Applications$FOLDER_TAIL"
  #$DEF_W $DOCK 'persistent-others' -array-add "$FOLDER_HEAD/Applications/Utilities$FOLDER_TAIL"
  #$DEF_W $DOCK 'persistent-others' -array-add "$FOLDER_HEAD$HOME/Documents$FOLDER_TAIL"

  $OSA -e 'tell application "Dock" to quit'

}

set_dock_apps