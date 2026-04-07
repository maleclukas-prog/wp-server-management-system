🚀 WSMS Deployment & Operations Guide
This document provides a comprehensive, step-by-step Standard Operating Procedure (SOP) for deploying the WordPress Management System (WSMS) PRO on an Ubuntu Server.

📋 Table of Contents
Infrastructure Initialization

Centralized Configuration (wsms-config.sh)

Automated Deployment (The Master Installer)

Shell Environment Provisioning (Aliases)

Automated Task Scheduling (Crontab)

System Verification & SOP

1. DIRECTORY INFRASTRUCTURE
The system requires a specific folder hierarchy for backups, logs, and security.

code
Bash
# Core operational directories
mkdir -p ~/scripts ~/backups-lite ~/backups-full ~/backups-manual ~/backups-mysqldump ~/mysql-backups ~/logs

# Security zones
sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
2. CENTRALIZED CONFIGURATION
WSMS PRO uses a "Single Source of Truth" model. You only need to define your infrastructure parameters in one place.

File: ~/scripts/wsms-config.sh

code
Bash
# Edit this file to manage your sites and NAS settings
SITES=(
    "site-name:/var/www/path/to/public_html:system_user"
)

NAS_HOST="your-nas.synology.me"
NAS_PORT="58365"
NAS_USER="your_user"
NAS_PATH="/remote/path"
NAS_SSH_KEY="$HOME/.ssh/id_rsa"
3. MODULAR SCRIPT DEPLOYMENT
The system consists of 17 specialized modules. It is highly recommended to use the install-wsms.sh script to deploy them automatically.

Managed Modules:

server-health-audit.sh - Core hardware diagnostics.

wp-fleet-status-monitor.sh - Fleet inventory & updates audit.

wp-multi-instance-audit.sh - Deep-dive site health scores.

wp-automated-maintenance-engine.sh - Unattended patching orchestration.

infrastructure-permission-orchestrator.sh - Security isolation & ACLs.

wp-full-recovery-backup.sh - Full bare-metal snapshots.

wp-essential-assets-backup.sh - Lean high-frequency backups.

mysql-backup-manager.sh - Dynamic SQL snapshot engine.

standalone-mysql-backup-engine.sh - Low-level mysqldump fallback.

nas-sftp-sync.sh - Hybrid Cloud NAS synchronization.

red-robin-system-backup.sh - Emergency OS config recovery.

wp-interactive-backup-tool.sh - CLI menu for manual tasks.

wp-smart-retention-manager.sh - Heuristic disk space cleanup.

clamav-auto-scan.sh - Daily malware audit.

clamav-full-scan.sh - Weekly deep system audit.

wp-cli-infrastructure-validator.sh - Connectivity & Dependency test.

wp-help.sh - Centralized command reference.

4. ENVIRONMENT ALIASES
Add these to your ~/.bashrc to enable the "Executive Command Center".

code
Bash
# Diagnostics
alias wp-status="system-diag && wp-fleet"
alias system-diag="bash ~/scripts/server-health-audit.sh"
alias wp-fleet="bash ~/scripts/wp-fleet-status-monitor.sh"
alias wp-audit="bash ~/scripts/wp-multi-instance-audit.sh"

# Maintenance & Security
alias wp-update-safe="wp-backup-lite && wp-automated-maintenance-engine.sh"
alias wp-fix-perms="bash ~/scripts/infrastructure-permission-orchestrator.sh"
alias clamav-scan="bash ~/scripts/clamav-auto-scan.sh"

# Backup & Recovery
alias wp-backup-ui="bash ~/scripts/wp-interactive-backup-tool.sh"
alias nas-sync="bash ~/scripts/nas-sftp-sync.sh"
alias backup-clean="bash ~/scripts/wp-smart-retention-manager.sh apply"
alias wp-help="bash ~/scripts/wp-help.sh"
5. AUTOMATION (CRONTAB)
Automate the lifecycle of your server using the following production-standard schedule:

code
Text
# 01:00 - ClamAV Update
0 1 * * * sudo freshclam

# 02:00 - Off-site NAS Sync
0 2 * * * ~/scripts/nas-sftp-sync.sh

# 03:00 - Daily Malware Scan
0 3 * * * ~/scripts/clamav-auto-scan.sh

# 04:00 - Smart Retention Cleanup
0 4 * * * ~/scripts/wp-smart-retention-manager.sh apply

# 06:00 - Sunday Maintenance (Fleet Patching)
0 6 * * 0 ~/scripts/wp-automated-maintenance-engine.sh
6. INCIDENT RESPONSE & SOP (Troubleshooting)
Scenario	Standard Operating Procedure (SOP)
Low Disk Space (<20% free)	Run backup-clean. If still low, inspect logs/ size.
Site Permission Errors	Execute wp-fix-perms to re-enforce isolated user ownership.
Integrity Failure	Run wp-cli-validator. If fails, check wsms-config.sh credentials.
Security Threat Detected	Check clamav-logs, inspect /var/quarantine/, and run wp-fix-perms.
Backup Cycle Failed	Check df -h. Run wp-interactive-backup-tool for a manual test.
✅ SYSTEM STATUS: PRODUCTION READY
You can now manage your entire fleet using wp-status and wp-help.

