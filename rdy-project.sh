#!/usr/bin/env bash

# ============================================================
#                    RDY SSH MONITOR PRO
# ============================================================
# Author : @RDY73
# Platform : Linux
# Purpose : SSH Security / Incident Monitoring
# ============================================================

set -u

# ---------------- COLORS ----------------

RESET="\033[0m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
WHITE="\033[1;37m"
MAGENTA="\033[1;35m"

# ---------------- CONFIG ----------------

REPORT_DIR="$HOME/rdy-ssh-reports"
mkdir -p "$REPORT_DIR"

REPORT="$REPORT_DIR/rdy-report-$(date +%Y%m%d-%H%M%S).txt"

SSH_PORT=22

# ============================================================
# ROOT CHECK
# ============================================================

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[X] Please run as root:${RESET}"
    echo
    echo "    sudo $0"
    exit 1
fi

# ============================================================
# DEPENDENCY CHECK
# ============================================================

check_dependencies()
{
    local missing=()

    for cmd in ss awk grep sed ip journalctl last who ufw; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[X] Missing commands:${RESET}"
        printf '%s\n' "${missing[@]}"
        exit 1
    fi
}

# ============================================================
# LOG FUNCTION
# ============================================================

write_report()
{
    echo "$1" >> "$REPORT"
}

# ============================================================
# SSH SERVICE
# ============================================================

get_ssh_service()
{
    if systemctl is-active --quiet ssh 2>/dev/null; then
        echo "ssh"
        return
    fi

    if systemctl is-active --quiet sshd 2>/dev/null; then
        echo "sshd"
        return
    fi

    echo ""
}

SSH_SERVICE=$(get_ssh_service)

# ============================================================
# INTERFACES
# ============================================================

get_interfaces()
{
    ip -br addr |
    awk '$1 != "lo" && $2 == "UP" {
        printf "%s ", $1
    }'
}

INTERFACES=$(get_interfaces)

# ============================================================
# LOCAL IPs
# ============================================================

get_local_ips()
{
    ip -o -4 addr show |
    awk '$2 != "lo" {
        split($4,a,"/");
        print $2 " -> " a[1]
    }'
}

# ============================================================
# LIVE SSH CONNECTIONS
# ============================================================

get_live_ssh()
{
    ss -tnp 2>/dev/null |
    awk '
    $1 == "ESTAB" &&
    ($4 ~ /:22$/ || $5 ~ /:22$/)
    {
        print
    }'
}

# ============================================================
# SOURCE IP FROM LIVE SSH
# ============================================================

get_source_ips()
{
    ss -tn 2>/dev/null |
    awk '
    $1 == "ESTAB" &&
    ($4 ~ /:22$/ || $5 ~ /:22$/)
    {
        if ($4 ~ /:22$/)
            print $5
        else
            print $4
    }' |
    sed -E 's/^\[//;s/\]:[0-9]+$//;s/:[0-9]+$//' |
    sort -u
}

# ============================================================
# SUCCESSFUL SSH LOGINS
# ============================================================

get_success_logins()
{
    if [[ -n "$SSH_SERVICE" ]]; then

        journalctl -u "$SSH_SERVICE" \
            --since "24 hours ago" \
            --no-pager 2>/dev/null |
        grep -E \
        'Accepted (password|publickey|keyboard-interactive)' |
        tail -100

    elif [[ -f /var/log/auth.log ]]; then

        grep -E \
        'Accepted (password|publickey|keyboard-interactive)' \
        /var/log/auth.log |
        tail -100

    elif [[ -f /var/log/secure ]]; then

        grep -E \
        'Accepted (password|publickey|keyboard-interactive)' \
        /var/log/secure |
        tail -100
    fi
}

# ============================================================
# FAILED SSH LOGINS
# ============================================================

get_failed_logins()
{
    if [[ -n "$SSH_SERVICE" ]]; then

        journalctl -u "$SSH_SERVICE" \
            --since "24 hours ago" \
            --no-pager 2>/dev/null |
        grep -Ei \
        'Failed password|Invalid user|authentication failure' |
        tail -100

    elif [[ -f /var/log/auth.log ]]; then

        grep -Ei \
        'Failed password|Invalid user|authentication failure' \
        /var/log/auth.log |
        tail -100

    elif [[ -f /var/log/secure ]]; then

        grep -Ei \
        'Failed password|Invalid user|authentication failure' \
        /var/log/secure |
        tail -100
    fi
}

# ============================================================
# PARSE SUCCESSFUL LOGIN
# ============================================================

parse_success()
{
    get_success_logins |
    awk '
    {
        user="";
        ip="";
        auth="";

        for(i=1;i<=NF;i++)
        {
            if($i=="for")
                user=$(i+1);

            if($i=="from")
                ip=$(i+1);

            if($i=="password")
                auth="PASS";

            if($i=="publickey")
                auth="KEY";

            if($i=="keyboard-interactive")
                auth="KBD";
        }

        if(user!="" && ip!="")
        {
            time=$3;
            printf "%-8s %-12s %-17s %-7s %-8s\n",
                   time,user,ip,auth,"ACCEPT";
        }
    }'
}

