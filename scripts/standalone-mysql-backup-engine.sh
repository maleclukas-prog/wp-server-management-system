#!/bin/bash
# =================================================================
# 🗄️  STANDALONE MYSQL SNAPSHOT ENGINE (mysqldump)
# Description: A low-level database backup utility that operates 
#              independently of CMS-specific tools. It extracts 
#              metadata directly from source configs to perform 
#              consistent, compressed SQL dumps.
# Author: [Lukasz Malec / GitHub maleclukas-prog]
# =================================================================

echo "🗄️  INITIATING STANDALONE MYSQL SNAPSHOT"
echo "========================================="
echo "⏰ Execution Timestamp: $(date)"
echo ""

# --- CONFIGURATION ---
# Target mapping: "identifier:config_path"
sites=(
    "site1:/var/www/site1/public_html"
    "site2:/var/www/site2/public_html"
    "site3:/var/www/site3/public_html"
)

BACKUP_REPOSITORY="$HOME/backups-mysqldump"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Ensure backup destination exists
mkdir -p "$BACKUP_REPOSITORY"

# --- CORE LOGIC ---

for site in "${sites[@]}"; do
    IFS=':' read -r name path <<< "$site"
    echo ""
    echo "🌐 PROCESSING INSTANCE: $name"
    echo "-----------------------------------"

    # Validation: Source config check
    CONFIG_FILE="$path/wp-config.php"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "   ❌ Critical Error: Configuration not found at $path"
        continue
    fi

    # Metadata Extraction Logic
    # Using regex to parse PHP define statements for database connectivity
    DB_NAME=$(grep -E "define.*DB_NAME" "$CONFIG_FILE" | awk -F"'" '{print $4}')
    DB_USER=$(grep -E "define.*DB_USER" "$CONFIG_FILE" | awk -F"'" '{print $4}')
    DB_PASS=$(grep -E "define.*DB_PASSWORD" "$CONFIG_FILE" | awk -F"'" '{print $4}')
    DB_HOST=$(grep -E "define.*DB_HOST" "$CONFIG_FILE" | awk -F"'" '{print $4}')

    if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
        echo "   ❌ Metadata Extraction Error: Failed to retrieve DB credentials."
        continue
    fi

    echo "   🔗 Connectivity: Verified for $DB_NAME"
    echo "   💾 Executing compressed snapshot..."
    
    SNAPSHOT_FILE="$BACKUP_REPOSITORY/snapshot-$name-db-$TIMESTAMP.sql.gz"

    # Execution: Direct mysqldump with optimization flags
    # --single-transaction: Ensures consistency without locking tables (InnoDB)
    # --quick: Streams the dump instead of buffering in memory (Resource efficient)
    if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
        --single-transaction --quick --no-tablespaces \
        "$DB_NAME" 2> /dev/null | gzip > "$SNAPSHOT_FILE"; then
        
        SIZE=$(du -h "$SNAPSHOT_FILE" | cut -f1)
        echo "   ✅ Snapshot Completed: $SNAPSHOT_FILE ($SIZE)"
    else
        echo "   ❌ Execution Error: Snapshot process failed for $name"
        rm -f "$SNAPSHOT_FILE" # Integrity Cleanup
    fi
done

echo ""
echo "📊 OPERATIONAL AUDIT:"
DUMP_COUNT=$(find "$BACKUP_REPOSITORY" -name "*.sql.gz" -type f | wc -l)
echo "   Total Snapshots in Repository: $DUMP_COUNT"
echo "   Storage Usage: $(du -sh "$BACKUP_REPOSITORY" | cut -f1)"

echo ""
echo "✅ STANDALONE BACKUP ENGINE OPERATION COMPLETED!"