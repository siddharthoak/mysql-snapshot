#!/bin/bash

# Configuration (set these to match your setup)
CONTAINER_NAME=${CONTAINER_NAME:-"halo_mysql"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"rootpassword"}
DATABASE_NAME=${DATABASE_NAME:-"halo_chat"}
SNAPSHOT_DIR=${SNAPSHOT_DIR:-"./snapshots"}
SNAPSHOT_NAME=${SNAPSHOT_NAME:-"${DATABASE_NAME}_$(date +%Y%m%d_%H%M%S)"}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    exit 1
}

# Export database snapshot function
export_database_snapshot() {
    log "Creating complete database snapshot..."
    # Create snapshot directory if it doesn't exist
    mkdir -p "$SNAPSHOT_DIR"
    # Export entire database
    log "Exporting entire database: $DATABASE_NAME"
    if ! docker exec $CONTAINER_NAME mysqldump \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --complete-insert \
        --extended-insert \
        --add-drop-table \
        --add-locks \
        --create-options \
        --disable-keys \
        --hex-blob \
        $DATABASE_NAME \
        > "$SNAPSHOT_DIR/$SNAPSHOT_NAME.sql" 2>/dev/null; then
        error "Failed to create complete database dump. Check database connection and permissions."
    fi
    log "Database snapshot created successfully: $SNAPSHOT_DIR/$SNAPSHOT_NAME.sql"
    # Create a compressed version
    if command -v gzip >/dev/null 2>&1; then
        log "Creating compressed snapshot..."
        gzip -c "$SNAPSHOT_DIR/$SNAPSHOT_NAME.sql" > "$SNAPSHOT_DIR/$SNAPSHOT_NAME.sql.gz"
        log "Compressed snapshot created: $SNAPSHOT_DIR/$SNAPSHOT_NAME.sql.gz"
    fi
    # Display file sizes
    log "Snapshot file sizes:"
    ls -lh "$SNAPSHOT_DIR/$SNAPSHOT_NAME.sql"*
}

# Run the export
export_database_snapshot