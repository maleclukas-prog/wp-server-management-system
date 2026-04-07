#!/bin/bash
# =================================================================
# 🔴 PROJECT: RED ROBIN - CRITICAL SYSTEM & CONFIG RECOVERY
# Description: Automated bare-metal configuration backup. Focuses 
#              on OS settings/configs while excluding heavy media 
#              already handled by separate sync tasks.
# Author: [Your Name]
# =================================================================

# --- CONFIGURATION ---
REMOTE_HOST="nas.your-domain.me"        # Placeholder for Synology/Remote Server
REMOTE_PORT="22"
REMOTE_USER="backup_operator"           # Generic user for documentation
REMOTE_DIR="/remote_backups/entire_server"
SSH_KEY="$HOME/.ssh/id_rsa_backup"      # Path to your private key

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="red-robin-sys-$(hostname)-$TIMESTAMP.tar.gz"
LOCAL_TMP="$HOME/system_backup_tmp"

# UI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# =================================================================
echo -e "${RED}🔴 RED ROBIN: INITIATING SYSTEM EMERGENCY BACKUP${NC}"

# 1. Pre-flight Check: Disk Space
# Ensures at least 5GB free space before creating the archive
FREE_SPACE=$(df /home | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "${FREE_SPACE%.*}" -lt 5 ]; then
    echo -e "${RED}❌ ERROR: Insufficient disk space ($FREE_SPACE GB). 5GB required.${NC}"
    exit 1
fi

mkdir -p "$LOCAL_TMP"

# 2. Archive Creation
echo -e "${YELLOW}📦 Archiving system files and configurations...${NC}"
echo -e "${CYAN}   (Excluding media/uploads to optimize package size)${NC}"

# Logic: Package root filesystem while excluding virtual filesystems, 
# local backups, and heavy web media.
sudo tar -cpzf "$LOCAL_TMP/$BACKUP_NAME" \
    --exclude="$LOCAL_TMP" \
    --exclude="$HOME/backups-*" \
    --exclude="$HOME/mysql-backups" \
    --exclude="*/wp-content/uploads" \
    --exclude="*/wp-content/cache" \
    --exclude="/proc" \
    --exclude="/sys" \
    --exclude="/dev" \
    --exclude="/run" \
    --exclude="/tmp" \
    --exclude="/var/tmp" \
    / 2> /dev/null

if [ -f "$LOCAL_TMP/$BACKUP_NAME" ]; then
    SIZE=$(du -h "$LOCAL_TMP/$BACKUP_NAME" | cut -f1)
    echo -e "${GREEN}✅ System archived. Package size: $SIZE${NC}"
else
    echo -e "${RED}❌ ERROR: Failed to create backup archive.${NC}"
    exit 1
fi

# 3. Off-site Synchronization (SFTP)
echo -e "${YELLOW}📤 Uplinking to Synology NAS via SFTP...${NC}"

# Ensure remote directory structure exists
echo "mkdir $REMOTE_DIR" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" > /dev/null 2>&1

# Execute file transfer
if echo "put \"$LOCAL_TMP/$BACKUP_NAME\" \"$REMOTE_DIR/$BACKUP_NAME\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST"; then
    echo -e "${GREEN}✅ RED ROBIN safely stored on remote NAS!${NC}"
    
    # 4. Cleanup local temporary files
    rm -f "$LOCAL_TMP/$BACKUP_NAME"
    echo -e "${CYAN}🧹 Local temporary file removed.${NC}"
else
    echo -e "${RED}❌ ERROR: Transfer failed. Backup remains at: $LOCAL_TMP${NC}"
    exit 1
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}      OPERATIONAL SUCCESS - SYSTEM SAFE  ${NC}"
echo -e "${GREEN}=========================================${NC}"
