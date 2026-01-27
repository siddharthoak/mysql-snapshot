#!/bin/bash

# MySQL Restore from Snapshot Script
# Usage: ./restore-mysql-snapshot.sh [options]

set -e  # Exit on any error

# Default values
SNAPSHOT_FILE="snapshots/latest-snapshot.sql"
NEW_CONTAINER_NAME="mysql-restored"
DATABASE_NAME="demo_db"
MYSQL_ROOT_PASSWORD="demo123"

# External DB connection variables
EXTERNAL_DB_HOST=""
EXTERNAL_DB_PORT=""
EXTERNAL_DB_USER=""
EXTERNAL_DB_PASSWORD=""
EXTERNAL_DB_NAME=""
USE_EXTERNAL_DB=false

# Function to parse connection string
parse_connection_string() {
    local connection_string="$1"
    
    # Remove mysql:// prefix if present
    connection_string="${connection_string#mysql://}"
    
    # Extract user:password@host:port/database
    if [[ $connection_string =~ ^([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+)$ ]]; then
        EXTERNAL_DB_USER="${BASH_REMATCH[1]}"
        EXTERNAL_DB_PASSWORD="${BASH_REMATCH[2]}"
        EXTERNAL_DB_HOST="${BASH_REMATCH[3]}"
        EXTERNAL_DB_PORT="${BASH_REMATCH[4]}"
        EXTERNAL_DB_NAME="${BASH_REMATCH[5]}"
    elif [[ $connection_string =~ ^([^:]+):([^@]+)@([^:]+)/(.+)$ ]]; then
        # No port specified, use default
        EXTERNAL_DB_USER="${BASH_REMATCH[1]}"
        EXTERNAL_DB_PASSWORD="${BASH_REMATCH[2]}"
        EXTERNAL_DB_HOST="${BASH_REMATCH[3]}"
        EXTERNAL_DB_PORT="3306"
        EXTERNAL_DB_NAME="${BASH_REMATCH[4]}"
    else
        echo "ERROR: Invalid connection string format. Expected: mysql://user:password@host:port/database"
        exit 1
    fi
}

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
        --db-connection)
            # Parse connection string: mysql://user:password@host:port/database
            CONNECTION_STRING="$2"
            parse_connection_string "$CONNECTION_STRING"
            USE_EXTERNAL_DB=true
            shift 2
            ;;
        --db-host)
            EXTERNAL_DB_HOST="$2"
            USE_EXTERNAL_DB=true
            shift 2
            ;;
        --db-port)
            EXTERNAL_DB_PORT="$2"
            shift 2
            ;;
        --db-user)
            EXTERNAL_DB_USER="$2"
            shift 2
            ;;
        --db-password)
            EXTERNAL_DB_PASSWORD="$2"
            shift 2
            ;;
        --db-name)
            EXTERNAL_DB_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [options]

Restores MySQL snapshot to a Docker container or external MySQL database.

Container Options:
  -f, --file FILE         Snapshot SQL file (default: snapshots/latest-snapshot.sql)
  -c, --container NAME    Target container name (default: mysql-restored)
  -d, --database NAME     Target database name (default: demo_db)
  -p, --password PASS     MySQL root password (default: demo123)

External Database Options:
  --db-connection STRING  Full connection string: mysql://user:password@host:port/database
  --db-host HOST          Database hostname or IP
  --db-port PORT          Database port (default: 3306)
  --db-user USER          Database username
  --db-password PASS      Database password
  --db-name DATABASE      Database name

General Options:
  -h, --help             Show this help message

Examples:
  # Container restoration (default behavior)
  $0                                               # Use all defaults
  $0 -f snapshots/users.sql -c my-mysql          # Custom file and container
  $0 -c halo_mysql -d halo_new -p mypass         # Container, database, and password

  # External database restoration
  $0 --db-connection "mysql://admin:secret@db.example.com:3306/production"
  $0 --db-host localhost --db-user admin --db-password secret --db-name production
  $0 -f backup.sql --db-host 192.168.1.100 --db-user root --db-password mypass --db-name testdb

  # Mixed (external DB with custom snapshot file)
  $0 -f custom-backup.sql --db-connection "mysql://user:pass@remote.db:3306/mydb"

