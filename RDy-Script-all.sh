#!/usr/bin/env bash
if command -v chmod &> /dev/null; then
        sudo chmod +x ./process.sh
fi
# alternative using tput
# red=$(tput setaf 1) gree=$(tput setaf 2 ) reset=$(tput sgr0)
black="\033[30m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
magenta="\033[35m"
cyan="\033[36m"
white="\033[37m"
reset="\033[0m"
fast="[+]"
low="[-]"
second=0
minutes=0
hours=0
days=0
process=
while getopts :s:m:h:d:p: timed 2>/dev/null
do
        case $timed in
                s) second = $OPTARG ;;
                m) (( minutes = $OPTARG * 60  )) ;;
                h) (( hours = $OPTARG * 3600 )) ;;
                d) (( days = $OPTARG * 86400 )) ;;
                p) process = $OPTARG ;;
                \?) usage "${cyan}"
                        exit ;;
        esac
done
(( Total_seconds = seconds + minutes + hours + days ))
trap_exit(){
        break_out='Y'
        print -p $break_out
}
process_watch(){
        while :
        do
                read $break_out
                if [[ $break_out = 'Y' ]]; then
                        return 0
                fi
        done
}
sleep 2
echo -e "${red} $fast Start trap command! ${reset}"

trap 'trap_exit; exit 2'  1 2 3  15
Total_seconds=300
process_watch |&
PW_PID=$1
until (( $Total_seconds == 0 ))
do
        (( $Total_secondS = $Total_seconds - 1 ))
        sleep 1
done

break_out='Y'
print -p $break_out
kill $PW_PID
exit 0
sleep 2
echo "$fast successfull"
--------------------------------------------------------------------
2)
#!/usr/bin/env bash
if command -v chmod 2>/dev/null ; then
        sudo chmod +x ./output.sh
fi
func(){
        while read line;
        do
                echo "$line"
                :
        done < $filename
}
func-line(){
        exec 3<&0
        exec 0< $filename
        while read line ;
        do
                echo "$line"
                :
        done
        exec 0<&3
}

---------------------------------------------------
3) 

#!/usr/bin/env bash
if command -v chmod &> /dev/null; then
        sudo chmod +x ./test.sh
fi
first="[+]"
second="[-]"
test -d /usr/local/bin
if [ "$?" -eq 0 ]; then
        echo ""$first" /usr/local/bin does  exit "
else
        echo ""$second" /usr/local/bin/ doesn't exit."
fi
sleep 2
echo "Second process"
if test -d /usr/local/bin ; then
        echo ""$first" /usr/local/bin/ does exist."
else
        echo ""$second" /usr/local/bin/ doesn't exist."
fi
sleep 2
echo "thrid process"
if [ -d /usr/local/bin ]; then
        echo ""$first" /usr/local/bin does exist."
else
        echo ""$second" /usr/local/bin/ doesn't exist."
fi

4)
#!/usr/bin/env bash
if command -v chmod 2>/dev/null; then
        sudo chmod +x ./first.sh
fi
file="/var/log/file.log"
file_log(){
        echo "$(date "+%Y:%m:%d %H-%M-%S" )" - "$1" | sudo tee -a "$file"
}
file_log "Files"
sleep 2
find /etc -type f -print0 | while read -r -d ''
do
        file_log "=== Processing: ==="
        log_file $( printf '"%p" "%f" "%g" "%u" "%s" "%M" "%TY-%Tm-%Td"' )
        file_log "Done..."
done

5)

###############################################################################
#                                                                             #
#   Project     : Linux System Installer                                      #
#   Author      : @RDY77333                                                   #
#   Version     : 1.0                                                         #
#   Description : Automated package installation and system configuration     #
#   Platform    : Debian | RHEL | Arch Linux                                  #
#   Shell       : Bash                                                        #
#                                                                             #
#   Features:                                                                 #
#     - OS detection                                                          #
#     - Multi package-manager support                                         #
#     - Package installation                                                  #
#     - Service management                                                    #
#     - Installation verification                                             #
#     - Logging                                                               #
#                                                                             #
###############################################################################

