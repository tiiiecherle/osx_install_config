#!/bin/bash

SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

"$SCRIPT_DIR"/bash/install.sh
wait

echo ''
echo "done ;)"
echo ''

