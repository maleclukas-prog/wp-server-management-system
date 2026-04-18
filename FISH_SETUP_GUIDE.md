## 📄 FILE: `FISH_SETUP_GUIDE.md`

```markdown
# 🐟 WSMS PRO - Fish Shell Configuration Guide

**Version:** 4.1 | **For:** Ubuntu Server with Fish Shell

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Create Config Directory](#1-create-config-directory)
3. [Create Fish Config File](#2-create-fish-config-file)
4. [Reload Configuration](#3-reload-configuration)
5. [Verification](#4-verification)
6. [Troubleshooting](#5-troubleshooting)

---

## Prerequisites

- Fish shell installed (`sudo apt install fish`)
- WSMS PRO scripts installed in `~/scripts/`
- Central config file `~/scripts/wsms-config.sh` configured

---

## 1. Create Config Directory

```fish
mkdir -p ~/.config/fish
```

---

## 2. Create Fish Config File

**File:** `~/.config/fish/config.fish`

Copy and paste the ENTIRE block below:

```fish
# ============================================
# WSMS PRO v4.1 - FISH SHELL CONFIGURATION
# ============================================

set -gx SCRIPTS_DIR "$HOME/scripts"

# ============================================
# SYSTEM DIAGNOSTICS
# ============================================
alias system-diag='bash $SCRIPTS_DIR/server-health-audit.sh'
alias scripts-dir='ls -la $SCRIPTS_DIR/'

# ============================================
# WORDPRESS MANAGEMENT
# ============================================
alias wp-list='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-cli-validator='bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'

# ============================================
# UPDATES
# ============================================
alias wp-update='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update-all='wp-update'

# ============================================
# BACKUPS
# ============================================
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'

# ============================================
# BACKUP MANAGEMENT
# ============================================
alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean'
alias backup-force-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias backup-dirs='ls -la $HOME/backups-*'

# ============================================
# DATABASE MANAGEMENT
# ============================================
alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
alias mysql-backup='db-backup'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias mysql-backup-list='bash $SCRIPTS_DIR/mysql-backup-manager.sh list'

# ============================================
# HELP
# ============================================
alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'

# ============================================
# NAS SYNC
# ============================================
alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias nas-sync-logs='tail -f $HOME/logs/nas_sync.log'
alias nas-sync-status='echo "📊 Last NAS sync:"; tail -10 $HOME/logs/nas_sync.log 2>/dev/null || echo "No logs yet"'

# ============================================
# CLAMAV
# ============================================
alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias clamav-deep-scan='bash $SCRIPTS_DIR/clamav-full-scan.sh'
alias clamav-status='sudo systemctl status clamav-daemon --no-pager | head -15'
alias clamav-update='sudo freshclam'
alias clamav-logs='sudo tail -f /var/log/clamav/auto_scan.log'

# ============================================
# FUNCTIONS
# ============================================
function wp-status
    echo "🌐 Quick Status:"
    wp-list
    echo ""
    backup-size
end

function wp-update-safe
    echo "📦 Creating backup first..."
    wp-backup-lite
    and echo "⏳ Waiting 10 seconds..."
    and sleep 10
    and echo "🔄 Running updates..."
    and wp-update-all
    and echo "✅ Update completed successfully!"
end

function wp-quick-status
    wp-status
end

echo "✅ WSMS PRO v4.1 - Fish aliases loaded!"
```

---

## 3. Reload Configuration

```fish
source ~/.config/fish/config.fish
```

---

## 4. Verification

Run these commands to verify everything works:

```fish
# Check if aliases are loaded
alias | wc -l

# Test specific aliases
wp-status
backup-list
wp-help | head -20

# Check Fish version
fish --version
```

**Expected output:** 30+ aliases, wp-status shows system diagnostics.

---

## 5. Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found` | Run `source ~/.config/fish/config.fish` again |
| Aliases not loading | Check file exists: `ls -la ~/.config/fish/config.fish` |
| Syntax errors | Open file: `nano ~/.config/fish/config.fish` and check for typos |
| WP-CLI errors | Run `wp-cli-validator` to test connectivity |

---

## 📁 One-Line Installation

Copy and paste this ENTIRE command into your Fish terminal:

```fish
mkdir -p ~/.config/fish && cat > ~/.config/fish/config.fish << 'FISH_EOF'
# ============================================
# WSMS PRO v4.1 - FISH SHELL CONFIGURATION
# ============================================

set -gx SCRIPTS_DIR "$HOME/scripts"

alias system-diag='bash $SCRIPTS_DIR/server-health-audit.sh'
alias scripts-dir='ls -la $SCRIPTS_DIR/'
alias wp-list='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-audit='bash $SCRIPTS_DIR/wp-multi-instance-audit.sh'
alias wp-fleet='bash $SCRIPTS_DIR/wp-fleet-status-monitor.sh'
alias wp-cli-validator='bash $SCRIPTS_DIR/wp-cli-infrastructure-validator.sh'
alias wp-fix-perms='bash $SCRIPTS_DIR/infrastructure-permission-orchestrator.sh'
alias wp-update='bash $SCRIPTS_DIR/wp-automated-maintenance-engine.sh'
alias wp-update-all='wp-update'
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'
alias backup-list='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh list'
alias backup-size='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh size'
alias backup-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh clean'
alias backup-force-clean='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh force-clean'
alias backup-emergency='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency'
alias backup-dirs='ls -la $HOME/backups-*'
alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
alias mysql-backup='db-backup'
alias mysql-backup-all='bash $SCRIPTS_DIR/mysql-backup-manager.sh all'
alias mysql-backup-list='bash $SCRIPTS_DIR/mysql-backup-manager.sh list'
alias wp-help='bash $SCRIPTS_DIR/wp-help.sh'
alias nas-sync='bash $SCRIPTS_DIR/nas-sftp-sync.sh'
alias nas-sync-logs='tail -f $HOME/logs/nas_sync.log'
alias clamav-scan='bash $SCRIPTS_DIR/clamav-auto-scan.sh'
alias clamav-deep-scan='bash $SCRIPTS_DIR/clamav-full-scan.sh'
alias clamav-status='sudo systemctl status clamav-daemon --no-pager | head -15'
alias clamav-update='sudo freshclam'
alias clamav-logs='sudo tail -f /var/log/clamav/auto_scan.log'

function wp-status
    echo "🌐 Quick Status:"
    wp-list
    echo ""
    backup-size
end

function wp-update-safe
    echo "📦 Creating backup first..."
    wp-backup-lite
    and echo "⏳ Waiting 10 seconds..."
    and sleep 10
    and echo "🔄 Running updates..."
    and wp-update-all
    and echo "✅ Update completed successfully!"
end

echo "✅ WSMS PRO v4.1 - Fish aliases loaded!"
FISH_EOF

source ~/.config/fish/config.fish
echo ""
echo "✅ Fish configuration complete! Test with: wp-status"
```

---

## ✅ Final Check

```fish
# This should show system diagnostics
wp-status

# This should show available commands
wp-help | head -30
```

**Maintainer:** Lukasz Malec | [GitHub](https://github.com/maleclukas-prog)
```