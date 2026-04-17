
#!/bin/bash
# =============================================================================
#                           Software Audit system
# =============================================================================
# Script Name  : software_audit.sh
# Description  : Software Audit Module — Collects detailed OS & software info
# Author(s)    : ABABSA Zakaria & KARA Abdelbasset
# School       : National Higher School of Cyber Security (NSCS)
# Date         : 2026
# Version      : 1.0
# Usage        : sudo bash software_audit.sh [--short | --full | --menu]
# =============================================================================
source "$HOME/NSCS_Audit_project/config/config.sh"
# =============================================================================
# SECTION 1 : COLOR DEFINITIONS (Colorized Output)
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'


# The Explaination :
# \033[ : this is the start of the color code
# the number (exemple : 0;32 ) the color
# m : this is the end of the color code
# RESET : the end of using this color and return to the original colors
# exemple : echo -e "${GREEN}HELLO${RESET}" (HELLO will be writen on a green color
# echo -e to encode the colors symbols
# =============================================================================
# SECTION 2 : GLOBAL VARIABLES
# =============================================================================
source "$HOME/NSCS_Audit_project/config/config.sh"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
HOSTNAME_SYS=$(hostname)
SHORT_REPORT="$REPORT_DIR/software_short_$TIMESTAMP.txt"
FULL_REPORT="$REPORT_DIR/software_full_$TIMESTAMP.txt"

# =============================================================================
# SECTION 3 : UTILITY FUNCTIONS
# =============================================================================
print_header() {
    local title="$1"
    echo -e "\n${MAGENTA}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${WHITE}${BOLD}  ${WHITE}${title}${WHITE}${BOLD}${RESET}"
    echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
}

print_header_to_file() {
    local title="$1"
    local file="$2"
    echo "" >> "$file"
    echo "╔══════════════════════════════════════════════════╗" >> "$file"
    echo "║  $title" >> "$file"
    echo "╚══════════════════════════════════════════════════╝" >> "$file"
}
print_info() {
    local key="$1"
    local value="$2"
    echo -e "  ${BLUE}${key}:${RESET} ${WHITE}${value}${RESET}"
}

print_separator() {
    echo -e "${CYAN}──────────────────────────────────────────────────${RESET}"
}

check_command() {
    command -v "$1" &>/dev/null
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[WARNING]${RESET} Some software info requires root. Run with sudo for full details."
    fi
}

setup_report_dir() {
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir -p "$REPORT_DIR" 2>/dev/null || {
            REPORT_DIR="$HOME/sys_audit"
            mkdir -p "$REPORT_DIR"
            SHORT_REPORT="$REPORT_DIR/software_short_$TIMESTAMP.txt"
            FULL_REPORT="$REPORT_DIR/software_full_$TIMESTAMP.txt"
            echo -e "${YELLOW}[INFO]${RESET} Reports will be saved to: $REPORT_DIR"
        }
    fi
}

# =============================================================================
# SECTION 4 : SOFTWARE COLLECTION FUNCTIONS
# =============================================================================

# --- 4.1 OS Information ---
get_os_info() {
    print_header "OPERATING SYSTEM INFORMATION"

    local os_name os_version kernel arch #arch : architecter (exp :x86-64)

    # Try /etc/os-release first (most distros), then fall back to uname
    if [ -f /etc/os-release ]; then # if it exists
        os_name=$(. /etc/os-release && echo "$NAME") # The . (dot) is equivalent to source command . It executes the file in the current shell, meaning it reads the file and loads all the variable definitions inside it into your current environment.
        os_version=$(. /etc/os-release && echo "$VERSION")
    else
        os_name=$(uname -s)
        os_version="N/A"
    fi

    kernel=$(uname -r)
    arch=$(uname -m)

    print_info "OS Name"       "$os_name"
    print_info "OS Version"    "$os_version"
    print_info "Kernel"        "$kernel"
    print_info "Architecture"  "$arch"
    print_info "Hostname"      "$(hostname)"
    print_info "Uptime"        "$(uptime -p 2>/dev/null || uptime)" #-p: pretty (friendly)
}

write_os_to_file() {
    local file="$1"
    print_header_to_file "OPERATING SYSTEM INFORMATION" "$file"
    {
        if [ -f /etc/os-release ]; then
            echo "  OS Name     : $(. /etc/os-release && echo "$NAME")"
            echo "  OS Version  : $(. /etc/os-release && echo "$VERSION")"
        else
            echo "  OS Name     : $(uname -s)"
            echo "  OS Version  : N/A (Not Available)"
        fi
        echo "  Kernel      : $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo "  Hostname    : $(hostname)"
        echo "  Uptime      : $(uptime -p 2>/dev/null || uptime)"
    } >> "$file"
}

