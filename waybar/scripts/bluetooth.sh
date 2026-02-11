#!/bin/bash

bluetooth_power_status() {
    bluetoothctl show | grep "Powered" | awk '{print $2}'
}

bluetooth_connected_devices() {
    bluetoothctl devices Connected | wc -l
}

bluetooth_paired_devices() {
    bluetoothctl devices Paired | awk '{print $2}'
}

bluetooth_toggle_power() {
    current_power=$(bluetooth_power_status)
    if [ "$current_power" == "yes" ]; then
        bluetoothctl power off
    else
        bluetoothctl power on
    fi
}

bluetooth_toggle_connection() {
    connected_count=$(bluetooth_connected_devices)
    if [ "$connected_count" -gt 0 ]; then
        # Disconnect all connected devices
        bluetoothctl devices Connected | awk '{print $2}' | while read -r device_mac; do
            bluetoothctl disconnect "$device_mac"
        done
    else
        # Attempt to connect to the first paired device
        first_paired_device=$(bluetooth_paired_devices | head -n 1)
        if [ -n "$first_paired_device" ]; then
            bluetoothctl connect "$first_paired_device"
        fi
    fi
}

case "$1" in
    --toggle-power)
        bluetooth_toggle_power
        ;; 
    --toggle-connection)
        bluetooth_toggle_connection
        ;; 
    *)
        power_status=$(bluetooth_power_status)
        connected_count=$(bluetooth_connected_devices)
        paired_count=$(bluetooth_paired_devices | wc -l)

        if [ "$power_status" == "yes" ]; then
            if [ "$connected_count" -gt 0 ]; then
                echo '{"text": "\uf294", "tooltip": "Bluetooth (Connected)", "class": "connected"}'
            elif [ "$paired_count" -gt 0 ]; then
                echo '{"text": "\uf293", "tooltip": "Bluetooth (On, Paired)", "class": "on"}'
            else
                echo '{"text": "\uf293", "tooltip": "Bluetooth (On, No Devices)", "class": "on"}'
            fi
        else
            echo '{"text": "\uf293", "tooltip": "Bluetooth (Off)", "class": "off"}'
        fi
        ;;
esac