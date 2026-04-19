## 📄 PLIK 4/12: `docs/TECHNICAL_REFERENCE.md`

```markdown
# 📜 WSMS PRO - Technical Module Reference

**Project:** WordPress Server Management System (WSMS)  
**Architecture:** Modular Bash Framework with Centralized Configuration  
**Version:** 4.2 | **Status:** Production Ready | **Last Updated:** April 2026

---

## 🛠 The Brain: `wsms-config.sh`

### Overview
The **"Single Source of Truth"** for the entire ecosystem. This configuration file decouples logic from data, allowing global management of sites, system users, and remote storage parameters.

### Key Technical Features
- **Centralized Registry:** Stores all managed WordPress instances in a structured array
- **Dynamic Variable Injection:** All 18 scripts source this file to identify target paths and NAS credentials
- **Organized Logging:** Structured log paths in `~/logs/wsms/[category]/`
- **Maintainability:** Allows scaling from 1 to 100+ sites by editing a single line

### Configuration Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `SITES` | Array of WordPress instances | Required |
| `NAS_HOST` | Synology NAS address | Required for sync |
| `RETENTION_LITE` | Days to keep lite backups | 14 |
| `RETENTION_FULL` | Days to keep full backups | 35 |
| `RETENTION_MYSQL` | Days to keep MySQL dumps | 7 |
| `RETENTION_ROLLBACK` | Days to keep rollback snapshots | 7 |
| `DISK_ALERT_THRESHOLD` | Emergency mode trigger (%) | 80 |

---

## 🔍 Section 1: Observability & Diagnostics (4 modules)

### 1. `server-health-audit.sh`
**Overview:** Comprehensive diagnostic tool for real-time monitoring of hardware resources and service uptime.

**Key Features:**
- Audits CPU Load, RAM, and Disk I/O
- Checks core services (nginx, mysql, php-fpm)
- Displays WordPress fleet status
- Shows backup repository statistics
- Uses heuristics to provide operational advice

**Logs:** `~/logs/wsms/system/health.log`

### 2. `wp-fleet-status-monitor.sh`
**Overview:** Application-level observability for multi-tenant environments.

**Key Features:**
- Extracts core versions across the entire fleet
- Counts pending plugin/theme updates
- Shows HTTP status for each site
- Displays available rollback snapshots

**Output:** Terminal only (no log file)

### 3. `wp-multi-instance-audit.sh`
**Overview:** Deep-dive security and performance auditor for individual WordPress sites.

**Key Features:**
- Database integrity checks
- Plugin update inventory
- Site health score (WordPress 5.2+)
- Security configuration audit (permissions, debug mode)

**Output:** Terminal only

### 4. `wp-cli-infrastructure-validator.sh`
**Overview:** Pre-flight connectivity tester for the WSMS automation layer.

**Key Features:**
- Validates WP-CLI binary paths
- Tests user impersonation (`sudo -u`) connectivity
- Reports WP-CLI version

**Output:** Terminal only

---

## 🛡️ Section 2: Security & Hardening (3 modules)

### 5. `infrastructure-permission-orchestrator.sh`
**Overview:** High-level security engine enforcing the Principle of Least Privilege.

**Key Features:**
- Standardizes ownership for isolated PHP-FPM users
- Sets secure permissions (755/644/640)
- Implements ACLs for secure backup access
- Stops/restarts web server during operation

**Logs:** `~/logs/wsms/maintenance/permissions.log`

### 6. `clamav-auto-scan.sh`
**Overview:** Automated daily malware detection targeting high-risk directories.

**Key Features:**
- Recursive scanning of `/var/www` and `/home`
- Real-time alerting for infected files
- Runs as daily cron job

**Logs:** `~/logs/wsms/security/clamav-scan.log`

### 7. `clamav-full-scan.sh`
**Overview:** High-intensity root-level security audit with automated incident response.

**Key Features:**
- Scans entire OS (excluding `/sys`, `/proc`, `/dev`)
- Automatically moves infected files to `/var/quarantine`
- Generates detailed audit report
- Runs weekly

**Logs:** `~/logs/wsms/security/clamav-full.log`

---

## 💾 Section 3: Backup & Disaster Recovery (5 modules)

### 8. `wp-full-recovery-backup.sh`
**Overview:** Complete bare-metal snapshots for catastrophic failure recovery.

**Key Features:**
- Combines optimized SQL dumps with full filesystem archive
- Pre-backup database optimization
- 35-day retention policy
- Automatic cleanup of expired backups

**Logs:** `~/logs/wsms/backups/full.log`
**Output:** `~/backups-full/full-[site]-[timestamp].tar.gz`

### 9. `wp-essential-assets-backup.sh`
**Overview:** Resource-efficient "Lite" backup focusing on unique data.

**Key Features:**
- Backs up: `wp-content/uploads`, `wp-content/themes`, `wp-content/plugins`, `wp-config.php`
- Captures 90% of risk with 30% of storage footprint
- 14-day retention policy
- Runs twice weekly (Sunday/Wednesday)

**Logs:** `~/logs/wsms/backups/lite.log`
**Output:** `~/backups-lite/lite-[site]-[timestamp].tar.gz`

### 10. `mysql-backup-manager.sh`
**Overview:** "Zero-Config" database snapshot engine.

**Key Features:**
- Dynamically parses `wp-config.php` to extract credentials
- No hardcoded passwords
- Supports single-site or fleet-wide backups
- List mode to show available backups
- 7-day retention policy

**Logs:** `~/logs/wsms/backups/mysql.log`
**Output:** `~/mysql-backups/db-[site]-[timestamp].sql.gz`

### 11. `standalone-mysql-backup-engine.sh`
**Overview:** Low-level recovery tool using raw mysqldump logic.

**Key Features:**
- Operates independently of high-level CLI tools
- Reliable fallback in degraded system states
- Calls `mysql-backup-manager.sh all`

### 12. `red-robin-system-backup.sh`
**Overview:** Bare-metal OS configuration and metadata recovery.

**Key Features:**
- Backs up `/etc`, `/var/log`, `/home`
- Excludes heavy media directories
- Emergency system state capture
- Manual trigger only

**Output:** `~/backups-manual/red-robin-sys-[timestamp].tar.gz`

---

## 🔄 Section 4: Automation & Hybrid Cloud (3 modules)

### 13. `nas-sftp-sync.sh`
**Overview:** Orchestrates off-site data synchronization with Synology NAS.

**Key Features:**
- SFTP-based synchronization
- "Minimum Copy" safety rule - never deletes final backup copy
- Separate error logging
- Runs daily

**Logs:** `~/logs/wsms/sync/nas-sync.log`, `~/logs/wsms/sync/nas-errors.log`

### 14. `wp-automated-maintenance-engine.sh`
**Overview:** Unattended lifecycle management for the entire fleet.

**Key Features:**
- **Pre-update rollback snapshot** (NEW in v4.2)
- Updates core/plugins/themes
- Migrates database schemas
- Flushes caches
- Runs weekly (Sunday)

**Logs:** `~/logs/wsms/maintenance/updates.log`

### 15. `wp-smart-retention-manager.sh`
**Overview:** Heuristic storage cleanup engine.

**Key Features:**
- **Emergency Mode:** Activates at 80% disk usage
- Keeps only 2 latest copies in emergency
- Interactive cleanup mode
- Force-clean for cron automation
- Multiple display modes (list, size, dirs)

**Logs:** `~/logs/wsms/retention/retention.log`

---

## 🆕 Section 5: Rollback System (1 module) - NEW in v4.2

### 16. `wp-rollback.sh`
**Overview:** Automated disaster recovery with pre-update snapshots.

**Key Features:**
- **Snapshot:** Creates point-in-time backup of database and critical files
- **Rollback:** Restores site to previous state in ~30 seconds
- **List:** Shows available snapshots with timestamps and sizes
- **Clean:** Removes snapshots older than retention period
- Automatic snapshot before every update

**Commands:**
| Command | Description |
|---------|-------------|
| `snapshot all` | Create snapshots for all sites |
| `snapshot [site]` | Create snapshot for specific site |
| `rollback [site]` | Restore to latest snapshot |
| `rollback [site] [date]` | Restore to specific snapshot |
| `list [site]` | List available snapshots |
| `clean [days]` | Remove old snapshots |

**Logs:** `~/logs/wsms/rollback/snapshots.log`, `~/logs/wsms/rollback/rollback-clean.log`
**Storage:** `~/backups-rollback/[site]/[timestamp]/`

---

## 🛠 Section 6: Operator Interface (2 modules)

### 17. `wp-interactive-backup-tool.sh`
**Overview:** Menu-driven CLI utility for manual backup operations.

**Key Features:**
- Guided interface for selecting sites and backup types
- Options: Lite, Full, Database only, Rollback snapshot
- Reduces human error in high-stakes operations

### 18. `wp-help.sh`
**Overview:** Centralized command reference and internal documentation.

**Key Features:**
- Complete command reference
- Quick start guide
- Incident response procedures
- Retention policy summary
- Log file locations
- Crontab schedule

---

## 📁 Log Directory Structure (NEW in v4.2)

```
~/logs/wsms/
├── backups/
│   ├── lite.log           # Lite backup operations
│   ├── full.log           # Full backup operations
│   └── mysql.log          # Database backup operations
├── maintenance/
│   ├── updates.log        # WordPress updates
│   └── permissions.log    # Permission fixes
├── security/
│   ├── clamav-scan.log    # Daily malware scans
│   ├── clamav-full.log    # Weekly full scans
│   └── clamav-update.log  # Virus definition updates
├── sync/
│   ├── nas-sync.log       # NAS synchronization
│   └── nas-errors.log     # Sync errors
├── retention/
│   └── retention.log      # Cleanup operations
├── rollback/
│   ├── snapshots.log      # Snapshot creation
│   └── rollback-clean.log # Snapshot cleanup
└── system/
    └── health.log         # System diagnostics
