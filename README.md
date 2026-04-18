## 📄 PLIK: `README.md` (POPRAWIONA WERSJA)

```markdown
# 🚀 WSMS PRO - WordPress Server Management System

**Version:** 4.1 | **Status:** Production Ready | **License:** MIT

> **The ultimate automation suite for professional WordPress multi-site fleet management on Ubuntu Server.**  
> Built for High Availability, Security Compliance, and Automated Disaster Recovery.

---

## 📖 Overview

**WSMS PRO** is a production-grade automation ecosystem designed to solve the complexities of managing multi-tenant WordPress infrastructures. It uses a **Modular Architecture** with a **Single Source of Truth** (centralized configuration), replacing manual technical debt with a scalable automation layer.

### 🌟 Core Pillars

| Pillar | Description |
|--------|-------------|
| 🔍 **Fleet Observability** | Real-time hardware diagnostics and application health audits |
| 🛡️ **Infrastructure Hardening** | Security isolation using isolated system-user contexts and ACLs |
| 💾 **Disaster Recovery** | Multi-tier backup strategy (Lite/Full/MySQL) with Hybrid Cloud sync |
| 🧹 **Self-Healing Storage** | Heuristic retention engine with "Last-Copy-Safe" data preservation |

---

## 🚀 Quick Deployment

### Prerequisites
- Ubuntu 20.04+ / 22.04+
- Root/sudo access
- WordPress sites with wp-config.php

### One-Command Installation

```bash
# Clone the repository
git clone https://github.com/maleclukas-prog/wp-server-management-system.git
cd wp-server-management-system

# Edit configuration (REQUIRED!)
nano scripts/wsms-config.sh

# Run installer for your shell
# For Bash users:
./installers/install_wsms.sh

# For Fish users:
fish installers/install_wsms.fish
```

### Post-Installation

```bash
# Reload shell configuration
source ~/.bashrc        # For Bash
# OR
source ~/.config/fish/config.fish   # For Fish

# Verify installation
wp-status
```

---

## 🛠️ Operational Dashboard (Aliases)

| Command | Description |
|---------|-------------|
| `wp-status` | Executive Overview: Hardware metrics + fleet health |
| `wp-fleet` | Fleet inventory audit (Versions, plugin updates) |
| `wp-update-safe` | Production Path: Backup → Patch → Verify → Optimize |
| `wp-fix-perms` | Re-enforce security isolation and ACL policies |
| `nas-sync` | Manual trigger for off-site SFTP synchronization |
| `clamav-scan` | Initiate recursive daily malware signature audit |
| `backup-list` | List all backups with size, date, and age |
| `backup-clean` | Interactive cleanup with confirmation |
| `backup-emergency` | Emergency: Keep only 2 latest copies per site |
| `mysql-backup-all` | Backup all WordPress databases |
| `wp-help` | Complete command reference |

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | Step-by-step Standard Operating Procedure |
| [Technical Reference](docs/TECHNICAL_REFERENCE.md) | Deep dive into 17 script modules |

---

## 🔧 Incident Response (SOP)

| Scenario | Action |
|----------|--------|
| Low Disk Space (<20%) | Run `backup-clean` or `backup-emergency` |
| Site Permission Errors | Execute `wp-fix-perms` |
| Update Failure | Run `wp-fix-perms` then `wp-update-safe` |
| Backup Cycle Failed | Check `df -h`, run `wp-interactive-backup-tool` |
| Security Threat Detected | Check `clamav-logs`, inspect `/var/quarantine/` |
| NAS Sync Failed | Check `~/.ssh/` keys, run `nas-sync-logs` |

---

## 📁 Repository Structure

```
wp-server-management-system/
├── .github/              # GitHub templates (issues, PRs)
├── docs/                 # Documentation
│   ├── DEPLOYMENT_GUIDE.md
│   └── TECHNICAL_REFERENCE.md
├── scripts/              # 17 WSMS operational modules
│   └── wsms-config.sh    # Central configuration (EDIT THIS!)
├── installers/           # Installation scripts
│   ├── install_wsms.sh   # Bash installer
│   └── install_wsms.fish # Fish installer
├── LICENSE
└── README.md
```

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

## 🙏 Acknowledgments

- WP-CLI team for the excellent WordPress management tool
- ClamAV for open-source antivirus
- The open-source community for inspiration

---

**✅ SYSTEM READY FOR PRODUCTION DEPLOYMENT**
```

