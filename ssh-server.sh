#!/usr/bin/env bash
if command -v chmod 2>/dev/null 
then 
	sudo chmod +x ssh-server.sh 
fi
if [[ "$EUID" -ne 0 ]] then 
	echo "Please run as a root!"
	exit 1
fi
set -u
INTERVAL=5
ROUNDS=6
OUT="/var/log/rdy-ssh-trace-$(date +%Y%m%d-%H%M%S).log"
C=$(tput setaf 3)
G=$(tput setaf 4)
R=$(tput setaf 5)
Y=$(tput setaf 6)
W=$(tput sgr0)
log() {
    echo -e "$*" | tee -a "$OUT"
}
clear
log "${C}"
log "============================================================"
log "                 RDY-SSH-TRACE"
log "             SSH INCIDENT TRIAGE"
log "============================================================"
log "${W}"
log "${Y}[+] Host:${W} $(hostname)"
log "${Y}[+] Time:${W} $(date)"
log "${Y}[+] Output:${W} $OUT"
log ""
if [[ -f /var/log/auth.log ]]; then
    AUTHLOG="/var/log/auth.log"
elif [[ -f /var/log/secure ]]; then
    AUTHLOG="/var/log/secure"
else
    AUTHLOG=""
fi
snapshot() {
    log ""
    log "${C}================ SSH CONNECTIONS ================${W}"
    ss -tnp 2>/dev/null |
        grep -E '(:22|ssh)' |
        tee -a "$OUT"
    log ""
    log "${C}================ SSH LOGINS =====================${W}"
    if [[ -n "$AUTHLOG" ]]; then
        grep -Ei \
        'Accepted (password|publickey|keyboard-interactive)|Failed password|Invalid user' \
        "$AUTHLOG" |
        tail -30 |
        tee -a "$OUT"
    else
        journalctl -u ssh -u sshd --no-pager -n 30 2>/dev/null |
        grep -Ei \
        'Accepted|Failed password|Invalid user' |
        tee -a "$OUT"
    fi
    log ""
    log "${C}================ USER/IP SUMMARY ===============${W}"

    if [[ -n "$AUTHLOG" ]]; then

        grep -Ei 'Accepted (password|publickey|keyboard-interactive)' "$AUTHLOG" |
        tail -100 |
        awk '
        {
            user="";
            ip="";

            for(i=1;i<=NF;i++) {
                if($i=="for")
                    user=$(i+1);

                if($i=="from")
                    ip=$(i+1);
            }

            if(user!="" && ip!="")
                print ip " -> " user;
        }' |
        sort | uniq -c | sort -nr |
        tee -a "$OUT"
    else
        journalctl -u ssh -u sshd --no-pager 2>/dev/null |
        grep 'Accepted' |
        tail -100 |
        awk '
        {
            user="";
            ip="";

            for(i=1;i<=NF;i++) {
                if($i=="for")
                    user=$(i+1);

                if($i=="from")
                    ip=$(i+1);
            }

            if(user!="" && ip!="")
                print ip " -> " user;
        }' |
        sort | uniq -c | sort -nr |
        tee -a "$OUT"
    fi
    log ""
    log "${C}================ CURRENT USERS =================${W}"
    who -a 2>/dev/null | tee -a "$OUT"
    log ""
    log "${C}================ SSH KEYS ======================${W}"
    find /home /root \
        -type f \
        -name authorized_keys \
        -print 2>/dev/null |
    while read -r keyfile; do
        log "${Y}[KEY]${W} $keyfile"
        grep -vE '^\s*#|^\s*$' "$keyfile" 2>/dev/null |
        tee -a "$OUT"
    done
    log ""
    log "${C}================ LISTENING PORTS ===============${W}"
    ss -lntup 2>/dev/null |
        tee -a "$OUT"
}
for ((i=1; i<=ROUNDS; i++)); do

    log ""
    log "${G}[SCAN $i/$ROUNDS] $(date '+%H:%M:%S')${W}"
    snapshot
    if (( i < ROUNDS )); then
        sleep "$INTERVAL"
    fi
done
log ""
log "${G}============================================================${W}"
log "${G} RDY-SSH-TRACE COMPLETE${W}"
log "${G} Evidence saved: $OUT${W}"
log "${G}============================================================${W}"