set -Eeuo pipefail

if command -v chmod >/dev/null 2>&1
then
        sudo chmod +x ./tools.sh
fi

if [[ "$EUID" -ne 0 ]];
then
        echo "Please run as a root!"
        exit
fi

RESET=$(tput sgr0)
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

_banner(){
cat <<'EOF'

                ██████╗ ██████╗ ██╗   ██╗    ███████╗ ██████╗ ██████╗  ██████╗ ███████╗
                ██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝
                ██████╔╝██║  ██║ ╚████╔╝     █████╗  ██║   ██║██████╔╝██║  ███╗█████╗
                ██╔══██╗██║  ██║  ╚██╔╝      ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝
                ██║  ██║██████╔╝   ██║       ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
                ╚═╝  ╚═╝╚═════╝    ╚═╝       ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
                        Linux Infrastructure Automation Framework
                                Created by @RDY77333
EOF
}
log="/var/log/error.log"
_console(){
        echo "$(date "+%Y-%m-%d %M%H%S") -$1" | sudo tee -a "$log"
}
if ! command -v tee >/dev/null 2>&1;
then
        _console "[!]${BLUE}Already installed:${RESET}"

if ! command -v curl >/dev/null 2>&1; then
    _console "[+]${RED}Installing curl...${RESET}"
    sudo apt update
    sudo apt install -y curl
else
    _console "[-]${BLUE}curl is already installed.${RESET}"
fi
        sudo apt install tee -y
        exit 1
fi
package=( tlp snap nginx sysstat btop htop strace tshark hping3 openssh-server nmap masscan rustscan netdiscover arp-scan zmap \
                wireshark tshark tcpdump dumpcap termshark nagios zabbix prometheus grafana cacti icinga librenms ntopng dnstop delv fping \
                iperf3 netperf nuttcp smokeping mtr ping traceroute tracepath mtr ss netstat ip ethtool route arp dig nslookup host dnsperf \
                curl wget httpie hping3 siege apachebench ab nc netcat socat ncat telnet iftop nload bmon vnstat iptraf-ng nethogs nfdump \
                flow-tools pmacct softflowd aircrack-ng airodump-ng aireplay-ng iw wavemon kismet nftables iptables ufw firewall-cmd \
                conntrack sync borgbackup restic rclone sleuthkit autopsy foremost scalpel binwalk top htop btop atop  ps \
                pstree pidstat pgrep perf sysstat strace ltrace valgrind flamegraph volatility3 rekall avml lime memprocfs ftrace perf crash kgdb \
                kdumpiotop duf ncdu du df smartctl hdparm inotify-tools lsof fuser auditd journalctl rsyslog logwatch logrotate multitail suricata \
                snort zeek ossec wazuh yara radare2 ghidra capa sleuthkit autopsy foremost scalpel binwalk docker podman containerd crictl kubectl \
                kubeadm helm k9s qemu kvm virt-manager virsh lxc rsync borgbackup restic rclone testdisk photorec extundelete gpg  openssl \
                cryptsetup apt yum dnf pacman zypper ansible puppet chef salt tmux screen vim nano ripgrep fd lshw lscpu lsblk lspci lsusb  \
                dmidecode memtest86+ stress-ng lm-sensors mysql-client psql redis-cli mongosh git gcc make cmake gdb openvpn wireguard-tools \
                strontrgswan tailscale sar vmstat iostat dstat glances nmon  uptime
        )
