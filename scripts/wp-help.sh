#!/bin/bash
# =================================================================
# 🆘 WORDPRESS MANAGEMENT SYSTEM - HELP
# Version: 3.5 (Full Production Ready)
# Description: Centralized help utility and command reference 
#              for the WSMS infrastructure.
# Author: Lukasz Malec / GitHub: maleclukas-prog
# =================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo -e "${WHITE}🆘 WORDPRESS MANAGEMENT SYSTEM - HELP & REFERENCE${NC}"
echo -e "${WHITE}=================================================${NC}"
echo -e "${BLUE}⏰ System Time: $(date)${NC}"
echo ""

show_section() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '%.0s-' {1..55})${NC}"
}

show_command() {
    printf "  ${GREEN}%-26s${NC} %s\n" "$1" "$2"
}

# ==================== QUICK START ====================
show_section "⚡ QUICK START - Essential Commands"
show_command "wp-status"          "# 🌐 Executive overview: System + Fleet status"
show_command "system-diag"        "# 🖥️  Core server health & resource audit"
show_command "wp-fleet"           "# 📊 Monitor all WordPress instances"
show_command "wp-update-safe"     "# 🛡️  Secure Update (Backup -> Update -> Verify)"
show_command "wp-backup-lite"     "# ⚡ Fast assets backup (Themes/Plugins/DB)"
show_command "nas-sync"           "# 🔄 Off-site sync to Synology NAS"
echo ""

# ==================== DIAGNOSTICS & OBSERVABILITY ====================
show_section "🔍 OBSERVABILITY & MONITORING"
show_command "system-diag"        "# Hardware metrics: CPU, RAM, Disk, Services"
show_command "wp-fleet"           "# Fleet inventory: Versions, plugin counts"
show_command "wp-audit"           "# Deep-dive instance diagnostics & vitals"
show_command "scripts-dir"        "# List all underlying management scripts"
show_command "wp-cli-validator"   "# 🧪 Test WP-CLI functionality"
echo ""

# ==================== WORDPRESS MANAGEMENT ====================
show_section "📝 WORDPRESS MANAGEMENT"
show_command "wp-fleet"           "# List all WordPress sites with status"
show_command "wp-update-all"      "# 🔄 Update WordPress core, plugins, themes"
show_command "wp-update-safe"     "# 🛡️ Backup then update (RECOMMENDED)"
show_command "wp-fix-perms"       "# 🔧 Fix file permissions (PHP-FPM)"
echo ""

# ==================== MAINTENANCE & SECURITY ====================
show_section "🛠️  MAINTENANCE & SECURITY ORCHESTRATION"
show_command "wp-update-all"      "# Automated fleet-wide patching (Core/Plugins)"
show_command "wp-fix-perms"       "# 🔐 Standardize security isolation & ACLs"
show_command "wp-update-safe"     "# Production-safe update workflow"
echo ""

# ==================== BACKUP & DISASTER RECOVERY ====================
show_section "💾 BACKUP & DISASTER RECOVERY (DR)"
show_command "wp-backup-lite"     "# Lean assets backup (14-day retention)"
show_command "wp-backup-full"     "# Full filesystem snapshot (35-day retention)"
show_command "wp-backup-ui"       "# 🎯 Interactive backup menu (Manual Mode)"
show_command "red-robin"          "# 🔴 Emergency bare-metal system backup"
show_command "backup-size"        "# 💽 Audit storage utilization"
show_command "backup-clean"       "# 🧹 Trigger smart retention engine (Manual)"
echo ""

# ==================== DATABASE MANAGEMENT ====================
show_section "🗄️  DATABASE OPERATIONS (MySQL)"
show_command "db-backup all"      "# Dump all databases across the fleet"
show_command "db-backup list"     "# List available database snapshots"
show_command "db-backup [site]"   "# Targeted backup for a specific instance"
echo ""

# ==================== HYBRID CLOUD SYNC (NAS) ====================
show_section "🔄 OFF-SITE SYNC (SYNOLOGY NAS)"
show_command "nas-sync"           "# 📤 Uplink local backups to remote vault"
show_command "nas-sync-status"    "# 📊 Verification of last sync operation"
show_command "nas-sync-logs"      "# 📄 Real-time stream of sync logs"
echo -e "  ${YELLOW}📋 Off-site Policy:${NC}"
echo -e "     • Target: lukas-nas-server-2.synology.me:58365"
echo -e "     • User: Lukas_Malec"
echo -e "     • Path: /homes/Lukas_Malec/server_backups/"
echo -e "     • Retention: 120 days (Guarantees min 2 copies)"
echo -e "     • Automated Cycle: Daily at 2:00 AM"
echo ""

# ==================== CYBERSECURITY (ClamAV) ====================
show_section "🦠 CYBERSECURITY & ANTIVIRUS"
show_command "clamav-status"      "# 📊 Monitor ClamAV daemon health"
show_command "clamav-update"      "# 🔄 Synchronize virus definitions"
show_command "clamav-scan"        "# 🔍 High-risk audit: /home + /var/www"
show_command "clamav-deep-scan"   "# 🌍 Root-level deep system audit (/)"
show_command "clamav-logs"        "# 📄 View security scan history"
show_command "clamav-quarantine"  "# 📁 Check quarantine folder"
echo ""

