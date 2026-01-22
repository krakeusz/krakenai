#!/bin/sh

DEST="D:/SteamLibrary/steamapps/common/OpenTTD/ai/krakenai"

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r ./* "$DEST/"