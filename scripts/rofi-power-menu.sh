#!/bin/bash

chosen=$(printf "  Power Off\n  Restart\n  Sleep\n  Lock\n  Log Out" | rofi -dmenu -i -p "Power Menu" \
  -kb-row-down j \
  -kb-row-up k \
  -theme /home/reyhan/.config/rofi/powermenu.rasi)

case "$chosen" in
    "  Power Off") systemctl poweroff ;;
    "  Restart") systemctl reboot ;;
    "  Sleep") systemctl suspend ;;
    "  Lock") ~/.config/scripts/lock.sh ;;
    "  Log Out") loginctl terminate-session $XDG_SESSION_ID ;;
esac
