#!/bin/bash

# --- Configuration ---
CONTAINER_NAME="halo_mysql"
DB_USER="halo_user"
DB_PASS="halo"
DB_NAME="halo_chat"
SQL_FILE="generate_crm_data.sql"

echo "Checking container status..."

# 1. Check if the container is actually running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "[ERROR] Container '$CONTAINER_NAME' is not running."
    exit 1
fi

echo "Injecting $SQL_FILE into $CONTAINER_NAME..."

# 2. Execute SQL file via Docker Exec
# We cat the file and pipe it into the mysql client inside the container
cat "$SQL_FILE" | docker exec -i "$CONTAINER_NAME" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"

# 3. Capture the exit status
STATUS=$?

if [ $STATUS -eq 0 ]; then
    echo "---------------------------------------------------"
    echo "[SUCCESS] SQL script and Procedure CALL finished."
    
    # 4. Verify inside the container
    echo -n "Final User Count: "
    docker exec -i "$CONTAINER_NAME" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e "SELECT COUNT(*) FROM users;"
else
    echo "---------------------------------------------------"
    echo "[FAILURE] MySQL execution failed inside the container."
    exit 1
fi