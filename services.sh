#!/usr/bin/env bash

# ============================================================
#                 RDY SSH SECURITY MONITOR
# ============================================================
# Author : @RDY73
# Purpose: SSH login / source-IP incident triage
# Platform: Kali / Debian / Ubuntu
# ============================================================

set -u

# ---------------- COLORS ----------------

reset="\033[0m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
cyan="\033[1;36m"
blue="\033[1;34m"
white="\033[1;37m"

install="${cyan}[+]${reset}"
sucess="${green}[OK]${reset}"
warning="${yellow}[!]${reset}"
error="${red}[X]${reset}"

# ---------------- REQUIRE ROOT ----------------

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${red}[X] Run this tool as root:${reset}"
    echo "    sudo $0"
    exit 1
fi

# ---------------- FUNCTIONS ----------------

log()
{
    echo -e "$1"
}

pause()
{
    sleep 1
}

get_ssh_service()
{
    if systemctl is-active --quiet ssh 2>/dev/null; then
        echo "ssh"
    elif systemctl is-active --quiet sshd 2>/dev/null; then
        echo "sshd"
    else
        echo ""
    fi
}

# ============================================================
# BANNER
# ============================================================

clear

echo -e "${cyan}"
cat <<'EOF'
██████╗ ██████╗ ██╗   ██╗    ███████╗███████╗██╗  ██╗
██╔══██╗██╔══██╗╚██╗ ██╔╝    ██╔════╝██╔════╝██║  ██║
██████╔╝██║  ██║ ╚████╔╝     ███████╗███████╗███████║
██╔══██╗██║  ██║  ╚██╔╝      ╚════██║╚════██║██╔══██║
██████╔╝██████╔╝   ██║       ███████║███████║██║  ██║
╚═════╝ ╚═════╝    ╚═╝       ╚══════╝╚══════╝╚═╝  ╚═╝
EOF
echo -e "${reset}"

echo -e "${white}             SSH SECURITY MONITOR${reset}"
echo -e "${cyan}             AUTHOR: @RDY73${reset}"
echo

# ============================================================
# SYSTEM INFORMATION
# ============================================================

log "${install} ${yellow}Checking system information${reset}"

echo -e " Host       : ${green}$(hostname)${reset}"
echo -e " Date       : ${green}$(date)${reset}"
echo -e " Kernel     : ${green}$(uname -r)${reset}"

echo

# ============================================================
# NETWORK INTERFACES
# ============================================================

log "${install} ${yellow}Checking LAN / WLAN interfaces${reset}"

ip -br addr

echo

# ============================================================
# SSH SERVICE
# ============================================================

log "${install} ${yellow}Checking SSH service${reset}"

SSH_SERVICE=$(get_ssh_service)

if [[ -n "$SSH_SERVICE" ]]; then
    echo -e "${green}[OK] SSH service running: $SSH_SERVICE${reset}"
else
    echo -e "${red}[X] SSH service is not running${reset}"
fi

echo

# ============================================================
# LIVE SSH CONNECTIONS
# ============================================================

log "${install} ${yellow}Checking LIVE SSH connections${reset}"

LIVE_SSH=$(ss -tnp 2>/dev/null | grep -E ':[[:space:]]*22[[:space:]]|:22 ' || true)

if [[ -n "$LIVE_SSH" ]]; then

    echo -e "${green}"
    echo "$LIVE_SSH"
    echo -e "${reset}"

else

    echo -e "${yellow}[!] No active SSH connection found${reset}"

fi

echo

# ============================================================
# EXTRACT REMOTE IP FROM LIVE SSH
# ============================================================

log "${install} ${yellow}Finding remote SSH source IP${reset}"

REMOTE_IPS=$(ss -tn 2>/dev/null |
    awk '$1 == "ESTAB" && ($4 ~ /:22$/ || $5 ~ /:22$/) {
        if ($4 ~ /:22$/)
            print $5;
        else
            print $4;
    }' |
    sed -E 's/:[0-9]+$//' |
    sed 's/^\[//;s/\]$//' |
    sort -u)

if [[ -n "$REMOTE_IPS" ]]; then

    echo -e "${red}"
    echo "$REMOTE_IPS"
    echo -e "${reset}"

else

    echo -e "${yellow}[!] No live remote SSH IP detected${reset}"

fi

echo

# ============================================================
# SSH AUTHENTICATION LOG
# ============================================================

log "${install} ${yellow}Checking successful SSH logins${reset}"

if [[ -n "$SSH_SERVICE" ]]; then

    AUTH_EVENTS=$(journalctl -u "$SSH_SERVICE" \
        --since "24 hours ago" \
        --no-pager 2>/dev/null |
        grep -E 'Accepted (password|publickey|keyboard-interactive)' |
        tail -30 || true)

else

    AUTH_EVENTS=""

fi

if [[ -n "$AUTH_EVENTS" ]]; then

    echo -e "${green}"
    echo "$AUTH_EVENTS"
    echo -e "${reset}"

else

    echo -e "${yellow}[!] No successful SSH login events found${reset}"

fi

echo

# ============================================================
# USERNAME + SOURCE IP
# ============================================================

log "${install} ${yellow}Extracting SSH username + source IP${reset}"

