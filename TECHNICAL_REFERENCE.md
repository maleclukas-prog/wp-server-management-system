📜 WSMS Technical Module Reference
Project: WordPress Server Management System (WSMS)
Architecture: Modular Bash Framework with Centralized Configuration
Version: 4.0 (Production Ready)

🛠 The Brain: wsms-config.sh
Overview:
The "Single Source of Truth" for the entire ecosystem. This configuration file decouples logic from data, allowing the global management of sites, system users, and remote storage parameters.

Key Technical Features:

Centralized Registry: Stores all managed WordPress instances in a structured array.

Dynamic Variable Injection: All 17 scripts source this file to identify target paths and NAS credentials.

Maintainability: Allows scaling from 1 to 100+ sites by editing a single line.

🔍 Section 1: Observability & Diagnostics

1. server-health-audit.sh
Overview:
A comprehensive diagnostic tool for real-time monitoring of hardware resources and service uptime.
Key Features: Audits CPU Load, RAM, and Disk I/O. Uses heuristics to provide operational advice (e.g., "Run cleanup if disk > 80%").
Why for Zepz: Demonstrates a Proactive Monitoring mindset, essential for maintaining high-availability fintech infrastructures.

2. wp-fleet-status-monitor.sh
Overview:
Application-level observability for multi-tenant environments.
Key Features: Extracts core versions and pending updates across the entire server fleet.
Why for Zepz: Shows the ability to manage Fleet Inventory and track technical debt (unpatched software) automatically.

3. wp-multi-instance-audit.sh
Overview:
A deep-dive security and performance auditor for individual WordPress sites.
Key Features: Interfaces with site-health APIs to generate numerical health scores and audit database integrity.
Why for Zepz: Highlights a focus on Application Reliability and deep system visibility.

4. wp-cli-infrastructure-validator.sh
Overview:
A pre-flight connectivity tester for the WSMS automation layer.
Key Features: Validates binary paths and tests user impersonation (sudo -u) connectivity to ensure automation reliability.

🛡️ Section 2: Security & Hardening

5. infrastructure-permission-orchestrator.sh
Overview:
A high-level security engine that enforces the Principle of Least Privilege.
Key Features: Standardizes ownership for isolated PHP-FPM users and implements ACLs (Access Control Lists) for secure backup access.
Why for Zepz: Proves a deep understanding of the Linux Security Model and multi-tenant isolation, critical for handling sensitive financial data environments.

6. clamav-auto-scan.sh
Overview:
Automated daily malware detection targeting high-risk web directories.
Key Features: Recursive scanning with real-time alerting for "FOUND" status files.

7. clamav-full-scan.sh
Overview:
A high-intensity root-level security audit with automated incident response.
Key Features: Scans the entire OS and automatically moves infected files to /var/quarantine.
Why for Zepz: Demonstrates Automated Incident Response capabilities — detecting and isolating threats without manual intervention.

💾 Section 3: Backup & Disaster Recovery (DR)

8. wp-full-recovery-backup.sh
Overview:
Complete bare-metal snapshots for catastrophic failure recovery.
Key Features: Combines optimized SQL dumps with a full filesystem archive.

9. wp-essential-assets-backup.sh
Overview:
A resource-efficient "Lite" backup focusing on unique data (Themes, Plugins, Uploads).
Key Features: Optimized for storage efficiency, capturing 90% of the risk with 30% of the storage footprint.
Why for Zepz: Shows Cost Optimization skills — understanding that storage space in the cloud is a recurring expense.

10. mysql-backup-manager.sh
Overview:
A "Zero-Config" database snapshot engine.
Key Features: Dynamically parses wp-config.php to extract credentials, ensuring passwords are never hardcoded in scripts.

11. standalone-mysql-backup-engine.sh
Overview:
A low-level recovery tool using raw mysqldump logic.
Key Features: Operates independently of high-level CLI tools, providing a reliable fallback in degraded system states.

12. red-robin-system-backup.sh
Overview:
Focuses on "Bare-metal" OS configuration and metadata recovery.
Key Features: Excludes heavy media to prioritize system-level configs (Nginx, PHP, SSH settings).
Why for Zepz: Proves a Disaster Recovery mindset — knowing that data is useless if you cannot reconstruct the server configuration rapidly.

🔄 Section 4: Automation & Hybrid Cloud

13. nas-sftp-sync.sh
Overview:
Orchestrates off-site data synchronization between the VPS and a remote Synology NAS vault.
Key Features: Implements a "Minimum Copy" safety rule — it will never delete the final backup copy, even if it exceeds the retention age.
Why for Zepz: Demonstrates the ability to manage Hybrid Cloud Data Integrity and off-site data durability.

14. wp-automated-maintenance-engine.sh
Overview:
Unattended lifecycle management for the entire fleet.
Key Features: Updates core/plugins/themes, migrates database schemas, and flushes caches in one atomic operation.
Why for Zepz: Aligns with the "Velocity" value — automating routine patches to keep the platform secure and high-performing.

15. wp-smart-retention-manager.sh
Overview:
A heuristic storage cleanup engine.
Key Features: Automatically shifts from "Standard Retention" to "Emergency Purge" if disk usage crosses the 80% threshold.
Why for Zepz: Shows System Self-Healing capabilities — building scripts that manage their own resource consumption.

🛠 Section 5: Operator Interface

16. wp-interactive-backup-tool.sh
Overview:
A menu-driven CLI utility for manual, high-stakes operational tasks.
Key Features: Reduces human error by providing a guided interface for choosing targets and backup depths.

17. wp-help.sh
Overview:
The centralized command reference and internal documentation for system operators.

🏁 Operational Logic Summary
The WSMS is built on the principle of Modular Automation. Instead of one large, fragile script, it uses 17 specialized tools that communicate via the central wsms-config.sh. This architecture ensures that the system is scalable, auditable, and production-ready.

Maintained by Lukasz Malec | maleclukas-prog
17.3s
