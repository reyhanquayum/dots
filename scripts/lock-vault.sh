#!/bin/bash

MOUNT_POINT="$HOME/.local/share/Cryptomator/mnt/recall-verbalize-burned"

# lazy unmount (detach even if busy)
fusermount3 -uz "$MOUNT_POINT"

