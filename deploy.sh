#!/bin/sh

DEST="D:/Program Files/OpenTTD/ai/krakenai"

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r ./* "$DEST/"