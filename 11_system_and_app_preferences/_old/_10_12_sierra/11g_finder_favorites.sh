#!/bin/zsh

# sfltool
# sfltool prepend|append|restore|archive|list-info|add [options]

# favorite servers for connect to
/usr/bin/sfltool add -n "smb://172.16.1.200" com.apple.LSSharedFileList.FavoriteServers "smb://172.16.1.200" && sleep 2
echo ''

echo 'done ;)'