# --- 4.2 Installed Packages ---
get_packages_info() {
    print_header "INSTALLED PACKAGES"

    local pkg_count pkg_manager
    pkg_manager="Unknown"

    # Detect package manager and count packages
    if check_command dpkg; then
        pkg_manager="dpkg (Debian/Ubuntu)"
        pkg_count=$(dpkg --list 2>/dev/null | grep "^ii" | wc -l)
    elif check_command rpm; then
        pkg_manager="rpm (RedHat/CentOS/Fedora)"
        pkg_count=$(rpm -qa 2>/dev/null | wc -l)
    elif check_command pacman; then
        pkg_manager="pacman (Arch)"
        pkg_count=$(pacman -Q 2>/dev/null | wc -l)
    else
        pkg_count="N/A"
    fi

    print_info "Package Manager" "$pkg_manager"
    print_info "Total Installed" "$pkg_count packages"
    print_separator
    echo -e "  ${CYAN}Last 10 installed packages (if available):${RESET}"

    # Show last installed packages (Debian/Ubuntu only via dpkg log)
    if [ -f /var/log/dpkg.log ]; then
        grep " install " /var/log/dpkg.log 2>/dev/null | tail -10 | \
            awk '{print "  "$4" ("$1" "$2")"}' | \
            while read -r line; do
                echo -e "  ${WHITE}${line}${RESET}"
            done
    else
        echo -e "  ${YELLOW}dpkg log not available on this system.${RESET}"
    fi
}

write_packages_to_file() {
    local file="$1"
    print_header_to_file "INSTALLED PACKAGES" "$file"
    {
        if check_command dpkg; then
            echo "  Package Manager : dpkg (Debian/Ubuntu)"
            echo "  Total Installed : $(dpkg --list 2>/dev/null | grep '^ii' | wc -l) packages"
            echo ""
            echo "  --- Full Package List ---"
            dpkg --list 2>/dev/null | grep "^ii" | awk '{print "  "$2" "$3}'
        elif check_command rpm; then
            echo "  Package Manager : rpm"
            echo "  Total Installed : $(rpm -qa 2>/dev/null | wc -l) packages"
            echo ""
            echo "  --- Full Package List ---"
            rpm -qa --qf "  %{NAME} %{VERSION}\n" 2>/dev/null
        elif check_command pacman; then
            echo "  Package Manager : pacman"
            echo "  Total Installed : $(pacman -Q 2>/dev/null | wc -l) packages"
            echo ""
            echo "  --- Full Package List ---"
            pacman -Q 2>/dev/null | awk '{print "  "$0}'
        else
            echo "  No recognized package manager found."
        fi
    } >> "$file"
}

# --- 4.3 Logged-in Users ---
get_users_info() {
    print_header "LOGGED-IN USERS"

    echo -e "  ${CYAN}Currently active sessions:${RESET}"
    who | while read -r line; do
        echo -e "  ${WHITE}${line}${RESET}"
    done

    print_separator
    echo -e "  ${CYAN}Last login records:${RESET}"
    last -n 10 2>/dev/null | head -10 | while read -r line; do
        echo -e "  ${WHITE}${line}${RESET}"
    done
}

write_users_to_file() {
    local file="$1"
    print_header_to_file "LOGGED-IN USERS" "$file"
    {
        echo "  --- Active Sessions ---"
        who
        echo ""
        echo "  --- Last 10 Logins ---"
        last -n 10 2>/dev/null | head -10
    } >> "$file"
}

# --- 4.4 Running Services ---
get_services_info() {
    print_header "RUNNING SERVICES"

    if check_command systemctl; then
        echo -e "  ${CYAN}Active systemd services:${RESET}"
        systemctl list-units --type=service --state=running --no-pager 2>/dev/null | \
            grep ".service" | awk '{print "  "$1" — "$4" "$5}' | \
            while read -r line; do
                echo -e "  ${WHITE}${line}${RESET}"
            done
    elif check_command service; then
        echo -e "  ${CYAN}Running services (service --status-all):${RESET}"
        service --status-all 2>/dev/null | grep "\[ + \]" | \
            while read -r line; do
                echo -e "  ${WHITE}${line}${RESET}"
            done
    else
        echo -e "  ${RED}No service manager detected.${RESET}"
    fi
}

write_services_to_file() {
    local file="$1"
    print_header_to_file "RUNNING SERVICES" "$file"
    if check_command systemctl; then
        {
            echo "  --- Active systemd Services ---"
            systemctl list-units --type=service --state=running --no-pager 2>/dev/null
        } >> "$file"
    elif check_command service; then
        {
            echo "  --- Running Services (service --status-all) ---"
            service --status-all 2>/dev/null | grep "\[ + \]"
        } >> "$file"
    else
        echo "  No service manager detected." >> "$file"
    fi
}