_checkOS(){
        source /etc/os-release
        case "$ID" in
                ubuntu|debian|linuxmint|kali|zorin)
                        _console "${RED}Debian-based${RESET}"
                        ;;
                rhel|fedora|centos|rocky|almalinux)
                        _console "${BLUE}RHEL-based${RESET}"
                        ;;
                arch|manjaro|endeavouros)
                        console "${GREEN}Arch-based${RESET}"
                        ;;
                *)
                        echo "Unsupported distribution: $ID"
                        exit 1
                        ;;
        esac
}
_installer(){
        _console "${RED} Please select(1-3):${RESET}"
        printf  "${GREEN}1.Install Debian-based: ${RESET}\n"
        printf  "${CYAN}2.Install Rhel-based: ${RESET}\n"
        printf  "${BLUE}3.Install Arch-based: ${RESET}\n"
        printf  "${RED}4.Exit ${RESET}\n"
        read -rp "Select three options:" choice
        case "$choice" in
                1)
                        for setup in "${package[@]}"
                        do
                                if dpkg -s "$setup" >/dev/null 2>&1;
                                then
                                        _console "${CYAN} already installed ${RESET}"
                                else
                                        sudo apt-get update || sudo apt-get upgrade -y
                                        sudo nala install "$setup" || sudo apt install "$setup"
                                       if ! command -v snap >/dev/null 2>&1
                                       then
                                               sudo snap install "$setup"
                                               exit 1
                                       fi
                                fi
                        done
                        ;;
                2)
                        for setup in "${package[@]}";
                        do
                                if rpm -q "$setup" >/dev/null 2>&1; then
                                        _console "[+]${RED}$setup already installed${RESET}"
                                else
                                        sudo dnf install -y "$setup"
                                fi
                        done
                        ;;
                3)
                        for setup in "${package[@]}";
                        do
                                if pacman -Qi "${setup}" >/dev/null 2>&1; then
                                        _console "[*]${CYAN}${setup} already installed ${RESET}"
                                else
                                        pacman -Sy --noconfirm "${setup}"
                                fi
                        done
                        ;;
                4)
                        read -rp "Invalid options Please try new one: " choice
                        exit ;;
                *)
                        echo "'[-]${BLACK}Invalid option.${RESET}" ;;
        esac
}
service=("${package[@]}")
_test-service(){
    for s in "${service[@]}"
    do
        if command -v systemctl >/dev/null 2>&1;
        then
                _console "[+]${RED}Starting service: $s ${RESET}"
        if systemctl list-unit-files | grep -q "^${service}.service";
        then
            if systemctl enable --now "$s"; then
                _console "[+]${RED}$s is running ${RESET}"
            else
                _console "[+]${BLUE}Restarting $s ${RESET}"
                systemctl restart "$s"
            fi
        fi
        else
                 _console "[+]${CYAN}systemctl not available. Skipping $s ${RESET}"
        fi
        done
}
setup_install(){
        _console "[+]${RED}Installed tools:${RESET}"
        _console "----------------"
        for tool in "${package[@]}"; do
                if command -v "$tool" >/dev/null 2>&1; then
                        printf "%-15s : Installed (%s)\n" "$tool" "$(command -v "$tool")"
                else
                        printf "%-15s : Not Installed\n" "$tool"
                fi
        done
}
process_(){
        for s in $(systemctl list-unit-files --type=service --no-legend | awk '{print $1}');
        do
                _console "[+]${GREEN}Checking $s ${RESET}"
                sudo systemctl is-active "$s"
        done
}
_main(){
        _console "[*]${BLUE}Installing packages...${RESET}"
        sleep 1
        _console "[+] Installing" || [ command -v sysvbanner ] && sudo apt install  sysvbanner

        _banner
        _checkOS
        _installer
        _test-service
        setup_install
        process_
        _console "[*]${RED}Complete!! ${RESET}"
}
_main
6)
#!/usr/bin/env bash
if command -chmod 2> /dev/null; then
        chmod +x ./first-02.sh
fi

