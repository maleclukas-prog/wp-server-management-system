## 📄 PLIK 6/12: `README.md`


# 🚀 WSMS PRO - WordPress Server Management System

**Version:** 4.2 | **Status:** Production Ready | **License:** MIT

> **The ultimate automation suite for professional WordPress multi-site fleet management on Ubuntu Server.**  
> Built for High Availability, Security Compliance, and Automated Disaster Recovery.

---

## 🆕 What's New in v4.2

| Feature | Description |
|---------|-------------|
| 🔄 **Rollback Engine** | Instant recovery from failed updates with pre-update snapshots |
| ✅ **Configuration Validation** | Installer validates site configurations before deployment |
| 📊 **Health Verification** | Automatic HTTP checks after updates and rollbacks |
| 📁 **Organized Logs** | Structured log directory `~/logs/wsms/` with categories |
| 🔔 **Notifications** | Optional Slack/Email alerts for critical events |
| 🐛 **Enhanced Error Handling** | SFTP sync with retry logic and separate error logs |
| 🧹 **Universal Uninstaller** | One-command complete system removal |

---

## 📖 Overview

**WSMS PRO** is a production-grade automation ecosystem designed to solve the complexities of managing multi-tenant WordPress infrastructures.

### 🌟 Core Pillars

| Pillar | Description |
|--------|-------------|
| 🔍 **Fleet Observability** | Real-time hardware diagnostics and application health audits |
| 🛡️ **Infrastructure Hardening** | Security isolation using isolated system-user contexts and ACLs |
| 💾 **Disaster Recovery** | Multi-tier backup strategy (Lite/Full/MySQL) with Hybrid Cloud sync |
| 🔄 **Instant Rollback** | Pre-update snapshots for zero-downtime recovery |
| 🧹 **Self-Healing Storage** | Heuristic retention engine with emergency mode |
| 📝 **Organized Logging** | Structured logs in `~/logs/wsms/` for easy debugging |

---

## 🚀 Quick Deployment

### Prerequisites
- Ubuntu 20.04+ / 22.04+
- Root/sudo access
- WordPress sites with `wp-config.php`
- Fish or Bash shell

### One-Command Installation

```bash
# Clone the repository
git clone https://github.com/maleclukas-prog/wp-server-management-system.git
cd wp-server-management-system

# Edit configuration (REQUIRED!)
nano installers/install.sh

# Run installer (works in any shell)
chmod +x installers/install.sh
./installers/install.sh

# Reload your shell
source ~/.bashrc        # For Bash
# OR
source ~/.config/fish/config.fish   # For Fish

# Verify installation
wp-status
```

### Polish Version

```bash
# For Polish installation
./installers/install-pl.sh
```

---

## 🛠️ Command Reference

### 🔄 Rollback Commands (NEW!)

| Command | Description |
|---------|-------------|
| `wp-snapshot all` | Create snapshots for all sites |
| `wp-snapshot [site]` | Create snapshot for specific site |
| `wp-snapshots` | List all available snapshots |
| `wp-snapshots [site]` | List snapshots for specific site |
| `wp-rollback [site]` | Rollback to latest snapshot |
| `wp-rollback [site] [date]` | Rollback to specific snapshot |

### 📊 Monitoring

| Command | Description |
|---------|-------------|
| `wp-status` | Executive overview of entire infrastructure |
| `wp-fleet` | WordPress versions and pending updates |
| `wp-audit` | Deep security and performance audit |
| `wp-cli-validator` | Test WP-CLI connectivity |

### 💾 Backups

| Command | Description |
|---------|-------------|
| `wp-backup-lite` | Fast assets backup (themes, plugins, uploads) |
| `wp-backup-full` | Complete site snapshot |
| `wp-backup-ui` | Interactive backup tool |
| `backup-list` | List all backups with details |
| `backup-size` | Show storage usage |
| `backup-clean` | Interactive cleanup |
| `backup-emergency` | Emergency: keep only 2 latest copies |
| `red-robin` | Emergency system configuration backup |

### 🗄️ Database

| Command | Description |
|---------|-------------|
| `mysql-backup-all` | Backup all WordPress databases |
| `mysql-backup-list` | List available database backups |
| `mysql-backup [site]` | Backup specific database |

### 🔧 Maintenance

| Command | Description |
|---------|-------------|
| `wp-update-safe` | Backup → Snapshot → Update → Verify |
| `wp-update-all` | Fleet-wide unattended updates |
| `wp-fix-perms` | Fix file permissions and security ACLs |
| `nas-sync` | Sync backups to remote NAS |
| `clamav-scan` | Daily malware scan |
| `clamav-deep-scan` | Full system malware scan |

### 📝 Help

| Command | Description |
|---------|-------------|
| `wp-help` | Complete command reference |

---

## 📁 Directory Structure

```
~/scripts/               # 18 operational modules
~/backups-lite/          # Daily asset backups (14 days retention)
~/backups-full/          # Monthly full backups (35 days retention)
~/backups-rollback/      # Pre-update snapshots (7 days retention)
~/mysql-backups/         # Database dumps (7 days retention)
~/logs/wsms/             # Organized log files
├── backups/             # Backup logs
├── maintenance/         # Update/permission logs
├── security/            # ClamAV scan logs
├── sync/                # NAS sync logs
├── retention/           # Retention management logs
├── rollback/            # Rollback operation logs
└── system/              # System health logs
```

---

## 🚨 Incident Response (SOP)

| Scenario | Action |
|----------|--------|
| **Site down after update** | `wp-rollback [site-name]` |
| **Low disk space** | `backup-emergency` |
| **Permission errors (403/500)** | `wp-fix-perms` |
| **Suspected malware** | `clamav-deep-scan` |
| **Backup cycle failed** | `df -h && wp-backup-ui` |
| **NAS sync failed** | `tail ~/logs/wsms/sync/nas-errors.log` |
| **WP-CLI connection failed** | `wp-cli-validator` |
| **White Screen of Death** | `wp-rollback [site-name]` |

---

## 🗑️ Uninstall

```bash
# Complete removal (keeps backups by default)
./tools/uninstall.sh

# Complete removal INCLUDING all backups and logs
./tools/uninstall.sh --force
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | Step-by-step installation SOP |
| [Technical Reference](docs/TECHNICAL_REFERENCE.md) | Deep dive into all 18 modules |
| [Fish Setup Guide](docs/FISH_SETUP_GUIDE.md) | Fish shell configuration |
| [Changelog](CHANGELOG.md) | Version history |

---

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Maintainer

**Lukasz Malec** | [GitHub: maleclukas-prog](https://github.com/maleclukas-prog)

---

## ⭐ Star History

If you find this project useful, please consider giving it a star on GitHub!

---

**✅ WSMS PRO v4.2 - Ready for Production**
```

