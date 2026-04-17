#!/bin/bash
# =============================================================================
# Script Name  : email_sender.sh
# Description  : Sends audit reports via email using msmtp
# Author(s)    : ABABSA Zakaria & KARA Abdelbasset
# School       : National Higher School of Cyber Security (NSCS)
# Date         : 2026
# Version      : 1.0
# Usage        : bash email_sender.sh [--short | --full | --both | --setup | --menu]
# =============================================================================
source "$HOME/NSCS_Audit_project/config/config.sh"
# =============================================================================
# SECTION 1 : COLOR DEFINITIONS
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
# SECTION 2 : CONFIGURATION — Edit these before running
# =============================================================================
RECIPIENT="@gmail.com"        # who receives the report
SENDER="@gmail.com"          # your Gmail address
SMTP_PASS=""
source "$HOME/NSCS_Audit_project/config/config.sh"

# =============================================================================
# SECTION 3 : UTILITY FUNCTIONS
# =============================================================================
print_header() {
    local title="$1"
    echo -e "\n${BLUE}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}${BOLD}║  ${CYAN}${title}${BLUE}${BOLD}${RESET}"
    echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
}

print_info() {
    local key="$1"
    local value="$2"
    echo -e "  ${YELLOW}${key}:${RESET} ${WHITE}${value}${RESET}"
}

print_separator() {
    echo -e "${BLUE}──────────────────────────────────────────────────${RESET}"
}

# =============================================================================
# SECTION 4 : msmtp SETUP
# =============================================================================

# Writes ~/.msmtprc with Gmail SMTP settings
# msmtp reads this file automatically when sending
setup_msmtp() {
    cat > ~/.msmtprc <<EOF
account         gmail
host            smtp.gmail.com
port            587
auth            on
tls             on
tls_starttls    on
user            $SENDER
password        $SMTP_PASS
from            $SENDER
account default : gmail
EOF

    # lock the file — it contains your password
    chmod 600 ~/.msmtprc
    echo -e "  ${GREEN}msmtp configured successfully.${RESET}"
}

# =============================================================================
# SECTION 5 : SEND FUNCTION
# =============================================================================

# Takes a subject and a report file, builds the email and sends it
send_email() {
    local subject="$1"
    local report_file="$2"

    # check the report file exists before trying to send
    if [ ! -f "$report_file" ]; then
        echo -e "  ${RED}[ERROR]${RESET} File not found: $report_file"
        return 1
    fi

    print_info "Sending to" "$RECIPIENT"
    print_info "Subject"    "$subject"
    print_info "File"       "$report_file"
    print_separator

    # Build and send the email in one pipeline:
    # { headers + blank line + report content } → msmtp
    {
        echo "To: $RECIPIENT"
        echo "From: $SENDER"
        echo "Subject: $subject"
        echo "Date: $(date -R)"
        echo ""              # blank line separates headers from body
        cat "$report_file"   # the report becomes the email body
    } | msmtp "$RECIPIENT"

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}Sent successfully!${RESET}"
    else
        echo -e "  ${RED}[ERROR]${RESET} Failed to send. Check your msmtp config."
    fi
}

# =============================================================================
# SECTION 6 : REPORT SENDERS
# =============================================================================

send_short() {
    print_header "SENDING SHORT REPORTS"

    # ls -t = sort by date (newest first) | head -1 = pick the latest one
    local hw=$(ls -t "$REPORT_DIR"/hardware_short_*.txt 2>/dev/null | head -1)
    local sw=$(ls -t "$REPORT_DIR"/software_short_*.txt 2>/dev/null | head -1)

    [ -n "$hw" ] && send_email "[Audit] Hardware Short Report — $(hostname)" "$hw"
    [ -n "$sw" ] && send_email "[Audit] Software Short Report — $(hostname)" "$sw"

    [ -z "$hw" ] && [ -z "$sw" ] && \
        echo -e "  ${RED}[ERROR]${RESET} No short reports found in $REPORT_DIR"
}

send_full() {
    print_header "SENDING FULL REPORTS"

    local hw=$(ls -t "$REPORT_DIR"/hardware_full_*.txt 2>/dev/null | head -1)
    local sw=$(ls -t "$REPORT_DIR"/software_full_*.txt 2>/dev/null | head -1)

    [ -n "$hw" ] && send_email "[Audit] Hardware Full Report — $(hostname)" "$hw"
    [ -n "$sw" ] && send_email "[Audit] Software Full Report — $(hostname)" "$sw"

    [ -z "$hw" ] && [ -z "$sw" ] && \
        echo -e "  ${RED}[ERROR]${RESET} No full reports found in $REPORT_DIR"
}

send_both() {
    send_short
    send_full
}

# =============================================================================
# SECTION 7 : INTERACTIVE MENU
# =============================================================================
show_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}"
        echo "  +-------------------------------------+"
        echo "  |     EMAIL SENDER SYSTEM - NSCS     |"
        echo "  |     $(date +%F_%T)            |"
        echo "  +-------------------------------------+"
        echo "  |  [1] Send Short Reports            |"
        echo "  |  [2] Send Full Reports             |"
        echo "  |  [3] Send Both                     |"
        echo "  |  [4] Setup msmtp Config            |"
        echo "  |  [5] Exit                          |"
        echo "  +-------------------------------------+"
        echo -e "${RESET}"
        echo -ne "  ${YELLOW}Choose an option [1-5]: ${RESET}"
        read -r choice

        case $choice in
            1) send_short        ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            2) send_full         ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            3) send_both         ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            4) setup_msmtp       ; echo -e "\n${GREEN}Press Enter...${RESET}"; read -r ;;
            5) echo -e "${GREEN}Goodbye!${RESET}\n"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
        esac
    done
}

# =============================================================================
# SECTION 8 : MAIN ENTRY POINT
# =============================================================================
main() {
    # check msmtp is installed
    if ! command -v msmtp &>/dev/null; then
        echo -e "${RED}[ERROR]${RESET} msmtp not installed. Run: sudo apt install msmtp msmtp-mta"
        exit 1
    fi

    case "${1:-}" in
        --short)  send_short  ;;
        --full)   send_full   ;;
        --both)   send_both   ;;
        --setup)  setup_msmtp ;;
        --menu)   show_menu   ;;
        "")       show_menu   ;;
        *)
            echo -e "${RED}Usage: bash email_sender.sh [--short | --full | --both | --setup | --menu]${RESET}"
            exit 1
            ;;
    esac
}

main "$@"
