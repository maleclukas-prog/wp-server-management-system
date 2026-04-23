cat > ~/scripts/nas-sftp-sync.sh << 'EOF'
#!/bin/bash
# =================================================================
# WSMS PRO - NAS SFTP SYNC (Production)
# =================================================================

source "$HOME/scripts/wsms-config.sh"

REMOTE_SERVER="${NAS_HOST:-}"
REMOTE_PORT="${NAS_PORT:-22}"
REMOTE_USER="${NAS_USER:-}"
REMOTE_BASE_DIR="${NAS_PATH:-}"
SSH_KEY="${NAS_SSH_KEY:-}"

if [ -z "$REMOTE_SERVER" ] || [ -z "$REMOTE_USER" ] || [ ! -f "$SSH_KEY" ]; then
    echo "❌ ERROR: Missing NAS configuration"
    exit 1
fi

LOCAL_BASE_DIR="$HOME"
BACKUP_DIRS=("backups-full" "backups-lite" "backups-manual" "mysql-backups")
DAYS_TO_KEEP="${NAS_RETENTION_DAYS:-120}"
MIN_KEEP_COPIES="${NAS_MIN_KEEP_COPIES:-2}"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_DIR="${LOG_DIR:-$HOME/logs}"
LOG_FILE="$LOG_DIR/nas_sync.log"
mkdir -p "$LOG_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

TOTAL_UPLOADED=0; TOTAL_EXISTING=0; TOTAL_FAILED=0; TOTAL_DELETED=0

log_info() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${CYAN}[$ts]${NC} $1"; echo "[$ts] INFO: $1" >> "$LOG_FILE"; }
log_success() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${GREEN}[$ts] ✅ $1${NC}"; echo "[$ts] SUCCESS: $1" >> "$LOG_FILE"; }
log_warning() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${YELLOW}[$ts] ⚠️ $1${NC}"; echo "[$ts] WARNING: $1" >> "$LOG_FILE"; }
log_error() { local ts=$(date '+%Y-%m-%d %H:%M:%S'); echo -e "${RED}[$ts] ❌ $1${NC}"; echo "[$ts] ERROR: $1" >> "$LOG_FILE"; }