'
E_WRONG=85
PARAMETERS="-a -m -h -z"
if [[  $#  !=   $PARAMETERS ]]; then
        echo "Usage: `basename $0` $PARAMETERS"
        exit $E_WRONG
fi
batcat first-01.sh

initial=( ` cat "first-01.sh" | sed '/#/d' | tr -d '\n' | sed -e 's/\./\. /g' -e 's/_/_  /g' `)
echo "$initial"

if [ -x "$filename" ]; then
        echo "File already exits."
       if  [ `touch`   "$filename" ]  &&  [ `mkdir`  "$filename" ]; then
              cp "$filename"  "$filename.bak"
      else
            touch  "$filename"
       fi
else
        echo "File not found"
fi
echo "File test Completed!"
'

file="filename.txt"

if [ -e "$file" ]; then
        echo "File already exits."

        if [ ! -s "$file" ]; then
                find ~mint/script -type f -name "file"  -exec bash  -c 'echo "hello,world" > "$1"' _  {} \;
               #find ~mint/script -type f -name "file" -exec bash -c 'echo "hi" > "$0"' _ {} /?
                #find ~mint/script -type f -name "file" -exec bash -c 'echo "hi"  | sudo tee -a  "$1"  > /dev/null' _ {}
                #find ~mint/script -type f -name "file" -print0  |xargs -0 -I{} sh -c 'echo "hie" > "{ }"'
        echo "not empty.."
        fi
        if [ -f "$file" ]; then
                cp "$fil" "$file.bak" && echo "check the backup file."
        else
                echo "Not regular file Skip.."
        fi

else
        echo "File not found Creating file..."
        touch "$file" && echo "File is created."
fi
7)
#!/usr/bin/env bash
if command -v chmod 2>/dev/null
then
        sudo chmod +x ./backup_script.sh
fi

#Author: RDY
#Date created: 12/8/2026
#last Modifier: 12/8/2026

echo "Hello there, ${USER}"
echo "I will now back u your name  directory, $HOME"
currentdir=$(pwd)
echo "I will create save the backup file in  $currentdir"

tar -cf  "$currentdir/my_backup_$(date +%Y-%m-%d_%H-%M-%S).tar" $HOME  2>/dev/null
echo "Backup completed successfully"
exit 0
8)
#!/usr/bin/env bash
if command -v chmod 2>/dev/null ; then
        sudo chmod +x ./service.sh
fi

if [[ "$EUID" -ne 0 ]] then
        printf "\rPlease run as a root!\n"
        exit 1
        if [[ $? -eq 0 ]]; then
                printf "\rSucessfully\n"
        else
                printf "\rNot successfully\n"
        fi
fi

red=$(tput bold; tput setaf 1)
green=$(tput bold; tput setaf 2)
yellow=$(tput bold; tput setaf 3)
cyan=$(tput bold; tput setaf 4)
blue=$(tput bold; tput setaf 5)
white=$(tput bold; tput setaf 7)
reset=$(tput sgr0)

install="${cyan}[+]${reset}"
sucess="${green}[OK]${reset}"
warning="${yellow}[!]${reset}"
error="${red}[X]${reset}"

log(){
        echo -e "$1"
}
pause(){
        sleep 1
}

get_ssh_service()
{
        if systemctl is-active --quite ssh 2>/dev/null; then
               echo "ssh"
        elif systemctl is-active --quite sshd 2>/dev/null; then
               echo "sshd"
        else
                echo ""
        fi
}
clear
echo -e "${cyan}"
cat <<'EOF'
____  ______   __  ____ ____  _   _
|  _ \|  _ \ \ / / / ___/ ___|| | | |
| |_) | | | \ V /  \___ \___ \| |_| |
|  _ <| |_| || |    ___) |__) |  _  |
|_| \_\____/ |_|   |____/____/|_| |_|
EOF
echo -e "${reset}"
echo -e "${white}"
echo -e "${cyan}"
echo

log "${install} ${yellow}Checking system information${reset}"
echo -e " Host   : ${green}$(hostname)${reset}"
echo -e " Date   : ${green}$(date)${reset}"
echo -e " kernal : ${green}$(uname -r)${reset}"
echo
log "${install} ${yellow}Checking LAN / WLAN interfaces${reset}"
ip -br addr
echo
log "${install} ${yellow} Checking ssh services${reset}"
ssh_service=$(get_ssh_service)
if [[ -n "$ssh_service" ]]; then
        echo -e "${green}[OK] SSh service running: $ssh_service${reset}"
