# NSCS Linux Audit & Monitoring System

**Authors:** ABABSA Zakaria & KARA Abdelbasset  
**School:** National School of Cyber Security (NSCS)  
**Academic Year:** 2025/2026  

---

## Description

An automated Linux system audit and monitoring solution built with shell scripting.  
The system collects hardware and software information, generates formatted reports,
sends them via email, and supports remote monitoring via SSH.

---

## Project Structure

```
NSCS_Audit_project/
├── config/
│   └── config.sh            # shared configuration (paths, variables)
├── logs/                    # execution logs
├── modules/
│   ├── hardware_audit3.sh   # collects hardware information
│   ├── software_audit.sh    # collects software & OS information
│   ├── email_sender.sh      # sends reports via email
│   └── remote_monitor.sh    # monitors remote machine via SSH
├── reports/                 # generated reports saved here
├── main.sh                  # main launcher
└── README.md
```

---

## Requirements

- Linux distribution (Kali, Ubuntu, ...)
- `sudo` privileges
- `msmtp` — for sending emails
- `ssh` — for remote monitoring

Install msmtp:
```bash
sudp apt update
sudo apt install msmtp msmtp-mta
```

---

## Installation

```bash
# 1. clone or copy the project to your machine
cd ~
git clone <> Audit project

# 2. give execution permissions to all scripts
chmod +x ~/NSCS_Audit_project/main.sh
chmod +x ~/NSCS_Audit_project/modules/*.sh

# 3. create required directories
mkdir -p ~/NSCS_Audit_project/reports
mkdir -p ~/NSCS_Audit_project/logs
```

---

## Configuration

### 1. Shared Config
Edit `config/config.sh` and set your paths:
```bash
REPORT_DIR="$HOME/Audit_project/reports"
LOG_DIR="$HOME/Audit_project/logs"
```

### 2. Email Config
Edit `modules/email_sender.sh` and set:
```bash
RECIPIENT="recipient@example.com"
SENDER="your_email@gmail.com"
SMTP_PASS="your_app_password"    # from myaccount.google.com/apppasswords
```

Then run setup once:
```bash
bash ~/NSCS_Audit_project/modules/email_sender.sh --setup
```

### 3. Remote Monitor Config
Edit `modules/remote_monitor.sh` and set:
```bash
REMOTE_USER=""           # SSH username on remote machine
REMOTE_HOST=""  # IP address of remote machine
SSH_KEY="$HOME/.ssh/id_rsa"  # your private SSH key path
```

Then copy your SSH key to the remote machine once:
```bash
ssh-copy-id -i ~/.ssh/id_rsa user@ip
```

---

## How to Run

### Main Launcher (recommended)
```bash
sudo bash ~/Audit_project/main.sh
```
This opens the main menu where you can access all modules.

### Run Modules Individually
```bash
# hardware audit
sudo bash ~/Audit_project/modules/hardware_audit.sh --menu

# software audit
sudo bash ~/Audit_project/modules/software_audit.sh --menu

# email sender
bash ~/Audit_project/modules/email_sender.sh --menu

# remote monitor
bash ~/Audit_project/modules/remote_monitor.sh
```

### Command Line Flags (no menu)
```bash
--short    # display and generate short report
--full     # display and generate full report
--report   # generate both reports without display
--menu     # open interactive menu
```

---

## Automation (Cron Job)

The system is scheduled to run automatically every day at 04:00 AM.  
To verify the cron job is configured:
```bash
crontab -l
```

To edit the cron job:
```bash
crontab -e
```

Cron execution logs are saved to:
```
~/Audit_project/logs/cron.log
```

---

## Reports

Generated reports are saved to:
```
~/Audit_project/reports/
```

Two types of reports are generated:

| Type | Description | Filename |
|---|---|---|
| Short | Summary — essential info only | `hardware_short_TIMESTAMP.txt` |
| Full | Detailed — complete audit info | `hardware_full_TIMESTAMP.txt` |

---

## Authors

| - - -  Name - - - groupe - - -  
|
| ABABSA Zakaria      A1
| KARA Abdelbasset    A4

**Module's Supervisor:** Dr. BENTRAD Sassi  
**Institution:** National Higher School of Cyber Security (NSCS)  
**Year:** 2025/2026
