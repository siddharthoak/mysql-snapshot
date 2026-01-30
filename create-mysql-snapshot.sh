#!/bin/bash
# Display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Setup MySQL database with DDL and CSV data, then export snapshot"
    echo ""
    echo "OPTIONS:"
    echo "  -c CONTAINER_NAME    MySQL container name (default: mysql-db)"
    echo "  -d DATABASE_NAME     Database/schema name (default: halo_db)"
    echo "  -h                   Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MYSQL_ROOT_PASSWORD   MySQL root password (default: rootpassword)"
    echo "  MYSQL_PORT           MySQL port (default: 3306)"
    echo "  SNAPSHOT_DIR         Snapshot output directory (default: ./snapshots)"
    echo "  DATA_DIR             Data files directory (default: ./data)"
    echo ""
    echo "Examples:"
    echo "  $0 -c halo_mysql -d halo_new"
    echo "  $0 -c prod-mysql -d production_db"
    echo "  MYSQL_ROOT_PASSWORD=secret123 $0 -c my-container -d my_db"
    echo ""
    exit 0
}
# Parse command line arguments
while getopts "c:d:h" opt; do
    case $opt in
        c)
            CONTAINER_NAME="$OPTARG"
            ;;
        d)
            DATABASE_NAME="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "Use -h for help"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
