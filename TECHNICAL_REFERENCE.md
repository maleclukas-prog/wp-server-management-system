# WSMS Technical Module Reference
**Project:** WordPress Server Management System (WSMS)
**Scope:** Automation, Security, Observability, and Disaster Recovery

---

## Executive Summary
This document provides a detailed technical breakdown of the automation modules within the WSMS ecosystem. Each script is designed to solve specific operational challenges in a high-availability environment.

---

Script Name: clamav-auto-scan.sh

Overview:
A lightweight security utility designed for Ubuntu servers to automate malware detection. It integrates the ClamAV (Clam Antivirus) engine to perform scheduled audits of the most critical system areas.

Key Technical Features:

Targeted Scanning: Focuses on /home (user data) and /var/www (web application files), where vulnerabilities are most commonly exploited.

Logging & Auditing: Generates detailed logs in /var/log/clamav/ for compliance and security monitoring.

Real-time Alerts: Provides immediate console feedback and counts the number of detected threats ("FOUND" status).

Automation-Ready: Designed to be executed via cron for daily or weekly security maintenance.

Why this is important for Zepz:
This script demonstrates a Security-First mindset. It shows that I don't just manage servers; I actively protect them against unauthorized changes and malicious code, ensuring data integrity for the platform.



Script Name: clamav-full-scan.sh

Overview:
A high-intensity security script designed for deep system audits. Unlike the standard scan, this tool performs a recursive analysis of the entire root filesystem (/) and implements automated threat isolation (Quarantine).

Key Technical Features:

Automated Remediation: Uses the --move flag to immediately isolate suspicious files into a secure /var/quarantine directory, preventing further execution of malicious code.

Intelligent Exclusion: Explicitly excludes virtual Linux filesystems (/proc, /sys, /dev) to optimize performance and prevent false positives/scanning hangs.

Timestamped Auditing: Creates unique, date-stamped log files for historical security tracking and compliance reporting.

Error Redirection: Captures both standard output and errors (2>&1) to ensure a complete audit trail.

Why this is important for Zepz:
This tool demonstrates my ability to implement automated incident response. In a high-stakes fintech environment like Zepz, being able to not only detect but also instantly isolate threats is critical for maintaining infrastructure integrity. It shows I am proactive in protecting the underlying OS, not just the application layer.





Script Name: mysql-backup-manager.sh

Overview:
A sophisticated MySQL backup automation script designed for WordPress multi-site environments. The primary innovation is the Zero-Config approach—the script dynamically parses WordPress configuration files to obtain database credentials, eliminating the need to store sensitive passwords in plain text within the script.

Key Technical Features:

Dynamic Credential Discovery: Uses advanced grep and sed regex patterns to extract DB_NAME, DB_USER, and DB_PASSWORD directly from wp-config.php.

Production-Safe Dumps: Utilizes the --single-transaction flag to ensure database consistency during backup without locking tables, maintaining 100% site uptime.

Validation Layer: Implements pre-backup connectivity tests to ensure the database is responsive before initiating the dump.

Smart Cleanup: Integrated retention logic that automatically prunes old backups, preventing disk overflow.

Modular Interface: Supports backing up all sites at once or targeting specific instances via CLI arguments.

Why this is important for Zepz:
This script demonstrates Security & Efficiency. Instead of hardcoding credentials (a security risk), I developed a method to retrieve them programmatically. This shows I can build tools that are not only functional but also adhere to security best practices and operational automation




Script Name: red-robin-system-backup.sh

Overview:
"Project Red Robin" is a specialized Disaster Recovery (DR) tool designed to capture the entire state of a Linux server's configuration and OS metadata. It is built to complement standard application backups by focusing on system-level files while intelligently excluding high-volume media data that is already synchronized elsewhere.

Key Technical Features:

Smart Exclusions: Uses advanced tar flags to exclude virtual filesystems (/proc, /sys, /dev) and existing backup directories, ensuring the resulting archive is lean and restorable.

Pre-flight Resource Validation: Implements a disk space check before execution to prevent system hangs or storage exhaustion during the compression phase.

Secure Remote Integration: Automates off-site data transfer to a Synology NAS using SFTP with SSH key authentication, ensuring encrypted data in transit.

Operational Excellence: Automated cleanup of temporary local files upon successful remote confirmation, maintaining "Zero-Waste" storage on the source server.