Note: 
- If external DB options are provided, container options are ignored
- If container doesn't exist, it will be created
- If container exists and is running, data will be restored to it
- External DB must be accessible and running
EOF
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to wait for MySQL to be ready (container)
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

# Function to test external database connection
test_external_db_connection() {
    log "Testing external database connection..."
    
    # Set default port if not specified
    if [ -z "$EXTERNAL_DB_PORT" ]; then
        EXTERNAL_DB_PORT="3306"
    fi
    
    # Test connection using mysql client
    if command -v mysql >/dev/null 2>&1; then
        if mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
            log "✅ External database connection successful"
            return 0
        else
            error "❌ Failed to connect to external database at $EXTERNAL_DB_HOST:$EXTERNAL_DB_PORT"
        fi
    else
        warn "MySQL client not found locally. Attempting restoration anyway..."
        return 0
    fi
}

# Function to restore to external database
restore_to_external_db() {
    local sql_file="$1"
    
    info "Restoring to external database:"
    info "  Host: $EXTERNAL_DB_HOST:$EXTERNAL_DB_PORT"
    info "  User: $EXTERNAL_DB_USER"
    info "  Database: $EXTERNAL_DB_NAME"
    
    # Test connection first
    test_external_db_connection
    
    # Create database if it doesn't exist
    log "Ensuring database '$EXTERNAL_DB_NAME' exists..."
    if command -v mysql >/dev/null 2>&1; then
        mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            -e "CREATE DATABASE IF NOT EXISTS \`$EXTERNAL_DB_NAME\`;" 2>/dev/null || \
            warn "Could not create database (may already exist or insufficient permissions)"
        
        # Restore data
        log "Restoring data from snapshot..."
        if mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            "$EXTERNAL_DB_NAME" < "$sql_file" 2>/dev/null; then
            log "✅ Data restoration completed successfully"
        else
            error "❌ Failed to restore data to external database"
        fi
    else
        error "MySQL client not available. Please install mysql-client to restore to external database"
    fi
}

