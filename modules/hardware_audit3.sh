#!/bin/bash
# =============================================================================
# Script Name  : hardware_audit.sh
# Description  : Hardware Audit Module — Collects detailed hardware info
# Author(s)    : ABABSA Zakaria & KARA Abdelbasset
# School       : National Higher School of Cyber Security (NSCS)
# Date         : 2026
# Version      : 1.0
# Usage        : sudo bash hardware_audit.sh [--short | --full | --menu]
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

# =============================================================================
# SECTION 2 : GLOBAL VARIABLES
# =============================================================================
source "$HOME/NSCS_Audit_project/config/config.sh"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
HOSTNAME_SYS=$(hostname)
SHORT_REPORT="$REPORT_DIR/hardware_short_$TIMESTAMP.txt"
FULL_REPORT="$REPORT_DIR/hardware_full_$TIMESTAMP.txt"
CPU_ALERT_THRESHOLD=80

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
    echo -e "  ${CYAN}${key}:${RESET} ${WHITE}${value}${RESET}"
}

print_separator() {
    echo -e "${BLUE}──────────────────────────────────────────────────${RESET}"
}

check_command() {
    command -v "$1" &>/dev/null
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[WARNING]${RESET} Some hardware info requires root. Run with sudo for full details."
    fi
}

setup_report_dir() {
    if [ ! -d "$REPORT_DIR" ]; then
        mkdir -p "$REPORT_DIR" 2>/dev/null || {
            REPORT_DIR="$HOME/sys_audit"
            mkdir -p "$REPORT_DIR"
            SHORT_REPORT="$REPORT_DIR/hardware_short_$TIMESTAMP.txt"
            FULL_REPORT="$REPORT_DIR/hardware_full_$TIMESTAMP.txt"
            echo -e "${YELLOW}[INFO]${RESET} Reports will be saved to: $REPORT_DIR"
        }
    fi
}

# =============================================================================
# SECTION 4 : HARDWARE COLLECTION FUNCTIONS
# =============================================================================

# --- 4.1 CPU Information ---
get_cpu_info() {
    print_header "CPU INFORMATION"
    local cpu_model cores threads architecture cpu_speed
    cpu_model=$(lscpu | grep "Model name" | sed 's/Model name:\s*//')
    cores=$(lscpu | grep "^Core(s) per socket" | awk '{print $NF}')
    threads=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    architecture=$(lscpu | grep Architecture | awk '{print $2}')
    cpu_speed=$(cat /proc/cpuinfo | grep "cpu MHz" | uniq | awk '{print $NF}')
    print_info "Model" "$cpu_model"
    print_info "Architecture" "$architecture"
    print_info "Cores" "$cores"
    print_info "Threads (logical CPUs)" "$threads"
    print_info "Speed (MHz)" "$cpu_speed"
}

write_cpu_to_file() {
    local file="$1"
    print_header_to_file "CPU INFORMATION" "$file"
    {
        echo "  Model       : $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
        echo "  Architecture: $(lscpu | grep Architecture | awk '{print $2}')"
        echo "  Cores       : $(lscpu | grep '^Core(s) per socket' | awk '{print $NF}')"
        echo "  Threads     : $(lscpu | grep '^CPU(s):' | awk '{print $2}')"
        echo "  Speed (MHz) : $(cat /proc/cpuinfo | grep 'cpu MHz' | uniq | awk '{print $NF}')"
    } >> "$file"
}

# --- 4.2 CPU Usage + Alert System ---
get_cpu_usage() {
    print_header "CPU USAGE & ALERT SYSTEM"
    local cpu_idle cpu_usage
    cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    cpu_usage=$((100 - cpu_idle))
    print_info "Current CPU Usage" "${cpu_usage}%"
    if [ "$cpu_usage" -ge "$CPU_ALERT_THRESHOLD" ]; then
        echo -e "${RED} ALERT! CPU : ${cpu_usage}%${RESET}"
        echo "[ALERT] $(date) -- CPU : ${cpu_usage}%" >> "$REPORT_DIR/alert.log"
    else
        echo -e "  ${GREEN}CPU usage is normal (below ${CPU_ALERT_THRESHOLD}%)${RESET}"
    fi
}

