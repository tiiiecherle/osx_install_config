#!/bin/bash

SCRIPT_DIR=$(echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd)")
ICNS_NAME=brew_casks_update
PNG_NAME=brew

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