#!/bin/bash
set -eu

target=$1
replace_example="$2"
replace_cidr="$3"

rm -rf "$target/*" || true
mkdir -p "$target"

sed_args=
for i in $replace_example; do
  sed_args="$sed_args -e s/$i/example/Ig"
done
for i in $replace_cidr; do
  sed_args="$sed_args -e s/$i/1.2.3.4/Ig"
done

for i in $(git ls-files | grep env/ --invert); do
    mkdir -p $(dirname "$target/$i")
    sed $sed_args "$i" > "$target/$i"
done
