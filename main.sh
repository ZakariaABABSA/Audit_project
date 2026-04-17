#!/bin/bash
# =============================================================================
# Script Name  : main.sh
# Description  : Main launcher — opens the menu of each module
# Author(s)    : ABABSA Zakaria & KARA Abdelbasset
# School       : National Higher School of Cyber Security (NSCS)
# Date         : 2026
# Version      : 1.0
# Usage        : sudo bash main.sh
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
# SECTION 2 : CONFIGURATION
# =============================================================================
MODULES_DIR="/home/zaki/NSCS_Audit_project/modules"

# =============================================================================
# SECTION 3 : CHECK SCRIPTS EXIST
# =============================================================================
check_scripts() {
    local missing=0
    for script in hardware_audit3.sh software_audit.sh email_sender.sh remote_monitor.sh; do
        if [ ! -f "$MODULES_DIR/$script" ]; then
            echo -e "  ${RED}[ERROR]${RESET} Missing: $MODULES_DIR/$script"
            missing=1
        fi
    done
    [ "$missing" -eq 1 ] && exit 1
}

# =============================================================================
# SECTION 4 : MAIN MENU
# =============================================================================
show_menu() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}"
        echo "  +-------------------------------------+"
        echo "  |     NSCS AUDIT SYSTEM — MAIN MENU  |"
        echo "  |     $(date +%F_%T)            |"
        echo "  +-------------------------------------+"
        echo "  |  [1] Hardware Audit                |"
        echo "  |  [2] Software Audit                |"
        echo "  |  [3] Email Sender                  |"
        echo "  |  [4] Remote Monitor                |"
        echo "  |  [5] Exit                          |"
        echo "  +-------------------------------------+"
        echo -e "${RESET}"
        echo -ne "  ${YELLOW}Choose an option [1-5]: ${RESET}"
        read -r choice

        case $choice in
            # each option launches the sub-script with --menu
            # when the user exits the sub-menu, they come back here
            1) sudo bash "$MODULES_DIR/hardware_audit3.sh"  --menu ;;
            2) sudo bash "$MODULES_DIR/software_audit.sh"  --menu ;;
            3)      bash "$MODULES_DIR/email_sender.sh"    --menu ;;
            4)      bash "$MODULES_DIR/remote_monitor.sh"  --menu ;;
            5) echo -e "${GREEN}Goodbye!${RESET}\n"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
        esac
    done
}

# =============================================================================
# SECTION 5 : MAIN ENTRY POINT
# =============================================================================
check_scripts
show_menu