# ============================================================
# PARSE FAILED LOGIN
# ============================================================

parse_failed()
{
    get_failed_logins |
    awk '
    {
        user="";
        ip="";
        auth="PASS";

        for(i=1;i<=NF;i++)
        {
            if($i=="for")
                user=$(i+1);

            if($i=="from")
                ip=$(i+1);
        }

        if(user=="")
            user="unknown";

        if(ip=="")
            ip="-";

        time=$3;

        printf "%-8s %-12s %-17s %-7s %-8s\n",
               time,user,ip,auth,"FAILED";
    }'
}

# ============================================================
# SOURCE IP SUMMARY
# ============================================================

source_summary()
{
    {
        get_success_logins
        get_failed_logins
    } |
    grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' |
    sort |
    uniq -c |
    sort -nr
}

# ============================================================
# FIREWALL STATUS
# ============================================================

firewall_status()
{
    ufw status verbose 2>/dev/null
}

# ============================================================
# AUTHORIZED KEYS
# ============================================================

authorized_keys()
{
    find /home /root \
        -type f \
        -name authorized_keys \
        -print 2>/dev/null
}

# ============================================================
# BANNER
# ============================================================

banner()
{
    clear

    echo -e "${CYAN}"
    cat <<'EOF'
╔════════════════════════════════════════════════════════════╗
║                  RDY SSH MONITOR PRO                      ║
╠════════════════════════════════════════════════════════════╣
║             SSH INCIDENT RESPONSE CONSOLE                 ║
║                    AUTHOR: @RDY73                          ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

# ============================================================
# DASHBOARD
# ============================================================

dashboard()
{
    banner

    local platform
    local status
    local iface
    local ssh_status

    platform="LINUX"

    if [[ -n "$SSH_SERVICE" ]]; then
        ssh_status="${GREEN}RUNNING${RESET}"
    else
        ssh_status="${RED}STOPPED${RESET}"
    fi

    iface=$(get_interfaces)

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET} PLATFORM       : ${GREEN}${platform}${RESET}"
    echo -e "${CYAN}║${RESET} INTERFACE      : ${GREEN}${iface:-unknown}${RESET}"
    echo -e "${CYAN}║${RESET} SSH PORT       : ${GREEN}${SSH_PORT}${RESET}"
    echo -e "${CYAN}║${RESET} SSH SERVICE    : ${ssh_status}"
    echo -e "${CYAN}║${RESET} STATUS         : ${GREEN}MONITORING${RESET}"
    echo -e "${CYAN}║${RESET} TIME           : ${GREEN}$(date '+%H:%M:%S')${RESET}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"

    echo -e "${CYAN}║${RESET} TIME     USER         SOURCE IP         AUTH    STATUS  ${CYAN}║${RESET}"

    local success
    local failed

    success=$(parse_success 2>/dev/null || true)
    failed=$(parse_failed 2>/dev/null || true)

    if [[ -n "$success" ]]; then
        echo "$success" | tail -8 |
        while read -r line; do
            echo -e "${CYAN}║${RESET} $line"
        done
    fi

    if [[ -n "$failed" ]]; then
        echo "$failed" | tail -5 |
        while read -r line; do
            echo -e "${CYAN}║${RESET} ${RED}$line${RESET}"
        done
    fi

    if [[ -z "$success" && -z "$failed" ]]; then
        echo -e "${CYAN}║${RESET} ${YELLOW}No SSH authentication events found${RESET}"
    fi

    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET} LAN/WLAN SOURCE TRACKING                                ${CYAN}║${RESET}"

    local ips

    ips=$(get_local_ips)

    if [[ -n "$ips" ]]; then

        while read -r line; do
            echo -e "${CYAN}║${RESET} ${GREEN}$line${RESET}"
        done <<< "$ips"

    else
        echo -e "${CYAN}║${RESET} ${YELLOW}No active interface found${RESET}"
    fi

    echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET} [1] LIVE SSH                                             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [2] LOGIN HISTORY                                        ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [3] FAILED LOGINS                                        ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [4] SOURCE IP                                            ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [5] USERS                                                 ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [6] LAN/WLAN                                             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [7] FIREWALL                                             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [8] EXPORT REPORT                                        ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [9] BLOCK SOURCE IP                                      ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET} [0] EXIT                                                 ${CYAN}║${RESET}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"

    echo
}

# ============================================================
# OPTION 1
# ============================================================

