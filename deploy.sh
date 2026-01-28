#!/bin/sh
set -eux

DEST="D:/Documents/OpenTTD/ai/krakenai"

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r ./src *.nut "$DEST/"