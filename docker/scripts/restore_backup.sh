#!/bin/bash

# Script to restore database from backup
# Usage: ./restore_backup.sh [backup_file]

set -e

echo "================================================"
echo "Chatwoot Database Restore Tool"
echo "================================================"

# Check if running inside container
if [ ! -f /.dockerenv ]; then
  echo "This script should be run inside the Docker container:"
  echo "docker exec -it chatwoot_rails_1 /app/docker/scripts/restore_backup.sh"
  exit 1
fi

# Load environment variables
source /app/.env 2>/dev/null || true

BACKUP_DIR="${BACKUP_DIR:-/app/storage/backups}"

# If no backup file specified, list available backups
if [ -z "$1" ]; then
  echo "Available backups:"
  echo "=================="
  ls -lh "$BACKUP_DIR"/chatwoot_backup_*.sql.gz 2>/dev/null || echo "No backups found in $BACKUP_DIR"
  echo ""
  echo "Usage: $0 <backup_file>"
  echo "Example: $0 $BACKUP_DIR/chatwoot_backup_20240309_120000.sql.gz"
  exit 1
fi

BACKUP_FILE=$1

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Selected backup: $BACKUP_FILE"
echo ""
echo "⚠️  WARNING: This will replace your current database!"
echo "Press Ctrl+C to cancel or Enter to continue..."
read

# Create a current backup before restoring
echo "Creating safety backup of current database..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SAFETY_BACKUP="$BACKUP_DIR/chatwoot_safety_${TIMESTAMP}.sql"

PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
  -h $POSTGRES_HOST \
  -p $POSTGRES_PORT \
  -U $POSTGRES_USERNAME \
  -d $POSTGRES_DATABASE \
  --no-owner \
  --clean \
  --if-exists \
  > "$SAFETY_BACKUP"

gzip "$SAFETY_BACKUP"
echo "✅ Safety backup created: ${SAFETY_BACKUP}.gz"

# Restore the selected backup
echo "Restoring database from backup..."

# Stop all connections to the database
echo "Stopping application..."
# You might want to stop sidekiq and other services here

# Restore the backup
gunzip -c "$BACKUP_FILE" | PGPASSWORD=$POSTGRES_PASSWORD psql \
  -h $POSTGRES_HOST \
  -p $POSTGRES_PORT \
  -U $POSTGRES_USERNAME \
  -d $POSTGRES_DATABASE \
  -v ON_ERROR_STOP=1

if [ $? -eq 0 ]; then
  echo "✅ Database restored successfully!"
  echo ""
  echo "Please restart all Chatwoot services:"
  echo "  docker-compose restart"
else
  echo "❌ Restore failed!"
  echo "Your safety backup is available at: ${SAFETY_BACKUP}.gz"
  exit 1
fi