#!/usr/bin/env bash 

if command -v chmod 2>/dev/null 
then 
	sudo chmod +x check-ssh.sh 
fi

if [[ "$EUID" -ne 0 ]]
then 
	echo "Pleas run as a root!"
	exit 
fi

red=$(tput setaf 4)
green=$(tput setaf 5)
yellow=$(tput setaf 6)
reset=$(tput sgr0)

success="[+]"
failed="[-]"
install="[*]"
running="[!]"

file="/var/log/ssh-error.log"
log(){
	echo "$(date "+%Y-%m-%d %H:%S:%M") - $1" | sudo tee -a "$file"
}

log "${success}${red} Check the services running ssh ${reset}"
sleep 1

if sudo systemctl list-units --type service --state running 2>/dev/null 
then 
	log "${success}${green} ssh services not running ${reset}"
else 
	service --status-all
       log "${failed}${green} Failed to ssh services ${reset}"	
fi

log "${install}${yellow} Checking unknow ip address${reset}"
sudo ss -tupln | grep ':22'
netstat -an  | grep ssh 

log "${installl}${red} Found attacker ip address${reset}"
sleep 2 

log "${install}${green} Checking process running to ssh service ${reset}"
ps aux  | grep ssh 
kali=$(ps aux | awk '{ print $2 }' 2>/dev/null | grep ssh)

pkill -u "$kali"
log "${sucess} ${red} Firewall blocking attacker ip address ${reset}"
sudo ufw status verbose 

sudo ufw enable
ip=$(ip addr show eth0 | grep inet | tr -d ' ' -f 10)
sudo ufw deny from "$ip"

sudo ufw status numbered 
log "${install} ${yellow} Verify the process still nunning not! ${reset}"
sleep 1 

ps aux | grep ssh 

log "${install} ${red} Checking UFW logs ${reset}"
sudo journalctil -k -f
sudo journalctl -u ssh --since "24 hours ago" 

log "${install} ${red} checking last login username ${reset}" 

sudo last --fullnames --fulltimes 
loginctl session-status && loginctl 

log "${install} ${green} Complete!! ${reset}"





















