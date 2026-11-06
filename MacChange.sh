#!/usr/bin/env bash 
if command -v chmod 2>/dev/null; then 
sudo chmod +x ./MacChange.sh
fi

echo "--------------------------------------------"
batcat /sys/class/net/eth0/address 
echo 00:15:5d:7e:04:62
original=00:15:5d:7e:04:62
echo "$original"
printf '02:%02X:%02X:%02X:%02X:%02X\n'
$((RANDOM%256))
$((RANDOM%256))
$((RANDOM%256))
$((RANDOM%256))
$((RANDOM%256))