```

---

## 📊 Retention Policy Summary

| Backup Type | Directory | Retention | Emergency Mode |
|-------------|-----------|-----------|----------------|
| Lite Assets | `~/backups-lite` | 14 days | Keep 2 latest |
| Full Snapshots | `~/backups-full` | 35 days | Keep 2 latest |
| MySQL Dumps | `~/mysql-backups` | 7 days | Keep 2 latest |
| Rollback Snapshots | `~/backups-rollback` | 7 days | N/A |
| NAS Vault | Remote NAS | 120 days | Keep 2 latest |

---

## 🏁 Operational Logic Summary

The WSMS is built on the principle of **Modular Automation**. Instead of one large, fragile script, it uses 18 specialized tools that communicate via the central `wsms-config.sh`. This architecture ensures:

- **Scalability** - Add new sites by editing one line in configuration
- **Auditability** - Each module has a single, clear responsibility
- **Production-Ready** - Defensive programming with multiple safety nets
- **Observability** - Comprehensive logging in organized structure

---

## 📁 Quick Reference

| Command | Module |
|---------|--------|
| `wp-status` | server-health-audit.sh |
| `wp-fleet` | wp-fleet-status-monitor.sh |
| `wp-audit` | wp-multi-instance-audit.sh |
| `backup-list` | wp-smart-retention-manager.sh |
| `backup-size` | wp-smart-retention-manager.sh |
| `backup-clean` | wp-smart-retention-manager.sh |
| `backup-emergency` | wp-smart-retention-manager.sh |
| `wp-snapshot` | wp-rollback.sh |
| `wp-rollback` | wp-rollback.sh |
| `mysql-backup-all` | mysql-backup-manager.sh |
| `wp-update-safe` | wp-essential-assets-backup.sh + wp-automated-maintenance-engine.sh |
| `wp-fix-perms` | infrastructure-permission-orchestrator.sh |
| `nas-sync` | nas-sftp-sync.sh |
| `clamav-scan` | clamav-auto-scan.sh |
| `wp-help` | wp-help.sh |

---

## 🔧 Development Notes

### Adding a New Site
Edit `~/scripts/wsms-config.sh`:
```bash
SITES=(
    "existing:/var/www/existing/public_html:user_existing"
    "newsite:/var/www/newsite/public_html:user_newsite"  # Add this line
)
```

### Adding a New Module
1. Create script in `~/scripts/`
2. Source `wsms-config.sh`
3. Use appropriate `LOG_*` variable
4. Add alias to installer
5. Update documentation

### Testing
```bash
# Syntax check
bash -n script.sh

