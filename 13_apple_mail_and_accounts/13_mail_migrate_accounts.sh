#!/usr/bin/env bash

# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


###
### in 10.11 apple moves all remaining accounts from
### ~/Library/Mail/V2/MailData/Accounts.plist to
### ~/Library/Accounts/Accounts3.sqlite
### if you are doing a clean install of 10.11 to update from 10.10 you need to run this script to update accounts
### be careful of the order of the steps to take for that (see separate file)
###

# run the file with the scritp or by double clicking
sudo open /System/Library/InternetAccounts/internetAccountsMigrator

echo "done"
