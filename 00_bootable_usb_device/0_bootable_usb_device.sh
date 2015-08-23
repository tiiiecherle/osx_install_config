#!/bin/bash

# format usb drive with guid partition table
# format partition with OS X Extended (Journaled) and name it "Untitled" and leave it mounted
# download installer to /Applications/
# adjust installer name and run the following command in terminal and enter admin password

sudo /Applications/Install\ OS\ X\ 10.11\ Developer\ Beta.app/Contents/Resources/createinstallmedia --volume /Volumes/Untitled --applicationpath /Applications/Install\ OS\ X\ 10.11\ Developer\ Beta.app --nointeraction