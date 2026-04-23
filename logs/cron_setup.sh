#!/bin/bash
# =============================================================================
# Script Name  : cron_setup.sh
# Description  : Sets up cron job to run audit scripts every day at 04:00 AM
# Usage        : bash cron_setup.sh
# =============================================================================

CRON_JOB="0 4 * * * sudo bash $HOME/Audit_project/modules/hardware_audit3.sh --report && sudo bash $HOME/Audit_project/modules/software_audit.sh --report && bash $HOME/Audit_project/modules/email_sender.sh --both"

# check if job already exists
( crontab -l 2>/dev/null | grep -qF "hardware_audit3.sh" ) && {
    echo "Cron job already exists."
    exit 0
}

# add the job
( crontab -l 2>/dev/null; echo "$CRON_JOB" ) | crontab -

echo "Cron job added successfully."
echo "Verify with: crontab -l"
