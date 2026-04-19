#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MASTER REFERENCE GUIDE
# Complete command reference with rollback system documentation
# Enhanced with Health Check, Log Management, and Interactive Help
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}🆘 WSMS PRO v4.2 - MASTER REFERENCE GUIDE${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "⏰ System Time: $(date)"
echo -e "📦 Version: 4.2 (Enhanced with Rollback Engine)"
echo -e "📂 Config: $(basename "$HOME")/scripts/wsms-config.sh"
echo ""

# ============================================
# QUICK START
# ============================================
echo -e "${CYAN}▶ QUICK START - Most Important Commands${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Full overview: hardware + WordPress + backups"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "WordPress versions and available updates"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "Safe update (Backup → Snapshot → Update)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Create rollback snapshots for all sites"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site]" "Restore site to latest snapshot"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-health" "Quick health check of system"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "This document"
echo ""

# ============================================
# ROLLBACK SYSTEM (NEW!)
# ============================================
echo -e "${CYAN}▶ 🔄 ROLLBACK SYSTEM - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Automatic pre-update snapshots enable instant"
echo -e "            site recovery in case of update failures."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot all" "Create snapshots for ALL sites"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot [site]" "Create snapshot for specific site"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshots" "List all available snapshots"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshots [site]" "List snapshots for specific site"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback [site]" "Restore to LATEST snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback [site] [date]" "Restore to specific snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback-safe [site]" "Rollback with confirmation"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback-clean [days]" "Clean old snapshots (default: $RETENTION_ROLLBACK days)"
echo ""
echo -e "${YELLOW}Examples:${NC}"
echo "   wp-snapshot mysite"
echo "   wp-snapshots mysite"
echo "   wp-rollback mysite"
echo "   wp-rollback mysite 20260419_143022"
echo ""

# ============================================
# BACKUP MANAGEMENT
# ============================================
echo -e "${CYAN}▶ 💾 BACKUP MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Three-tier backup system (Lite/Full/MySQL)"
echo "            with automatic retention management."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-lite" "Fast backup (themes, plugins, uploads, config)"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-full" "Complete site snapshot"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-ui" "Interactive backup tool"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-site" "Alias for wp-backup-ui"
printf "  ${GREEN}%-26s${NC} %s\n" "red-robin" "Emergency system configuration backup"
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "backup-list" "List all backups with details"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-size" "Show backup storage usage"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-dirs" "Show backup directory structure"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-clean" "Interactive cleanup (with confirmation)"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-force-clean" "Automatic cleanup based on retention"
printf "  ${GREEN}%-26s${NC} %s\n" "backup-emergency" "EMERGENCY: keep only 2 latest copies"
echo ""

# ============================================
# DATABASE MANAGEMENT
# ============================================
echo -e "${CYAN}▶ 🗄️ DATABASE MANAGEMENT${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Automatic database backups reading credentials"
echo "            directly from wp-config.php files."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup-all" "Backup all WordPress databases"
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup-list" "List available database backups"
printf "  ${GREEN}%-26s${NC} %s\n" "mysql-backup [site]" "Backup specific database"
printf "  ${GREEN}%-26s${NC} %s\n" "db-backup" "Alias for mysql-backup"
echo ""

# ============================================
# MAINTENANCE & SECURITY
# ============================================
echo -e "${CYAN}▶ 🔧 MAINTENANCE & SECURITY${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Tools for maintaining and securing infrastructure."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update-all" "Update all sites (without backup)"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-update" "Alias for wp-update-all"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-perms" "Fix file permissions and ACLs"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-fix-permissions" "Alias for wp-fix-perms"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-audit" "Deep security and performance audit"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-diagnoza" "Alias for wp-audit"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-cli-validator" "Test WP-CLI connectivity for all sites"
printf "  ${GREEN}%-26s${NC} %s\n" "system-diag" "Operating system diagnostics"
echo ""

# ============================================
# NAS SYNC
# ============================================
echo -e "${CYAN}▶ ☁️ NAS SYNCHRONIZATION${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Automatic backup replication to remote NAS/SFTP server."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync" "Manual trigger for synchronization"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync-status" "Show last synchronization status"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync-logs" "View sync logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "nas-sync-errors" "View sync errors (live)"
echo ""

