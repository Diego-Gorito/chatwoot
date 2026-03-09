#!/bin/sh

set -x

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /app/tmp/pids/server.pid
rm -rf /app/tmp/cache/*

echo "Waiting for postgres to become ready...."

# Let DATABASE_URL env take presedence over individual connection params.
# This is done to avoid printing the DATABASE_URL in the logs
$(docker/entrypoints/helpers/pg_database_url.rb)
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"

until $PG_READY
do
  sleep 2;
done

echo "Database ready to accept connections."

# Function to create backup
create_backup() {
  if [ "$ENABLE_AUTO_BACKUP" = "true" ] || [ "$ENABLE_AUTO_MIGRATE" = "true" ]; then
    echo "================================================"
    echo "Creating database backup before migrations..."
    echo "================================================"

    # Create backup directory if it doesn't exist
    BACKUP_DIR="${BACKUP_DIR:-/app/storage/backups}"
    mkdir -p "$BACKUP_DIR"

    # Generate backup filename with timestamp
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/chatwoot_backup_${TIMESTAMP}.sql"

    # Create the backup
    echo "Backing up to: $BACKUP_FILE"
    PGPASSWORD=$POSTGRES_PASSWORD pg_dump \
      -h $POSTGRES_HOST \
      -p $POSTGRES_PORT \
      -U $POSTGRES_USERNAME \
      -d $POSTGRES_DATABASE \
      --no-owner \
      --clean \
      --if-exists \
      > "$BACKUP_FILE"

    if [ $? -eq 0 ]; then
      # Compress the backup
      gzip "$BACKUP_FILE"
      echo "✅ Backup created successfully: ${BACKUP_FILE}.gz"

      # Keep only the last N backups (default 7)
      BACKUP_RETENTION="${BACKUP_RETENTION:-7}"
      echo "Keeping last $BACKUP_RETENTION backups..."
      ls -t "$BACKUP_DIR"/chatwoot_backup_*.sql.gz 2>/dev/null | tail -n +$((BACKUP_RETENTION + 1)) | xargs -r rm -f

      # List current backups
      echo "Current backups:"
      ls -lh "$BACKUP_DIR"/chatwoot_backup_*.sql.gz 2>/dev/null | tail -5

      return 0
    else
      echo "❌ Backup failed! Stopping to prevent data loss."
      return 1
    fi
  fi
  return 0
}

# Function to check if migrations are pending
check_pending_migrations() {
  echo "Checking for pending migrations..."
  PENDING=$(bundle exec rails db:migrate:status | grep "down" | wc -l)

  if [ "$PENDING" -gt 0 ]; then
    echo "Found $PENDING pending migrations"
    return 0
  else
    echo "No pending migrations found"
    return 1
  fi
}

# Run migrations if ENABLE_AUTO_MIGRATE is set to true
if [ "$ENABLE_AUTO_MIGRATE" = "true" ]; then
  echo "================================================"
  echo "Auto-migration is enabled"
  echo "================================================"

  # Check if there are pending migrations
  if check_pending_migrations; then
    # Create backup before running migrations
    if create_backup; then
      echo "================================================"
      echo "Running database migrations..."
      echo "================================================"

      bundle exec rails db:migrate

      if [ $? -eq 0 ]; then
        echo "✅ Migrations completed successfully!"

        # Optional: Run db:seed if it's the first setup
        if [ "$RUN_DB_SEED" = "true" ]; then
          echo "Running database seeds..."
          bundle exec rails db:seed
        fi
      else
        echo "❌ Migration failed! Backup is available at: ${BACKUP_FILE}.gz"
        echo "To restore: gunzip -c ${BACKUP_FILE}.gz | psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE"
        exit 1
      fi
    else
      echo "❌ Backup failed, skipping migrations for safety"
      exit 1
    fi
  else
    echo "No migrations needed, skipping backup"
  fi
elif [ "$ENABLE_AUTO_BACKUP" = "true" ]; then
  # Just create backup without running migrations
  echo "Auto-backup is enabled (without migrations)"
  create_backup
fi

#install missing gems for local dev as we are using base image compiled for production
bundle install

BUNDLE="bundle check"

until $BUNDLE
do
  sleep 2;
done

# Execute the main process of the container
exec "$@"