# ShellCheck
shellcheck script.sh

# Run test suite
bash tests/test_suite.sh
```

---

**Maintainer:** Lukasz Malec | [GitHub: maleclukas-prog](https://github.com/maleclukas-prog)  
**License:** MIT  
**Last Updated:** April 2026
```

---

## 📄 PLIK 5/12: `docs/DEPLOYMENT_GUIDE.md`

```markdown
# 🚀 WSMS PRO v4.2 - Deployment & Operations Guide

**Version:** 4.2 | **Last Updated:** April 2026 | **Status:** Production Ready

---

## 📋 Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Infrastructure Initialization](#2-infrastructure-initialization)
3. [Centralized Configuration](#3-centralized-configuration)
4. [Automated Deployment](#4-automated-deployment)
5. [Shell Environment Provisioning](#5-shell-environment-provisioning)
6. [Automated Task Scheduling](#6-automated-task-scheduling)
7. [System Verification](#7-system-verification)
8. [Incident Response & SOP](#8-incident-response--sop)
9. [Uninstallation](#9-uninstallation)
10. [Log Management](#10-log-management)

---

## 1. Prerequisites

### System Requirements
| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS |
| RAM | 2 GB | 4+ GB |
| Disk Space | 10 GB free | 20+ GB free |
| Access | sudo/root | sudo/root |

### Required Services
- **Web Server:** Nginx or Apache2 (running)
- **Database:** MySQL 5.7+ or MariaDB 10.3+ (running)
- **PHP:** PHP-FPM 7.4+ with isolated pools per site
- **SSH:** OpenSSH client (for NAS sync)

### Required System Users
Each WordPress site should have a dedicated system user:
```bash
# Create isolated users for each site
sudo adduser --disabled-password --gecos "" wordpress_site1
sudo adduser --disabled-password --gecos "" wordpress_site2
```

---

## 2. Infrastructure Initialization

The installer automatically creates the following directory structure:

```
~/scripts/               # 18 operational modules
~/backups-lite/          # Daily asset backups (14 days retention)
~/backups-full/          # Monthly full backups (35 days retention)
~/backups-manual/        # Manual backup storage
~/backups-rollback/      # Pre-update snapshots (7 days retention)
~/mysql-backups/         # Database dumps (7 days retention)
~/logs/wsms/             # Organized log files (see Section 10)
/var/quarantine/         # Malware quarantine (ClamAV)
/var/log/clamav/         # ClamAV system logs
```

---

## 3. Centralized Configuration

**File: `~/scripts/wsms-config.sh`** (generated by installer)

### Core Configuration Variables

```bash
# WordPress Sites Array
SITES=(
    "mysite:/var/www/mysite/public_html:wordpress_mysite"
    "another:/var/www/another/public_html:wordpress_another"
)

