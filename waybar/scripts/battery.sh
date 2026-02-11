#!/bin/bash

battery_info=$(upower -i $(upower -e | grep 'battery'))
percentage=$(echo "$battery_info" | grep "percentage" | awk '{print $2}' | sed 's/%//')
state=$(echo "$battery_info" | grep "state" | awk '{print $2}')
time_to_empty=$(echo "$battery_info" | grep "time to empty" | awk '{print $4, $5}')
time_to_full=$(echo "$battery_info" | grep "time to full" | awk '{print $4, $5}')

icon=""
tooltip_text=""

if [[ "$state" == "charging" ]]; then
    icon="" # Charging icon (lightning bolt)
    tooltip_text="Charging: $time_to_full"
elif [[ "$state" == "fully-charged" ]]; then
    icon="" # Full battery icon
    tooltip_text="Fully Charged"
else
    if (( percentage > 90 )); then
        icon=""
    elif (( percentage > 75 )); then
        icon=""
    elif (( percentage > 50 )); then
        icon=""
    elif (( percentage > 25 )); then
        icon=""
    else
        icon="" # Empty battery icon
    fi
    tooltip_text="Discharging: $time_to_empty"
fi

json_output="{\"text\": \"$icon $percentage%\", \"tooltip\": \"$tooltip_text\"}"
echo "$json_output"