else
        echo -e "${red}[X]  SSh service is not running${reset}"
fi
echo
log "${install} ${yellow} Checking LIVE SSH Connections${reset}"
live_ssh=$(ss -tnp 2>/dev/null  |grep -E ':[[:space:]]*22[[:space:]]:22' || true)
if [[ -n  "$live_ssh" ]]; then
        echo -e "${green}"
        echo "$live_ssh"
        echo -e "${reset}"
else
        echo -e "${yellow}[!] No active  SSH Connection found${reset}"
fi
echo
log "${install} ${yellow}Finding remote  SSH service IP${reset}"
remote_ip=$(ss -tn 2>/dev/null |
        awk '$1 == "ESTAB" &&  ($4 ~ /:22$/ ||  $5 ~ /:22$/){
                if ($4 ~ /:22$/)
                        print $5;
                else
                        print $4;
                }' |
                sed -E 's/:[0-9]+$//' |
                sed 's/^\[//;s/\$//' | sort -u )
if [[ -n "$remote_ip" ]]; then
        echo -e "${red}"
        echo "$remote_ip"
        echo -e "${reset}"
else
        echo -e "${yellow}[!] No live remote  SSH IP detected${reset}"
fi
echo
log "${install} ${yellow} Checking successfully SSH logins${reset}"
if [[ -n "$ssh_service" ]]; then
        auth_events=$(journalctl  -u "$ssh_service" \
                --since "24 hours ago" \
                --no-page 2>/dev/null  |
                grep -E 'Accepted (password|publickey|keyboard-interactive)' |  tail -30 || true )
else
        auth_events=""
fi
if [[ -n "$auth_events" ]]; then
        echo -e "${green}"
        echo "$auth_events"
        echo -e "${reset}"
else
        echo -e "${yellow}[!] No successfully SSH login events found${reset}"
fi
echo
log "${insatll} ${yellow} Extracing SSH username + source IP${reset}"
if [[ -n "$auth_events" ]]; then
        echo "$auth_events" |
                awk '
        {
                user="";
                ip="";
                method="";
                for(i=1; i<=NF; i++)
                {
                        if($i=="for")
                                user=$(i+1);
                        if($i=="from")
                                ip=$(i+1);
                        if($i=="password")
                                method="password";
                        if($i=="publikey")
                                method="publikey";
                        if($i=="keyboard-interactive")
                                method="keyboard-interactive";
                }
        if (user!="" && ip!="")
                print "USER=" user "  IP=" ip " auth=" method;
        }'
else
        echo -e "${yellow}[!] Nothing to extract${reset}"
fi
echo
log "${install} ${yellow} Checking failed SSH  login attempts${reset}"
if [[ -n "$ssh_service" ]]; then
        failed=$(journalctl -u "$ssh_service" \
                --since "24 hours ago" \
                --no-page 2>/dev/null | grep -Ei 'Failed password|Invalid user|authentication failure' |
                tail -30 || true )
else
        failed=""
fi
if [[ -n "$failed" ]]; then
        echo -e "${red}"
        echo "$failed"
        echo -e "${reset}"
else
        echo -e "${green}[OK] No failed  SSH events found${reset}"
fi
echo
log "${install} ${yellow}Checking login history${reset}"
last -ai  |head -30
echo
log "${install} ${yellow}Checking current logged-in user${reset}"
ps aux | grep '[s]sh'
echo
log "${install} ${yellow} Chekcing SSH listening port${reset}"
ss -lntp 2>/dev/null | grep ':22' || \
        echo -e  "${yellow}[!] SSH port  22 is not  listening${reset}"
echo
log "${install} ${yellow}Chekcing authorized_keys files${reset}"
find /home/ /root  \
        -type f -name authorized_keys -print 2>/dev/null