write_cpu_usage_to_file() {
    local file="$1"
    local cpu_usage cpu_idle
    cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    cpu_usage=$((100 - cpu_idle))
    print_header_to_file "CPU USAGE" "$file"
    echo "  Current Usage : ${cpu_usage}%" >> "$file"
    if [ "$cpu_usage" -ge "$CPU_ALERT_THRESHOLD" ]; then
        echo "  *** ALERT: CPU usage exceeds threshold of ${CPU_ALERT_THRESHOLD}% ***" >> "$file"
    fi
}

# --- 4.3 GPU Information ---
get_gpu_info() {
    print_header "GPU INFORMATION"
    if check_command lspci; then
        local gpu
        gpu=$(lspci | grep -iE "vga|3d|display" | sed 's/.*: //')
        if [ -z "$gpu" ]; then
            echo -e "  ${YELLOW}No dedicated GPU detected.${RESET}"
        else
            print_info "GPU" "$gpu"
        fi
    else
        echo -e "  ${RED}lspci not available. Install pciutils.${RESET}"
    fi
}

write_gpu_to_file() {
    local file="$1"
    print_header_to_file "GPU INFORMATION" "$file"
    if check_command lspci; then
        local gpu
        gpu=$(lspci | grep -iE "vga|3d|display" | sed 's/.*: //')
        [ -z "$gpu" ] && gpu="No dedicated GPU detected"
        echo "  GPU : $gpu" >> "$file"
    else
        echo "  lspci not available" >> "$file"
    fi
}

# --- 4.4 RAM Information ---
get_ram_info() {
    print_header "RAM / MEMORY INFORMATION"
    local total used free available
    total=$(free -h | grep "^Mem" | awk '{print $2}')
    used=$(free -h | grep "^Mem" | awk '{print $3}')
    free=$(free -h | grep "^Mem" | awk '{print $4}')
    available=$(free -h | grep "^Mem" | awk '{print $7}')
    print_info "Total Ram" "$total"
    print_info "Used" "$used"
    print_info "Free" "$free"
    print_info "Available" "$available"
    local swap_total swap_used
    swap_total=$(free -h | grep "^Swap" | awk '{print $2}')
    swap_used=$(free -h | grep "^Swap" | awk '{print $3}')
    print_separator
    print_info "Swap Total" "$swap_total"
    print_info "Swap Used" "$swap_used"
}

write_ram_to_file() {
    local file="$1"
    print_header_to_file "RAM / MEMORY INFORMATION" "$file"
    {
        echo "  Total RAM  : $(free -h | grep '^Mem' | awk '{print $2}')"
        echo "  Used       : $(free -h | grep '^Mem' | awk '{print $3}')"
        echo "  Free       : $(free -h | grep '^Mem' | awk '{print $4}')"
        echo "  Available  : $(free -h | grep '^Mem' | awk '{print $7}')"
        echo "  Swap Total : $(free -h | grep '^Swap' | awk '{print $2}')"
        echo "  Swap Used  : $(free -h | grep '^Swap' | awk '{print $3}')"
    } >> "$file"
}

# --- 4.5 Disk Information ---
get_disk_info() {
    print_header "DISK INFORMATION"
    echo -e "  ${CYAN}Partitions & Usage:${RESET}"
    df -h --output=source,fstype,size,used,avail,pcent,target 2>/dev/null | grep -v "tmpfs\|udev\|loop"
    print_separator
    echo -e "  ${CYAN}Block Devices:${RESET}"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null | head -20
}

write_disk_to_file() {
    local file="$1"
    print_header_to_file "DISK INFORMATION" "$file"
    echo "  Partitions & Usage:" >> "$file"
    df -h --output=source,fstype,size,used,avail,pcent,target 2>/dev/null | \
        grep -v "tmpfs\|udev\|loop" >> "$file"
    echo "" >> "$file"
    echo "  Block Devices:" >> "$file"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT 2>/dev/null >> "$file"
}

