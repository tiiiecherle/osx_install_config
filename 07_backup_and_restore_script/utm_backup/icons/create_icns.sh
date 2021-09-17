#!/bin/zsh

###
### sourcing config file
###

if [[ -f ~/.shellscriptsrc ]]; then . ~/.shellscriptsrc; else echo '' && echo -e '\033[1;31mshell script config file not found...\033[0m\nplease install by running this command in the terminal...\n\n\033[1;34msh -c "$(curl -fsSL https://raw.githubusercontent.com/tiiiecherle/osx_install_config/master/_config_file/install_config_file.sh)"\033[0m\n' && exit 1; fi
eval "$(typeset -f env_get_shell_specific_variables)" && env_get_shell_specific_variables



###
### set icon
###

ICNS_NAME=utm_backup
PNG_NAME=macos_11_icon_utm_backup

# Force all images to sRGB with alpha
# brew install imagemagick
#mogrify -alpha on "$SCRIPT_DIR"/"$PNG_NAME".png
#convert "$SCRIPT_DIR"/"$PNG_NAME".png -colorspace srgb "$SCRIPT_DIR"/"$PNG_NAME".png
#sips -g all /Users/tom/Desktop/"$PNG_NAME".png

mkdir -p "$SCRIPT_DIR"/"$ICNS_NAME".iconset
sips -z 16 16 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_16x16.png
sips -z 32 32 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_16x16@2x.png
sips -z 32 32 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_32x32.png
sips -z 64 64 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_32x32@2x.png
sips -z 128 128 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_128x128.png
sips -z 256 256 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_128x128@2x.png
sips -z 256 256 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_256x256.png
sips -z 512 512 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_256x256@2x.png
sips -z 512 512 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_512x512.png
sips -z 1024 1024 "$SCRIPT_DIR"/"$PNG_NAME".png --out "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_512x512@2x.png
#cp "$SCRIPT_DIR"/"$PNG_NAME".png "$SCRIPT_DIR"/"$ICNS_NAME".iconset/icon_512x512@2x.png
iconutil --convert icns "$SCRIPT_DIR"/"$ICNS_NAME".iconset
sips -i "$SCRIPT_DIR"/"$ICNS_NAME".icns
rm -R "$SCRIPT_DIR"/"$ICNS_NAME".iconset
