#!/usr/bin/env bash 
if command -v chmod 2>/dev/null; then 
sudo chmod +x ./wifi.sh 
fi

if [[ "$EUID" -ne 0 ]]; then 
	echo "Please run as a root!" && exit 1 
fi

read -rp "Enter the target WI-FI: " test

if ip link set "$test" 2>/dev/null 2>&1 ; then  
	echo "found it "
else
	echo "not found"
	exit 1 
fi 
