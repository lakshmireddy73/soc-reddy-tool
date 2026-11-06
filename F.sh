#!/usr/bin/env bash 
if command -v chmod 2>/dev/null; then 
	sudo chmod +x ./F.sh 
fi

ORIGINAL=$(cat /sys/class/net/eth0/address)
echo "$ORIGINAL"
printf '02:%02X:%02X:%02X:%02X:%02X\n' \
$((RANDOM%256)) \
$((RANDOM%256)) \
$((RANDOM%256)) \
$((RANDOM%256)) \
$((RANDOM%256))
