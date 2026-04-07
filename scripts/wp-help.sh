#!/bin/bash
# =================================================================
# 🆘 WSMS PRO v4.0 - ULTIMATE OPERATIONAL HANDBOOK
# Description: Centralized command reference, SOP, and system logic.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================
source $HOME/scripts/wsms-config.sh

# Professional UI Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

clear
echo -e "${WHITE}🆘 WORDPRESS MANAGEMENT SYSTEM - MASTER REFERENCE GUIDE${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "⏰ System Time: $(date)"
echo -e "📦 Version:     4.0 (Production Ready)"
echo ""

show_section() { echo -e "${CYAN}▶ $1${NC}"; echo -e "${CYAN}$(printf '%.0s-' {1..60})${NC}"; }
show_cmd() { printf "  ${GREEN}%-20s${NC} | %s\n" "$1" "$2"; }

# ==================== QUICK START ====================
show_section "⚡ QUICK START - MOST USED"
show_cmd "wp-status"          "Executive overview: Hardware + Fleet Health"
show_cmd "wp-fleet"           "Monitor WordPress versions and pending updates"
show_cmd "wp-update-safe"     "Recommended Update Path (Backup -> Patch -> Clean)"
show_cmd "wp-backup-lite"     "Fast daily assets backup (DB + Themes/Plugins)"
show_cmd "nas-sync"           "Manual trigger for off-site NAS synchronization"
echo ""

# ==================== DIAGNOSTICS & OBSERVABILITY ====================
show_section "🔍 OBSERVABILITY & MONITORING"
show_cmd "system-diag"        "Full hardware audit (CPU, RAM, Disk, Services)"
show_cmd "wp-audit"           "Deep-dive site diagnostics & Site-Health scores"
show_cmd "wp-cli-validator"   "Verify WP-CLI connectivity & isolation for all sites"
show_cmd "scripts-dir"        "List all underlying WSMS automation files"
echo ""

# ==================== MAINTENANCE & SECURITY ====================
show_section "🛠️  MAINTENANCE & SECURITY ORCHESTRATION"
show_cmd "wp-update-all"      "Trigger unattended fleet-wide patching"
show_cmd "wp-fix-perms"       "Enforce security isolation and restore ACL policies"
show_cmd "clamav-scan"        "Execute daily malware signature recursive audit"
show_cmd "clamav-deep-scan"   "Execute root-level system-wide malware audit (/)"
echo ""

# ==================== BACKUP & DISASTER RECOVERY ====================
show_section "💾 BACKUP & DISASTER RECOVERY (DR)"
show_cmd "wp-backup-lite"     "Daily assets backup (14-day local retention)"
show_cmd "wp-backup-full"     "Full bare-metal snapshots (35-day local retention)"
show_cmd "wp-backup-ui"       "Interactive CLI menu for on-demand recovery"
show_cmd "red-robin"          "Emergency OS-state and configuration backup"
show_cmd "backup-size"        "Audit current storage consumption per repository"
show_cmd "backup-clean"       "Manually trigger heuristic smart retention engine"
echo ""

# ==================== HYBRID CLOUD SYNC (NAS) ====================
show_section "🔄 OFF-SITE SYNC (SYNOLOGY NAS)"
show_cmd "nas-sync"           "Uplink all local archives to remote NAS vault"
show_cmd "nas-sync-status"    "Check result of the last sync operation"
show_cmd "nas-sync-logs"      "Stream synchronization logs in real-time"
echo -e "  ${YELLOW}📋 Off-site Context:${NC}"
echo -e "     • Remote Host: $NAS_HOST:$NAS_PORT"
echo -e "     • Remote Path: $NAS_PATH"
echo -e "     • Policy:      120 days retention (Ensures min $NAS_MIN_KEEP_COPIES copies)"
echo ""

# ==================== DATABASE MANAGEMENT ====================
show_section "🗄️  DATABASE OPERATIONS (MySQL)"
show_cmd "db-backup all"      "Force snapshots for every managed database"
show_cmd "db-backup list"     "List all available database snapshots"
show_cmd "db-backup [site]"   "Targeted snapshot for a specific instance"
echo ""