# --- 4.6 Network Interfaces, IP & MAC ---
get_network_info() {
    print_header "NETWORK INTERFACES / IP & MAC ADDRESSES"
    for iface in $(ip -o link show | awk '{print $2}' | tr -d ":"); do
        local mac ip_addr
        mac=$(ip link show "$iface" | grep "link/ether" | awk '{print $2}')
        ip_addr=$(ip -4 addr show "$iface" | grep "inet " | awk '{print $2}')
        echo -e "  ${CYAN}Interface: ${WHITE}${iface}${RESET}"
        [ -n "$mac" ]     && print_info "    MAC Address" "$mac"
        [ -n "$ip_addr" ] && print_info "    IP Address" "$ip_addr"
        [ -z "$mac" ] && [ -z "$ip_addr" ] && echo -e "    ${YELLOW}(No address assigned)${RESET}"
        print_separator
    done
}

write_network_to_file() {
    local file="$1"
    for iface in $(ip -o link show | awk '{print $2}' | tr -d ":"); do
        local mac ip_addr
        mac=$(ip link show "$iface" | grep "link/ether" | awk '{print $2}')
        ip_addr=$(ip -4 addr show "$iface" | grep "inet " | awk '{print $2}')
        echo "  Interface : $iface" >> "$file"
        [ -n "$mac" ]     && echo "    MAC : $mac" >> "$file"
        [ -n "$ip_addr" ] && echo "    IP  : $ip_addr" >> "$file"
        echo "" >> "$file"
    done
}

# --- 4.7 Motherboard / System Info ---
get_motherboard_info() {
    print_header "MOTHERBOARD / SYSTEM INFORMATION"
    if check_command dmidecode && [ "$EUID" -eq 0 ]; then
        local manufacturer product serial bios_version
        manufacturer=$(dmidecode -t system | grep "Manufacturer" | awk -F: '{print $2}' | xargs)
        product=$(dmidecode -t system | grep "Product Name" | awk '{print $3}' | xargs)
        serial=$(dmidecode -t system | grep "Serial" | awk '{print $3}' | xargs)
        bios_version=$(dmidecode -t bios | grep "Version" | awk '{print $2}' | xargs)
        print_info "Manufacturer" "$manufacturer"
        print_info "Product Name" "$product"
        print_info "Serial Number" "$serial"
        print_info "BIOS Version" "$bios_version"
    else
        echo -e "  ${YELLOW}Run as root (sudo) to retrieve motherboard info.${RESET}"
        print_info "Hostname" "$(hostname)"
        machine_id=$(cat /etc/machine-id 2>/dev/null || echo "Not Available")
        print_info "Machine ID" "$machine_id"
    fi
}

write_motherboard_to_file() {
    local file="$1"
    print_header_to_file "MOTHERBOARD / SYSTEM INFORMATION" "$file"
    if check_command dmidecode && [ "$EUID" -eq 0 ]; then
        manufacturer=$(dmidecode -t system | grep "Manufacturer" | awk -F: '{print $2}' | xargs)
        product=$(dmidecode -t system | grep "Product Name" | awk '{print $3}' | xargs)
        serial=$(dmidecode -t system | grep "Serial" | awk '{print $3}' | xargs)
        bios_version=$(dmidecode -t bios | grep "Version" | awk '{print $2}' | xargs)
        {
            echo "  Manufacturer : $manufacturer"
            echo "  Product Name : $product"
            echo "  Serial Number: $serial"
            echo "  BIOS Version : $bios_version"
        } >> "$file"
    else
        machine_id=$(cat /etc/machine-id 2>/dev/null || echo "N/A")
        {
            echo "  Hostname   : $(hostname)"
            echo "  Machine ID : $machine_id"
            echo "  (Run as root for full motherboard info)"
        } >> "$file"
    fi
}

# --- 4.8 USB Devices ---
get_usb_info() {
    print_header "USB DEVICES"
    if check_command lsusb; then
        lsusb | while read -r line; do
            echo -e "  ${WHITE}${line}${RESET}"
        done
    else
        echo -e "  ${RED}lsusb not available. Install: sudo apt install usbutils${RESET}"
    fi
}

