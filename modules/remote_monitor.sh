#!/bin/bash
# =============================================================================
# Script Name  : remote_monitor.sh
# Description  : Connects to a remote machine via SSH, runs the audit scripts,
#                and fetches the reports back to this machine
# Author(s)    : ABABSA Zakaria & KARA Abdelbasset
# School       : National Higher School of Cyber Security (NSCS)
# Date         : 2026
# Version      : 1.0
# Usage        : bash remote_monitor.sh
# =============================================================================

# =============================================================================
# SECTION 1 : COLOR DEFINITIONS
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# =============================================================================
# SECTION 2 : CONFIGURATION — Edit these before running
# =============================================================================
REMOTE_USER=""                    # SSH username on the remote machine
REMOTE_HOST=""           # IP address of the remote machine
SSH_KEY="$HOME/.ssh/id_rsa"           # your private SSH key
REMOTE_SCRIPTS_DIR="~/audit"          # where audit scripts are on remote machine
REMOTE_REPORT_DIR="/var/log/sys_audit" # where reports are saved on remote machine
LOCAL_CENTRAL_DIR="/var/log/sys_audit/remote" # where to save fetched reports locally

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
    echo -e "  ${YELLOW}${1}:${RESET} ${WHITE}${2}${RESET}"
}

# =============================================================================
# SECTION 4 : MAIN LOGIC
# =============================================================================
main() {

    # --- Step 1 : Check SSH key exists ---
    if [ ! -f "$SSH_KEY" ]; then
        echo -e "${RED}[ERROR]${RESET} SSH key not found at $SSH_KEY"
        echo -e "  Generate one with: ${WHITE}ssh-keygen -t rsa -b 4096 -f $SSH_KEY -N \"\"${RESET}"
        echo -e "  Then copy it with: ${WHITE}ssh-copy-id -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST${RESET}"
        exit 1
    fi

    # --- Step 2 : Test the connection ---
    print_header "CONNECTING TO REMOTE MACHINE"
    print_info "Target" "$REMOTE_USER@$REMOTE_HOST"

    ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o PasswordAuthentication=no \
        "$REMOTE_USER@$REMOTE_HOST" "echo ok" &>/dev/null

    if [ $? -ne 0 ]; then
        echo -e "  ${RED}[ERROR]${RESET} Cannot connect to $REMOTE_HOST"
        echo -e "  Make sure the key is copied: ${WHITE}ssh-copy-id -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST${RESET}"
        exit 1
    fi
    echo -e "  ${GREEN}Connected successfully.${RESET}"

    # --- Step 3 : Run the audit scripts on the remote machine ---
    print_header "RUNNING AUDIT ON REMOTE MACHINE"

    ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" bash << EOF
        echo "[*] Running hardware audit..."
        sudo bash $REMOTE_SCRIPTS_DIR/hardware_audit.sh --report

        echo "[*] Running software audit..."
        sudo bash $REMOTE_SCRIPTS_DIR/software_audit.sh --report

        echo "[+] Audit done."
EOF

    # --- Step 4 : Fetch the reports back to this machine ---
    print_header "FETCHING REPORTS"

    mkdir -p "$LOCAL_CENTRAL_DIR/$REMOTE_HOST"

    scp -i "$SSH_KEY" \
        "$REMOTE_USER@$REMOTE_HOST:$REMOTE_REPORT_DIR/*.txt" \
        "$LOCAL_CENTRAL_DIR/$REMOTE_HOST/"

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}Reports saved to: ${WHITE}$LOCAL_CENTRAL_DIR/$REMOTE_HOST/${RESET}"
    else
        echo -e "  ${RED}[ERROR]${RESET} Could not fetch reports."
    fi
}

main
