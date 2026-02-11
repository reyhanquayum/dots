#!/bin/bash

VAULT_PATH="/home/reyhan/gdrive/recall-verbalize-burned"
MOUNT_POINT="$HOME/.local/share/Cryptomator/mnt/recall-verbalize-burned"
MOUNTER="org.cryptomator.frontend.fuse.mount.LinuxFuseMountProvider"

mkdir -p "$MOUNT_POINT"

read -s -p "Enter vault password: " VAULT_PASS
echo

printf "%s" "$VAULT_PASS" | cryptomator-cli unlock \
  --password:stdin \
  --mountPoint="$MOUNT_POINT" \
  --mounter="$MOUNTER" \
  "$VAULT_PATH" &

unset VAULT_PASS