write_usb_to_file() {
    local file="$1"
    print_header_to_file "USB DEVICES" "$file"
    if check_command lsusb; then
        lsusb >> "$file"
    else
        echo "  lsusb not available" >> "$file"
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
        echo "║         HARDWARE AUDIT REPORT — $report_type"
        echo "╠══════════════════════════════════════════════════════════════╣"
        echo "║  Hostname  : $(hostname)"
        echo "║  Date/Time : $(date +%F_%T)"
        echo "║  Generated by: hardware_audit.sh v1.0 — NSCS 2025/2026"
        echo "╚══════════════════════════════════════════════════════════════╝"
    } > "$file"
}

generate_short_report() {
    echo -e "\n${GREEN}${BOLD}Generating SHORT report...${RESET}"
    write_report_header "$SHORT_REPORT" "SHORT SUMMARY"
    write_cpu_to_file "$SHORT_REPORT"
    write_ram_to_file "$SHORT_REPORT"
    print_header_to_file "DISK (Summary)" "$SHORT_REPORT"
    df -h / >> "$SHORT_REPORT"
    print_header_to_file "NETWORK (Summary)" "$SHORT_REPORT"
    ip -4 addr show | grep "inet " | while read -r line; do
        echo "  $line" >> "$SHORT_REPORT"
    done
    echo -e "${GREEN}Short report saved: ${WHITE}$SHORT_REPORT${RESET}"
}

generate_full_report() {
    echo -e "\n${GREEN}${BOLD}Generating FULL report...${RESET}"
    write_report_header "$FULL_REPORT" "FULL DETAILED AUDIT"
    write_cpu_to_file "$FULL_REPORT"
    write_cpu_usage_to_file "$FULL_REPORT"
    write_gpu_to_file "$FULL_REPORT"
    write_ram_to_file "$FULL_REPORT"
    write_disk_to_file "$FULL_REPORT"
    write_network_to_file "$FULL_REPORT"
    write_motherboard_to_file "$FULL_REPORT"
    write_usb_to_file "$FULL_REPORT"
    print_header_to_file "FULL lscpu OUTPUT" "$FULL_REPORT"
    lscpu >> "$FULL_REPORT"
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
    echo "  |    HARDWARE AUDIT - SHORT VIEW            |"
    echo "  |    Host: $(hostname) | $current_time          |"
    echo "  +-------------------------------------------+"
    echo -e "${RESET}"
    get_cpu_info
    get_ram_info
    get_network_info
}

display_full() {
    clear
    current_time=$(date +%F_%R)
    echo -e "${RED}${BOLD}"
    echo "  +-------------------------------------------+"
    echo "  |    HARDWARE AUDIT - FULL DETAILED VIEW    |"
    echo "  |    Host: $(hostname) | $current_time          |"
    echo "  +-------------------------------------------+"
    echo -e "${RESET}"
    get_cpu_info
    get_cpu_usage
    get_gpu_info
    get_ram_info
    get_disk_info
    get_network_info
    get_motherboard_info
    get_usb_info
}

# =============================================================================
# SECTION 7 : INTERACTIVE MENU 
# =============================================================================
show_menu() {
    while true; do
        clear
        current_time=$(date +%F_%T)
        echo -e "${MAGENTA}${BOLD}"
        echo "  +------------------------------------+"
        echo "  |     HARDWARE AUDIT SYSTEM - NSCS   |"
        echo "  |     $current_time            |"
        echo "  +------------------------------------+"
        echo "  |  [1] Display Short Summary         |"
        echo "  |  [2] Display Full Audit            |"
        echo "  |  [3] Generate Short Report         |"
        echo "  |  [4] Generate Full Report          |"
        echo "  |  [5] Generate Both Reports         |"
        echo "  |  [6] Check CPU Usage and Alerts    |"
        echo "  |  [7] Exit                          |"
        echo "  +-------------------------------------+"
        echo -e "${RESET}"
        echo -ne "  ${CYAN}Choose an option [1-7]: ${RESET}"
        read -r choice

        case $choice in
            1) display_short         ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            2) display_full          ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            3) generate_short_report ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            4) generate_full_report  ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            5) generate_short_report ; generate_full_report ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            6) get_cpu_usage         ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
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
            echo -e "${RED}Usage: sudo bash hardware_audit.sh [--short | --full | --report | --menu]${RESET}"
            exit 1
            ;;
    esac
}

main "$@"
