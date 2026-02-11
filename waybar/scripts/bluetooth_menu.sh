#!/bin/bash

BLUETOOTH_SCRIPT="/home/reyhan/.config/waybar/scripts/bluetooth.sh"
ROFI_CMD="fuzzel --dmenu --prompt \"Bluetooth: \""

# Function to get Bluetooth power status
get_power_status() {
    bluetoothctl show | grep "Powered" | cut -d' ' -f2
}

# Function to get paired devices
get_paired_devices() {
    bluetoothctl devices Paired | while read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | awk '{print $3}')
        if [ -n "$mac" ]; then
            info=$(bluetoothctl info "$mac" 2>/dev/null)
            connected=$(echo "$info" | grep "Connected: yes")
            if [ -n "$connected" ]; then
                echo "$name ($mac) [Connected]"
            else
                echo "$name ($mac) [Paired]"
            fi
        fi
    done
}

# Main menu logic
main_menu() {
    power_status=$(get_power_status)
    menu_options=""

    if [ "$power_status" == "yes" ]; then
        menu_options+="Toggle Bluetooth Off\n"
        paired_devices=$(get_paired_devices)
        if [ -n "$paired_devices" ]; then
            menu_options+="$paired_devices\n"
        fi
        # Optionally add scan for new devices, but it's slow
        # menu_options+="Scan for new devices\n"
    else
        menu_options+="Toggle Bluetooth On\n"
    fi

    selection=$(echo -e "$menu_options" | $ROFI_CMD)

    if [ -z "$selection" ]; then
        exit 0 # User cancelled
    elif [[ "$selection" == "Toggle Bluetooth On" ]]; then
        bluetoothctl power on
    elif [[ "$selection" == "Toggle Bluetooth Off" ]]; then
        bluetoothctl power off
    elif [[ "$selection" == *"[Connected]"* ]]; then
        mac=$(echo "$selection" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
        if [ -n "$mac" ]; then
            bluetoothctl disconnect "$mac"
        fi
    elif [[ "$selection" == *"[Paired]"* ]]; then
        mac=$(echo "$selection" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
        if [ -n "$mac" ]; then
            bluetoothctl connect "$mac"
        fi
    fi
}

main_menu
