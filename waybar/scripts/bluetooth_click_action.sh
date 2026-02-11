#!/bin/bash

BLUETOOTH_SCRIPT="/home/reyhan/.config/waybar/scripts/bluetooth.sh"

bluetooth_power_status() {
    bluetoothctl show | grep "Powered" | cut -d' ' -f2
}

bluetooth_connected_devices_macs() {
    bluetoothctl devices Connected | awk '{print $2}'
}

bluetooth_paired_devices_macs() {
    bluetoothctl devices Paired | awk '{print $2}'
}

current_power=$(bluetooth_power_status)

if [ "$current_power" == "yes" ]; then
    connected_macs=$(bluetooth_connected_devices_macs)
    if [ -n "$connected_macs" ]; then
        # Disconnect all connected devices
        echo "Disconnecting all connected Bluetooth devices..."
        echo "$connected_macs" | while read -r device_mac; do
            bluetoothctl disconnect "$device_mac"
        done
    else
        # No devices connected, try to connect to the first paired device
        paired_macs=$(bluetooth_paired_devices_macs)
        if [ -n "$paired_macs" ]; then
            first_paired_mac=$(echo "$paired_macs" | head -n 1)
            echo "Attempting to connect to $first_paired_mac..."
            # Add a small delay before attempting connection
            sleep 0.5
            bluetoothctl connect "$first_paired_mac"
        else
            echo "No paired Bluetooth devices found to connect."
        fi
    fi
else
    echo "Powering on Bluetooth..."
    bluetoothctl power on
fi