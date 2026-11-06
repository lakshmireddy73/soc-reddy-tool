printf '%-18s %s\n' "$(basename "$path")" "$(cat "$path/address" 2>/dev/null)"
        done
    else
        echo "Network interface information unavailable."
    fi
    echo "This module displays addresses only; it does not spoof or modify them."
}

generate_report() {
    local report
    report="${REPORT_DIR}/rdy-soc-report-$(date +%Y%m%d-%H%M%S).txt"
    {
        echo "$APP v$VERSION"
        echo "Developer: Lakshmi Reddy"
        echo "Generated: $(date)"
        echo "Host: $(hostname 2>/dev/null || echo unknown)"
        echo "OS: $(detect_os)"
        echo
        echo "===== SYSTEM ====="
        system_overview
        echo
        echo "===== NETWORK ====="
        network_overview
        echo
        echo "===== SSH SERVICE ====="
        ssh_overview
        echo
        echo "===== SUCCESSFUL SSH LOGINS ====="
        successful_ssh_logins
        echo
        echo "===== FAILED SSH LOGINS ====="
        failed_ssh_logins
        echo
        echo "===== SOURCE IP SUMMARY ====="
        source_ip_summary
        echo
        echo "===== USER AUDIT ====="
        user_audit
        echo
        echo "===== PROCESS AUDIT ====="
        process_audit
        echo
        echo "===== SERVICE AUDIT ====="
        service_audit
        echo
        echo "===== FIREWALL ====="
        firewall_audit
        echo
        echo "===== AUTHORIZED KEY INVENTORY ====="
        authorized_key_inventory
        echo
        echo "===== SECURITY EVENTS ====="
        security_events
        echo
        echo "===== MAC INVENTORY ====="
        mac_inventory
    } > "$report" 2>&1
    printf '\n%bReport saved:%b %s\n' "$C_GREEN" "$C_RESET" "$report"
}

menu() {
    while true; do
        show_banner
        cat <<'MENU'
 [1] System overview
 [2] Network interfaces, routes and connections
 [3] SSH service and live connections
 [4] Successful SSH logins
 [5] Failed SSH login attempts
 [6] SSH source IP event summary
 [7] User sessions and login history
 [8] Process audit
 [9] Running services
[10] Firewall status (read-only)
[11] Authorized SSH key file inventory
[12] Recent system warnings/errors
[13] MAC address inventory (read-only)
[14] Generate full SOC report
 [0] Exit
MENU
        line
        read -r -p "RDY-SOC > " choice || exit 0
        case "$choice" in
            1) system_overview; pause ;;
            2) network_overview; pause ;;
            3) ssh_overview; pause ;;
            4) successful_ssh_logins; pause ;;
            5) failed_ssh_logins; pause ;;
            6) source_ip_summary; pause ;;
            7) user_audit; pause ;;
            8) process_audit; pause ;;
            9) service_audit; pause ;;
            10) firewall_audit; pause ;;
            11) authorized_key_inventory; pause ;;
            12) security_events; pause ;;
            13) mac_inventory; pause ;;
            14) generate_report; pause ;;
            0) printf '%bGoodbye. Stay defensive.%b\n' "$C_GREEN" "$C_RESET"; exit 0 ;;
            *) printf '%bInvalid option.%b\n' "$C_RED" "$C_RESET"; sleep 1 ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    menu
fi