#!/bin/bash

# MySQL Restore from Snapshot Script
# Usage: ./restore-mysql-snapshot.sh [options]

set -e  # Exit on any error

# Default values
SNAPSHOT_FILE="snapshots/latest-snapshot.sql"
NEW_CONTAINER_NAME="mysql-restored"
DATABASE_NAME="demo_db"
MYSQL_ROOT_PASSWORD="demo123"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            SNAPSHOT_FILE="$2"
            shift 2
            ;;
        -c|--container)
            NEW_CONTAINER_NAME="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE_NAME="$2"
            shift 2
            ;;
        -p|--password)
            MYSQL_ROOT_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Restores MySQL snapshot to a running or new container."
            echo ""
            echo "Options:"
            echo "  -f, --file FILE         Snapshot SQL file (default: snapshots/latest-snapshot.sql)"
            echo "  -c, --container NAME    Target container name (default: mysql-restored)"
            echo "  -d, --database NAME     Target database name (default: demo_db)"
            echo "  -p, --password PASS     MySQL root password (default: demo123)"
            echo "  -h, --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                               # Use all defaults"
            echo "  $0 -f snapshots/users.sql -c my-mysql          # Custom file and container"
            echo "  $0 -c halo_mysql -d halo_new -p mypass         # Container, database, and password"
            echo "  $0 -f my-backup.sql -d production              # Custom file and database"
            echo ""
            echo "Note: If container doesn't exist, it will be created."
            echo "      If container exists and is running, data will be restored to it."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Function to wait for MySQL to be ready
wait_for_mysql() {
    log "Waiting for MySQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $NEW_CONTAINER_NAME mysqladmin -u root -p$MYSQL_ROOT_PASSWORD ping >/dev/null 2>&1; then
            log "MySQL is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    error "MySQL failed to start within ${max_attempts} attempts"
}

# Main execution
main() {
    # Check if snapshot file exists and handle compression
    if [ ! -f "$SNAPSHOT_FILE" ]; then
        error "Snapshot file '$SNAPSHOT_FILE' not found"
    fi
    
    # Handle compressed files
    ACTUAL_SQL_FILE="$SNAPSHOT_FILE"
    if [[ "$SNAPSHOT_FILE" == *.gz ]]; then
        log "Compressed snapshot detected. Extracting..."
        ACTUAL_SQL_FILE="${SNAPSHOT_FILE%.gz}"
        if [ ! -f "$ACTUAL_SQL_FILE" ] || [ "$SNAPSHOT_FILE" -nt "$ACTUAL_SQL_FILE" ]; then
            gunzip -c "$SNAPSHOT_FILE" > "$ACTUAL_SQL_FILE"
            log "Extracted to: $ACTUAL_SQL_FILE"
        else
            log "Using existing extracted file: $ACTUAL_SQL_FILE"
        fi
    fi
    
    log "Restoring MySQL from snapshot: $ACTUAL_SQL_FILE"
    log "Target container: $NEW_CONTAINER_NAME"
    log "Target database: $DATABASE_NAME"
    
    # Check if target container is already running
    if docker ps --format '{{.Names}}' | grep -q "^${NEW_CONTAINER_NAME}$"; then
        log "Container '$NEW_CONTAINER_NAME' is already running. Restoring data to existing container..."
        
        # Test MySQL connection
        log "Testing MySQL connection..."
        if ! docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; then
            error "Cannot connect to MySQL in container '$NEW_CONTAINER_NAME'. Check password or container status."
        fi
        
        # Create database if it doesn't exist
        log "Ensuring database '$DATABASE_NAME' exists..."
        docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD \
            -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;" 2>/dev/null
        
        # Restore to existing container
        log "Restoring data to existing container..."
        if ! docker exec -i $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME \
            < "$ACTUAL_SQL_FILE" 2>/dev/null; then
            error "Failed to restore data to container '$NEW_CONTAINER_NAME'"
        fi
            
    else
        # Stop and remove existing container if it exists but not running
        if docker ps -a --format '{{.Names}}' | grep -q "^${NEW_CONTAINER_NAME}$"; then
            warn "Container '$NEW_CONTAINER_NAME' exists but not running. Removing..."
            docker rm $NEW_CONTAINER_NAME >/dev/null 2>&1 || true
        fi
        
        # Create new MySQL container
        log "Creating new MySQL container '$NEW_CONTAINER_NAME'..."
        docker run -d \
            --name $NEW_CONTAINER_NAME \
            -p 3306:3306 \
            -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
            -e MYSQL_DATABASE=$DATABASE_NAME \
            -v "${NEW_CONTAINER_NAME}_storage:/var/lib/mysql" \
            mysql:8.0 \
            --local-infile=1
        
        # Wait for MySQL to be ready
        wait_for_mysql
        
        # Restore from snapshot
        log "Restoring data from snapshot..."
        if ! docker exec -i $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME \
            < "$ACTUAL_SQL_FILE" 2>/dev/null; then
            error "Failed to restore data from snapshot"
        fi
    fi
    
    # Verify restoration
    log "Verifying restoration..."
    if docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME \
        -e "DESCRIBE users;" >/dev/null 2>&1; then
        local user_count=$(docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME \
            -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
        log "✅ Users table verified with $user_count rows"
    else
        warn "Could not verify users table restoration"
    fi
    
    # Show restoration summary
    log "=== RESTORATION SUMMARY ==="
    log "Container: $NEW_CONTAINER_NAME"
    log "Database: $DATABASE_NAME"
    log "Snapshot: $ACTUAL_SQL_FILE"
    log "Connection: mysql -h localhost -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME"
    
    # Show available tables
    log "=== AVAILABLE TABLES ==="
    docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME \
        -e "SHOW TABLES;" 2>/dev/null || warn "Could not list tables"
    
    log "MySQL restoration completed successfully! 🎉"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [options]"
    echo ""
    echo "Restores MySQL snapshot to a running or new container."
    echo ""
    echo "Options:"
    echo "  -f, --file FILE         Snapshot SQL file (default: snapshots/latest-snapshot.sql)"
    echo "  -c, --container NAME    Target container name (default: mysql-restored)"
    echo "  -d, --database NAME     Target database name (default: demo_db)"
    echo "  -p, --password PASS     MySQL root password (default: demo123)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                               # Use all defaults"
    echo "  $0 -f snapshots/users.sql -c my-mysql          # Custom file and container"
    echo "  $0 -c halo_mysql -d halo_new -p mypass         # Container, database, and password"
    echo "  $0 -f my-backup.sql -d production              # Custom file and database"
    echo ""
    echo "Note: If container doesn't exist, it will be created."
    echo "      If container exists and is running, data will be restored to it."
    exit 0
fi

# Run main function
main "$@"