#!/bin/bash


SCRIPT_DIR=$(echo "$(cd "${BASH_SOURCE[0]%/*}" && pwd)")

find "$SCRIPT_DIR" -mindepth 1 ! -path "*/*.app/*" -name "*.app" -print0 | xargs -0 xattr -dr com.apple.quarantine

#xattr -dr com.apple.quarantine path/to/the/copied/app
###