# NAS/SFTP Settings
NAS_HOST="your-nas.synology.me"
NAS_PORT="22"
NAS_USER="admin"
NAS_PATH="/homes/admin/server_backups"
NAS_SSH_KEY="$HOME/.ssh/id_rsa"

# Retention Policies
RETENTION_LITE=14        # Days to keep lite backups
RETENTION_FULL=35        # Days to keep full backups
RETENTION_MYSQL=7        # Days to keep MySQL dumps
RETENTION_ROLLBACK=7     # Days to keep rollback snapshots

# System Thresholds
DISK_ALERT_THRESHOLD=80  # Emergency mode trigger (%)
```

### Editing Configuration
```bash
nano ~/scripts/wsms-config.sh
# Make changes, then reload
source ~/scripts/wsms-config.sh
```

---

## 4. Automated Deployment

### Option 1: English Version
```bash
# Clone repository
git clone https://github.com/maleclukas-prog/wp-server-management-system.git
cd wp-server-management-system

# Edit configuration
nano installers/install.sh
# Modify MANAGED_SITES and NAS settings at the top

# Run installer
chmod +x installers/install.sh
./installers/install.sh
```

### Option 2: Polish Version
```bash
nano installers/install-pl.sh
chmod +x installers/install-pl.sh
./installers/install-pl.sh
```

### Option 3: One-Line Install (English)
```bash
curl -s https://raw.githubusercontent.com/maleclukas-prog/wp-server-management-system/main/installers/install.sh | bash
```

### Installation Phases
| Phase | Description |
|-------|-------------|
| 0 | Configuration validation |
| 1 | Directory infrastructure creation |
| 2 | Dependency installation |
| 3 | Central configuration generation |
| 4 | 18 operational modules deployment |
| 5 | Shell aliases installation |
| 6 | Crontab configuration |
| 7 | Final summary |

---

## 5. Shell Environment Provisioning

### Bash
```bash
source ~/.bashrc
```

### Fish
```fish
source ~/.config/fish/config.fish
```

### Available Aliases (All Shells)

| Alias | Description | Category |
|-------|-------------|----------|
| `wp-status` | Full system diagnostics | Executive |
| `wp-fleet` | WordPress versions and updates | Monitoring |
| `wp-audit` | Deep security audit | Monitoring |
| `wp-update-safe` | Safe update with snapshot | Maintenance |
| `wp-update-all` | Fleet-wide updates | Maintenance |
| `wp-fix-perms` | Fix file permissions | Security |
| `wp-backup-lite` | Fast assets backup | Backup |
| `wp-backup-full` | Complete site backup | Backup |
| `wp-backup-ui` | Interactive backup | Backup |
| `backup-list` | List all backups | Backup |
| `backup-size` | Show storage usage | Backup |
| `backup-clean` | Interactive cleanup | Backup |
| `backup-emergency` | Emergency cleanup | Backup |
| `wp-snapshot all` | Create rollback snapshots | Rollback |
| `wp-snapshot [site]` | Snapshot for site | Rollback |
| `wp-snapshots` | List snapshots | Rollback |
| `wp-rollback [site]` | Restore site | Rollback |
| `mysql-backup-all` | Backup all databases | Database |
| `mysql-backup-list` | List database backups | Database |
| `nas-sync` | Manual NAS sync | Cloud |
| `clamav-scan` | Daily malware scan | Security |
| `clamav-deep-scan` | Full system scan | Security |
| `red-robin` | System backup | Emergency |
| `wp-help` | Command reference | Help |

### Per-Site Aliases (Auto-generated)
```bash
wp-mysite           # WP-CLI for mysite
wp-backup-mysite    # Lite backup for mysite
wp-snapshot-mysite  # Snapshot for mysite
wp-rollback-mysite  # Rollback for mysite
```

---

## 6. Automated Task Scheduling (Crontab)

```cron
# ============================================
# WSMS PRO v4.2 - CRONTAB (9 automated tasks)
# ============================================