# --- 4.5 Active Processes ---
get_processes_info() {
    print_header "ACTIVE PROCESSES (Top 15 by CPU)"

    echo -e "  ${CYAN}PID      CPU%  MEM%  COMMAND${RESET}"
    print_separator
    ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 {printf "  %-8s %-5s %-5s %s\n", $2, $3, $4, $11}' | head -15 | \
        while read -r line; do
            echo -e "  ${WHITE}${line}${RESET}"
        done
}

write_processes_to_file() {
    local file="$1"
    print_header_to_file "ACTIVE PROCESSES (Top 15 by CPU)" "$file"
    {
        echo "  PID      CPU%  MEM%  COMMAND"
        echo "  ------------------------------------------------"
        ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 {printf "  %-8s %-5s %-5s %s\n", $2, $3, $4, $11}' | head -15
    } >> "$file"
}

# --- 4.6 Open Ports ---
get_ports_info() {
    print_header "OPEN PORTS & LISTENING SERVICES"

    if check_command ss; then
        echo -e "  ${CYAN}Listening ports (ss):${RESET}"
        ss -tlnp 2>/dev/null | awk 'NR>1 {print "  "$0}' | \
            while read -r line; do
                echo -e "  ${WHITE}${line}${RESET}"
            done
    elif check_command netstat; then
        echo -e "  ${CYAN}Listening ports (netstat):${RESET}"
        netstat -tlnp 2>/dev/null | awk 'NR>2 {print "  "$0}' | \
            while read -r line; do
                echo -e "  ${WHITE}${line}${RESET}"
            done
    else
        echo -e "  ${RED}Neither ss nor netstat available. Install net-tools or iproute2.${RESET}"
    fi
}

write_ports_to_file() {
    local file="$1"
    print_header_to_file "OPEN PORTS & LISTENING SERVICES" "$file"
    if check_command ss; then
        {
            echo "  --- Listening Ports (ss) ---"
            ss -tlnp 2>/dev/null
        } >> "$file"
    elif check_command netstat; then
        {
            echo "  --- Listening Ports (netstat) ---"
            netstat -tlnp 2>/dev/null
        } >> "$file"
    else
        echo "  No network socket tool available." >> "$file"
    fi
}

# --- 4.7 System Logs (Recent Entries) ---
get_logs_info() {
    print_header "RECENT SYSTEM LOG ENTRIES (Last 15)"

    if check_command journalctl; then
        journalctl -n 15 --no-pager 2>/dev/null | while read -r line; do
            echo -e "  ${WHITE}${line}${RESET}"
        done
    elif [ -f /var/log/syslog ]; then
        tail -15 /var/log/syslog 2>/dev/null | while read -r line; do
            echo -e "  ${WHITE}${line}${RESET}"
        done
    else
        echo -e "  ${YELLOW}No accessible system log found.${RESET}"
    fi
}
 
write_logs_to_file() {
    local file="$1"
    print_header_to_file "RECENT SYSTEM LOG ENTRIES (Last 15)" "$file"
    if check_command journalctl; then
        journalctl -n 15 --no-pager 2>/dev/null >> "$file"
    elif [ -f /var/log/syslog ]; then
        tail -15 /var/log/syslog 2>/dev/null >> "$file"
    else
        echo "  No accessible system log found." >> "$file"
    fi
}
 
# =============================================================================
# SECTION 5 : REPORT GENERATION
# =============================================================================
write_report_header() {
    local file="$1"
    local report_type="$2"
    {
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║         SOFTWARE AUDIT REPORT — $report_type"
        echo "╠══════════════════════════════════════════════════════════════╣"
        echo "║  Hostname  : $(hostname)"
        echo "║  Date/Time : $(date +%F_%T)"
        echo "║  Generated by: software_audit.sh v1.0 — NSCS 2025/2026"
        echo "╚══════════════════════════════════════════════════════════════╝"
    } > "$file"
}
 
