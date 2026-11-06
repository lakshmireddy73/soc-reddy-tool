#!/usr/bin/env bash 
if command -v chmod 2>/dev/null; then 
sudo chmod +x ./test.sh 
fi
echo "..........................."
ip -br link 
echo ".........................."
ip -br addr 
echo "......................."
ip addr 
ip route show 
echo ".................'
ping -c  3 google.com 