echo
log "${install} ${yellow} Checking UFW  firewall${reset}"
sudo ufw status verbose
echo
if [[ -n "$remote_ip" ]]; then
        echo -e "${red}==============================================${reset}"
        echo -e "${red} ACTIVE REMOTE SSH  SOURCE${reset}"
        echo -e "${red}===============================================${reset}"
        echo "$remote_ip"
        echo
        read -rp "Block these SSH source  IP(s) with UFW? [y/N]: " target
        if [[ "$target" =~ ^[Yy] ]]; then
                while read -r attacker_ip ;
                do
                        if [[ -z "$attacker_ip" ]]; then
                                continue
                        fi
                        if [[ "$attacker_ip"  =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]];
                        then
                               log "${install} ${yellow}Blocking SSH source: ${attacker_ip}${reset}"
                                sudo ufw deny from "$attacker_ip" to any port 22  proto  tcp
                                echo -e "${green}[OK] UFW rule added  for ${attacker_ip}${reset}"
                        else
                                echo -e "${yellow}[!] Skipping non-Ipv4 address: ${attacker_ip}${reset}"
                        fi
                done <<< "$remote_ip"
                sudo ufw status numbered
        else
                echo -e "${yellow}[!]No  firewall rule  chanaged${reset}"
        fi
else
        echo -e "${yellow}[!] No live SSH source IP  available to block${reset}"
fi
echo
log "${install} ${yellow}Checking UFW  logging${reset}"
sudo ufw status verbose  |grep -qi "Logging:  on"
if [[ $? -eq 0 ]]; then
        echo -e "${green}[OK] UFW logging enabled${reset}"
else
        echo -e "${yellow}[!] UFW logging is OFF${reset}"
        read -rp "Enable UFW logging? [y/N]:" logs
        if [[ "$logs" =~ ^[Yy]$ ]];
        then
                sudo ufw loggin on
                echo -e "${green}[OK] UFW logging enabled${reset}"
        fi
fi
echo
log "${install} ${yellow} Checking recent UFW  journal${reset}"
if [[ -n "$ssh_service" ]]; then
        journalctl -u "$ssh_service" --since "30 hours ago" --no-page  |tail -30
fi
echo
echo -e "${green}"
echo "==============================================="
echo "                  RDY SSH COMPLETED"
echo "==============================================="
echo -e "${reset}"
9)
#!/usr/bin/env bash
if command -v chmod 2>/dev/null
then
        sudo chmod +x ./tests.sh
fi
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please run as root!"
    exit 1
    if [[ $? -eq 0 ]]
    then
            ...
    fi
fi
echo "--------------------------------------------------------"
echo "[+] Checking required commands..."
if ! command -v journalctl >/dev/null 2>&1 || \
   ! command -v awk >/dev/null 2>&1
then
    echo "[!] Required command is not installed."
    exit 1
fi
echo "[+] Required commands are available."
echo "--------------------------------------------------------"
echo "[+] Finding IP addresses in SSH authentication logs..."
journalctl -u ssh --since "24 hours ago" --no-pager |
awk '
/Failed password|Invalid user/ {
    for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            print $i
        }
    }
}' |
sort -u
echo "--------------------------------------------------------"
echo "[+] Counting suspicious IP addresses..."
journalctl -u ssh --since "24 hours ago" --no-pager |
awk '
/Failed password|Invalid user/ {
    for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
            count[$i]++
        }
    }
}
END {
    for (ip in count) {
        print ip, count[ip]
    }
}' |
sort -k2,2nr
echo "--------------------------------------------------------"
echo "[+] Done."

11)
#!/usr/bin/env bash