generate_short_report() {
    echo -e "\n${GREEN}${BOLD}Generating SHORT report...${RESET}"
    write_report_header "$SHORT_REPORT" "SHORT SUMMARY"
    write_os_to_file         "$SHORT_REPORT"
    write_users_to_file      "$SHORT_REPORT"
    # Short disk of running services count only
    print_header_to_file "SERVICES (Summary)" "$SHORT_REPORT"
    if check_command systemctl; then
        svc_count=$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -c ".service")
        echo "  Running services: $svc_count" >> "$SHORT_REPORT"
    fi
    # Open listening ports summary
    print_header_to_file "OPEN PORTS (Summary)" "$SHORT_REPORT"
    ss -tlnp 2>/dev/null | awk 'NR>1 {print "  "$0}' >> "$SHORT_REPORT"
 
    echo "" >> "$SHORT_REPORT"
    echo "════ END OF REPORT ════" >> "$SHORT_REPORT"
    echo -e "${GREEN}Short report saved: ${WHITE}$SHORT_REPORT${RESET}"
}
 
generate_full_report() {
    echo -e "\n${GREEN}${BOLD}Generating FULL report...${RESET}"
    write_report_header "$FULL_REPORT" "FULL DETAILED AUDIT"
    write_os_to_file         "$FULL_REPORT"
    write_packages_to_file   "$FULL_REPORT"
    write_users_to_file      "$FULL_REPORT"
    write_services_to_file   "$FULL_REPORT"
    write_processes_to_file  "$FULL_REPORT"
    write_ports_to_file      "$FULL_REPORT"
    write_logs_to_file       "$FULL_REPORT"
 
    # Append raw uname output for completeness
    print_header_to_file "FULL uname OUTPUT" "$FULL_REPORT"
    uname -a >> "$FULL_REPORT"
 
    echo "" >> "$FULL_REPORT"
    echo "════ END OF REPORT ════" >> "$FULL_REPORT"
    echo -e "${GREEN}Full report saved: ${WHITE}$FULL_REPORT${RESET}"
}
 
# =============================================================================
# SECTION 6 : DISPLAY FUNCTIONS
# =============================================================================
display_short() {
    clear
    current_time=$(date +%F_%R)
    echo -e "${RED}${BOLD}"
    echo "  +-------------------------------------------+"
    echo "  |    SOFTWARE AUDIT - SHORT VIEW            |"
    echo "  |    Host: $(hostname) | $current_time      |"
    echo "  +-------------------------------------------+"
    echo -e "${RESET}"
    get_os_info
    get_users_info
    get_ports_info
}
 
display_full() {
    clear
    current_time=$(date +%F_%R)
    echo -e "${RED}${BOLD}"
    echo "  +-------------------------------------------+"
    echo "  |    SOFTWARE AUDIT - FULL DETAILED VIEW    |"
    echo "  |    Host: $(hostname) | $current_time      |"
    echo "  +-------------------------------------------+"
    echo -e "${RESET}"
    get_os_info
    get_packages_info
    get_users_info
    get_services_info
    get_processes_info
    get_ports_info
    get_logs_info
}
 
# =============================================================================
# SECTION 7 : INTERACTIVE MENU (Bonus)
# =============================================================================
show_menu() {
    while true; do
        clear
        current_time=$(date +%F_%T)
        echo -e "${MAGENTA}${BOLD}"
        echo "  +------------------------------------+"
        echo "  |     SOFTWARE AUDIT SYSTEM - NSCS   |"
        echo "  |     $current_time            |"
        echo "  +------------------------------------+"
        echo "  |  [1] Display Short Summary         |"
        echo "  |  [2] Display Full Audit            |"
        echo "  |  [3] Generate Short Report         |"
        echo "  |  [4] Generate Full Report          |"
        echo "  |  [5] Generate Both Reports         |"
        echo "  |  [6] Show Open Ports               |"
        echo "  |  [7] Exit                          |"
        echo "  +-------------------------------------+"
        echo -e "${RESET}"
        echo -ne "  ${CYAN}Choose an option [1-7]: ${RESET}"
        read -r choice

        case $choice in
            1) display_short          ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            2) display_full           ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            3) generate_short_report  ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            4) generate_full_report   ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            5) generate_short_report  ; generate_full_report ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            6) get_ports_info         ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            7) echo -e "${GREEN}Goodbye!${RESET}\n"; exit 0 ;;
            *) echo -e "${RED}Invalid${RESET}${YELLOW} option.${RESET}"; sleep 1 ;;
        esac
    done
}
 
# =============================================================================
# SECTION 8 : MAIN ENTRY POINT
# =============================================================================
main() {
    setup_report_dir
    check_root
    case "${1:-}" in
        --short)  display_short  ; generate_short_report ;;
        --full)   display_full   ; generate_full_report  ;;
        --report) generate_short_report ; generate_full_report ;;
        --menu)   show_menu ;;
        "")       show_menu ;;
        *)
            echo -e "${RED}Usage: sudo bash software_audit.sh [--short | --full | --report | --menu]${RESET}"
            exit 1
            ;;
    esac
}
 
main "$@"