# ClamAV - Daily definition update (1:00 AM)
0 1 * * * sudo freshclam >> ~/logs/wsms/security/clamav-update.log 2>&1

# ClamAV - Daily quick scan (3:00 AM)
0 3 * * * ~/scripts/clamav-auto-scan.sh >> ~/logs/wsms/security/clamav-scan.log 2>&1

# ClamAV - Weekly full scan (Sunday 4:00 AM)
0 4 * * 0 ~/scripts/clamav-full-scan.sh >> ~/logs/wsms/security/clamav-full.log 2>&1

# Lite backups - Sunday and Wednesday (2:00 AM)
0 2 * * 0,3 ~/scripts/wp-essential-assets-backup.sh >> ~/logs/wsms/backups/lite.log 2>&1

# Full backup - 1st day of month (3:00 AM)
0 3 1 * * ~/scripts/wp-full-recovery-backup.sh >> ~/logs/wsms/backups/full.log 2>&1

# Smart retention - daily (4:00 AM)
0 4 * * * ~/scripts/wp-smart-retention-manager.sh force-clean >> ~/logs/wsms/retention/retention.log 2>&1

# WordPress updates - weekly Sunday (6:00 AM)
0 6 * * 0 ~/scripts/wp-automated-maintenance-engine.sh >> ~/logs/wsms/maintenance/updates.log 2>&1

# NAS sync - daily (2:00 AM)
0 2 * * * ~/scripts/nas-sftp-sync.sh >> ~/logs/wsms/sync/nas-sync.log 2>&1

# Rollback cleanup - weekly Monday (5:00 AM)
0 5 * * 1 ~/scripts/wp-rollback.sh clean >> ~/logs/wsms/rollback/rollback-clean.log 2>&1
```

### Crontab Management
```bash
# View current crontab
crontab -l

# Edit crontab
crontab -e

# Backup crontab
crontab -l > ~/crontab.backup.txt
```

---

## 7. System Verification

### Quick Health Check
```bash
wp-status
```

### Comprehensive Verification
```bash
# Test aliases
alias | grep wp-

# List backups
backup-list

# Check storage usage
backup-size

# Test database backup
mysql-backup-all

# Verify WP-CLI connectivity
wp-cli-validator

# Check crontab
crontab -l | grep WSMS

# View recent logs
tail -f ~/logs/wsms/backups/lite.log
tail -f ~/logs/wsms/maintenance/updates.log
tail -f ~/logs/wsms/sync/nas-sync.log
```

### Test Rollback System
```bash
# Create test snapshot
wp-snapshot all

# List snapshots
wp-snapshots