file="/var/log/message.log"
cat << "EOF"
  ____                       _ _           _   _           _       _
 / ___|  ___  ___ _   _ _ __(_) |_ _   _  | | | |_ __   __| | __ _| |_ ___
 \___ \ / _ \/ __| | | | '__| | __| | | | | | | | '_ \ / _\` |/ _\` | __/ _ \
  ___) |  __/ (__| |_| | |  | | |_| |_| | | |_| | |_) | (_| | (_| | ||  __/
 |____/ \___|\___|\__,_|_|  |_|\__|\__, |  \___/| .__/ \__,_|\__,_|\__\___|
                                   |___/        |_|
EOF

log_message(){
        echo "$(date "+%Y-%m-%d %H:%M:%S") - $1"  | sudo tee -a "$file"
}

if [[ "$UID" -ne 0 ]]; then
        log_message "Please run as root!"
        exit 1
fi

if command -v chmod 2> /dev/null; then
        log_message "Permission allowing..."
        sudo chmod +x ./install.sh
else
        log_message "Not allowing permission."
fi

package_install=( openssh-server openssh-client \
        nginx lsd duf htop btop iftop sysstat ncat nala snapd snap \
        samba-ad-dc apache2 net-tools nmap wireshark  \
        tshark nikto firewalld figlet lolcat toilet \
        nmap tcpdump iftop nethogs net-tools iproute2 \
        dnsutils traceroute mtr curl wget netcat-openbsd \
        whois wireshark tshark iperf3 ethtool
)
install(){
        for install in "${package_install[@]}" ;
        do
                if command -v apt-get &> /dev/null; then
                        log_message "Already updated packages..."
                        sudo apt-get update && sudo apt upgrade -y
                        sudo apt install "$install"
                else
                        log_message "Not Please try again."
                fi

        done
}
start_service=("ssh" "samb" "nginx" "sysstat" "snapd")
service(){
        if ! systemctl  "$start_service" &> /dev/null; then
                if systemctl enable --now  "$start_service" && systemctl restart "$start_service"  2> /dev/null; then
                        log_message "Service starting......."
                else
                        log_message "Not found services."
                fi
        fi

}
main(){
        log_message "Update packages....."
        install
        service
        log_message "Completed..."
}
main
12)
#!/usr/bin/env bash
testing="/var/log/message_log.log"
message_error(){
        echo "$( date  "+%Y-%m-%d %H:%S:%M") -  $1" | sudo tee -a "$testing"
}

if [ "$UID" -ne 0 ]; then
        message_error "please run as root."
        exit 1
fi
if command -v chmod &> /dev/null; then
        message_error "Allowing the permission..."
        sudo chmod +x ./test.sh
else
        message_error "Not allowing permission..."
fi
cat << "EOF"

  __  __       _                          ____                       _ _
 |  \/  | __ _| |_      ____ _ _ __ ___  / ___|  ___  ___ _   _ _ __(_) |_ _   _
 | |\/| |/ _` | \ \ /\ / / _` | '__/ _ \ \___ \ / _ \/ __| | | | '__| | __| | | |
 | |  | | (_| | |\ V  V / (_| | | |  __/  ___) |  __/ (__| |_| | |  | | |_| |_| |
 |_|  |_|\__,_|_| \_/\_/ \__,_|_|  \___| |____/ \___|\___|\__,_|_|  |_|\__|\__, |
                                                                           |___/

                                                Write By @RDY73.
EOF

echo "-----------------------------------------------------------------------------------"

install=( chkrootkit rkhunter clamav )
for test in "${install[@]}" ; do
        if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt install "$test"
        else
                message_error "Not found the command."
        fi
done
echo -e "\e[37 Choose your want to used to \e[0m"
echo -e "\e[33m 1.Rootkit \e[0m"
echo -e "\e[34m 2.Rkhunter \e[0m"
echo -e "\e[35m 3.Malware \e[0m"
echo -e "\e[36m 4.Exit"
read -p "Enter the numbers:" username
case "$username" in
        1)
                sudo chkrootkit
                ;;
        2)
                sudo rkhunter --check
                ;;
        3)
                sudo clamscan -r /
                sudo clamscan --freshcalm
                ;;
        4)
                exit ;;
        *)
                printf "Invalid option\n"
                read -p "Please again try:"
                ;;
esac
printf "Completed......\n"
13) 
#!/bin/bash
echo "=== $$: Processing Files ==="
for file in "$@";
do
        echo -e "\tProcessing: $file"
done
4)
cdls
clearclear
clear
15)
#!/usr/bin/env bash
if command -v chmod >/dev/null 3>&1;
then
        sudo chmod +x ./first.sh
fi

printf "\rHello,world!\n"
world_big=big

printf "\rThe kernal is $(uname -r)\n"
printf "\rThe basename $(( basename ))\n"
printf "\rThe whomai $(who -w)\n"
echo ""
echo -n "No,newline"
printf "\r Part of $world\n"
printf "\r-----------------------------------------------------\n"

myvar="Hello,world!"
printf "\rThe value of the myvar $myvar\n"
myvar="suck"
printf "\rMyvar: $myvar\n"

declare -r mynmae="Scoot"
printf "\rThe value of the $myvar\n"
declare -l lovestring="this is scring"
printf "\rHello,wrold $lovescring\n"
lovestring="let's Change ro variable"
printf "\r[+] $lovestring\n"


16)
#!/usr/bin/env bash
if command -v chmod >/dev/null 2>&1
then
        sudo chmod +x ./detect_script.sh
fi

ifconfig | grep "broadcast" | cut -d " " -f 10 | cut -d "." -f 1,2,3|uniq > out.txt
test=$(cat out.txt)
echo "" > $test.txt
for ip in {1..254}
do
        ping -c 1 "$test.$ip"| grep "64 bytes"| cut -d " " -f 4| tr -d ":" >> $test.txt &
done
cat "$test.txt"  | sort > sort_$test.txt
nmap -sS --top-ports 20 -iL sort_$test.txt
18)

#!/usr/bin/env bash

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
reset=$(tput sgr0 )

echo -e "[*] ${red}Networking IP sweeping Decteted Local Networking${reset}"
sleep 1
if command -v chmod >/dev/null 2>&1
then
        sudo chmod +x ./ip.sh
fi
if [[ "$EUID" -ne 0 ]]
then
        echo "[+] ${red}Please run as a root!${reset}"
        exit 1
fi
for cmd in ip ping nmap; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[-] ${yellow} Error: $cmd is not installed.${reset}"
        exit 1
    fi
done
read -rp "Enter the targetIP: " network
network=$(ip -4 addr show | awk '/inet / && $2 !~ /^127/ {print $2}' | head -n1 | cut -d'/' -f1 | cut -d'.' -f1-3)

if [ -z "$network" ]; then
    echo "[-] ${green}Could not determine local network.${reset}"
    exit 1
fi
echo "[+] ${red}Scanning network${reset}: $network.0/24"
hosts_file="${network}.txt"
sorted_file="sort_${network}.txt"
> "$hosts_file"
for ip in {1..254}; do
(
    if ping -c 1 -W 1 "${network}.${ip}" >/dev/null 2>&1; then
        echo "${network}.${ip}"
    fi
) >> "$hosts_file" &
done
wait
sort -u "$hosts_file" > "$sorted_file"
echo "[!] ${red}Live hosts:${reset}"
cat "$sorted_file"
echo
echo "[+] ${yellow}Running Nmap scan...${reset}"
sudo nmap -sS --top-ports 20 -iL "$sorted_file" \ ||
        sudo nmap -sS -iL "$sorted_file" -T4

10)
#!/usr/bin/env bash
if command -v chmod >/dev/null 2>&1
then
        sudo chmod +x ./ip_sweeping.sh
fi
if [[ "$EUID" -ne 0 ]];
then
        echo "Please run as a root!"
        exit 1
fi

echo -e "[+] IP Sweeping:"
for ip in {1..254}
do
        ping -c1  172.20.42.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" &
done
echo -e "[!] Complete scripting..."
clea