# ==================== SERVER MANAGEMENT ====================
show_section "🖥️ SERVER MANAGEMENT"
show_command "sudo apt update"    "# 📦 Update system repositories"
show_command "sudo apt upgrade"   "# ⬆️ Upgrade system packages"
show_command "sudo apt autoremove" "# 🗑️ Remove unused packages"
show_command "sudo reboot"        "# 🔄 Reboot server"
echo ""

# ==================== MONITORING ====================
show_section "📊 MONITORING"
show_command "htop"               "# 📈 Real-time process viewer (if installed)"
show_command "sudo tail -f /var/log/nginx/error.log" "# 🌐 View Nginx error log"
show_command "sudo journalctl -u php8.4-fpm -f" "# 🐘 View PHP-FPM logs"
echo ""

# ==================== AUTOMATION (CRON) ====================
show_section "⏰ AUTOMATION SCHEDULE"
echo -e "  ${BLUE}Daily 01:00${NC}     - Freshclam (Virus definitions)"
echo -e "  ${BLUE}Daily 02:00${NC}     - Off-site NAS Sync"
echo -e "  ${BLUE}Daily 03:00${NC}     - Security Audit (Auto-scan)"
echo -e "  ${BLUE}Daily 04:00${NC}     - Smart Retention Engine (Cleanup)"
echo -e "  ${BLUE}Sunday 06:00${NC}    - Automated Fleet Maintenance (Updates)"
echo -e "  ${BLUE}Sun/Wed 02:00${NC}   - Lite Backups"
echo -e "  ${BLUE}1st of month 03:00${NC} - Full Backups"
echo ""
show_command "crontab -l"        "# List current cron jobs"
show_command "crontab -e"        "# Edit cron jobs"
echo ""

# ==================== SOP / TROUBLESHOOTING ====================
show_section "🚨 INCIDENT RESPONSE (SOP)"
echo -e "  ${RED}Disk >80%?${NC}       → Run 'backup-clean' (Triggers emergency purge)"
echo -e "  ${RED}Permissions?${NC}     → Run 'wp-fix-perms' (Realigns ACLs)"
echo -e "  ${RED}Site Failure?${NC}    → Run 'wp-fleet' -> 'system-diag'"
echo -e "  ${RED}Security Hit?${NC}    → Check '/var/quarantine' and 'clamav-logs'"
echo -e "  ${RED}Update Error?${NC}    → Run 'wp-fix-perms' then retry update"
echo -e "  ${RED}Sync to NAS failed?${NC}  → Check SSH key and network connectivity"
echo ""

# ==================== RETENTION POLICY ====================
show_section "📋 DATA RETENTION POLICY"
echo -e "  ${YELLOW}⚡ Lite backups:${NC}     14 days"
echo -e "  ${YELLOW}💾 Full backups:${NC}     35 days"
echo -e "  ${YELLOW}🛠️ Manual backups:${NC}   14 days"
echo -e "  ${YELLOW}🗄️ MySQL backups:${NC}    7 days"
echo -e "  ${YELLOW}🔄 NAS backups:${NC}      120 days (keeps min 2 copies)"
echo -e "  ${YELLOW}⚠️ Emergency mode:${NC}   Keeps only 2 latest copies when disk >80%"
echo ""

# ==================== AVAILABLE SCRIPTS ====================
show_section "📜 AVAILABLE SCRIPTS"
if [ -d "$HOME/scripts" ]; then
    ls -la ~/scripts/ 2>/dev/null | grep "^-" | awk '{print "  📜 " $9}' | sed 's/\.sh//' | sort | while read -r script; do
        echo "  $script"
    done
else
    echo "  ⚠️ Scripts directory not found"
fi
echo ""

# ==================== QUICK REFERENCE CARD ====================
show_section "🔖 QUICK REFERENCE CARD"
echo -e "  ${GREEN}WordPress:${NC}   wp-fleet | wp-update-safe | wp-backup-lite | wp-fix-perms"
echo -e "  ${GREEN}Backup:${NC}      backup-size | backup-clean | backup-size"
echo -e "  ${GREEN}NAS Sync:${NC}    nas-sync | nas-sync-status | nas-sync-logs"
echo -e "  ${GREEN}Security:${NC}    sudo ufw status | clamav-status"
echo -e "  ${GREEN}Antivirus:${NC}   clamav-update | clamav-scan | clamav-deep-scan | clamav-logs"
echo -e "  ${GREEN}System:${NC}      system-diag | scripts-dir | sudo apt update"
echo ""

echo -e "${GREEN}✅ SYSTEM OPERATIONAL${NC}"
echo -e "${BLUE}💡 PRO-TIP:${NC} Start your shift with 'wp-status' for an instant fleet audit."
echo ""