# (After update) Rollback if needed
wp-rollback mysite
```

---

## 8. Incident Response & SOP

### 🚨 Critical Scenarios

| Scenario | Symptom | Solution |
|----------|---------|----------|
| **Site Down After Update** | 500 error / WSOD | `wp-rollback [site-name]` |
| **Low Disk Space** | <20% free | `backup-emergency` |
| **Permission Errors** | 403 Forbidden | `wp-fix-perms` |
| **Malware Detected** | Unusual files | `clamav-deep-scan` |
| **Backup Failed** | Missing files | `df -h && wp-backup-ui` |
| **NAS Sync Failed** | No remote backup | `tail ~/logs/wsms/sync/nas-errors.log` |
| **WP-CLI Broken** | Command not found | `wp-cli-validator` |
| **Database Corruption** | Site errors | Restore from `~/mysql-backups/` |

### Recovery Procedures

#### 1. Rollback After Failed Update
```bash
# List available snapshots
wp-snapshots mysite

# Rollback to latest
wp-rollback mysite

# Or rollback to specific snapshot
wp-rollback mysite 20260419_143022
```

#### 2. Emergency Disk Cleanup
```bash
# Check usage
backup-size

# Emergency cleanup (keeps 2 latest)
backup-emergency

# Verify freed space
df -h
```

#### 3. Fix Permission Issues
```bash
# Fix all sites
wp-fix-perms

# Verify
wp-cli-validator
```

#### 4. Restore from Backup
```bash
# List available backups
backup-list

# Manual restore (example)
cd /var/www/mysite/public_html
tar -xzf ~/backups-lite/lite-mysite-20260419-120000.tar.gz
```

---

## 9. Uninstallation

### Standard Uninstall (Keeps Backups)
```bash
cd wp-server-management-system
./tools/uninstall.sh
```

### Complete Uninstall (Removes Everything)
```bash
./tools/uninstall.sh --force
```

### What Gets Removed
| Component | Standard | --force |
|-----------|----------|---------|
| Shell aliases | ✅ | ✅ |
| `~/scripts/` | ✅ | ✅ |
| Crontab entries | ✅ | ✅ |
| Installation files | ✅ | ✅ |
| Backup directories | ❌ | ✅ |
| Log directories | ❌ | ✅ |
| Quarantine | ❌ | ✅ |

### Manual Cleanup (If Needed)
```bash
rm -rf ~/scripts
rm -rf ~/backups-*
rm -rf ~/mysql-backups
rm -rf ~/logs/wsms
crontab -r  # Removes entire crontab!
```

---

## 10. Log Management

### Log Directory Structure
```
~/logs/wsms/
├── backups/
│   ├── lite.log           # Lite backup operations
│   ├── full.log           # Full backup operations
│   └── mysql.log          # Database backup operations
├── maintenance/
│   ├── updates.log        # WordPress updates
│   └── permissions.log    # Permission fixes
├── security/
│   ├── clamav-scan.log    # Daily malware scans
│   ├── clamav-full.log    # Weekly full scans
│   └── clamav-update.log  # Virus definition updates
├── sync/
│   ├── nas-sync.log       # NAS synchronization
│   └── nas-errors.log     # Sync errors
├── retention/
│   └── retention.log      # Cleanup operations
├── rollback/
│   ├── snapshots.log      # Snapshot creation
│   └── rollback-clean.log # Snapshot cleanup
└── system/
    └── health.log         # System diagnostics
```

### Log Viewing Commands
```bash
# Real-time monitoring
tail -f ~/logs/wsms/backups/lite.log
tail -f ~/logs/wsms/sync/nas-sync.log

# Check for errors
grep -i error ~/logs/wsms/**/*.log
grep -i fail ~/logs/wsms/**/*.log

# View last 50 lines
tail -50 ~/logs/wsms/maintenance/updates.log

# Check NAS sync errors
cat ~/logs/wsms/sync/nas-errors.log

# Search for specific site
grep "mysite" ~/logs/wsms/**/*.log
```

### Log Rotation (Manual)
```bash
# Archive old logs
tar -czf ~/logs-archive-$(date +%Y%m).tar.gz ~/logs/wsms/

# Clear old logs (keep 30 days)
find ~/logs/wsms -name "*.log" -mtime +30 -delete
```

---

## ✅ System Ready

```bash
wp-status      # Quick health check
wp-help        # Full command reference
```

**Maintainer:** Lukasz Malec | [GitHub](https://github.com/maleclukas-prog)
```

---

Kontynuuję z kolejnymi plikami? (README.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE, .gitignore, tools/uninstall.sh, tests/test_suite.sh)