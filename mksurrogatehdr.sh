#!/bin/sh
# Taken from https://stackoverflow.com/questions/20889460/
sysdir="./system-headers"
for header in "$@"
do
    mkdir -p "$sysdir/$(dirname $header)"
    echo "include <$header>" > "$sysdir/$header"
done