# Configuration with defaults (can be overridden by command line flags or environment variables)
CONTAINER_NAME=${CONTAINER_NAME:-"mysql-db"}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"rootpassword"}
DATABASE_NAME=${DATABASE_NAME:-"halo_db"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}
SNAPSHOT_DIR=${SNAPSHOT_DIR:-"./snapshots"}
SNAPSHOT_NAME=${SNAPSHOT_NAME:-"${DATABASE_NAME}_$(date +%Y%m%d_%H%M%S)"}
DATA_DIR=${DATA_DIR:-"./data"}
DOCUMENT_SUMMARY_SOURCE="dump"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1"
}
error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
    exit 1
}
warning() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >&2
}
# Check if container exists and is running
check_container() {
    log "Checking MySQL container status..."
    if ! docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "Container $CONTAINER_NAME does not exist. Creating new container..."
        create_container
    elif ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        log "Container $CONTAINER_NAME exists but is not running. Starting container..."
        if ! docker start $CONTAINER_NAME; then
            error "Failed to start container $CONTAINER_NAME"
        fi
        wait_for_mysql
    else
        log "Container $CONTAINER_NAME is already running"
        # Note: Database recreation will be handled in setup_database() function
    fi
}
# Create new MySQL container
create_container() {
    log "Creating MySQL container: $CONTAINER_NAME"
    if ! docker run -d \
        --name $CONTAINER_NAME \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
        -e MYSQL_DATABASE=$DATABASE_NAME \
        -p $MYSQL_PORT:3306 \
        mysql:8.0 \
        --local-infile=1; then
        error "Failed to create MySQL container"
    fi
    log "MySQL container created successfully"
    wait_for_mysql
}
# Wait for MySQL to be ready
wait_for_mysql() {
    log "Waiting for MySQL to be ready..."
    local max_attempts=30
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec $CONTAINER_NAME mysqladmin ping -u root -p"$MYSQL_ROOT_PASSWORD" --silent 2>/dev/null; then
            log "MySQL is ready"
            return 0
        fi
        log "Attempt $attempt/$max_attempts: MySQL not ready yet, waiting 5 seconds..."
        sleep 5
        ((attempt++))
    done
    error "MySQL failed to become ready after $max_attempts attempts"
}
# Recreate database (drop and create)
recreate_database() {
    log "Recreating database: $DATABASE_NAME"
    # Drop database if it exists
    log "Dropping database $DATABASE_NAME if it exists..."
    if ! docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        -e "DROP DATABASE IF EXISTS $DATABASE_NAME;" 2>/dev/null; then
        error "Failed to drop database $DATABASE_NAME"
    fi
    log "Database $DATABASE_NAME dropped successfully"
    # Create fresh database
    log "Creating fresh database $DATABASE_NAME..."
    if ! docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        -e "CREATE DATABASE $DATABASE_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null; then
        error "Failed to create database $DATABASE_NAME"
    fi
    log "Database $DATABASE_NAME created successfully with UTF8MB4 charset"
}
# Execute SQL file in container
execute_sql_file() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    if [ ! -f "$file_path" ]; then
        warning "File $file_path not found, skipping..."
        return 1
    fi
    log "Executing SQL file: $file_name"
    # Copy file to container
    if ! docker cp "$file_path" "$CONTAINER_NAME:/tmp/$file_name"; then
        error "Failed to copy $file_name to container"
    fi
    # Execute SQL file (since we have a fresh database, this should work cleanly)
    log "Executing $file_name on fresh database..."
    if ! docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "source /tmp/$file_name" 2>/dev/null; then
        # Clean up temporary file even on failure
        docker exec $CONTAINER_NAME rm -f "/tmp/$file_name"
        error "Failed to execute $file_name on fresh database"
    fi
    # Clean up temporary file in container
    docker exec $CONTAINER_NAME rm -f "/tmp/$file_name"
    log "Successfully executed $file_name"
    # Verify that key tables were created
    log "Verifying DDL execution by checking for key tables..."
    local key_tables=("users" "customers")
    local tables_exist=0
    for table in "${key_tables[@]}"; do
        if docker exec $CONTAINER_NAME mysql \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            $DATABASE_NAME \
            -e "SHOW TABLES LIKE '$table';" 2>/dev/null | grep -q "$table"; then
            log "✓ Table $table created successfully"
            ((tables_exist++))
        fi
    done
    log "DDL verification: Created $tables_exist expected tables"
}
# Process CSV for binary(16) ID conversion
process_csv_for_binary() {
    local csv_path=$1
    local table_name=$2
    local processed_csv="./processed_$(basename "$csv_path")"
    # Only process for customers table, return original path for all other tables
    if [ "$table_name" = "customers" ]; then
        # Log to stderr to avoid interfering with return value
        log "Processing CSV for binary(16) ID conversion: $(basename "$csv_path")" >&2
        # Ensure we have a local file path
        if [ ! -f "$csv_path" ]; then
            error "CSV file not found: $csv_path"
            return 1
        fi
        # Read the CSV and process the ID column
        # First line is header, keep as-is
        # Subsequent lines: convert X'hexstring' to just hexstring for UNHEX() function
        awk -F',' '
        BEGIN { OFS="," }
        NR==1 { print; next }  # Print header as-is
        {
            # Process first field (ID) - remove X and quotes, keep just the hex string
            if ($1 ~ /^X['"'"'][0-9a-fA-F]+['"'"']$/) {
                gsub(/^X['"'"']/, "", $1)  # Remove X'"'"' prefix
                gsub(/['"'"']$/, "", $1)   # Remove '"'"' suffix
                $1 = "\"" $1 "\""          # Add quotes back for CSV format
            }
            print
        }' "$csv_path" > "$processed_csv"
        echo "$processed_csv"
    else
        # For all other tables (users, etc.), return original path without processing
        echo "$csv_path"
    fi
}
# Find CSV files by pattern
find_csv_files() {
    local pattern=$1
    local table_name=$2
    log "Looking for CSV files matching pattern: ${pattern}*.csv"
    # Find all CSV files that start with the pattern
    local files=($(find "$DATA_DIR" -name "${pattern}*.csv" -type f 2>/dev/null))
    if [ ${#files[@]} -eq 0 ]; then
        warning "No CSV files found matching pattern ${pattern}*.csv in $DATA_DIR"
        return 1
    fi
    log "Found ${#files[@]} CSV file(s) for $table_name table"
    # Check if table exists and has data before processing any files
    local has_existing_data=false
    if docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "SHOW TABLES LIKE '$table_name';" 2>/dev/null | grep -q "$table_name"; then
        local existing_count=$(docker exec $CONTAINER_NAME mysql \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            $DATABASE_NAME \
            -e "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tail -n 1)
        if [ "$existing_count" -gt 0 ]; then
            log "Table $table_name currently has $existing_count rows"
            has_existing_data=true
        fi
    fi
    # Clear table once before importing all CSV files (if data exists)
    if [ "$has_existing_data" = true ]; then
        log "Clearing existing data from $table_name before importing new data..."
        if ! docker exec $CONTAINER_NAME mysql \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            $DATABASE_NAME \
            -e "DELETE FROM $table_name;" 2>/dev/null; then
            warning "Failed to clear existing data from $table_name, continuing anyway..."
        else
            log "Successfully cleared existing data from $table_name"
        fi
    fi
    # Import each found file
    local total_imported=0
    for file in "${files[@]}"; do
        local file_name=$(basename "$file")
        log "Processing file: $file_name"
        if import_csv_file_no_clear "$file" "$table_name"; then
            ((total_imported++))
        else
            warning "Failed to import $file_name"
        fi
    done
    # Final verification
    local final_count=$(docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "SELECT COUNT(*) FROM $table_name;" 2>/dev/null | tail -n 1)
    log "Completed importing $total_imported file(s) to $table_name. Final row count: $final_count"
    return 0
}
# Import CSV file into table without clearing (updated for binary(16) support)
import_csv_file_no_clear() {
    local csv_path=$1
    local table_name=$2
    local csv_name=$(basename "$csv_path")
    # Verify the source file exists and is readable
    if [ ! -f "$csv_path" ]; then
        error "Source CSV file not found: $csv_path"
        return 1
    fi
    if [ ! -r "$csv_path" ]; then
        error "Source CSV file not readable: $csv_path"
        return 1
    fi
    log "  Source file: $csv_path"
    log "  File size: $(wc -c < "$csv_path") bytes"
    # Process CSV if needed for binary conversion
    local processed_csv_path=$(process_csv_for_binary "$csv_path" "$table_name")
    local processed_csv_name=$(basename "$processed_csv_path")
    # Verify processed file exists
    if [ ! -f "$processed_csv_path" ]; then
        error "Processed CSV file not found: $processed_csv_path"
        return 1
    fi
    # Copy processed CSV to container
    log "  Copying $processed_csv_name to container..."
    if ! docker cp "$processed_csv_path" "$CONTAINER_NAME:/tmp/$processed_csv_name"; then
        error "Failed to copy $processed_csv_name to container"
        # Clean up temporary processed file if we created one
        if [ "$processed_csv_path" != "$csv_path" ]; then
            rm -f "$processed_csv_path"
        fi
        return 1
    fi
    # Choose import SQL based on table type
    local import_sql
    if [ "$table_name" = "customers" ]; then
        # Special handling for customers table with binary(16) ID
        log "  Using binary(16) import method for customers table..."
        import_sql="SET GLOBAL local_infile = 1;
                   LOAD DATA LOCAL INFILE '/tmp/$processed_csv_name' 
                   INTO TABLE $table_name 
                   FIELDS TERMINATED BY ',' 
                   ENCLOSED BY '\"' 
                   LINES TERMINATED BY '\n' 
                   IGNORE 1 ROWS
                   (
                     @id_hex,
                     name,
                     email,
                     created_at,
                     updated_at,
                     @tag_metadata,
                     phone,
                     preferred_contact_method,
                     primary_city,
                     primary_state,
                     zip_code_extended,
                     age,
                     profession,
                     is_married,
                     is_homeowner,
                     income_source,
                     publisher,
                     advertiser,
                     customer_segment,
                     estimated_aum,
                     income,
                     cash_allocation,
                     investments_allocation,
                     retirement_allocation,
                     home_value_allocation,
                     other_investments_allocation,
                     time_to_retirement,
                     investment_obj,
                     market_drop,
                     long_term_plan_conf,
                     open_to_remote,
                     prev_paid_advice,
                     lead_id,
                     @portfolio_management_json,
                     @preferred_relationships_json,
                     @speciality_interests_json,
                     @verifications_json,
                     @tag_metadata_json,
                     @basic_data_json
                   )
                   SET 
                     id = UNHEX(@id_hex),
                     tag_metadata = IF(@tag_metadata = '', NULL, @tag_metadata),
                     portfolio_management_json = IF(@portfolio_management_json = '', NULL, @portfolio_management_json),
                     preferred_relationships_json = IF(@preferred_relationships_json = '', NULL, @preferred_relationships_json),
                     speciality_interests_json = IF(@speciality_interests_json = '', NULL, @speciality_interests_json),
                     verifications_json = IF(@verifications_json = '', NULL, @verifications_json),
                     tag_metadata_json = IF(@tag_metadata_json = '', NULL, @tag_metadata_json),
                     basic_data_json = IF(@basic_data_json = '', NULL, @basic_data_json);"
    elif [ "$table_name" = "document_summary" ]; then
        # Special handling for users table (if needed)
        log "  Using specific command for inserting in doc_summary..."
        import_sql="SET GLOBAL local_infile = 1;
                    LOAD DATA LOCAL INFILE '/tmp/$processed_csv_name' 
                    INTO TABLE $table_name 
                    FIELDS TERMINATED BY ',' 
                    ENCLOSED BY '\"'
                    LINES TERMINATED BY '\n';"
    else
        # Standard import for other tables
        log "  Using standard import method..."
        import_sql="SET GLOBAL local_infile = 1;
                   LOAD DATA LOCAL INFILE '/tmp/$processed_csv_name' 
                   INTO TABLE $table_name 
                   FIELDS TERMINATED BY ',' 
                   ENCLOSED BY '\"' 
                   LINES TERMINATED BY '\n' 
                   IGNORE 1 ROWS;"
    fi
    
    log "  Executing import SQL..."
    # Debug: Show first few lines of the processed CSV
    log "  Debugging: First 3 lines of processed CSV:"
    docker exec $CONTAINER_NAME head -n 3 "/tmp/$processed_csv_name" 2>/dev/null || log "  Could not read processed CSV for debugging"
    # Debug: Show table structure
    log "  Debugging: Table structure:"
    docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "DESCRIBE $table_name;" 2>/dev/null || log "  Could not describe table"
    # Try the import with error output
    log "  Attempting import with detailed error output..."
    local import_result
    import_result=$(docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        --local-infile=1 \
        $DATABASE_NAME \
        -e "$import_sql" 2>&1)
    local import_exit_code=$?
    if [ $import_exit_code -ne 0 ]; then
        log "  Import failed with exit code: $import_exit_code"
        log "  Error output: $import_result"
        # Clean up temporary files even on failure
        docker exec $CONTAINER_NAME rm -f "/tmp/$processed_csv_name" 2>/dev/null
        if [ "$processed_csv_path" != "$csv_path" ]; then
            rm -f "$processed_csv_path"
        fi
        log "  ✗ Failed to import $csv_name (check CSV format and table structure)"
        return 1
    fi
    # Clean up temporary files in container and local
    docker exec $CONTAINER_NAME rm -f "/tmp/$processed_csv_name" 2>/dev/null
    if [ "$processed_csv_path" != "$csv_path" ]; then
        rm -f "$processed_csv_path"
    fi
    log "  ✓ Imported $csv_name successfully"
    return 0
}

# Load document_summary from SQL dump file
load_document_summary_dump() {
    log "Loading document_summary from SQL dump file..."
    
    # Find the dump file matching pattern document_summary_*.sql.gz
    local dump_files=($(find "$DATA_DIR" -name "document_summary_*.sql.gz" -type f 2>/dev/null))
    
    if [ ${#dump_files[@]} -eq 0 ]; then
        error "No document_summary_*.sql.gz dump file found in $DATA_DIR"
        return 1
    fi
    
    if [ ${#dump_files[@]} -gt 1 ]; then
        warning "Multiple dump files found, using first one: ${dump_files[0]}"
    fi
    
    local dump_file="${dump_files[0]}"
    local dump_name=$(basename "$dump_file")
    
    log "  Found dump file: $dump_name"
    log "  File size: $(wc -c < "$dump_file") bytes"
    
    # Copy dump file to container
    log "  Copying dump file to container..."
    if ! docker cp "$dump_file" "$CONTAINER_NAME:/tmp/$dump_name"; then
        error "Failed to copy $dump_name to container"
        return 1
    fi
    
    # Decompress and execute SQL dump
    log "  Decompressing and executing SQL dump..."
    local exec_result
    exec_result=$(docker exec $CONTAINER_NAME bash -c "gunzip -c /tmp/$dump_name | mysql -u root -p'$MYSQL_ROOT_PASSWORD' $DATABASE_NAME" 2>&1)
    local exec_exit_code=$?
    
    if [ $exec_exit_code -ne 0 ]; then
        log "  SQL dump execution failed with exit code: $exec_exit_code"
        log "  Error output: $exec_result"
        docker exec $CONTAINER_NAME rm -f "/tmp/$dump_name"
        error "Failed to execute document_summary SQL dump"
        return 1
    fi
    
    # Clean up temporary file
    docker exec $CONTAINER_NAME rm -f "/tmp/$dump_name"
    
    # Verify import
    local final_count=$(docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "SELECT COUNT(*) FROM document_summary;" 2>/dev/null | tail -n 1)
    
    log "  ✓ SQL dump loaded successfully. Final row count: $final_count"
    return 0
}

# Execute stored procedure file (handles DELIMITER changes)
execute_stored_procedure_file() {
    local file_path="$DATA_DIR/mock_sf_data.sql"
    local file_name=$(basename "$file_path")
    
    if [ ! -f "$file_path" ]; then
        warning "Stored procedure file $file_path not found, skipping..."
        return 1
    fi
    
    log "Executing stored procedure file: $file_name"
    
    # Copy file to container
    if ! docker cp "$file_path" "$CONTAINER_NAME:/tmp/$file_name"; then
        error "Failed to copy $file_name to container"
    fi
    
    # Execute SQL file from within container (this handles DELIMITER properly)
    log "Creating stored procedure from $file_name..."
    local exec_output
    exec_output=$(docker exec $CONTAINER_NAME bash -c "mysql -u root -p'$MYSQL_ROOT_PASSWORD' $DATABASE_NAME < /tmp/$file_name" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        log "Stored procedure execution failed with exit code: $exit_code"
        log "Error output: $exec_output"
        docker exec $CONTAINER_NAME rm -f "/tmp/$file_name"
        error "Failed to execute stored procedure file $file_name"
        return 1
    fi
    
    log "SQL file executed with exit code: $exit_code"
    if [ -n "$exec_output" ]; then
        log "Output: $exec_output"
    fi
    
    # Verify the procedure was created
    log "Verifying stored procedure creation..."
    local proc_check
    proc_check=$(docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "SHOW PROCEDURE STATUS WHERE Db = '$DATABASE_NAME' AND Name = 'generate_advisor_customer_data';" 2>&1)
    
    if echo "$proc_check" | grep -q "generate_advisor_customer_data"; then
        log "✓ Stored procedure 'generate_advisor_customer_data' created successfully"
    else
        warning "✗ Stored procedure 'generate_advisor_customer_data' was not found after execution"
        log "Procedure check output: $proc_check"
    fi
    
    # Clean up temporary file in container
    docker exec $CONTAINER_NAME rm -f "/tmp/$file_name"
    
    return 0
}

# Invoke the stored procedure
invoke_stored_procedure() {
    log "Invoking stored procedure: generate_advisor_customer_data"
    
    # First verify the procedure exists
    local proc_exists
    proc_exists=$(docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "SHOW PROCEDURE STATUS WHERE Db = '$DATABASE_NAME' AND Name = 'generate_advisor_customer_data';" 2>/dev/null | wc -l)
    
    if [ "$proc_exists" -lt 2 ]; then
        error "Stored procedure 'generate_advisor_customer_data' does not exist. Cannot invoke."
        return 1
    fi
    
    log "Stored procedure exists, calling it now..."
    
    # Call the stored procedure with detailed output
    local call_output
    call_output=$(docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -vvv \
        -e "CALL generate_advisor_customer_data();" 2>&1)
    local call_exit_code=$?
    
    if [ $call_exit_code -ne 0 ]; then
        log "Stored procedure call failed with exit code: $call_exit_code"
        log "Error output: $call_output"
        error "Failed to invoke stored procedure generate_advisor_customer_data"
        return 1
    fi
    
    log "Stored procedure executed with exit code: $call_exit_code"
    if [ -n "$call_output" ]; then
        log "Procedure output: $call_output"
    fi
    
    log "Successfully executed stored procedure generate_advisor_customer_data"
    
    # Show some statistics about generated data
    log "Checking generated data..."
    docker exec $CONTAINER_NAME mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        $DATABASE_NAME \
        -e "SELECT 'customers' as table_name, COUNT(*) as row_count FROM customers 
            UNION ALL 
            SELECT 'users', COUNT(*) FROM users;" 2>/dev/null || true
    
    return 0
}


# Setup database with DDL and data

# Setup database with DDL and data
setup_database() {
    log "Setting up database with DDL and data..."
    
    # 0. Drop and recreate database for clean setup
    log "Step 0: Recreating database for clean setup..."
    # recreate_database
    
    # 1. Execute DDL first
    log "Step 1: Executing DDL..."
    execute_sql_file "$DATA_DIR/ddl.sql"
    
    # 1.5. Execute stored procedure file and invoke it
    log "Step 1.5: Setting up and executing stored procedures..."
    if execute_stored_procedure_file; then
        log "Stored procedure file executed successfully"
        # Invoke the stored procedure to generate mock data
        if invoke_stored_procedure; then
            log "Stored procedure invoked successfully"
        else
            warning "Failed to invoke stored procedure, continuing anyway..."
        fi
    else
        warning "Stored procedure file not found or failed to execute, continuing anyway..."
    fi
    
    # 2. Import users data (files starting with "users")
    log "Step 2: Importing users data..."
    if find_csv_files "users" "users"; then
        log "Users data import completed"
    else
        warning "No users CSV files found or import failed"
    fi
    
    
    # 3. Import or load document_summary data based on DOCUMENT_SUMMARY_SOURCE flag
    log "Step 3: Loading document_summary data (source: $DOCUMENT_SUMMARY_SOURCE)"
    if [ "$DOCUMENT_SUMMARY_SOURCE" = "csv" ]; then
        # Load from CSV (original behavior)
        if find_csv_files "document_summary" "document_summary"; then
            log "Document summary CSV import completed"
        else
            warning "Document summary CSV files not found or import failed"
        fi
    else
        # Load from dump (default)
        if load_document_summary_dump; then
            log "Document summary SQL dump loaded successfully"
        else
            warning "Failed to load document summary SQL dump"
        fi
    fi
    
    log "Database setup completed"
}


# Export entire database snapshot
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
# Verify database setup
verify_database() {
    log "Verifying database setup..."
    # Check if tables exist and have data
    local tables=("users" "customers", "document_summary")
    for table in "${tables[@]}"; do
        log "Checking table: $table"
        # Check if table exists
        if ! docker exec $CONTAINER_NAME mysql \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            $DATABASE_NAME \
            -e "DESCRIBE $table;" >/dev/null 2>&1; then
            warning "Table $table does not exist or is not accessible"
            continue
        fi
        # Get row count
        local count=$(docker exec $CONTAINER_NAME mysql \
            -u root -p"$MYSQL_ROOT_PASSWORD" \
            $DATABASE_NAME \
            -e "SELECT COUNT(*) FROM $table;" 2>/dev/null | tail -n 1)
        log "Table $table contains $count rows"
        # For customers table, show sample ID to verify binary(16) import
        if [ "$table" = "customers" ] && [ "$count" -gt 0 ]; then
            log "Sample customers ID (hex): "
            docker exec $CONTAINER_NAME mysql \
                -u root -p"$MYSQL_ROOT_PASSWORD" \
                $DATABASE_NAME \
                -e "SELECT HEX(id) as hex_id, name FROM $table LIMIT 3;" 2>/dev/null || true
        fi
    done
    log "Database verification completed"
}
# Main execution
main() {
    log "Starting MySQL database setup and export process..."
    log "Configuration:"
    log "  Container: $CONTAINER_NAME"
    log "  Database: $DATABASE_NAME"
    log "  Port: $MYSQL_PORT"
    log "  Data Directory: $DATA_DIR"
    log "  Snapshot Directory: $SNAPSHOT_DIR"
    log "  Binary(16) Support: Enabled for customers table"
    # Check Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running or not accessible"
    fi
    # Setup or start container
    check_container
    # Setup database if data files exist
    if  [ -n "$(find "$DATA_DIR" -name "users*.csv" -o -name "customers*.csv" 2>/dev/null)" ]; then
        log "Data files found, setting up database..."
        setup_database
        verify_database
    else
        log "No data files found in $DATA_DIR (users*.csv, or customers*.csv), skipping database setup"
    fi
    # Export snapshot
    export_database_snapshot
    log "Process completed successfully!"
    log "Container: $CONTAINER_NAME"
    log "Database: $DATABASE_NAME"
    log "Snapshot: $SNAPSHOT_DIR/$SNAPSHOT_NAME.sql"
}
# Run main function
main "$@"