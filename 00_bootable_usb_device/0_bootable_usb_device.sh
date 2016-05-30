#!/bin/bash

# format usb drive with guid partition table
# format partition with OS X Extended (Journaled) and name it "Untitled" and leave it mounted
# download installer to some directory and put the POSIX path in the variable
# adjust installer path and name and run the following command in terminal and enter admin password

INSTALLERPATH="/Applications/Install OS X El Capitan.app"
VOLUMEPATH="/Volumes/Untitled"

sudo "$INSTALLERPATH"/Contents/Resources/createinstallmedia --volume "$VOLUMEPATH" --applicationpath "$INSTALLERPATH" --nointeraction