# Function to verify external database restoration
verify_external_db_restoration() {
    log "Verifying external database restoration..."
    
    if command -v mysql >/dev/null 2>&1; then
        # Check if users table exists and get count
        if mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            "$EXTERNAL_DB_NAME" -e "DESCRIBE users;" >/dev/null 2>&1; then
            local user_count=$(mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
                "$EXTERNAL_DB_NAME" -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
            log "✅ Users table verified with $user_count rows"
        else
            warn "Could not verify users table in external database"
        fi
        
        # Show available tables
        log "=== AVAILABLE TABLES ==="
        mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            "$EXTERNAL_DB_NAME" -e "SHOW TABLES;" 2>/dev/null || warn "Could not list tables"
    else
        warn "MySQL client not available for verification"
    fi
}

# Function to restore to container (existing functionality)
restore_to_container() {
    local sql_file="$1"
    
    info "Restoring to Docker container:"
    info "  Container: $NEW_CONTAINER_NAME"
    info "  Database: $DATABASE_NAME"
    
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
            -e "CREATE DATABASE IF NOT EXISTS \`$DATABASE_NAME\`;" 2>/dev/null
        
        # Restore to existing container
        log "Restoring data to existing container..."
        if ! docker exec -i $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
            < "$sql_file" 2>/dev/null; then
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
        if ! docker exec -i $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
            < "$sql_file" 2>/dev/null; then
            error "Failed to restore data from snapshot"
        fi
    fi
}

# Function to verify container restoration
verify_container_restoration() {
    log "Verifying container restoration..."
    if docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
        -e "DESCRIBE users;" >/dev/null 2>&1; then
        local user_count=$(docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
            -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
        log "✅ Users table verified with $user_count rows"
    else
        warn "Could not verify users table restoration"
    fi
    
    # Show available tables
    log "=== AVAILABLE TABLES ==="
    docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
        -e "SHOW TABLES;" 2>/dev/null || warn "Could not list tables"
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
    
    log "Starting MySQL restoration from snapshot: $ACTUAL_SQL_FILE"
    
    # Route to appropriate restoration method
    if [ "$USE_EXTERNAL_DB" = true ]; then
        # Validate external DB parameters
        if [ -z "$EXTERNAL_DB_HOST" ] || [ -z "$EXTERNAL_DB_USER" ] || [ -z "$EXTERNAL_DB_NAME" ]; then
            error "External database requires at least host, user, and database name"
        fi
        
        restore_to_external_db "$ACTUAL_SQL_FILE"
        verify_external_db_restoration
        
        # Show summary for external DB
        log "=== EXTERNAL DATABASE RESTORATION SUMMARY ==="
        log "Host: $EXTERNAL_DB_HOST:$EXTERNAL_DB_PORT"
        log "Database: $EXTERNAL_DB_NAME"
        log "User: $EXTERNAL_DB_USER"
        log "Snapshot: $ACTUAL_SQL_FILE"
        log "Connection string: mysql -h $EXTERNAL_DB_HOST -P $EXTERNAL_DB_PORT -u $EXTERNAL_DB_USER -p $EXTERNAL_DB_NAME"
        
    else
        # Use container restoration (existing functionality)
        restore_to_container "$ACTUAL_SQL_FILE"
        verify_container_restoration
        
        # Show summary for container
        log "=== CONTAINER RESTORATION SUMMARY ==="
        log "Container: $NEW_CONTAINER_NAME"
        log "Database: $DATABASE_NAME"
        log "Snapshot: $ACTUAL_SQL_FILE"
        log "Connection: mysql -h localhost -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME"
    fi
    
    log "MySQL restoration completed successfully! 🎉"
}

# Validate dependencies
check_dependencies() {
    if [ "$USE_EXTERNAL_DB" = true ]; then
        if ! command -v mysql >/dev/null 2>&1; then
            warn "MySQL client not found. Install it with:"
            warn "  Ubuntu/Debian: sudo apt-get install mysql-client"
            warn "  CentOS/RHEL: sudo yum install mysql"
            warn "  macOS: brew install mysql-client"
            warn ""
            warn "Proceeding anyway, but restoration may fail..."
        fi
    else
        if ! command -v docker >/dev/null 2>&1; then
            error "Docker is required for container restoration but not found"
        fi
    fi
}

# Run dependency check and main function
check_dependencies
main "$@"
#!/bin/bash

# MySQL Restore from Snapshot Script
# Usage: ./restore-mysql-snapshot.sh [options]

set -e  # Exit on any error

# Default values
SNAPSHOT_FILE="snapshots/latest-snapshot.sql"
NEW_CONTAINER_NAME="mysql-restored"
DATABASE_NAME="demo_db"
MYSQL_ROOT_PASSWORD="demo123"

# External DB connection variables
EXTERNAL_DB_HOST=""
EXTERNAL_DB_PORT=""
EXTERNAL_DB_USER=""
EXTERNAL_DB_PASSWORD=""
EXTERNAL_DB_NAME=""
USE_EXTERNAL_DB=false

# Function to parse connection string
parse_connection_string() {
    local connection_string="$1"
    
    # Remove mysql:// prefix if present
    connection_string="${connection_string#mysql://}"
    
    # Extract user:password@host:port/database
    if [[ $connection_string =~ ^([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+)$ ]]; then
        EXTERNAL_DB_USER="${BASH_REMATCH[1]}"
        EXTERNAL_DB_PASSWORD="${BASH_REMATCH[2]}"
        EXTERNAL_DB_HOST="${BASH_REMATCH[3]}"
        EXTERNAL_DB_PORT="${BASH_REMATCH[4]}"
        EXTERNAL_DB_NAME="${BASH_REMATCH[5]}"
    elif [[ $connection_string =~ ^([^:]+):([^@]+)@([^:]+)/(.+)$ ]]; then
        # No port specified, use default
        EXTERNAL_DB_USER="${BASH_REMATCH[1]}"
        EXTERNAL_DB_PASSWORD="${BASH_REMATCH[2]}"
        EXTERNAL_DB_HOST="${BASH_REMATCH[3]}"
        EXTERNAL_DB_PORT="3306"
        EXTERNAL_DB_NAME="${BASH_REMATCH[4]}"
    else
        echo "ERROR: Invalid connection string format. Expected: mysql://user:password@host:port/database"
        exit 1
    fi
}

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
        --db-connection)
            # Parse connection string: mysql://user:password@host:port/database
            CONNECTION_STRING="$2"
            parse_connection_string "$CONNECTION_STRING"
            USE_EXTERNAL_DB=true
            shift 2
            ;;
        --db-host)
            EXTERNAL_DB_HOST="$2"
            USE_EXTERNAL_DB=true
            shift 2
            ;;
        --db-port)
            EXTERNAL_DB_PORT="$2"
            shift 2
            ;;
        --db-user)
            EXTERNAL_DB_USER="$2"
            shift 2
            ;;
        --db-password)
            EXTERNAL_DB_PASSWORD="$2"
            shift 2
            ;;
        --db-name)
            EXTERNAL_DB_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [options]

