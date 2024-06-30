#!/bin/bash
set -eu

target_directory=$1

ln -sf /usr/src/nextcloud/* "$target_directory"

echo init-webroot-links finished