if [[ -n "$AUTH_EVENTS" ]]; then

    echo "$AUTH_EVENTS" |
    awk '
    {
        user="";
        ip="";
        method="";

        for(i=1;i<=NF;i++)
        {
            if($i=="for")
                user=$(i+1);

            if($i=="from")
                ip=$(i+1);

            if($i=="password")
                method="password";

            if($i=="publickey")
                method="publickey";

            if($i=="keyboard-interactive")
                method="keyboard-interactive";
        }

        if(user!="" && ip!="")
            print "USER=" user "  IP=" ip "  AUTH=" method;
    }'

else

    echo -e "${yellow}[!] Nothing to extract${reset}"

fi

echo

# ============================================================
# FAILED SSH LOGINS
# ============================================================

log "${install} ${yellow}Checking failed SSH login attempts${reset}"

if [[ -n "$SSH_SERVICE" ]]; then

    FAILED=$(journalctl -u "$SSH_SERVICE" \
        --since "24 hours ago" \
        --no-pager 2>/dev/null |
        grep -Ei 'Failed password|Invalid user|authentication failure' |
        tail -30 || true)

else

    FAILED=""

fi

if [[ -n "$FAILED" ]]; then

    echo -e "${red}"
    echo "$FAILED"
    echo -e "${reset}"

else

    echo -e "${green}[OK] No failed SSH events found${reset}"

fi

echo

# ============================================================
# LAST LOGIN HISTORY
# ============================================================

log "${install} ${yellow}Checking login history${reset}"

last -ai | head -30

echo

# ============================================================
# CURRENT LOGGED-IN USERS
# ============================================================

log "${install} ${yellow}Checking current logged-in users${reset}"

who -a

echo

# ============================================================
# SSH PROCESSES
# ============================================================

log "${install} ${yellow}Checking SSH processes${reset}"

ps aux | grep '[s]sh'

echo

# ============================================================
# LISTENING SSH PORT
# ============================================================

log "${install} ${yellow}Checking SSH listening port${reset}"

ss -lntp 2>/dev/null | grep ':22' || \
echo -e "${yellow}[!] SSH port 22 is not listening${reset}"

echo

# ============================================================
# SSH AUTHORIZED KEYS
# ============================================================

log "${install} ${yellow}Checking authorized_keys files${reset}"

find /home /root \
    -type f \
    -name authorized_keys \
    -print 2>/dev/null

echo

# ============================================================
# UFW STATUS
# ============================================================

log "${install} ${yellow}Checking UFW firewall${reset}"

ufw status verbose

echo

# ============================================================
# INTERACTIVE BLOCK
# ============================================================

if [[ -n "$REMOTE_IPS" ]]; then

    echo -e "${red}================================================${reset}"
    echo -e "${red} ACTIVE REMOTE SSH SOURCE${reset}"
    echo -e "${red}================================================${reset}"

    echo "$REMOTE_IPS"

    echo

    read -r -p "Block these SSH source IP(s) with UFW? [y/N]: " answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then

        while read -r attacker_ip; do

            [[ -z "$attacker_ip" ]] && continue

            if [[ "$attacker_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then

                log "${install} ${yellow}Blocking SSH source: ${attacker_ip}${reset}"

                ufw deny from "$attacker_ip" to any port 22 proto tcp

                echo -e "${green}[OK] UFW rule added for ${attacker_ip}${reset}"

            else

                echo -e "${yellow}[!] Skipping non-IPv4 address: ${attacker_ip}${reset}"

            fi

        done <<< "$REMOTE_IPS"

        ufw status numbered

    else

        echo -e "${yellow}[!] No firewall rule changed${reset}"

    fi

else

    echo -e "${yellow}[!] No live SSH source IP available to block${reset}"

fi

echo

# ============================================================
# UFW LOGGING
# ============================================================

log "${install} ${yellow}Checking UFW logging${reset}"

ufw status verbose | grep -qi "Logging: on"

if [[ $? -eq 0 ]]; then
    echo -e "${green}[OK] UFW logging enabled${reset}"
else
    echo -e "${yellow}[!] UFW logging is OFF${reset}"

    read -r -p "Enable UFW logging? [y/N]: " ufwlog

    if [[ "$ufwlog" =~ ^[Yy]$ ]]; then
        ufw logging on
        echo -e "${green}[OK] UFW logging enabled${reset}"
    fi
fi

echo

# ============================================================
# UFW RECENT EVENTS
# ============================================================

log "${install} ${yellow}Checking recent UFW events${reset}"

if [[ -f /var/log/ufw.log ]]; then

    tail -30 /var/log/ufw.log

else

    journalctl -k --since "30 min ago" --no-pager 2>/dev/null |
        grep -i ufw |
        tail -30 || true

fi

echo

# ============================================================
# SSH JOURNAL
# ============================================================

log "${install} ${yellow}Checking SSH journal${reset}"

if [[ -n "$SSH_SERVICE" ]]; then

    journalctl -u "$SSH_SERVICE" \
        --since "30 minutes ago" \
        --no-pager |
        tail -50

fi

echo

# ============================================================
# COMPLETE
# ============================================================

echo -e "${green}"
echo "============================================================"
echo "                 RDY SSH CHECK COMPLETE"
echo "============================================================"
echo -e "${reset}"