Restores MySQL snapshot to a Docker container or external MySQL database.

Container Options:
  -f, --file FILE         Snapshot SQL file (default: snapshots/latest-snapshot.sql)
  -c, --container NAME    Target container name (default: mysql-restored)
  -d, --database NAME     Target database name (default: demo_db)
  -p, --password PASS     MySQL root password (default: demo123)

External Database Options:
  --db-connection STRING  Full connection string: mysql://user:password@host:port/database
  --db-host HOST          Database hostname or IP
  --db-port PORT          Database port (default: 3306)
  --db-user USER          Database username
  --db-password PASS      Database password
  --db-name DATABASE      Database name

General Options:
  -h, --help             Show this help message

Examples:
  # Container restoration (default behavior)
  $0                                               # Use all defaults
  $0 -f snapshots/users.sql -c my-mysql          # Custom file and container
  $0 -c halo_mysql -d halo_new -p mypass         # Container, database, and password

  # External database restoration
  $0 --db-connection "mysql://admin:secret@db.example.com:3306/production"
  $0 --db-host localhost --db-user admin --db-password secret --db-name production
  $0 -f backup.sql --db-host 192.168.1.100 --db-user root --db-password mypass --db-name testdb

  # Mixed (external DB with custom snapshot file)
  $0 -f custom-backup.sql --db-connection "mysql://user:pass@remote.db:3306/mydb"

Note: 
- If external DB options are provided, container options are ignored
- If container doesn't exist, it will be created
- If container exists and is running, data will be restored to it
- External DB must be accessible and running
EOF
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to wait for MySQL to be ready (container)
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

# Function to test external database connection
test_external_db_connection() {
    log "Testing external database connection..."
    
    # Set default port if not specified
    if [ -z "$EXTERNAL_DB_PORT" ]; then
        EXTERNAL_DB_PORT="3306"
    fi
    
    # Test connection using mysql client
    if command -v mysql >/dev/null 2>&1; then
        if mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
            log "✅ External database connection successful"
            return 0
        else
            error "❌ Failed to connect to external database at $EXTERNAL_DB_HOST:$EXTERNAL_DB_PORT"
        fi
    else
        warn "MySQL client not found locally. Attempting restoration anyway..."
        return 0
    fi
}

# Function to restore to external database
restore_to_external_db() {
    local sql_file="$1"
    
    info "Restoring to external database:"
    info "  Host: $EXTERNAL_DB_HOST:$EXTERNAL_DB_PORT"
    info "  User: $EXTERNAL_DB_USER"
    info "  Database: $EXTERNAL_DB_NAME"
    
    # Test connection first
    test_external_db_connection
    
    # Create database if it doesn't exist
    log "Ensuring database '$EXTERNAL_DB_NAME' exists..."
    if command -v mysql >/dev/null 2>&1; then
        mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            -e "CREATE DATABASE IF NOT EXISTS \`$EXTERNAL_DB_NAME\`;" 2>/dev/null || \
            warn "Could not create database (may already exist or insufficient permissions)"
        
        # Restore data
        log "Restoring data from snapshot..."
        if mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            "$EXTERNAL_DB_NAME" < "$sql_file" 2>/dev/null; then
            log "✅ Data restoration completed successfully"
        else
            error "❌ Failed to restore data to external database"
        fi
    else
        error "MySQL client not available. Please install mysql-client to restore to external database"
    fi
}

