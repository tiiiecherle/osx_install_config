#!/usr/bin/env bash


# asking for the administrator password upfront
sudo -v

# keep-alive: update existing 'sudo' time stamp until script is finished
while true; do sudo -n true; sleep 300; kill -0 "$$" || exit; done 2>/dev/null &

# sfltool
# sfltool restore|add-item|save-lists|test|archive|enable-modern|dump-server-state|clear|disable-modern|dump-storage|list-info [options]

# favorite servers for connect to
/usr/bin/sfltool add-item -n "smb://172.16.1.200" com.apple.LSSharedFileList.FavoriteServers "smb://172.16.1.200" && sleep 2
echo ''

echo 'done ;)'