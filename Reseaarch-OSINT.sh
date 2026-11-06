#!/usr/bin/env bash
# ============================================================
#  Developer: @RDY7733
# ============================================================

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; DIM='\033[2m'; BOLD='\033[1m'; RESET='\033[0m'

if command -v chmod 2>&1 >/dev/null; then 
	sudo chmod +x ./RDY-OSINT.sh 
fi

if (( $EUID != 0 )); then 
	printf '\rPlease run as a root!\n' && exit 1
	if (( $? == 0 )); then 
		printf '\rExecutable is successfully\n'
	else 
		printf '\rExecutable is failer\n'
	fi	
fi

clear_screen() { printf '\033[2J\033[H'; }

loading_animation() {
    local msg="${1:-Processing}" duration="${2:-1}"
    local spin='◐◓◑◒' i=0
    local end=$((SECONDS + duration))
    while (( SECONDS < end )); do
        printf "\r${CYAN}  %s %s${RESET}" "${spin:i++%4:1}" "$msg"
        sleep 0.1
    done
    printf "\r\033[K"
}

create_header() {
    clear_screen
    echo -e "${RED}${BOLD}"
    cat <<'BANNER'
 ██████╗ ███████╗██╗███╗   ██╗████████╗      ██████╗ ██████╗ ██╗   ██╗
██╔═══██╗██╔════╝██║████╗  ██║╚══██╔══╝      ██╔══██╗██╔══██╗╚██╗ ██╔╝
██║   ██║███████╗██║██╔██╗ ██║   ██║         ██████╔╝██║  ██║ ╚████╔╝
██║   ██║╚════██║██║██║╚██╗██║   ██║         ██╔══██╗██║  ██║  ╚██╔╝
╚██████╔╝███████║██║██║ ╚████║   ██║         ██║  ██║██████╔╝   ██║
 ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝         ╚═╝  ╚═╝╚═════╝    ╚═╝
BANNER
    echo -e "${RESET}"
    echo -e "  ${YELLOW}${BOLD}📱 ADVANCED PHONE INFORMATION TOOL${RESET}   ${DIM}·   👨‍💻 @RDY7733${RESET}"
    echo
}
json_keys() {
    if command -v jq >/dev/null 2>&1; then
        echo "$1" | jq -r 'keys[]' 2>/dev/null
    else
        echo "$1" | python3 -c "
import sys, json
try:
    for k in json.load(sys.stdin): print(k)
except Exception: pass"
    fi
}

json_get() {
    local json="$1" key="$2"
    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null
    else
        echo "$json" | python3 -c "
import sys, json
try:
    v = json.load(sys.stdin).get('$key', '')
    print(v if v is not None else '')
except Exception: pass"
    fi
}

truncate() { local s="$1"; (( ${#s} > 45 )) && echo "${s:0:42}..." || echo "$s"; }

fetch_phone_info() {
    curl -s --max-time 10 "https://api-calltracer-eternal.vercel.app/api?number=$1" 2>/dev/null
}

# ---------- Offline logic ----------
carrier_from_prefix() {
    local n="$1"
    case "$n" in
        6*)  echo "Jio";;
        7*)  echo "Airtel/Jio/Vi";;
        8*|9*) echo "Airtel/Vi/Jio";;
        *)   echo "Unknown";;
    esac
}

validate_phone_number() {
    local clean="${1#+91}"
    if [[ "$clean" =~ ^[0-9]{10}$ ]]; then
        CLEAN_PHONE="$clean"; FULL_PHONE="+91${clean}"; return 0
    fi
    return 1
}

# ---------- Row renderer ----------
# row <label> <value> <color>
row() {
    printf "   ${DIM}├─${RESET} ${CYAN}%-22s${RESET} ${DIM}▸${RESET} ${3}%s${RESET}\n" "$1" "$2"
}

