#!/usr/bin/env bash

# sfltool
# sfltool restore|add-item|save-lists|test|archive|enable-modern|dump-server-state|clear|disable-modern|dump-storage|list-info [options]

# favorite servers for connect to
/usr/bin/sfltool add-item -n "smb://172.16.1.200" com.apple.LSSharedFileList.FavoriteServers "smb://172.16.1.200" && sleep 2
echo ''

echo 'done ;)'