# Function to verify external database restoration
verify_external_db_restoration() {
    log "Verifying external database restoration..."
    
    if command -v mysql >/dev/null 2>&1; then
        # Check if users table exists and get count
        if mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            "$EXTERNAL_DB_NAME" -e "DESCRIBE users;" >/dev/null 2>&1; then
            local user_count=$(mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
                "$EXTERNAL_DB_NAME" -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
            log "✅ Users table verified with $user_count rows"
        else
            warn "Could not verify users table in external database"
        fi
        
        # Show available tables
        log "=== AVAILABLE TABLES ==="
        mysql -h"$EXTERNAL_DB_HOST" -P"$EXTERNAL_DB_PORT" -u"$EXTERNAL_DB_USER" -p"$EXTERNAL_DB_PASSWORD" \
            "$EXTERNAL_DB_NAME" -e "SHOW TABLES;" 2>/dev/null || warn "Could not list tables"
    else
        warn "MySQL client not available for verification"
    fi
}

# Function to restore to container (existing functionality)
restore_to_container() {
    local sql_file="$1"
    
    info "Restoring to Docker container:"
    info "  Container: $NEW_CONTAINER_NAME"
    info "  Database: $DATABASE_NAME"
    
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
            -e "CREATE DATABASE IF NOT EXISTS \`$DATABASE_NAME\`;" 2>/dev/null
        
        # Restore to existing container
        log "Restoring data to existing container..."
        if ! docker exec -i $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
            < "$sql_file" 2>/dev/null; then
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
        if ! docker exec -i $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
            < "$sql_file" 2>/dev/null; then
            error "Failed to restore data from snapshot"
        fi
    fi
}

# Function to verify container restoration
verify_container_restoration() {
    log "Verifying container restoration..."
    if docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
        -e "DESCRIBE users;" >/dev/null 2>&1; then
        local user_count=$(docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
            -se "SELECT COUNT(*) FROM users;" 2>/dev/null)
        log "✅ Users table verified with $user_count rows"
    else
        warn "Could not verify users table restoration"
    fi
    
    # Show available tables
    log "=== AVAILABLE TABLES ==="
    docker exec $NEW_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD "$DATABASE_NAME" \
        -e "SHOW TABLES;" 2>/dev/null || warn "Could not list tables"
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
    
    log "Starting MySQL restoration from snapshot: $ACTUAL_SQL_FILE"
    
    # Route to appropriate restoration method
    if [ "$USE_EXTERNAL_DB" = true ]; then
        # Validate external DB parameters
        if [ -z "$EXTERNAL_DB_HOST" ] || [ -z "$EXTERNAL_DB_USER" ] || [ -z "$EXTERNAL_DB_NAME" ]; then
            error "External database requires at least host, user, and database name"
        fi
        
        restore_to_external_db "$ACTUAL_SQL_FILE"
        verify_external_db_restoration
        
        # Show summary for external DB
        log "=== EXTERNAL DATABASE RESTORATION SUMMARY ==="
        log "Host: $EXTERNAL_DB_HOST:$EXTERNAL_DB_PORT"
        log "Database: $EXTERNAL_DB_NAME"
        log "User: $EXTERNAL_DB_USER"
        log "Snapshot: $ACTUAL_SQL_FILE"
        log "Connection string: mysql -h $EXTERNAL_DB_HOST -P $EXTERNAL_DB_PORT -u $EXTERNAL_DB_USER -p $EXTERNAL_DB_NAME"
        
    else
        # Use container restoration (existing functionality)
        restore_to_container "$ACTUAL_SQL_FILE"
        verify_container_restoration
        
        # Show summary for container
        log "=== CONTAINER RESTORATION SUMMARY ==="
        log "Container: $NEW_CONTAINER_NAME"
        log "Database: $DATABASE_NAME"
        log "Snapshot: $ACTUAL_SQL_FILE"
        log "Connection: mysql -h localhost -u root -p$MYSQL_ROOT_PASSWORD $DATABASE_NAME"
    fi
    
    log "MySQL restoration completed successfully! 🎉"
}

# Validate dependencies
check_dependencies() {
    if [ "$USE_EXTERNAL_DB" = true ]; then
        if ! command -v mysql >/dev/null 2>&1; then
            warn "MySQL client not found. Install it with:"
            warn "  Ubuntu/Debian: sudo apt-get install mysql-client"
            warn "  CentOS/RHEL: sudo yum install mysql"
            warn "  macOS: brew install mysql-client"
            warn ""
            warn "Proceeding anyway, but restoration may fail..."
        fi
    else
        if ! command -v docker >/dev/null 2>&1; then
            error "Docker is required for container restoration but not found"
        fi
    fi
}

# Run dependency check and main function
check_dependencies
main "$@"