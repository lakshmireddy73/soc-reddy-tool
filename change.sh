#!/usr/bin/env bash 
if command -v chmod 2>/dev/null; then 
	sudo chmod +x ./change.sh 
fi

echo -e "\e[0;35m Select you wan to options:\e[0m"
echo -e "\e[0;37m1.Show MAC\e[0m"
echo -e "\e[0;34m2.Random MAC\e[0m"
echo -e "\e[0;33m3.Restore MAC\e[0m"
echo -e "\e[0;36m4.Custom\e[0m"
echo -e "\e[0;38m5.Exit\e[0m"

while true ; do 
	printf '%s\n' 'Choose yours options'
	read -p "Choice:" ch 
	case "$ch" in 
		1)
		       	read -rp "Enter the Ethernet: " ifname
			clear
			sudo macchanger -s  "$ifname" 
			;;
		2)      read -rp "Enter the Ethernet: " ifname
			clear
			sudo ip link set "$ifname" down 
			sudo macchanger -r "$ifname"
			sudo ip link set "$ifname" up 
			;;
		3)      read -rp "Enter the Ethernet: " ifname
			clear
			sudo ip link set "$ifname" down 
			sudo macchanger -p "$ifname"
			sudo ip link set "$ifname" up
			;;
		4)      read -rp "Enter the Ethernet: " ifname
			read -rp "Enter the MAC:" mac
			clear
	       		sudo ip link set "$ifname" down 
			sudo macchanger -m "$mac" "$ifname"
			sudo ip link set "$ifname" up 
			;;
		5)  exit 0
		       	;;
		*)	echo "Invalid Options"
			read -rp "Press enter to  return to  Home:" 
			;;
	esac
done 