live_ssh()
{
    clear

    echo -e "${CYAN}========== LIVE SSH CONNECTIONS ==========${RESET}"
    echo

    local data
    data=$(get_live_ssh)

    if [[ -n "$data" ]]; then
        echo "$data"
    else
        echo -e "${YELLOW}No active SSH connections.${RESET}"
    fi

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 2
# ============================================================

login_history()
{
    clear

    echo -e "${CYAN}========== LOGIN HISTORY ==========${RESET}"
    echo

    last -ai | head -40

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 3
# ============================================================

failed_logins()
{
    clear

    echo -e "${RED}========== FAILED SSH LOGINS ==========${RESET}"
    echo

    local data
    data=$(get_failed_logins 2>/dev/null || true)

    if [[ -n "$data" ]]; then
        echo "$data"
    else
        echo -e "${GREEN}No failed SSH login events found.${RESET}"
    fi

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 4
# ============================================================

source_ips()
{
    clear

    echo -e "${CYAN}========== SOURCE IP SUMMARY ==========${RESET}"
    echo

    source_summary

    echo
    echo -e "${YELLOW}Active SSH source IPs:${RESET}"
    get_source_ips

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 5
# ============================================================

users()
{
    clear

    echo -e "${CYAN}========== CURRENT USERS ==========${RESET}"
    echo

    who -a

    echo
    echo -e "${CYAN}========== SYSTEM USERS ==========${RESET}"
    echo

    awk -F: '$3 >= 1000 || $1=="root" {
        printf "%-20s UID=%-6s HOME=%s\n",$1,$3,$6
    }' /etc/passwd

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 6
# ============================================================

lan_wlan()
{
    clear

    echo -e "${CYAN}========== LAN / WLAN ==========${RESET}"
    echo

    echo -e "${YELLOW}Interfaces:${RESET}"
    ip -br addr

    echo
    echo -e "${YELLOW}Routes:${RESET}"
    ip route

    echo
    echo -e "${YELLOW}Neighbor table:${RESET}"
    ip neigh

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 7
# ============================================================

firewall()
{
    clear

    echo -e "${CYAN}========== UFW FIREWALL ==========${RESET}"
    echo

    ufw status numbered

    echo
    ufw status verbose

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 8
# ============================================================

export_report()
{
    clear

    echo -e "${CYAN}========== EXPORTING REPORT ==========${RESET}"
    echo

    {
        echo "============================================================"
        echo "RDY SSH MONITOR PRO - INCIDENT REPORT"
        echo "============================================================"
        echo
        echo "HOST      : $(hostname)"
        echo "DATE      : $(date)"
        echo "KERNEL    : $(uname -r)"
        echo
        echo "========== INTERFACES =========="
        ip -br addr
        echo
        echo "========== LIVE SSH =========="
        get_live_ssh
        echo
        echo "========== SUCCESSFUL LOGINS =========="
        get_success_logins
        echo
        echo "========== FAILED LOGINS =========="
        get_failed_logins
        echo
        echo "========== LOGIN HISTORY =========="
        last -ai | head -50
        echo
        echo "========== CURRENT USERS =========="
        who -a
        echo
        echo "========== SOURCE IP SUMMARY =========="
        source_summary
        echo
        echo "========== AUTHORIZED KEYS =========="
        authorized_keys
        echo
        echo "========== LISTENING PORTS =========="
        ss -lntup
        echo
        echo "========== UFW =========="
        ufw status verbose
        echo
        echo "============================================================"
        echo "END REPORT"
        echo "============================================================"
    } > "$REPORT"

    echo -e "${GREEN}[OK] Report saved:${RESET}"
    echo
    echo "$REPORT"

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# OPTION 9 - BLOCK IP
# ============================================================

block_source()
{
    clear

    echo -e "${RED}========== BLOCK SSH SOURCE IP ==========${RESET}"
    echo
    echo "Active SSH source IPs:"
    echo

    get_source_ips

    echo

    read -r -p "Enter IP to block: " attacker_ip

    if [[ -z "$attacker_ip" ]]; then
        echo -e "${YELLOW}[!] No IP entered.${RESET}"
        sleep 2
        return
    fi

    # IPv4 format validation
    if [[ ! "$attacker_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo -e "${RED}[X] Invalid IPv4 address.${RESET}"
        sleep 2
        return
    fi

    echo
    echo -e "${YELLOW}You selected:${RESET} $attacker_ip"
    echo
    read -r -p "Block this IP from SSH using UFW? [y/N]: " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then

        ufw deny from "$attacker_ip" to any port 22 proto tcp

        echo
        echo -e "${GREEN}[OK] SSH access blocked for:${RESET} $attacker_ip"

        echo
        ufw status numbered

    else

        echo
        echo -e "${YELLOW}[!] No firewall change made.${RESET}"

    fi

    echo
    read -r -p "Press ENTER to continue..."
}

# ============================================================
# MENU LOOP
# ============================================================

menu()
{
    while true; do

        dashboard

        read -r -p " RDY-SSH > " option

        case "$option" in

            1)
                live_ssh
                ;;

            2)
                login_history
                ;;

            3)
                failed_logins
                ;;

            4)
                source_ips
                ;;

            5)
                users
                ;;

            6)
                lan_wlan
                ;;

            7)
                firewall
                ;;

            8)
                export_report
                ;;

            9)
                block_source
                ;;

            0)
                clear
                echo -e "${GREEN}RDY SSH MONITOR PRO stopped.${RESET}"
                exit 0
                ;;

            *)
                echo -e "${RED}[X] Invalid option.${RESET}"
                sleep 1
                ;;

        esac

    done
}

# ============================================================
# START
# ============================================================
check_dependencies
menu
