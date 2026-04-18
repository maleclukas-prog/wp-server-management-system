# 📜 WSMS PRO - Technical Module Reference

**Project:** WordPress Server Management System (WSMS)  
**Architecture:** Modular Bash Framework with Centralized Configuration  
**Version:** 4.1 | **Status:** Production Ready | **Last Updated:** April 2026

---

## 🛠 The Brain: `wsms-config.sh`

### Overview
The **"Single Source of Truth"** for the entire ecosystem. This configuration file decouples logic from data, allowing the global management of sites, system users, and remote storage parameters.

### Key Technical Features
- **Centralized Registry:** Stores all managed WordPress instances in a structured array
- **Dynamic Variable Injection:** All 17 scripts source this file to identify target paths and NAS credentials
- **Maintainability:** Allows scaling from 1 to 100+ sites by editing a single line

---

## 🔍 Section 1: Observability & Diagnostics (4 modules)

### 1. `server-health-audit.sh`
**Overview:** Comprehensive diagnostic tool for real-time monitoring of hardware resources and service uptime.

**Key Features:** Audits CPU Load, RAM, and Disk I/O. Uses heuristics to provide operational advice (e.g., "Run cleanup if disk > 80%").

### 2. `wp-fleet-status-monitor.sh`
**Overview:** Application-level observability for multi-tenant environments.

**Key Features:** Extracts core versions and pending updates across the entire server fleet.

### 3. `wp-multi-instance-audit.sh`
**Overview:** Deep-dive security and performance auditor for individual WordPress sites.

**Key Features:** Interfaces with site-health APIs to generate numerical health scores and audit database integrity.

### 4. `wp-cli-infrastructure-validator.sh`
**Overview:** Pre-flight connectivity tester for the WSMS automation layer.

**Key Features:** Validates binary paths and tests user impersonation (sudo -u) connectivity to ensure automation reliability.

---

## 🛡️ Section 2: Security & Hardening (3 modules)

### 5. `infrastructure-permission-orchestrator.sh`
**Overview:** High-level security engine that enforces the Principle of Least Privilege.

**Key Features:** Standardizes ownership for isolated PHP-FPM users and implements ACLs (Access Control Lists) for secure backup access.

### 6. `clamav-auto-scan.sh`
**Overview:** Automated daily malware detection targeting high-risk web directories.

**Key Features:** Recursive scanning with real-time alerting for "FOUND" status files.

### 7. `clamav-full-scan.sh`
**Overview:** High-intensity root-level security audit with automated incident response.

**Key Features:** Scans the entire OS and automatically moves infected files to `/var/quarantine`.

---

## 💾 Section 3: Backup & Disaster Recovery (5 modules)

### 8. `wp-full-recovery-backup.sh`
**Overview:** Complete bare-metal snapshots for catastrophic failure recovery.

**Key Features:** Combines optimized SQL dumps with a full filesystem archive. 35-day retention.

### 9. `wp-essential-assets-backup.sh`
**Overview:** Resource-efficient "Lite" backup focusing on unique data (Themes, Plugins, Uploads).

**Key Features:** Optimized for storage efficiency, capturing 90% of the risk with 30% of the storage footprint. 14-day retention.

### 10. `mysql-backup-manager.sh`
**Overview:** "Zero-Config" database snapshot engine.

**Key Features:** Dynamically parses `wp-config.php` to extract credentials, ensuring passwords are never hardcoded in scripts.

### 11. `standalone-mysql-backup-engine.sh`
**Overview:** Low-level recovery tool using raw mysqldump logic.

**Key Features:** Operates independently of high-level CLI tools, providing a reliable fallback in degraded system states.

### 12. `red-robin-system-backup.sh`
**Overview:** Focuses on "Bare-metal" OS configuration and metadata recovery.

**Key Features:** Excludes heavy media to prioritize system-level configs (Nginx, PHP, SSH settings).

---

## 🔄 Section 4: Automation & Hybrid Cloud (3 modules)

### 13. `nas-sftp-sync.sh`
**Overview:** Orchestrates off-site data synchronization between the VPS and a remote Synology NAS vault.

**Key Features:** Implements a "Minimum Copy" safety rule — it will never delete the final backup copy, even if it exceeds the retention age.

### 14. `wp-automated-maintenance-engine.sh`
**Overview:** Unattended lifecycle management for the entire fleet.

**Key Features:** Updates core/plugins/themes, migrates database schemas, and flushes caches in one atomic operation.

### 15. `wp-smart-retention-manager.sh`
**Overview:** Heuristic storage cleanup engine.

**Key Features:** Automatically shifts from "Standard Retention" to "Emergency Purge" if disk usage crosses the 80% threshold.

---

## 🛠 Section 5: Operator Interface (2 modules)

### 16. `wp-interactive-backup-tool.sh`
**Overview:** Menu-driven CLI utility for manual, high-stakes operational tasks.

**Key Features:** Reduces human error by providing a guided interface for choosing targets and backup depths.

### 17. `wp-help.sh`
**Overview:** Centralized command reference and internal documentation for system operators.

---

## 📊 Retention Policy Summary

| Backup Type | Directory | Retention | Emergency Mode |
|-------------|-----------|-----------|----------------|
| Lite Assets | `~/backups-lite` | 14 days | Keep 2 latest |
| Full Snapshots | `~/backups-full` | 35 days | Keep 2 latest |
| MySQL Dumps | `~/mysql-backups` | 7 days | Keep 2 latest |
| NAS Vault | Remote | 120 days | N/A |

---

## 🏁 Operational Logic Summary

The WSMS is built on the principle of **Modular Automation**. Instead of one large, fragile script, it uses 17 specialized tools that communicate via the central `wsms-config.sh`. This architecture ensures that the system is:

- **Scalable** - Add new sites by editing one line
- **Auditable** - Each module has a single responsibility
- **Production-Ready** - Defensive programming with safety nets

---

## 📁 Quick Reference

| Command | Module |
|---------|--------|
| `wp-status` | server-health-audit.sh |
| `backup-list` | wp-smart-retention-manager.sh |
| `backup-clean` | wp-smart-retention-manager.sh |
| `backup-emergency` | wp-smart-retention-manager.sh |
| `mysql-backup-all` | mysql-backup-manager.sh |
| `wp-update-safe` | wp-essential-assets-backup.sh + wp-automated-maintenance-engine.sh |
| `wp-fix-perms` | infrastructure-permission-orchestrator.sh |
| `nas-sync` | nas-sftp-sync.sh |
| `clamav-scan` | clamav-auto-scan.sh |
| `wp-help` | wp-help.sh |

---

**Maintainer:** Lukasz Malec | [GitHub: maleclukas-prog](https://github.com/maleclukas-prog)

**License:** MIT

**Last Updated:** April 2026