Why this is important for Zepz:
In a high-availability environment like Zepz, the ability to rapidly restore a server's configuration is as important as the data itself. This script demonstrates my Disaster Recovery mindset and my ability to build proactive automation that ensures business continuity. It proves I can manage complex, multi-site infrastructure while prioritizing security and resource optimization.




Script Name: nas-sftp-sync.sh

Overview:
A robust Hybrid Cloud Data Orchestrator designed to securely synchronize local backups to a remote Synology NAS using the SFTP protocol. This script acts as the final layer in a Disaster Recovery strategy, ensuring that critical data is stored off-site and managed according to a professional retention policy.

Key Technical Features:

Differential SFTP Transfer: Implements a "smart-sync" logic that compares local and remote inventories, transferring only missing files to minimize bandwidth and CPU overhead.

Filename-Based Age Detection: Features a regex-driven helper function that parses timestamps directly from filenames to calculate the data's age without relying on fragile filesystem metadata.

Safety Retention Policy: Implements a dual-layer cleanup logic. It prunes files older than 120 days but always guarantees a minimum number of copies (MIN_KEEP_COPIES), protecting against accidental data loss even if local backups stop running.

Automated Directory Bootstrapping: Dynamically detects and creates the remote directory structure on the NAS if it doesn't already exist.

Detailed Operational Auditing: Generates clean, timestamped logs and color-coded console output for real-time monitoring and historical troubleshooting.

Why this is important for Zepz:
This script demonstrates my ability to manage Off-site Data Integrity. In a fintech environment, losing data is not an option. By building this tool, I show that I understand the 3-2-1 backup rule (3 copies, 2 media, 1 off-site) and can implement the complex logic required to manage data life-cycles across different infrastructure providers.






Script Name: server-health-audit.sh

Overview:
An advanced, multi-layered diagnostic utility designed for Linux system administrators. This script goes beyond simple data display; it performs Service Orchestration Validation, Security Isolation Audits, and Heuristic Analysis of system health.

Key Technical Features:

Intelligent Service Auditing: Dynamically detects active PHP-FPM pools and Unix sockets, ensuring web applications are correctly interfaced with the backend.

Application-Level Verification: Maps WordPress root directories to specific system users to verify that security isolation (User-per-Site) is correctly implemented.

Backup Integrity Check: Scans multiple backup repositories to provide a unified view of data density and storage consumption.

Heuristic Recommendation Engine: Features a custom logic layer that analyzes current system metrics (like free disk space and backup counts) to provide actionable advice to the operator.

Resource Monitoring: Real-time extraction of CPU load, memory usage, and network exposure.

Why this is important for Zepz:
This tool highlights my Proactive Monitoring mindset. In a high-scale environment, waiting for a system to fail is not an option. This script shows that I can build tools that automatically identify risks (low disk space, missing backups, misconfigured users) before they become outages. It demonstrates a deep understanding of the full stack—from hardware metrics up to the application configuration.




Script Name: wp-full-recovery-backup.sh

Overview:
A high-integrity Disaster Recovery (DR) tool designed to create complete snapshots of WordPress environments. This script follows a "Maintenance-First" approach, ensuring that databases are optimized and cleaned of temporary data before archiving, which results in smaller, faster-to-restore backup packages.

Key Technical Features:

Pre-Backup Maintenance: Orchestrates wp-cli to perform transient cleanup, object cache flushing, and table optimization. This reduces database overhead and prevents bloated backups.

Granular Filesystem Snapshots: Implements intelligent tar exclusion rules to skip non-essential data (logs, cache directories, temporary files), optimizing storage efficiency.