show_results() {
    local phone="$1" api_json="$2"

    # ---- Phone card ----
    echo -e "  ${GREEN}╭───────────────────────────────────────────────────────╮${RESET}"
    echo -e "  ${GREEN}│${RESET}  📞  ${WHITE}${BOLD}${phone}${RESET}"
    echo -e "  ${GREEN}╰───────────────────────────────────────────────────────╯${RESET}"
    echo

    # ---- Online card ----
    if [[ -n "$api_json" && "$api_json" != "null" ]]; then
        echo -e "  ${CYAN}${BOLD}🌐 ONLINE DATA${RESET}"
        echo -e "  ${CYAN}╭───────────────────────────────────────────────────────╮${RESET}"
        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            local val color="${WHITE}"
            val="$(truncate "$(json_get "$api_json" "$key")")"
            case "$key" in
                "Owner Personality") color="${MAGENTA}";;
                "Owner Name")        [[ ${#val} -gt 3 ]] && val="🔒 PRIVATE"; color="${RED}";;
                "Complaints")        color="${YELLOW}";;
                "Connection")        color="${GREEN}";;
                "SIM card")          color="${BLUE}";;
                "Mobile State")      color="${MAGENTA}";;
                "Country")           color="${CYAN}";;
                "Tower Locations"|"Mobile Locations"|"Owner Address")
                                     color="${DIM}${WHITE}";;
            esac
            printf "   ${DIM}│${RESET} ${CYAN}%-22s${RESET} ${DIM}▸${RESET} ${color}%s${RESET}\n" "$key" "$val"
        done < <(json_keys "$api_json" | sort)
        echo -e "  ${CYAN}╰───────────────────────────────────────────────────────╯${RESET}"
        echo
    fi

    # ---- Offline card ----
    local carrier; carrier="$(carrier_from_prefix "$CLEAN_PHONE")"
    echo -e "  ${MAGENTA}${BOLD}📡 OFFLINE DATA${RESET}"
    echo -e "  ${MAGENTA}╭───────────────────────────────────────────────────────╮${RESET}"
    row "🌍 Country"         "India"                 "$WHITE"
    row "📍 Region"          "IN"                    "$WHITE"
    row "📱 Carrier"         "$carrier"              "$BLUE"
    row "🕐 Timezone"        "Asia/Calcutta"         "$WHITE"
    row "📊 Number Type"     "Mobile"                "$WHITE"
    row "✅ Valid Number"    "✔ Yes"                 "$GREEN"
    row "🔢 Possible Number" "✔ Yes"                 "$GREEN"
    row "📋 E164"            "+91${CLEAN_PHONE}"     "$DIM"
    row "📋 International"   "+91 ${CLEAN_PHONE:0:5} ${CLEAN_PHONE:5:5}"  "$DIM"
    row "📋 National"        "0${CLEAN_PHONE:0:5} ${CLEAN_PHONE:5:5}"     "$DIM"
    row "📋 RFC3966"         "tel:+91-${CLEAN_PHONE}"                     "$DIM"
    echo -e "  ${MAGENTA}╰───────────────────────────────────────────────────────╯${RESET}"
    echo

    # ---- Footer ----
    echo -e "  ${DIM}╾───────────────────────────────────────────────────────╼${RESET}"
    echo -e "  ${DIM}⏱  $(date '+%d %b %Y · %H:%M:%S')   ·   @RDY7733${RESET}"
    echo -e "  ${DIM}╾───────────────────────────────────────────────────────╼${RESET}"
}

process_phone_number() {
    local phone="$1"
    if ! validate_phone_number "$phone"; then
        echo -e "  ${RED}✖ Invalid number! Enter a valid Indian number (10 digits).${RESET}"
        return 1
    fi

    echo -e "  ${CYAN}◌ Connecting to server...${RESET}"
    local api_data
    api_data="$(fetch_phone_info "$CLEAN_PHONE")"
    loading_animation "Cracking the database" 1

    clear_screen
    create_header
    show_results "$FULL_PHONE" "$api_data"
}

main() {
    trap 'echo; echo -e "  ${YELLOW}⏹ Interrupted. Goodbye!${RESET}"; exit 0' INT

    command -v curl >/dev/null 2>&1 || { echo -e "${RED}✖ Missing: curl${RESET}"; exit 1; }
    command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 || \
        { echo -e "${RED}✖ Need jq or python3 for JSON.${RESET}"; exit 1; }

    while true; do
        create_header
        echo -e "  ${DIM}Format: 10 digits or +91XXXXXXXXXX   ·   'q' to exit${RESET}"
        echo
        read -rp $'  \033[1;36m❯\033[0m \033[1;33mNumber:\033[0m ' phone

        [[ "${phone,,}" == "q" ]] && { echo -e "\n  ${GREEN}✔ Done. Bye!${RESET}"; exit 0; }

        process_phone_number "$phone"

        echo
        read -rp $'  \033[1;36m↻ Search another? [y/N]\033[0m: ' again
        if [[ ! "${again,,}" =~ ^(y|yes)$ ]]; then
            echo -e "\n  ${GREEN}✔ Done. Bye!${RESET}"; exit 0
        fi
    done
}

main "$@"