# ============================================
# CLAMAV ANTIVIRUS
# ============================================
echo -e "${CYAN}▶ 🛡️ CLAMAV - ANTIVIRUS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Malware scanning with automatic quarantine."
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-scan" "Daily quick scan (/var/www, /home)"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-deep-scan" "Full system scan (everything)"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-status" "ClamAV service status"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-update" "Update virus definitions"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-logs" "View scan logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-quarantine" "List quarantined files"
printf "  ${GREEN}%-26s${NC} %s\n" "clamav-clean-quarantine" "Empty quarantine"
echo ""

# ============================================
# 🆕 HEALTH CHECK SYSTEM (NEW!)
# ============================================
echo -e "${CYAN}▶ 🏥 HEALTH CHECK SYSTEM - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Quick system health diagnostics"
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-health" "Complete health check"
printf "  ${GREEN}%-26s${NC} %s\n" "wp-quick-status" "Alias for wp-status"
echo ""

# ============================================
# 🆕 LOG MANAGEMENT (NEW!)
# ============================================
echo -e "${CYAN}▶ 📝 LOG MANAGEMENT - NEW in v4.2${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Quick access to log files"
echo ""
printf "  ${GREEN}%-26s${NC} %s\n" "wp-logs" "Show all log files status"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-backup" "View backup logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-update" "View update logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-sync" "View NAS sync logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-scan" "View malware scan logs (live)"
printf "  ${GREEN}%-26s${NC} %s\n" "logs-all" "List all log directories"
echo ""

# ============================================
# PER-SITE WP-CLI
# ============================================
echo -e "${CYAN}▶ 🎯 PER-SITE WP-CLI ACCESS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Description:${NC} Direct WP-CLI access for each site"
echo "            with the correct system user."
echo ""

for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-$name" "WP-CLI for $name (user: $user)"
done

echo ""
echo -e "${YELLOW}Usage examples:${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo "   wp-$name plugin list"
    echo "   wp-$name core version"
    echo "   wp-$name user list"
    break
done
echo ""

# ============================================
# PER-SITE QUICK COMMANDS
# ============================================
echo -e "${CYAN}▶ ⚡ PER-SITE QUICK COMMANDS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-backup-$name" "Lite backup for $name"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-snapshot-$name" "Rollback snapshot for $name"
    printf "  ${GREEN}%-26s${NC} %s\n" "wp-rollback-$name" "Rollback for $name"
    echo ""
done

# ============================================
# RETENTION POLICIES
# ============================================
echo -e "${CYAN}▶ 📊 DATA RETENTION POLICIES${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Directories and retention periods:${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %-18s %s\n" "Backup Type" "Directory" "Retention"
echo "  ------------------------------------------------------------------"
printf "  %-22s %-18s %s\n" "⚡ Lite Assets" "~/backups-lite/" "$RETENTION_LITE days"
printf "  %-22s %-18s %s\n" "💾 Full Snapshots" "~/backups-full/" "$RETENTION_FULL days"
printf "  %-22s %-18s %s\n" "🗄️ MySQL Dumps" "~/mysql-backups/" "$RETENTION_MYSQL days"
printf "  %-22s %-18s %s\n" "📸 Rollback Snapshots" "~/backups-rollback/" "$RETENTION_ROLLBACK days"
printf "  %-22s %-18s %s\n" "☁️ NAS Vault" "Remote NAS" "$NAS_RETENTION_DAYS days"
echo ""
echo -e "${RED}⚠️ EMERGENCY MODE:${NC} When disk usage > ${DISK_ALERT_THRESHOLD}%,"
echo "   system automatically keeps only 2 latest copies."
echo ""

# ============================================
# INCIDENT RESPONSE - QUICK REFERENCE
# ============================================
echo -e "${CYAN}▶ 🚨 INCIDENT RESPONSE (SOP)${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Quick reaction to problems:${NC}"
echo ""