get_file_age_days() {
    local filename="$1"
    if [[ "$filename" =~ ([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
        local file_date="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
        local file_timestamp=$(date -d "$file_date" +%s 2>/dev/null || echo 0)
        echo $(( ( $(date +%s) - file_timestamp ) / 86400 ))
    else
        echo 0
    fi
}

# Funkcja do tworzenia folderu na NAS
ensure_remote_dir() {
    local remote_dir="$1"
    
    # Sprawdź czy folder istnieje
    if echo "ls \"$remote_dir\"" 2>/dev/null | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -q "remote_dir"; then
        return 0
    fi
    
    # Tworzymy foldery po kolei
    local current_path=""
    IFS='/' read -ra parts <<< "$remote_dir"
    
    for part in "${parts[@]}"; do
        [ -z "$part" ] && continue
        current_path="$current_path/$part"
        echo "mkdir \"$current_path\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null
    done
    
    return 0
}

sync_directory() {
    local dir_name="$1"
    local local_dir="$LOCAL_BASE_DIR/$dir_name"
    local remote_dir="$REMOTE_BASE_DIR/$dir_name"
    
    log_info "📂 Processing: $dir_name"
    
    if [ ! -d "$local_dir" ]; then
        mkdir -p "$local_dir"
        log_warning "Created local directory: $local_dir"
    fi
    
    local file_count=$(ls -1 "$local_dir" 2>/dev/null | wc -l)
    if [ "$file_count" -eq 0 ]; then
        log_warning "No files in $dir_name - skipping"
        return 0
    fi
    
    log_info "Found $file_count file(s) locally"
    
    # Upewnij się że folder na NAS istnieje
    ensure_remote_dir "$remote_dir"
    
    # Pobierz listę plików z NAS
    local remote_files=$(echo "ls -1 \"$remote_dir\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -v "sftp>" | tr -d '\r' | sort)
    
    local uploaded=0; local existing=0; local failed=0
    
    for file in $(ls -1 "$local_dir"); do
        if echo "$remote_files" | grep -q "^$file$"; then
            echo -e "   ${YELLOW}⏭️ Already exists: $file${NC}"
            ((existing++))
        else
            echo -e "   ${CYAN}📤 Uploading: $file${NC}"
            if echo "put \"$local_dir/$file\" \"$remote_dir/$file\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null; then
                echo -e "   ${GREEN}✅ Uploaded: $file${NC}"
                ((uploaded++))
            else
                echo -e "   ${RED}❌ Failed: $file${NC}"
                ((failed++))
            fi
        fi
    done
    
    TOTAL_UPLOADED=$((TOTAL_UPLOADED + uploaded))
    TOTAL_EXISTING=$((TOTAL_EXISTING + existing))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    # Analiza wieku plików na NAS
    local remote_files_list=$(echo "ls -1 \"$remote_dir\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null | grep -v "sftp>" | tr -d '\r' | sort)
    
    local age_new=0; local age_medium=0; local age_old=0; local age_archive=0
    
    for file in $remote_files_list; do
        [ -z "$file" ] && continue
        local age=$(get_file_age_days "$file")
        if [ "$age" -le 14 ]; then ((age_new++))
        elif [ "$age" -le 30 ]; then ((age_medium++))
        elif [ "$age" -le $DAYS_TO_KEEP ]; then ((age_old++))
        else ((age_archive++)); fi
    done
    
    # Czyszczenie starych plików
    local keep_count=0; local deleted=0
    
    for file in $(echo "$remote_files_list" | sort -r); do
        [ -z "$file" ] && continue
        local age=$(get_file_age_days "$file")
        
        if [ $keep_count -lt $MIN_KEEP_COPIES ]; then
            ((keep_count++))
        elif [ $age -gt $DAYS_TO_KEEP ]; then
            if echo "rm \"$remote_dir/$file\"" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_SERVER" 2>/dev/null; then
                echo -e "   ${RED}🗑️ Deleted old: $file (age: ${age}d)${NC}"
                ((deleted++))
            fi
        else
            ((keep_count++))
        fi
    done
    
    TOTAL_DELETED=$((TOTAL_DELETED + deleted))
    
    echo ""
    echo -e "   📊 ${CYAN}Summary for $dir_name:${NC}"
    echo -e "      Uploaded: ${GREEN}$uploaded${NC} | Existing: ${YELLOW}$existing${NC} | Failed: ${RED}$failed${NC}"
    echo -e "      Deleted: ${RED}$deleted${NC}"
    echo -e "      Age: 0-14d:${GREEN}$age_new${NC} | 15-30d:${YELLOW}$age_medium${NC} | 31-${DAYS_TO_KEEP}d:${CYAN}$age_old${NC} | >${DAYS_TO_KEEP}d:${RED}$age_archive${NC}"
    echo "----------------------------------------------------"
}

main() {
    echo "=========================================================="
    echo -e "${CYAN}☁️ NAS SYNCHRONIZATION - $TIMESTAMP${NC}"
    echo "=========================================================="
    echo ""
    
    log_info "Testing SFTP connection..."
    if echo "ls" | sftp -i "$SSH_KEY" -P "$REMOTE_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_SERVER" >/dev/null 2>&1; then
        log_success "SFTP connection established"
    else
        log_error "Cannot connect to $REMOTE_SERVER:$REMOTE_PORT"
        exit 1
    fi
    
    log_info "Ensuring base directory: $REMOTE_BASE_DIR"
    ensure_remote_dir "$REMOTE_BASE_DIR"
    
    echo ""
    
    for dir in "${BACKUP_DIRS[@]}"; do
        sync_directory "$dir"
    done
    
    echo "=========================================================="
    echo -e "${CYAN}📊 FINAL SUMMARY${NC}"
    echo "=========================================================="
    echo -e "   Uploaded:   ${GREEN}$TOTAL_UPLOADED${NC} files"
    echo -e "   Already on NAS: ${YELLOW}$TOTAL_EXISTING${NC} files"
    echo -e "   Failed:     ${RED}$TOTAL_FAILED${NC} files"
    echo -e "   Deleted:    ${RED}$TOTAL_DELETED${NC} files"
    echo "=========================================================="
    echo -e "${GREEN}✅ NAS Sync Completed${NC}"
    echo "=========================================================="
    
    echo "[$TIMESTAMP] FINAL: U=$TOTAL_UPLOADED, E=$TOTAL_EXISTING, F=$TOTAL_FAILED, D=$TOTAL_DELETED" >> "$LOG_FILE"
}

main "$@"
EOF

chmod +x ~/scripts/nas-sftp-sync.sh

# Test
nas-sync