Modular Architecture: Seamlessly integrates with a centralized MySQL backup engine, following the DRY (Don't Repeat Yourself) principle of software engineering.

Security Integration: Executes optimization commands under specific system users to maintain proper file ownership and security isolation.

Automated Lifecycle Management: Features a built-in retention engine to automatically manage disk space, keeping only the most relevant archives (35-day default).

Why this is important for Zepz:
This script demonstrates a holistic approach to data integrity. In a fintech environment, backups must be both reliable and restorable. By optimizing the data before it is backed up, I demonstrate a commitment to Infrastructure Efficiency and Operational Excellence. It shows I can manage complex, multi-site environments while ensuring that storage costs are kept low and recovery times are kept fast.






Script Name: wp-essential-assets-backup.sh

Overview:
A resource-efficient backup utility designed for high-frequency WordPress maintenance. Unlike "Full" backups, this script implements a Selective Asset Strategy, capturing only the unique data (Uploads, Themes, Plugins, and Configurations) that cannot be reconstructed from core WordPress files. This approach significantly reduces backup window duration and storage costs.

Key Technical Features:

Selective Asset Isolation: Targets specific wp-content subdirectories to avoid backing up gigabytes of static, immutable WordPress core files.

Modular MySQL Integration: Decouples database exports from filesystem archiving by interfacing with a centralized MySQL Backup Engine, following a Micro-service architecture logic.

Permission Handling: Utilizes sudo for secure data access, ensuring even files with restrictive permissions (like those in uploads) are correctly archived.

Resilient Error Logging: Implements a multi-stage validation check—it distinguishes between "non-critical warnings" (e.g., files changed during backup) and "fatal errors," ensuring maximum backup availability.

High-Velocity Retention: Optimized for a 14-day rolling retention cycle, perfect for daily or twice-daily backup schedules.

Why this is important for Zepz:
This script demonstrates Infrastructure Cost Optimization. In cloud environments, storage is a recurring cost. By building a "Lite" backup system that captures 90% of the risk while using only 30% of the space, I show that I am a resource-aware engineer. It also highlights my ability to build modular tools that communicate with each other, a key skill for working in modern technical operations teams.







Script Name: standalone-mysql-backup-engine.sh

Overview:
A robust, CMS-agnostic database backup utility designed for environments where high-level CLI tools may not be available or suitable. This script interfaces directly with the mysqldump engine, providing a reliable fallback or primary backup method for MySQL/MariaDB databases.

Key Technical Features:

Low-Level Portability: Operates independently of CMS-specific libraries (like WP-CLI), ensuring high reliability across different system environments.

Automated Metadata Extraction: Implements an advanced parsing logic to dynamically retrieve database credentials from application configuration files, supporting a Zero-Manual-Config workflow.

Production-Optimized Dumps: Utilizes the --single-transaction flag to maintain data consistency during the backup process without causing service downtime or locking production tables.

Resource Efficiency: Implements the --quick flag to stream data directly to a compressed archive, minimizing memory consumption on the host server.

Automated Compression: Integrates gzip on-the-fly to reduce storage requirements and facilitate faster off-site data transfers.

Why this is important for Zepz:
This script demonstrates my ability to work with core infrastructure tools. While high-level tools are great, a Technical Operations expert must know how to interface with the raw database engine (mysqldump). It shows that I am prepared for edge-case scenarios and can build reliable, high-performance automation that ensures data durability even in complex or degraded environments.





Script Name: wp-interactive-backup-tool.sh

Overview:
An Interactive Operations Utility designed for manual, on-demand backups of multi-site WordPress environments. It provides a user-friendly CLI menu system that allows administrators to quickly perform specific maintenance tasks without typing complex commands, reducing human error during critical operations.

Key Technical Features:

Menu-Driven Interface: Implements a professional CLI menu for target selection, backup type choosing, and bulk operations.

Dual-Depth Backup Strategy:

Lite Mode: Focuses on high-speed asset preservation (Unique data only).

Full Mode: Performs a bare-metal snapshot of the entire web root, ideal for major upgrades or migrations.

Orchestrated Database Maintenance: Integrates wp-cli optimization routines (transient cleanup, database optimization) prior to archiving, following the Infrastructure-as-Code best practice of "Clean Data First."

Modular Architecture: Seamlessly calls the centralized MySQL Engine for database snapshots, ensuring consistent data handling across the entire ecosystem.

Permission-Aware Archiving: Leverages elevated privileges via sudo and tar flags to preserve file ownership and metadata, ensuring a reliable restore process.

Why this is important for Zepz:
This script demonstrates my focus on Operational Velocity and UX. In a fast-paced technology company like Zepz, tools need to be efficient and easy to use. By creating an interactive interface, I show that I can build tools that democratize complex technical tasks, allowing team members to perform safe operations with confidence. It highlights my ability to think about the "end-user" in a technical operations context.






Script Name: wp-smart-retention-manager.sh

Overview:
The Smart Retention Manager is a proactive system administration tool designed to solve the common "Disk Full" issue in backup environments. Unlike standard find -mtime -delete commands, this script implements a Heuristic Safety Layer that prevents the deletion of the "Last Known Good" backup, ensuring that every site always has at least one restorable copy, regardless of its age.

Key Technical Features:

Proactive Disk Utilization Monitoring: Dynamically checks root filesystem usage. If storage crosses a critical threshold (80% by default), it automatically switches from "Retention Mode" to "Emergency Purge Mode."

Last-Copy-Safe Preservation: Implements a pattern-matching logic that identifies unique site backups. It will never delete the final copy of a database or filesystem archive, protecting the infrastructure from total data loss during long periods of inactivity.

Emergency Purge Logic: In high-risk storage scenarios, the script intelligently prunes all but the two most recent archives to instantly reclaim disk space while maintaining recovery options.

Context-Aware Retention: Uses an associative array to apply different data lifecycles to different backup modules (e.g., keeping "Full Snapshots" longer than "Lite Assets").

DevOps Ready: Supports an automated apply mode (force-clean) for integration with system-wide cron jobs, providing "Set and Forget" storage management.

Why this is important for Zepz:
This script demonstrates Operational Excellence and Risk Mitigation. In a production environment, automation that blindly deletes files is a liability. By building a "Safe-to-Delete" logic, I show that I prioritize Data Durability above all. It also demonstrates my ability to write complex bash scripts that handle failure states (like low disk space) gracefully—a key requirement for any Senior Technical Operations role.






Script Name: wp-multi-instance-audit.sh

Overview:
A robust Infrastructure Observability script designed to provide an automated, bird's-eye view of all WordPress instances on a single server. It functions as a proactive monitoring tool, identifying performance bottlenecks, security vulnerabilities, and database inconsistencies before they lead to service degradation.

Key Technical Features:

Secure User Impersonation: Utilizes sudo -u [user] orchestration to perform audits within the site’s own security context, adhering strictly to the Principle of Least Privilege.

Full-Stack Health Check: Integrates native Linux commands (stat, lsb_release) with WP-CLI for a unified diagnostic report encompassing the OS, Database, and CMS layers.

Proactive Maintenance Indicators: Specifically audits plugin update availability and core integrity, aiding in the reduction of technical debt.

Heuristic Security Analysis: Directly inspects filesystem permissions of the wp-config.php file and provides hardening recommendations based on industry best practices.

Site Health Integration: Parses WordPress's internal health metrics to output a numerical "Health Score" directly to the CLI console.

Why this is important for Zepz:
At a fintech company like Zepz, visibility and security are paramount. This script demonstrates my ability to build audit-ready systems where every application instance is monitored and validated. It shows rekrutera that I am a proactive engineer who values automation as a tool for security, ensuring that all managed environments are running optimal, patched, and securely isolated software.






Script Name: infrastructure-permission-orchestrator.sh

Overview:
A high-level Security & Infrastructure Orchestration script designed for managing Linux-based web environments. This tool addresses the complex challenge of managing filesystem permissions in multi-tenant environments, ensuring that web services (Nginx/PHP-FPM) and background tasks (Backups/CRON) have the exact level of access required without compromising security.

Key Technical Features:

Multi-Version PHP-FPM Discovery: Dynamically detects and manages all installed PHP-FPM versions on the server, ensuring service continuity across different runtime environments.

Tenant Isolation Logic: Standardizes ownership and permissions (755/644) while enforcing strict isolation between different site owners to prevent cross-account vulnerabilities.

Advanced ACL Implementation: Utilizes Access Control Lists (ACLs) to grant the backup operator ('ubuntu') granular read access to web roots without altering the primary ownership or weakening the PHP-FPM security context.

Privilege Escalation Remediation: Automatically audits backup repositories to identify and fix "Root-owned" artifacts, ensuring all automated tasks can be managed by the appropriate non-privileged user.

System Hardening: Implements security best practices for global temporary directories and PHP session storage to prevent session hijacking and unauthorized data access.

Why this is important for Zepz:
In a fintech/tech-focused company like Zepz, Security is the foundation. This script demonstrates my deep understanding of the Linux Security Model. It shows rekrutera that I don't just "make things work"—I make them work securely. By implementing isolated user contexts and granular ACLs, I prove that I can design and maintain infrastructure that is both audit-ready and resilient against common attack vectors.








Script Name: wp-fleet-status-monitor.sh

Overview:
A high-visibility Infrastructure Observability tool designed to manage and monitor a multi-tenant WordPress fleet. This script provides an automated "Inventory Audit," giving system administrators real-time data on site availability, software versioning, and technical debt (pending updates) across the entire server environment.

Key Technical Features:

Multi-Tenant Awareness: Specifically engineered for servers with multiple isolated users, using sudo -u orchestration to query data within the correct security context.

Fleet Lifecycle Monitoring: Extracts core WordPress versions and provides a granular count of active plugins and themes for each instance.

Proactive Maintenance Alerts: Detects and reports pending security updates for themes and plugins, enabling "Just-in-Time" patching.

Automated Health Verification: Implements multi-stage validation, checking both the filesystem (directory existence) and application layer (wp-config.php integrity).

Operational Reporting: Generates a professional console-based "Health Dashboard" with color-coded status indicators and a final fleet-wide executive summary.

Why this is important for Zepz:
This tool highlights my Proactive Operations mindset. In a high-stakes tech company like Zepz, being able to audit the health of dozens of service instances in seconds is a critical efficiency gain. It demonstrates my ability to build scalable monitoring solutions that handle security isolation (multi-user) and technical maintenance (updates) automatically. It proves I value data-driven infrastructure management.




Script Name: wp-cli-infrastructure-validator.sh

Overview:
A diagnostic utility designed to validate the integration of WP-CLI (the industry-standard Command Line Interface for WordPress) within a multi-tenant Linux environment. This script acts as an automated "smoke test" to ensure that both the global binary and individual site configurations are correctly set up for administrative automation.

Key Technical Features:

Dependency Verification: Performs a clean validation of the global WP-CLI installation, capturing version metadata for the audit trail.

Security Context Validation: Uses sudo -u to execute commands within the specific system-user context of each WordPress instance. This verifies that filesystem permissions and database connectivity are correctly configured for that specific user.

Multi-Site Awareness: Supports auditing across multiple environments (Production, Staging, Dev) in a single run.

Detailed Output Reporting: Provides color-coded feedback on connectivity status, version detection, and common failure points (e.g., missing paths or permission errors).

Administrator Toolkit: Includes a quick-reference guide of essential WP-CLI commands to assist on-call engineers with rapid site troubleshooting.

Why this is important for Zepz:
This script demonstrates Proactive Quality Assurance. In a high-stakes environment like Zepz, before running complex updates or backup routines, you need to be 100% sure the underlying communication layer is stable. By building this validator, I show that I value Predictable Automation—ensuring that my tools only run in a healthy, verified environment. It also proves I have a deep understanding of Linux privilege isolation (running site commands as specific users).



Script Name: wp-automated-maintenance-engine.sh

Overview:
A mission-critical Infrastructure Automation script designed for high-availability multi-tenant WordPress environments. This engine provides a "Single-Pane-of-Glass" update mechanism, ensuring that the entire server fleet—from Core files to individual extensions—is patched, secure, and optimized with zero manual intervention.

Key Technical Features:

Tenant Isolation Logic: Executes all administrative tasks via sudo -u orchestration, ensuring that maintenance operations respect individual system-user boundaries and do not break security isolation.

Integrated Database Migration: Automatically detects and applies required database schema updates after Core upgrades, preventing "Database Update Required" errors on the frontend.

Proactive Conflict Mitigation: Explicitly checks for update availability before initiating the process, reducing system overhead and preventing unnecessary execution.

Self-Healing & Optimization: Includes a post-maintenance phase that invalidates object caches and purges expired transients, ensuring immediate performance gains after patching.

Operational Auditing: Features a final "Fleet Verification" logic that audits the health of all managed instances at the end of the cycle to confirm a 100% success rate.

Why this is important for Zepz:
In a technical environment like Zepz, manual work is technical debt. This script demonstrates my ability to build scalable maintenance pipelines. Instead of managing sites one-by-one, I built an "engine" that treats infrastructure as a single, manageable fleet. It highlights my deep knowledge of service orchestration, security isolation, and unattended operations—key requirements for any Technical Operations Manager or SysAdmin role.






