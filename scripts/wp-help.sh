#!/bin/bash
# =================================================================
# 🆘 WORDPRESS MANAGEMENT SYSTEM - COMMAND REFERENCE
# Version: 3.5 (English Production Ready)
# Description: Centralized help utility and command reference 
#              for the WSMS infrastructure.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
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
show_command "db-backup-all"      "# Dump all databases across the fleet"
show_command "db-backup-list"     "# List available database snapshots"
show_command "db-backup [site]"   "# Targeted backup for a specific instance"
echo ""

# ==================== HYBRID CLOUD SYNC (NAS) ====================
show_section "🔄 OFF-SITE SYNC (SYNOLOGY NAS)"
show_command "nas-sync"           "# 📤 Uplink local backups to remote vault"
show_command "nas-sync-status"    "# 📊 Verification of last sync operation"
show_command "nas-sync-logs"      "# 📄 Real-time stream of sync logs"
echo -e "  ${YELLOW}📋 Off-site Policy:${NC}"
echo -e "     • Target: lukas-nas-server-2.synology.me:58365"
echo -e "     • Retention: 120 days (Guarantees min 2 copies)"
echo -e "     • Automated Cycle: Daily at 2:00 AM"
echo ""

# ==================== CYBERSECURITY (ClamAV) ====================
show_section "🦠 CYBERSECURITY & ANTIVIRUS"
show_command "clamav-status"      "# Monitor ClamAV daemon health"
show_command "clamav-update"      "# 🔄 Synchronize virus definitions"
show_command "clamav-scan"        "# 🔍 High-risk audit: /home + /var/www"
show_command "clamav-deep-scan"   "# 🌍 Root-level deep system audit (/)"
show_command "clamav-logs"        "# View security scan history"
echo ""

# ==================== AUTOMATION (CRON) ====================
show_section "⏰ AUTOMATION SCHEDULE"
echo -e "  ${BLUE}Daily 01:00${NC}     - Freshclam (Virus definitions)"
echo -e "  ${BLUE}Daily 02:00${NC}     - Off-site NAS Sync"
echo -e "  ${BLUE}Daily 03:00${NC}     - Security Audit (Auto-scan)"
echo -e "  ${BLUE}Daily 04:00${NC}     - Smart Retention Engine (Cleanup)"
echo -e "  ${BLUE}Sunday 06:00${NC}    - Automated Fleet Maintenance (Updates)"
echo ""

# ==================== SOP / TROUBLESHOOTING ====================
show_section "🚨 INCIDENT RESPONSE (SOP)"
echo -e "  ${RED}Disk >80%?${NC}       → Run 'backup-clean' (Triggers emergency purge)"
echo -e "  ${RED}Permissions?${NC}     → Run 'wp-fix-perms' (Realigns ACLs)"
echo -e "  ${RED}Site Failure?${NC}    → Run 'wp-fleet' -> 'system-diag'"
echo -e "  ${RED}Security Hit?${NC}    → Check '/var/quarantine' and 'clamav-logs'"
echo -e "  ${RED}Update Error?${NC}    → Run 'wp-fix-perms' then retry update"
echo ""

# ==================== RETENTION POLICY ====================
show_section "📋 DATA RETENTION POLICY"
echo -e "  ${YELLOW}⚡ Assets:${NC}  14 days | ${YELLOW}💾 Snapshots:${NC} 35 days | ${YELLOW}🔄 NAS:${NC} 120 days"
echo -e "  ${YELLOW}⚠️ Safety Rule:${NC} System ALWAYS preserves the last valid copy."
echo ""

echo -e "${GREEN}✅ SYSTEM OPERATIONAL${NC}"
echo -e "${BLUE}💡 PRO-TIP:${NC} Start your shift with 'wp-status' for an instant fleet audit."
echo ""