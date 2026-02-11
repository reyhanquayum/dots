#!/bin/bash
swaylock -f -i ~/Pictures/nord_mountains_blurred.png --scaling fill --indicator-idle-visible --inside-color 00000000 --text-color 00000000 --ring-color 00ff00 --indicator-radius 100
pkill -f swayosd-libinput-backend
swayosd-server &
