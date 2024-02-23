#!/bin/sh
# Taken from https://stackoverflow.com/questions/20889460/
grep -h -e '^[[:space:]]*#[[:space:]]*include[[:space:]]*<[^>]*>' -r "${@:-.}" |
sed 's/^[[:space:]]*#[[:space:]]*include[[:space:]]*<\([^>]*\)>.*/\1/' |
sort -u
