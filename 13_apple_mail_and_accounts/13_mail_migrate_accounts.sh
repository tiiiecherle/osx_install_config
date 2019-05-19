#!/usr/bin/env bash

# sierra
if [ -e ~/Library/Accounts/Accounts3.sqlite ]
then
	echo "deleting ~/Library/Accounts/Accounts3.sqlite*..."
	rm ~/Library/Accounts/Accounts3.sqlite*
else
	:
fi

# rebuilding mail index on next run
echo "deleting files to rebuild the mailindex at next start of mail..."

# el capitan
if [ -e ~/Library/Mail/V3/MailData/ ]
then
	###
	### in 10.11 apple moves all remaining accounts from
	### ~/Library/Mail/V2/MailData/Accounts.plist to
	### ~/Library/Accounts/Accounts3.sqlite
	### if you are doing a clean install of 10.11 to update from 10.10 you need to run this script to update accounts
	### be careful of the order of the steps to take for that (see separate file accounts_mail_calendar_contacts_el_capitan.txt)
	###
	
	# el capitan
	#sudo open /System/Library/InternetAccounts/internetAccountsMigrator

	find ~/Library/Mail/V3/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm
	find ~/Library/Mail/V3/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm
else
	:
fi

# sierra
if [ -e ~/Library/Mail/V4/MailData/ ]
then
	find ~/Library/Mail/V4/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm
	find ~/Library/Mail/V4/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm
else
	:
fi

# high sierra
if [ -e ~/Library/Mail/V5/MailData/ ]
then
	find ~/Library/Mail/V5/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm
	find ~/Library/Mail/V5/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm
else
	:
fi

# mojave
if [ -e ~/Library/Mail/V6/MailData/ ]
then
	find ~/Library/Mail/V6/MailData/ -type f -name "Envelope Index*" -print0 | xargs -0 rm
	find ~/Library/Mail/V6/MailData/ -type f -name "ExternalUpdates.*" -print0 | xargs -0 rm
else
	:
fi

echo ''
echo "done ;)"
echo ''