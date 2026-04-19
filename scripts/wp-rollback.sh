#!/bin/bash
# wp-rollback.sh - Automated disaster recovery rollback engine

source $HOME/scripts/wsms-config.sh

# Struktura: ~/backups-rollback/site-name/YYYY-MM-DD_HHMMSS/
ROLLBACK_DIR="$HOME/backups-rollback"
mkdir -p "$ROLLBACK_DIR"

# ============================================
# FUNKCJA 1: AUTO-SNAPSHOT PRZED UPDATE
# ============================================
pre_update_snapshot() {
    local site=$1
    local path=$2
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_path="$ROLLBACK_DIR/$site/$timestamp"
    
    mkdir -p "$snapshot_path"
    
    # 1. Zrzut bazy danych
    bash "$SCRIPT_DIR/mysql-backup-manager.sh" "$site" 2>/dev/null
    cp "$BACKUP_MYSQL_DIR/db-$site-"* "$snapshot_path/" 2>/dev/null
    
    # 2. Backup plików (tylko zmieniane: plugins, themes)
    tar -czf "$snapshot_path/files.tar.gz" \
        -C "$path" \
        wp-content/plugins \
        wp-content/themes \
        wp-includes \
        wp-admin \
        2>/dev/null
    
    # 3. Metadane - wersje przed update
    sudo -u "$user" wp --path="$path" core version > "$snapshot_path/core_version.txt"
    sudo -u "$user" wp --path="$path" plugin list --format=csv > "$snapshot_path/plugins_before.csv"
    
    echo "$snapshot_path"  # Zwraca ścieżkę snapshota
}

# ============================================
# FUNKCJA 2: WYKONAJ ROLLBACK
# ============================================
perform_rollback() {
    local site=$1
    local snapshot_name=$2  # Opcjonalnie - konkretny snapshot
    
    IFS=':' read -r name path user <<< "$(get_site_config "$site")"
    
    # Znajdź najnowszy snapshot
    local snapshot_path
    if [ -n "$snapshot_name" ]; then
        snapshot_path="$ROLLBACK_DIR/$site/$snapshot_name"
    else
        snapshot_path=$(ls -td "$ROLLBACK_DIR/$site"/*/ 2>/dev/null | head -1)
    fi
    
    if [ ! -d "$snapshot_path" ]; then
        echo "❌ No snapshot found for $site"
        return 1
    fi
    
    echo "🔄 Rolling back $site to snapshot: $(basename "$snapshot_path")"
    
    # 1. Włącz tryb maintenance
    sudo -u "$user" wp --path="$path" maintenance-mode activate 2>/dev/null
    
    # 2. Przywróć pliki
    tar -xzf "$snapshot_path/files.tar.gz" -C "$path" 2>/dev/null
    
    # 3. Przywróć bazę danych
    local db_backup=$(ls "$snapshot_path"/db-*.sql.gz 2>/dev/null | head -1)
    if [ -f "$db_backup" ]; then
        # Parsuj wp-config dla credentials
        DB_NAME=$(grep -E "DB_NAME" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_USER=$(grep -E "DB_USER" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        DB_PASS=$(grep -E "DB_PASSWORD" "$path/wp-config.php" | awk -F"['\"]" '{print $4}')
        
        gunzip < "$db_backup" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null
    fi
    
    # 4. Wyłącz maintenance i wyczyść cache
    sudo -u "$user" wp --path="$path" maintenance-mode deactivate 2>/dev/null
    sudo -u "$user" wp --path="$path" cache flush 2>/dev/null
    
    # 5. Weryfikacja
    if curl -s -o /dev/null -w "%{http_code}" "https://$site" | grep -q "200\|301\|302"; then
        echo "✅ Rollback successful! Site is online."
        # Wyślę powiadomienie (opcjonalnie)
        # send_notification "✅ $site rollback completed"
    else
        echo "⚠️ Rollback completed but site may need manual check."
    fi
}

# ============================================
# FUNKCJA 3: LISTA DOSTĘPNYCH SNAPSHOTÓW
# ============================================
list_snapshots() {
    local site=$1
    
    echo "📸 Available rollback snapshots:"
    echo "=========================================="
    
    for snapshot in $(ls -td "$ROLLBACK_DIR/$site"/*/ 2>/dev/null); do
        local name=$(basename "$snapshot")
        local size=$(du -sh "$snapshot" 2>/dev/null | cut -f1)
        local timestamp=$(echo "$name" | sed 's/_/ /g')
        
        echo "  📁 $name ($size) - $timestamp"
    done
}

# ============================================
# FUNKCJA 4: AUTO-CLEANUP STARYCH SNAPSHOTÓW
# ============================================
cleanup_old_snapshots() {
    local site=$1
    local keep_days=${2:-7}  # Domyślnie trzymaj 7 dni
    
    find "$ROLLBACK_DIR/$site" -type d -mtime +$keep_days -exec rm -rf {} \; 2>/dev/null
    echo "🧹 Cleaned up snapshots older than $keep_days days for $site"
}

# ============================================
# MAIN
# ============================================
case "${1:-}" in
    snapshot)
        # Ręczne tworzenie snapshota
        for site in "${SITES[@]}"; do
            IFS=':' read -r name path user <<< "$site"
            if [ "$2" == "all" ] || [ "$2" == "$name" ]; then
                snapshot_path=$(pre_update_snapshot "$name" "$path")
                echo "✅ Snapshot created: $snapshot_path"
            fi
        done
        ;;
    
    rollback)
        # Rollback do ostatniego snapshota
        if [ -z "$2" ]; then
            echo "Usage: wp-rollback rollback <site-name> [snapshot-name]"
            exit 1
        fi
        perform_rollback "$2" "$3"
        ;;
    
    list)
        # Lista snapshotów
        list_snapshots "$2"
        ;;
    
    clean)
        # Czyszczenie starych snapshotów
        cleanup_old_snapshots "$2" "$3"
        ;;
    
    *)
        echo "Usage: wp-rollback {snapshot|rollback|list|clean} [site] [snapshot]"
        echo ""
        echo "Examples:"
        echo "  wp-rollback snapshot all              # Create snapshots for all sites"
        echo "  wp-rollback snapshot mysite           # Create snapshot for mysite"
        echo "  wp-rollback list mysite               # List snapshots for mysite"
        echo "  wp-rollback rollback mysite           # Rollback to latest"
        echo "  wp-rollback rollback mysite 20260115_143022  # Rollback to specific"
        echo "  wp-rollback clean mysite 30           # Keep only last 30 days"
        ;;
esac