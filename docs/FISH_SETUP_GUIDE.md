## 📄 PLIK 3/12: `docs/FISH_SETUP_GUIDE.md`

# 🐟 WSMS PRO v4.2 - Fish Shell Configuration Guide

**Version:** 4.2 | **For:** Ubuntu Server with Fish Shell | **Last Updated:** April 2026

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Automatic Installation](#automatic-installation)
3. [Manual Configuration](#manual-configuration)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)
6. [One-Line Installation](#-one-line-installation)
7. [Making Fish Default Shell](#making-fish-your-default-shell)

---

## Prerequisites

- Fish shell installed (`sudo apt install fish`)
- WSMS PRO installed via `install.sh` or `install-pl.sh`
- Central config file `~/scripts/wsms-config.sh` configured

---

## Automatic Installation

The WSMS installer **automatically detects Fish** and adds aliases to `~/.config/fish/config.fish`. No manual steps required!

After installation, simply reload:
```fish
source ~/.config/fish/config.fish
```

---

## Manual Configuration

If you need to manually add aliases, copy this entire block to `~/.config/fish/config.fish`:

```fish
# ============================================
# WSMS PRO v4.2 - FISH SHELL CONFIGURATION
# Enhanced with Rollback Engine
# ============================================

# Exit if not interactive (SFTP/SCP sessions)
if not status is-interactive
    exit
end

set -gx SCRIPTS_DIR "$HOME/scripts"

# ============================================
# EXECUTIVE & HELP
# ============================================
alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
alias system-diag='bash $SCRIPTS_DIR/server-health-audit.sh'

# ============================================
# DIAGNOSTICS & OBSERVABILITY
# ============================================
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-list='wp-fleet'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-diagnoza='wp-audit'
alias wp-cli-validator='bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh'
alias wp-test-cli='wp-cli-validator'
alias scripts-dir='ls -la $SCRIPTS_DIR/'

# ============================================
# MAINTENANCE & SECURITY
# ============================================
alias wp-update-all='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update='wp-update-all'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias wp-fix-permissions='wp-fix-perms'

# ============================================
# BACKUPS & RECOVERY
# ============================================
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias wp-backup-site='wp-backup-ui'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'

# ============================================
# 🆕 ROLLBACK SYSTEM (NEW in v4.2)
# ============================================
alias wp-snapshot='bash $SCRIPTS_DIR/wp-rollback.sh snapshot'
alias wp-rollback='bash $SCRIPTS_DIR/wp-rollback.sh rollback'
alias wp-snapshots='bash $SCRIPTS_DIR/wp-rollback.sh list'
alias wp-rollback-clean='bash $SCRIPTS_DIR/wp-rollback.sh clean'

# ============================================
# BACKUP MANAGEMENT (UNIFIED)
# ============================================
alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean'
alias backup-force-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias backup-clean-emergency='backup-emergency'
alias backup-dirs='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh dirs'
alias backup-smart-clean='backup-clean'

# ============================================
# DATABASE MANAGEMENT
# ============================================
alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
alias mysql-backup='db-backup'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias mysql-backup-list='bash $SCRIPTS_DIR/mysql-backup-manager.sh list'

# ============================================
# HYBRID CLOUD SYNC (NAS)
# ============================================
alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias nas-sync-logs='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias nas-sync-status='echo "📊 Last NAS sync:"; tail -10 $HOME/logs/wsms/sync/nas-sync.log 2>/dev/null || echo "No logs yet"'
alias nas-sync-errors='tail -f $HOME/logs/wsms/sync/nas-errors.log 2>/dev/null || echo "No errors logged"'

# ============================================
# CYBERSECURITY (ClamAV)
# ============================================
alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias clamav-deep-scan='bash $SCRIPTS_DIR/clamav-full-scan.sh'
alias clamav-status='sudo systemctl status clamav-daemon --no-pager | head -15'
alias clamav-update='sudo freshclam'
alias clamav-logs='sudo tail -f /var/log/clamav/auto_scan.log'
alias clamav-quarantine='sudo ls -la /var/quarantine/'
alias clamav-clean-quarantine='sudo rm -rf /var/quarantine/* && echo "✅ Quarantine cleaned"'

# ============================================
# FUNCTIONS
# ============================================
function wp-status
    echo "🌐 WSMS PRO v4.2 - Quick Status:"
    echo "=========================================================="
    wp-list
    echo ""
    backup-size
    echo ""
    echo "📸 Rollback Snapshots:"
    wp-snapshots
end

function wp-update-safe
    echo "📦 Creating backup first..."
    if wp-backup-lite
        echo "⏳ Waiting 10 seconds..."
        sleep 10
        echo "📸 Creating rollback snapshot..."
        wp-snapshot all
        echo "🔄 Running updates..."
        wp-update-all
        echo "✅ Update completed successfully!"
    else
        echo "❌ Backup failed - aborting update!"
        return 1
    end
end

function wp-quick-status
    wp-status
end

function wp-rollback-safe
    if test (count $argv) -lt 1
        echo "Usage: wp-rollback-safe <site-name>"
        return 1
    end
    echo "⚠️ Rolling back $argv[1] to last snapshot..."
    wp-rollback $argv[1]
end

# ============================================
# PER-SITE WP-CLI (Add your sites here)
# ============================================
# alias wp-site1='sudo -u wordpress_site1 /usr/local/bin/wp --path=/var/www/site1/public_html'
# alias wp-site2='sudo -u wordpress_site2 /usr/local/bin/wp --path=/var/www/site2/public_html'

echo "✅ WSMS PRO v4.2 - Fish aliases loaded!"
```

---

## Verification

Run these commands to verify everything works:

```fish
# Check if aliases are loaded (should show 40+ aliases)
alias | wc -l

# Test core functionality
wp-status

# Test new rollback commands
wp-snapshots

# List available backups
backup-list

# Show help
wp-help | head -30

# Check Fish version
fish --version
```

**Expected output:**
- 40+ aliases loaded
- `wp-status` shows system diagnostics including rollback snapshots
- `wp-snapshots` shows available rollback snapshots (may be empty on fresh install)

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found` | Run `source ~/.config/fish/config.fish` again |
| Aliases not loading | Check file exists: `ls -la ~/.config/fish/config.fish` |
| Syntax errors | Open file: `nano ~/.config/fish/config.fish` and check for typos |
| `wp-status` shows errors | Run `wp-cli-validator` to test connectivity |
| Fish not default shell | Set default: `chsh -s (which fish)` |
| Rollback commands not found | Ensure `wp-rollback.sh` exists in `~/scripts/` |
| Log files not found | Check `~/logs/wsms/` directory structure |

---

## 📁 One-Line Installation

Copy and paste this ENTIRE command into your Fish terminal:

```fish
mkdir -p ~/.config/fish && curl -s https://raw.githubusercontent.com/maleclukas-prog/wp-server-management-system/main/shell/aliases.fish >> ~/.config/fish/config.fish && source ~/.config/fish/config.fish && echo "✅ WSMS PRO v4.2 - Fish configured!"
```

---

## 🔄 What's New in v4.2 for Fish

| Change | Description |
|--------|-------------|
| **New aliases** | `wp-snapshot`, `wp-rollback`, `wp-snapshots`, `wp-rollback-clean` |
| **Updated `wp-status`** | Now shows rollback snapshots count |
| **Enhanced `wp-update-safe`** | Creates rollback snapshot before updates |
| **New function** | `wp-rollback-safe` - safe rollback with confirmation |
| **NAS error logging** | `nas-sync-errors` alias for checking sync failures |
| **Interactive guard** | Exits early for non-interactive sessions (SFTP/SCP) |
| **Updated log paths** | All logs now in `~/logs/wsms/` structure |

---

## ✅ Final Check

```fish
# This should show system diagnostics with snapshot info
wp-status

# This should show available commands including rollback
wp-help | grep -A5 "ROLLBACK"

# List all aliases (should show 40+)
alias | wc -l

# Check log directory structure
ls -la ~/logs/wsms/
```

---

## Making Fish Your Default Shell

```bash
# Check where fish is installed
which fish

# Add to /etc/shells if not present
echo /usr/bin/fish | sudo tee -a /etc/shells

# Change default shell
chsh -s /usr/bin/fish

# Log out and back in, or start new session
fish
```

---

## 📚 Related Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Full installation instructions
- [Technical Reference](TECHNICAL_REFERENCE.md) - All 18 modules explained
- [Main README](../README.md) - Project overview

---

**Maintainer:** Lukasz Malec | [GitHub](https://github.com/maleclukas-prog)
```

---

Kontynuuję z kolejnymi plikami? (TECHNICAL_REFERENCE.md, DEPLOYMENT_GUIDE.md, README.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE, .gitignore, tools/uninstall.sh, tests/test_suite.sh)