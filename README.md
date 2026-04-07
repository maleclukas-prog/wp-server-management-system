# 🚀 WSMS - WordPress Server Management System

**Version:** 4.0 | **Status:** Production Ready | **License:** MIT

[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnubash)](https://www.gnu.org/software/bash/)
[![WordPress](https://img.shields.io/badge/WordPress-6.0+-21759B?logo=wordpress)](https://wordpress.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04LTS+-E95420?logo=ubuntu)](https://ubuntu.com)
[![ClamAV](https://img.shields.io/badge/ClamAV-Integrated-00D4AA?logo=clamav)](https://clamav.net)

> **The ultimate automation ecosystem for managing professional WordPress multi-tenant fleets on Ubuntu Server.**  
> Optimized for Security, Observability, and Automated Disaster Recovery.

---

## 📖 Overview

**WSMS** is a production-grade suite of 17 specialized automation modules designed to bridge the gap between server-side administration and WordPress application maintenance. It replaces manual technical debt with a modular, scalable automation layer.

### 🌟 Core Pillars

- 🔍 **Unified Observability** - Real-time hardware diagnostics and fleet-wide health audits.
- 🛡️ **Infrastructure Hardening** - Multi-tenant isolation using system-user orchestration and granular ACLs.
- 💾 **Disaster Recovery** - Multi-tier backup architecture (Lite/Full/MySQL) with Hybrid Cloud synchronization (Synology NAS).
- 🔄 **Lifecycle Automation** - Unattended patching for WordPress Core, Plugins, and Themes with pre-update safety checks.
- 🧹 **Self-Healing Logic** - Heuristic retention engine that prevents disk exhaustion using "Last-Copy-Safe" policies.

---

## 🚀 Quick Deployment (One-Command Installer)

Deploy the entire management environment, including all 17 modules and automated cron schedules, using the Master Installer:

```bash
curl -sSL https://raw.githubusercontent.com/maleclukas-prog/wp-server-management-system/main/install-wsms.sh | bash
Note: After deployment, run source ~/.bashrc to activate the command center.

📦 System Architecture
WSMS uses a Modular Architecture where all 17 scripts communicate through a centralized configuration file (wsms-config.sh), ensuring a "Single Source of Truth."

Directory Structure
code
Text
/home/ubuntu/
├── scripts/                    # Core Automation Engine (17 Modules)
│   ├── wsms-config.sh         # ⚙️ CENTRAL REGISTRY (Manage sites here)
│   ├── server-health-audit.sh  # Executive hardware dashboard
│   ├── wp-fleet-monitor.sh    # Multi-site version inventory
│   ├── wp-automated-patch.sh  # Patching engine
│   ├── infrastructure-perms.sh # Security & ACL enforcement
│   └── [12 more modules...]   # (See Technical Reference)
├── backups-lite/              # Daily assets cycle
├── backups-full/              # Monthly bare-metal snapshots
├── mysql-backups/             # Compressed SQL repositories
└── logs/                      # Execution & Sync audit trails
🛠️ Operational Dashboard (Aliases)
WSMS provisions high-velocity aliases to your shell environment for rapid infrastructure management.

🔍 Diagnostics & Monitoring
Command	Description
wp-status	Executive Overview: Hardware metrics + fleet health in one view.
system-diag	Root-level hardware audit (CPU, RAM, Disk I/O).
wp-fleet	Fleet inventory audit (Versions, technical debt, updates).
wp-audit	Deep-dive application diagnostics and security vitals.
🔄 Maintenance & Security
Command	Description
wp-update-safe	Production Path: Backup -> Fleet-wide Update -> Optimization.
wp-fix-perms	Re-enforce tenant isolation and security ACLs.
clamav-scan	Initiate recursive daily malware signature audit.
💾 Backup & Data Durability
Command	Description
nas-sync	Manual trigger for off-site SFTP synchronization to NAS.
wp-backup-ui	Interactive CLI menu for on-demand recovery tasks.
red-robin	Critical OS state and configuration backup.
backup-clean	Manually trigger the heuristic smart retention engine.
⏰ Automation Orchestration
The system automates the boring stuff so you can focus on scale. Default Cron schedule:

01:00 - Malware signature updates (freshclam).

02:00 - Off-site sync to remote NAS vault.

03:00 - Proactive malware audit.

04:00 - Heuristic storage cleanup.

06:00 (Sun) - Fleet-wide security patching window.

🔧 Incident Response (SOP)
Scenario	Recovery Action
Storage >80%	System triggers backup-clean (Emergency Purge Mode).
Permission Drift	Run wp-fix-perms to standardize isolated ownership.
Sync Failure	Inspect ~/logs/nas-sync.log and verify NAS SSH keys.
Site Integrity	Run wp-fleet to identify specific service anomalies.
📄 Technical Documentation
Detailed information for each module can be found in the accompanying guides:

Deployment Guide - Step-by-step installation SOP.

Technical Module Reference - Deep dive into script logic.

🤝 Maintainer & License
👤 Maintainer: Lukasz Malec

📜 License: MIT License

📅 Last Update: April 2026