printf "  ${RED}%-32s${NC} %s\n" "Site down after update:" "wp-rollback [site-name]"
printf "  ${RED}%-32s${NC} %s\n" "Low disk space:" "backup-emergency"
printf "  ${RED}%-32s${NC} %s\n" "Permission errors (403/500):" "wp-fix-perms"
printf "  ${RED}%-32s${NC} %s\n" "Suspected malware:" "clamav-deep-scan"
printf "  ${RED}%-32s${NC} %s\n" "Backup cycle failed:" "df -h && wp-backup-ui"
printf "  ${RED}%-32s${NC} %s\n" "NAS sync failed:" "nas-sync-status && nas-sync-errors"
printf "  ${RED}%-32s${NC} %s\n" "WP-CLI connection failed:" "wp-cli-validator"
printf "  ${RED}%-32s${NC} %s\n" "White Screen of Death (WSOD):" "wp-rollback [site-name]"
echo ""

# ============================================
# LOG FILES LOCATION
# ============================================
echo -e "${CYAN}▶ 📝 LOG FILES LOCATION${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Log file locations (organized in ~/logs/wsms/):${NC}"
echo ""
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/backups/lite.log" "Lite backups"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/backups/full.log" "Full backups"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/backups/mysql.log" "Database backups"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/maintenance/updates.log" "WordPress updates"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/maintenance/permissions.log" "Permission fixes"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/retention/retention.log" "Retention management"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/sync/nas-sync.log" "NAS synchronization"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/sync/nas-errors.log" "NAS sync errors"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/security/clamav-scan.log" "ClamAV scan (daily)"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/security/clamav-full.log" "ClamAV scan (full)"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/rollback/snapshots.log" "Snapshot creation"
printf "  ${GREEN}%-35s${NC} %s\n" "~/logs/wsms/rollback/rollback-clean.log" "Snapshot cleanup"
echo ""

# ============================================
# CRONTAB SCHEDULE
# ============================================
echo -e "${CYAN}▶ ⏰ CRONTAB SCHEDULE${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo -e "${YELLOW}Scheduled tasks (9 automated jobs):${NC}"
echo ""
echo "   Daily:"
echo "   • 01:00 - Update ClamAV definitions"
echo "   • 02:00 - NAS synchronization"
echo "   • 03:00 - Quick malware scan"
echo "   • 04:00 - Backup retention management"
echo ""
echo "   Weekly:"
echo "   • Sunday 02:00 - Lite backup"
echo "   • Wednesday 02:00 - Lite backup"
echo "   • Sunday 04:00 - Full malware scan"
echo "   • Sunday 06:00 - WordPress updates (with snapshot!)"
echo "   • Monday 05:00 - Clean old snapshots"
echo ""
echo "   Monthly:"
echo "   • 1st day of month 03:00 - Full backup"
echo ""

# ============================================
# SYSTEM PATHS
# ============================================
echo -e "${CYAN}▶ 📂 SYSTEM PATHS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   📁 Scripts:        $SCRIPT_DIR"
echo "   💾 Lite backups:   $BACKUP_LITE_DIR"
echo "   💾 Full backups:   $BACKUP_FULL_DIR"
echo "   🗄️ MySQL backups:  $BACKUP_MYSQL_DIR"
echo "   📸 Rollback:       $BACKUP_ROLLBACK_DIR"
echo "   📋 Logs:           $LOG_BASE_DIR"
echo "   🛡️ Quarantine:     $QUARANTINE_DIR"
echo ""

# ============================================
# PRO TIPS
# ============================================
echo -e "${CYAN}▶ 💡 PRO TIPS${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo "   🔹 Use 'wp-update-safe' instead of 'wp-update-all' - creates snapshot"
echo "   🔹 Before major changes: 'wp-snapshot all'"
echo "   🔹 Monitor disk space: 'backup-size' weekly"
echo "   🔹 After failure: 'wp-rollback [site]' recovers in 30 seconds"
echo "   🔹 Check health: 'wp-health' for quick diagnostics"
echo "   🔹 View logs: 'logs-backup' or 'logs-update' for live monitoring"
echo "   🔹 Test WP-CLI after permission changes: 'wp-cli-validator'"
echo ""

# ============================================
# FOOTER
# ============================================
echo -e "${GREEN}✅ WSMS PRO v4.2 - READY FOR OPERATIONS${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${WHITE}📚 Full documentation:${NC} ~/scripts/, docs/ in repository"
echo -e "${WHITE}🐛 Report issues:${NC} https://github.com/maleclukas-prog/wp-server-management-system/issues"
echo -e "${WHITE}👤 Maintainer:${NC} Lukasz Malec"
echo ""