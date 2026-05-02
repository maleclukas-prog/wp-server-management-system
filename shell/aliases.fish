# ============================================
# WSMS PRO v4.3 - FISH SHELL ALIASES
# Complete Fish Shell Configuration
# Version: 4.3 | Last Updated: May 2026
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
alias wp-hosts-sync='bash $SCRIPTS_DIR/wp-hosts-sync.sh'

# ============================================
# BACKUPS & RECOVERY
# ============================================
alias wp-backup-lite='bash $SCRIPTS_DIR/wp-essential-assets-backup.sh'
alias wp-backup-full='bash $SCRIPTS_DIR/wp-full-recovery-backup.sh'
alias wp-backup-ui='bash $SCRIPTS_DIR/wp-interactive-backup-tool.sh'
alias wp-backup-site='wp-backup-ui'
alias red-robin='bash $SCRIPTS_DIR/red-robin-system-backup.sh'

# ============================================
# 🆕 ROLLBACK SYSTEM (NEW in v4.3)
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
alias backup-emergency-global='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh emergency-global'
alias backup-clean-emergency='backup-emergency'
alias backup-dirs='bash $SCRIPTS_DIR/wp-smart-retention-manager.sh dirs'
alias backup-smart-clean='backup-clean'
alias wsms-clean='bash $HOME/scripts/wsms-clean.sh'
alias wsms-clean-force='bash $HOME/scripts/wsms-clean.sh --force'

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
# LOG VIEWING SHORTCUTS
# ============================================
alias logs-backup='tail -f $HOME/logs/wsms/backups/lite.log'
alias logs-update='tail -f $HOME/logs/wsms/maintenance/updates.log'
alias logs-sync='tail -f $HOME/logs/wsms/sync/nas-sync.log'
alias logs-scan='tail -f $HOME/logs/wsms/security/clamav-scan.log'
alias logs-all='ls -la $HOME/logs/wsms/*/'

# ============================================
# FUNCTIONS
# ============================================
function wp-status
    echo "🌐 WSMS PRO v4.3 - Quick Status:"
    echo "=========================================================="
    wp-list
    echo ""
    backup-size
    echo ""
    echo "📸 Rollback Snapshots:"
    wp-snapshots
    echo ""
    echo "📝 Recent Logs:"
    echo "   Backup: "(tail -1 $HOME/logs/wsms/backups/lite.log 2>/dev/null | cut -c1-50 || echo "No logs")"..."
    echo "   Update: "(tail -1 $HOME/logs/wsms/maintenance/updates.log 2>/dev/null | cut -c1-50 || echo "No logs")"..."
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

function wp-logs
    echo "📝 WSMS Log Files:"
    echo "=========================================================="
    echo "   📂 Backups:"
    echo "      Lite:  "(ls -la $HOME/logs/wsms/backups/lite.log 2>/dev/null | awk '{print $6, $7, $8}' || echo "No log")
    echo "      Full:  "(ls -la $HOME/logs/wsms/backups/full.log 2>/dev/null | awk '{print $6, $7, $8}' || echo "No log")
    echo "      MySQL: "(ls -la $HOME/logs/wsms/backups/mysql.log 2>/dev/null | awk '{print $6, $7, $8}' || echo "No log")
    echo ""
    echo "   📂 Maintenance:"
    echo "      Updates: "(ls -la $HOME/logs/wsms/maintenance/updates.log 2>/dev/null | awk '{print $6, $7, $8}' || echo "No log")
    echo ""
    echo "   📂 Sync:"
    echo "      NAS:    "(ls -la $HOME/logs/wsms/sync/nas-sync.log 2>/dev/null | awk '{print $6, $7, $8}' || echo "No log")
    echo "      Errors: "(ls -la $HOME/logs/wsms/sync/nas-errors.log 2>/dev/null | awk '{print $6, $7, $8}' || echo "No log")
    echo ""
    echo "Use: logs-backup, logs-update, logs-sync, logs-scan"
end

function wp-health
    echo "🏥 WSMS Health Check..."
    echo "=========================================================="
    
    # Check disk space
    set disk_usage (df $HOME | awk 'NR==2 {print $5}' | sed 's/%//')
    if test $disk_usage -gt 80
        echo "   ⚠️ Disk usage: $disk_usage% (CRITICAL)"
    else if test $disk_usage -gt 60
        echo "   ⚠️ Disk usage: $disk_usage% (WARNING)"
    else
        echo "   ✅ Disk usage: $disk_usage%"
    end
    
    # Check services
    if systemctl is-active --quiet nginx; or systemctl is-active --quiet apache2
        echo "   ✅ Web server: Running"
    else
        echo "   ❌ Web server: Stopped"
    end
    
    if systemctl is-active --quiet mysql; or systemctl is-active --quiet mariadb
        echo "   ✅ Database: Running"
    else
        echo "   ❌ Database: Stopped"
    end
    
    # Check WP-CLI
    if command -v wp >/dev/null
        echo "   ✅ WP-CLI: Installed"
    else
        echo "   ❌ WP-CLI: Missing"
    end
    
    # Check recent backup
    set latest_backup (ls -t $HOME/backups-lite/*.tar.gz 2>/dev/null | head -1)
    if test -n "$latest_backup"
        set backup_age (math (date +%s) - (stat -c %Y "$latest_backup"))
        set backup_days (math $backup_age / 86400)
        if test $backup_days -gt 7
            echo "   ❌ Last backup: $backup_days days ago"
        else
            echo "   ✅ Last backup: $backup_days days ago"
        end
    else
        echo "   ❌ No backups found"
    end
end
# ============================================
# PER-SITE WP-CLI (Add your sites here)
# ============================================
# alias wp-site1='sudo -u wordpress_site1 /usr/local/bin/wp --path=/var/www/site1/public_html'
# alias wp-site2='sudo -u wordpress_site2 /usr/local/bin/wp --path=/var/www/site2/public_html'

# ============================================
# WELCOME MESSAGE
# ============================================
echo "✅ WSMS PRO v4.3 - Fish aliases loaded!"
echo "   Type 'wp-help' for command reference"
echo "   Type 'wp-status' for system overview"
echo "   Type 'wp-health' for health check"
echo ""