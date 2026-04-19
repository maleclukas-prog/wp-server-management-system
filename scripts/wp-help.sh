#!/bin/bash
# =================================================================
# WSMS PRO v4.2 - MASTER REFERENCE GUIDE
# Logically organized: Diagnostics → Backups → Sync → Recovery
# =================================================================

source "$HOME/scripts/wsms-config.sh"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${WHITE}║             🆘 WSMS PRO v4.2 - COMMAND REFERENCE            ║${NC}"
echo -e "${WHITE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${CYAN}⏰ $(date) │ 📦 v4.2 │ 🖥️  $(hostname)${NC}"
echo ""

# ============================================
# SECTION 1: SYSTEM DIAGNOSTICS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔍 SYSTEM DIAGNOSTICS                                      │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-status" "Full system overview (CPU, RAM, services, backups)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-health" "Quick health check (disk, services, WP-CLI)"
printf "  ${GREEN}%-22s${NC} %s\n" "system-diag" "Operating system diagnostics"
echo ""

# ============================================
# SECTION 2: WORDPRESS FLEET
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🌐 WORDPRESS FLEET MANAGEMENT                              │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fleet" "All sites: versions + pending updates"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-audit" "Deep audit: DB, plugins, themes, security"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-cli-validator" "Test WP-CLI connectivity for all sites"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-fix-perms" "Fix file permissions and ACLs"
echo ""

# ============================================
# SECTION 3: BACKUP MANAGEMENT
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  💾 BACKUP MANAGEMENT                                       │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${YELLOW}  Create Backups:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-lite" "Fast: themes, plugins, uploads, config"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-full" "Complete: all files + database"
printf "    ${GREEN}%-20s${NC} %s\n" "mysql-backup-all" "All WordPress databases"
printf "    ${GREEN}%-20s${NC} %s\n" "wp-backup-ui" "Interactive menu"
echo ""
echo -e "${YELLOW}  View Backups:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-list" "List all backups with size and date"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-size" "Storage usage per directory"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-dirs" "Show directory structure"
printf "    ${GREEN}%-20s${NC} %s\n" "mysql-backup-list" "List database backups"
echo ""
echo -e "${YELLOW}  Cleanup:${NC}"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-clean" "Interactive (with confirmation)"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-force-clean" "Automatic by retention policy"
printf "    ${GREEN}%-20s${NC} %s\n" "backup-emergency" "EMERGENCY: keep only 2 latest"
printf "    ${GREEN}%-20s${NC} %s\n" "wsms-clean" "Clean old logs and temp files"
echo ""

# ============================================
# SECTION 4: REMOTE SYNC (NAS)
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  ☁️ REMOTE SYNC (NAS)                                        │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync" "Manual sync to NAS"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-status" "Show last sync status"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-logs" "View sync logs (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "nas-sync-errors" "View sync errors (live)"
echo ""

# ============================================
# SECTION 5: UPDATES & MAINTENANCE
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 UPDATES & MAINTENANCE                                   │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-safe" "RECOMMENDED: Backup → Snapshot → Update"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update-all" "Update all sites (no backup)"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-update" "Alias for wp-update-all"
echo ""

# ============================================
# SECTION 6: ROLLBACK SYSTEM (NEW!)
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🔄 ROLLBACK SYSTEM — NEW in v4.2                           │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${CYAN}  Instant recovery from failed updates!${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot all" "Create snapshots for ALL sites"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot [site]" "Create snapshot for one site"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshots" "List all snapshots"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback [site]" "Restore to LATEST snapshot"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-safe [site]" "Rollback with confirmation"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-clean [days]" "Clean old snapshots"
echo ""
echo -e "${YELLOW}  Examples:${NC}"
echo "     wp-snapshot mysite"
echo "     wp-rollback mysite"
echo "     wp-rollback mysite 20260419_143022"
echo ""

# ============================================
# SECTION 7: SECURITY
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🛡️ SECURITY                                                 │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-scan" "Daily quick scan (/var/www, /home)"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-deep-scan" "Full system scan"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-status" "ClamAV service status"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-update" "Update virus definitions"
printf "  ${GREEN}%-22s${NC} %s\n" "clamav-quarantine" "List quarantined files"
echo ""

# ============================================
# SECTION 8: TROUBLESHOOTING
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🚨 TROUBLESHOOTING                                         │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${RED}%-30s${NC} %s\n" "Site down after update:" "wp-rollback [site]"
printf "  ${RED}%-30s${NC} %s\n" "Low disk space:" "backup-emergency"
printf "  ${RED}%-30s${NC} %s\n" "Permission errors:" "wp-fix-perms"
printf "  ${RED}%-30s${NC} %s\n" "Suspected malware:" "clamav-deep-scan"
printf "  ${RED}%-30s${NC} %s\n" "NAS sync failed:" "nas-sync-status"
printf "  ${RED}%-30s${NC} %s\n" "WP-CLI broken:" "wp-cli-validator"
echo ""

# ============================================
# SECTION 9: LOGS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📝 LOG FILES (~/logs/wsms/)                                │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "logs-backup" "View backup logs (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-update" "View update logs (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-sync" "View NAS sync logs (live)"
printf "  ${GREEN}%-22s${NC} %s\n" "logs-scan" "View malware scan logs"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-logs" "Show all log files status"
echo ""

# ============================================
# SECTION 10: PER-SITE COMMANDS
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  🎯 PER-SITE COMMANDS                                       │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-$name" "WP-CLI for $name"
done
echo ""
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-backup-$name" "Lite backup for $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-snapshot-$name" "Snapshot for $name"
    printf "  ${GREEN}%-22s${NC} %s\n" "wp-rollback-$name" "Rollback for $name"
    echo ""
done

# ============================================
# SECTION 11: OTHER
# ============================================
echo -e "${BLUE}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  📦 OTHER COMMANDS                                          │${NC}"
echo -e "${BLUE}└────────────────────────────────────────────────────────────┘${NC}"
echo ""
printf "  ${GREEN}%-22s${NC} %s\n" "red-robin" "Emergency system backup"
printf "  ${GREEN}%-22s${NC} %s\n" "wsms-clean" "Clean old logs and temp files"
printf "  ${GREEN}%-22s${NC} %s\n" "scripts-dir" "List scripts directory"
printf "  ${GREEN}%-22s${NC} %s\n" "wp-help" "This reference"
echo ""

# ============================================
# FOOTER
# ============================================
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ WSMS PRO v4.2 — READY FOR OPERATIONS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}📚 Docs: ~/scripts/ │ 🐛 Issues: github.com/maleclukas-prog${NC}"
echo -e "${WHITE}👤 Maintainer: Lukasz Malec${NC}"
echo ""