# ==================== CYBERSECURITY DETAILS ====================
show_section "🦠 CYBERSECURITY (ClamAV & Firewall)"
show_cmd "clamav-status"      "Monitor ClamAV protection daemon health"
show_cmd "clamav-update"      "Manually synchronize virus definitions (freshclam)"
show_cmd "clamav-logs"        "Review security audit history and detections"
show_cmd "clamav-quarantine"  "Inspect isolated malicious files in /var/quarantine"
show_cmd "sudo ufw status"    "Verify system firewall rules and active jails"
echo ""

# ==================== SERVER ADMINISTRATION ====================
show_section "🖥️  SERVER ADMINISTRATION"
show_cmd "sudo apt update"    "Refresh system software repositories"
show_cmd "sudo apt upgrade"   "Deploy latest OS-level security patches"
show_cmd "sudo reboot"        "Execute safe system restart"
show_cmd "htop"               "Interactive real-time process monitoring"
echo ""

# ==================== LOGS & JOURNALS ====================
show_section "📊 SYSTEM LOGS & JOURNALS"
show_cmd "nas-sync-logs"      "NAS synchronization event stream"
show_cmd "clamav-logs"        "Antivirus scan result stream"
show_cmd "tail -f /var/log/nginx/error.log" "Web server error event stream"
show_cmd "journalctl -u php8.4-fpm -f"     "PHP engine event stream"
echo ""

# ==================== AUTOMATION (CRON) ====================
show_section "⏰ AUTOMATION SCHEDULE (CRONTAB)"
echo -e "  ${BLUE}Daily 01:00${NC} | Malware definition updates"
echo -e "  ${BLUE}Daily 02:00${NC} | Off-site synchronization to Synology NAS"
echo -e "  ${BLUE}Daily 03:00${NC} | Proactive malware audit (/home + /var/www)"
echo -e "  ${BLUE}Daily 04:00${NC} | Smart Retention Engine (Resource cleanup)"
echo -e "  ${BLUE}Sunday 06:00${NC}| Fleet-wide security patching (Core/Plugins)"
echo -e "  ${BLUE}Sun/Wed 02:00${NC}| High-frequency Lite backups"
echo -e "  ${BLUE}1st Day 03:00${NC}| Full Bare-metal system snapshots"
echo ""

# ==================== DATA RETENTION POLICY ====================
show_section "📋 DATA RETENTION POLICIES"
echo -e "  ${YELLOW}⚡ Lite Assets:${NC} $RETENTION_LITE days | ${YELLOW}💾 Full Snapshots:${NC} $RETENTION_FULL days"
echo -e "  ${YELLOW}🗄️ MySQL Dumps:${NC}  $RETENTION_MYSQL days | ${YELLOW}🔄 Cloud NAS Vault:${NC} $NAS_RETENTION_DAYS days"
echo -e "  ${RED}⚠️ EMERGENCY MODE:${NC} Keeps only 2 latest copies when disk usage > $DISK_ALERT_THRESHOLD%"
echo -e "  ${GREEN}🛡️ SAFETY RULE:${NC} System ALWAYS preserves the last valid copy (Safety First)."
echo ""

# ==================== DYNAMIC SITE SHORTCUTS ====================
show_section "📌 DYNAMIC SITE SHORTCUTS"
for site in "${SITES[@]}"; do
    IFS=':' read -r name path user <<< "$site"
    echo -e "  ${YELLOW}wp-$name${NC} | ${YELLOW}wp-backup-$name${NC}"
done
echo ""

# ==================== INCIDENT RESPONSE (SOP) ====================
show_section "🚨 INCIDENT RESPONSE (SOP)"
echo -e "  ${RED}Disk Usage >$DISK_ALERT_THRESHOLD%?${NC}  → Run 'backup-clean' to reclaim space."
echo -e "  ${RED}Permission Denied?${NC}      → Run 'wp-fix-perms' to realign ACLs."
echo -e "  ${RED}Update Failure?${NC}        → Run 'wp-fix-perms' then 'wp-update-safe'."
echo -e "  ${RED}Sync Failure?${NC}          → Check SSH keys and run 'nas-sync' manually."
echo ""

# ==================== SCRIPT INVENTORY ====================
show_section "📜 INFRASTRUCTURE MODULES (Physical Files)"
ls -la ~/scripts/ 2>/dev/null | grep "^-" | awk '{print "  📜 " $9}' | sed 's/\.sh//' | sort
echo ""

echo -e "${GREEN}✅ ALL SYSTEMS OPERATIONAL${NC}"
echo -e "${BLUE}💡 PRO-TIP:${NC} Use 'wp-status' for an instant infrastructure health report."
echo ""
EOF