# 🚀 WSMS PRO - WordPress Server Management System

**Version:** 4.0 | **Status:** Production Ready | **License:** MIT

> **The ultimate automation suite for professional WordPress multi-site fleet management on Ubuntu Server.**  
> Built for High Availability, Security Compliance, and Automated Disaster Recovery.

---

## 📖 Overview
**WSMS PRO** is a production-grade automation ecosystem designed to solve the complexities of managing multi-tenant WordPress infrastructures. It uses a **Modular Architecture** with a **Single Source of Truth** (centralized configuration), replacing manual technical debt with a scalable automation layer.

### 🌟 Core Pillars
- 🔍 **Fleet Observability** - Real-time hardware diagnostics and application health audits.
- 🛡️ **Infrastructure Hardening** - Security isolation using isolated system-user contexts and ACLs.
- 💾 **Disaster Recovery** - Multi-tier backup strategy (Lite/Full/MySQL) with Hybrid Cloud sync (NAS).
- 🧹 **Self-Healing Storage** - Heuristic retention engine with "Last-Copy-Safe" data preservation.

---

## 🚀 Quick Deployment
Deploy the entire environment (17 modules + Cron + Aliases) using the Master Installer:

```bash
# 1. Download the installer
wget https://raw.githubusercontent.com/maleclukas-prog/wp-server-management-system/main/install_wsms.sh

# 2. Edit your site details inside the installer
nano install_wsms.sh

# 3. Run deployment
chmod +x install_wsms.sh
./install_wsms.sh
🛠️ Operational Dashboard (Aliases)
Command	Description
wp-status	Executive Overview: Hardware metrics + fleet health in one view.
wp-fleet	Fleet inventory audit (Versions, plugin updates).
wp-update-safe	Production Path: Backup -> Patch -> Verify -> Optimize.
wp-fix-perms	Re-enforce security isolation and ACL policies.
nas-sync	Manual trigger for off-site SFTP synchronization to NAS.
clamav-scan	Initiate recursive daily malware signature audit.
📄 Technical Documentation
Deployment Guide - Step-by-step Standard Operating Procedure.

Technical Reference - Deep dive into script logic.

👤 Maintainer: Lukasz Malec

code
Code
---

### 2. DEPLOYMENT_GUIDE.md (Instrukcja wdrożenia)
*Zaktualizowany o proces edycji pliku `wsms-config.sh`.*

```markdown
# 🚀 WSMS Deployment & Operations Guide (v4.0)

This document provides the Standard Operating Procedure (SOP) for deploying the WSMS PRO environment.

## 📋 Deployment Workflow

### 1. Centralized Configuration
WSMS PRO uses a centralized registry model. Before running the installer, define your sites and NAS parameters in the `MANAGED_SITES` array:
- **Format:** `Identifier:Path:SystemUser`
- **Location:** Inside `install_wsms.sh` (or `~/scripts/wsms-config.sh` after install).

### 2. Automated Installation
The `install_wsms.sh` script performs the following:
1. Initializes the directory structure.
2. Installs dependencies (`WP-CLI`, `ClamAV`, `ACL`, `bc`).
3. Deploys 17 specialized modules to `~/scripts/`.
4. Provisions shell aliases in `~/.bashrc`.
5. Schedules automated maintenance in `crontab`.

### 3. Verification
After installation, run:
```bash
source ~/.bashrc
wp-status
🔧 Incident Response (Troubleshooting)
Scenario	Action
Disk >80%	Run backup-clean. System triggers "Emergency Purge".
Permission Errors	Run wp-fix-perms.
Sync Failure	Inspect ~/logs/nas_sync.log.
code
Code
---

### 3. TECHNICAL_REFERENCE.md (Opis techniczny)
*Zaktualizowany o listę wszystkich 17 modułów.*

```markdown
# 📜 WSMS Technical Module Reference

### 🛠 The Engine: `wsms-config.sh`
The "Brain" of the system. All 17 scripts source this file to retrieve site paths, usernames, and NAS credentials.

### 🔍 Diagnostics & Monitoring
1. `server-health-audit.sh` - Deep hardware & services diagnostics.
2. `wp-fleet-status-monitor.sh` - Version tracking & update auditing.
3. `wp-multi-instance-audit.sh` - Deep site-health and DB integrity check.
4. `wp-cli-infrastructure-validator.sh` - Pre-flight connectivity test.

### 🛡️ Security & Hardening
5. `infrastructure-permission-orchestrator.sh` - Enforces isolation and ACLs.
6. `clamav-auto-scan.sh` - Daily targeted malware detection.
7. `clamav-full-scan.sh` - Weekly root-level system audit.

### 💾 Backup & Recovery
8. `wp-full-recovery-backup.sh` - Full bare-metal site snapshots.
9. `wp-essential-assets-backup.sh` - Lean high-frequency asset backups.
10. `mysql-backup-manager.sh` - Dynamic DB snapshot engine (Regex based).
11. `standalone-mysql-backup-engine.sh` - Low-level mysqldump fallback.
12. `red-robin-system-backup.sh` - Bare-metal OS config recovery.

### 🔄 Automation & Interface
13. `nas-sftp-sync.sh` - Off-site synchronization with Synology NAS.
14. `wp-automated-maintenance-engine.sh` - Fleet-wide patching & optimization.
15. `wp-smart-retention-manager.sh` - Heuristic disk cleanup engine.
16. `wp-interactive-backup-tool.sh` - CLI menu for manual tasks.
17. `wp-help.sh` - Central command reference.

🤝 Maintainer & License
👤 Maintainer: Lukasz Malec

📜 License: MIT License

📅 Last Update: April 2026