## ✅ TAK - to jest całość do skopiowania do `DEPLOYMENT_GUIDE.md`

Zaznacz wszystko od pierwszego do ostatniego znaku i wklej do pliku.

```markdown
# 🚀 WSMS PRO v4.1 - Deployment & Operations Guide

**Version:** 4.1 | **Last Updated:** April 2026 | **Status:** Production Ready

---

## 📋 Table of Contents

1. [Infrastructure Initialization](#1-infrastructure-initialization)
2. [Centralized Configuration](#2-centralized-configuration)
3. [Automated Deployment](#3-automated-deployment)
4. [Shell Environment Provisioning](#4-shell-environment-provisioning)
5. [Automated Task Scheduling](#5-automated-task-scheduling)
6. [System Verification](#6-system-verification)
7. [Incident Response & SOP](#7-incident-response--sop)

---

## 1. DIRECTORY INFRASTRUCTURE

```bash
mkdir -p ~/scripts ~/backups-lite ~/backups-full ~/backups-manual ~/mysql-backups ~/logs
sudo mkdir -p /var/quarantine /var/log/clamav
sudo chown $USER:$USER /var/log/clamav
```

---

## 2. CENTRALIZED CONFIGURATION

**File: `~/scripts/wsms-config.sh`**

```bash
SITES=(
    "site-name:/var/www/path/to/public_html:system_user"
)

NAS_HOST="your-nas.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/remote/path"
NAS_SSH_KEY="$HOME/.ssh/id_rsa"

RETENTION_LITE=14
RETENTION_FULL=35
RETENTION_MYSQL=7
DISK_ALERT_THRESHOLD=80
```

---

## 3. AUTOMATED DEPLOYMENT

### Bash Shell
```bash
git clone https://github.com/maleclukas-prog/wp-server-management-system.git
cd wp-server-management-system
nano scripts/wsms-config.sh
chmod +x installers/install_wsms.sh
./installers/install_wsms.sh
source ~/.bashrc
```

### Fish Shell
```fish
git clone https://github.com/maleclukas-prog/wp-server-management-system.git
cd wp-server-management-system
nano scripts/wsms-config.sh
fish installers/install_wsms.fish
source ~/.config/fish/config.fish
```

---

## 4. SHELL ALIASES

| Alias | Description |
|-------|-------------|
| `wp-status` | Full system diagnostics + fleet health |
| `wp-fleet` | Monitor WordPress versions and updates |
| `backup-list` | List all backups with size, date, age |
| `backup-size` | Show storage usage per directory |
| `backup-clean` | Interactive cleanup with confirmation |
| `backup-force-clean` | Automatic cleanup (for cron) |
| `backup-emergency` | Keep only 2 latest copies per site |
| `backup-dirs` | Show backup directory structure |
| `mysql-backup-all` | Backup all WordPress databases |
| `mysql-backup-list` | List available sites and backups |
| `wp-update-safe` | Backup + update (RECOMMENDED) |
| `wp-fix-perms` | Fix file permissions |
| `clamav-scan` | Daily malware scan |
| `nas-sync` | Manual NAS sync |
| `wp-help` | Complete command reference |

---

## 5. AUTOMATED TASK SCHEDULING (CRONTAB)

```cron
# ClamAV - Daily definition update at 1:00 AM
0 1 * * * sudo freshclam >> $HOME/logs/clamav-update.log 2>&1

# ClamAV - Daily quick scan at 3:00 AM
0 3 * * * $HOME/scripts/clamav-auto-scan.sh >> $HOME/logs/clamav-scan.log 2>&1

# ClamAV - Weekly full scan on Sunday at 4:00 AM
0 4 * * 0 $HOME/scripts/clamav-full-scan.sh >> $HOME/logs/clamav-full.log 2>&1

# Lite backups - Sunday and Wednesday at 2:00 AM
0 2 * * 0 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1
0 2 * * 3 $HOME/scripts/wp-essential-assets-backup.sh >> $HOME/logs/backup-lite.log 2>&1

# Full backup - 1st day of month at 3:00 AM
0 3 1 * * $HOME/scripts/wp-full-recovery-backup.sh >> $HOME/logs/backup-full.log 2>&1

# Smart retention - daily at 4:00 AM
0 4 * * * $HOME/scripts/wp-smart-retention-manager.sh force-clean >> $HOME/logs/retention.log 2>&1

# WordPress updates - weekly on Sunday at 6:00 AM
0 6 * * 0 $HOME/scripts/wp-automated-maintenance-engine.sh >> $HOME/logs/updates.log 2>&1

# NAS sync - daily at 2:00 AM
0 2 * * * $HOME/scripts/nas-sftp-sync.sh >> $HOME/logs/nas-sync.log 2>&1
```

---

## 6. SYSTEM VERIFICATION

```bash
# Test aliases
wp-status

# List backups
backup-list

# Check storage
backup-size

# Test database backup
mysql-backup-all

# Check crontab
crontab -l

# View logs
tail -f ~/logs/retention.log
```

---

## 7. INCIDENT RESPONSE & SOP

| Scenario | Solution |
|----------|----------|
| Low Disk Space (<20% free) | `backup-clean` or `backup-emergency` |
| Site Permission Errors | `wp-fix-perms` |
| Update Failure | `wp-fix-perms` then `wp-update-safe` |
| Backup Cycle Failed | `df -h` then `wp-interactive-backup-tool` |
| Security Threat Detected | Check `clamav-logs`, inspect `/var/quarantine/` |
| NAS Sync Failed | Check `~/.ssh/` keys, run `nas-sync-logs` |

---

## ✅ SYSTEM READY

```bash
wp-status      # Quick health check
wp-help        # Full command reference
```

**Maintainer:** Lukasz Malec | [GitHub](https://github.com/maleclukas-prog)
```