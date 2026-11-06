#!/usr/bin/env bash

echo -e "\e[0;35mSelect an option:\e[0m"
echo -e "\e[0;37m1. Show MAC\e[0m"
echo -e "\e[0;34m2. Random MAC\e[0m"
echo -e "\e[0;33m3. Restore MAC\e[0m"
echo -e "\e[0;36m4. Custom MAC\e[0m"
echo -e "\e[0;38m5. Exit\e[0m"

while true; do
    printf '%s\n' 'Choose your option:'
    read -rp "Choice: " ch

    case "$ch" in
        1)
            read -rp "Enter the Ethernet interface: " ifname
            clear
            sudo macchanger --show "$ifname"
            ;;

        2)
            read -rp "Enter the Ethernet interface: " ifname
            clear
            sudo ip link set "$ifname" down
            sudo macchanger -r "$ifname"
            sudo ip link set "$ifname" up
            ;;

        3)
            read -rp "Enter the Ethernet interface: " ifname
            clear
            sudo ip link set "$ifname" down
            sudo macchanger -p "$ifname"
            sudo ip link set "$ifname" up
            ;;

        4)
            read -rp "Enter the Ethernet interface: " ifname
            read -rp "Enter the custom MAC address: " mac
            clear
            sudo ip link set "$ifname" down
            sudo macchanger -m "$mac" "$ifname"
            sudo ip link set "$ifname" up
            ;;

        5)
            exit 0
            ;;

        *)
            echo "Invalid option"
            read -rp "Press Enter to return to menu..."
            ;;
    esac
done
