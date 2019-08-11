#!/bin/zsh

### sierra
if [[ -e ~/Library/Accounts/Accounts3.sqlite ]]
then
	echo "deleting ~/Library/Accounts/Accounts3.sqlite*..."
	rm ~/Library/Accounts/Accounts3.sqlite*
else
	:
fi


### migrating internet accounts
echo ''
echo "starting internetAccountsMigrator..."
sudo open /System/Library/InternetAccounts/internetAccountsMigrator

echo ''
echo "done ;)"
echo ''