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

# el capitan
#sudo open /System/Library/InternetAccounts/internetAccountsMigrator

# sierra
echo "deleting ~/Library/Accounts/Accounts3.sqlite*..."
rm ~/Library/Accounts/Accounts3.sqlite*

# rebuilding mail index on next run
echo "deleting files to rebuild the mailindex at next start of mail..."
if [ -e ~/Library/Mail/V3/MailData/ ]
then
	find ~/Library/Mail/V3/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm
	find ~/Library/Mail/V3/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm
else
	:
fi

if [ -e ~/Library/Mail/V4/MailData/ ]
then
	find ~/Library/Mail/V4/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm
	find ~/Library/Mail/V4/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm
else
	:
fi

echo "done"
