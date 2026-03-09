# Migration Guide: Adding Kanban to Fresh Chatwoot

This guide explains how to add the Kanban integration to a completely fresh Chatwoot installation.

## Prerequisites

- Fresh Chatwoot installation (v3.0.x or higher)
- Git access to both repositories
- Ruby and Node.js development environment

## Step 1: Copy Fazer AI Directory

```bash
# From your Kanban-enabled Chatwoot repo
cd /path/to/kanban-chatwoot

# Copy entire fazer_ai directory to target
cp -r fazer_ai /path/to/fresh-chatwoot/fazer_ai
```

This directory contains:
- All Kanban models, controllers, services
- Frontend code (Vue components)
- Database migrations
- Tests
- Policies

## Step 2: Apply Core Patches

```bash
cd /path/to/fresh-chatwoot

# Copy patch system
cp -r /path/to/kanban-chatwoot/.kanban-patches .kanban-patches

# Apply patches
.kanban-patches/scripts/apply-patches.sh
```

This adds:
- Redis key constant for Kanban round-robin
- Event type constants for Kanban events

## Step 3: Run Database Migrations

```bash
# Copy migrations
cp -r fazer_ai/db/migrate/* db/migrate/

# Run migrations
bundle exec rails db:migrate
```

Migrations will create:
- `kanban_boards` table
- `kanban_board_steps` table
- `kanban_board_agents` table
- `kanban_board_inboxes` table
- `kanban_tasks` table
- `kanban_account_user_preferences` table

## Step 4: Update Routes

The Kanban routes are auto-loaded from `fazer_ai/config/routes/fazer_ai.rb`.

Verify they're loaded:

```bash
bundle exec rails routes | grep kanban
```

You should see routes like:
```
GET    /api/v1/accounts/:account_id/kanban/boards
POST   /api/v1/accounts/:account_id/kanban/boards
...
```

## Step 5: Install Frontend Dependencies

```bash
# If you haven't already
pnpm install

# Rebuild frontend
pnpm build
```

## Step 6: Verify Installation

Start the server:

```bash
bundle exec rails server
# or
overmind start -f Procfile.dev
```

Check:
1. Navigate to `/app/accounts/1/kanban` (or your account ID)
2. You should see the Kanban board interface
3. Try creating a board
4. Add some tasks
5. Test drag & drop

## Step 7: Seed Sample Data (Optional)

```bash
# Seed basic Chatwoot data
bundle exec rails db:seed

# Or use Kanban-specific seeder (if you created one)
bundle exec rails runner "
  account = Account.first
  board = FazerAi::Kanban::Board.create!(
    account: account,
    name: 'Sales Pipeline',
    description: 'Track sales leads'
  )

  # Create steps
  %w[New Contacted Qualified Proposal Won Lost].each_with_index do |name, i|
    cancelled = (name == 'Lost')
    board.steps.create!(
      name: name,
      cancelled: cancelled,
      position: i
    )
  end
"
```

## Troubleshooting

### Issue: Routes not loading

**Solution:**
Check `config/routes.rb` includes Fazer AI routes:

```ruby
Rails.application.routes.draw do
  # ... existing routes ...

  # Fazer AI / Kanban routes
  draw(:fazer_ai) if File.exist?(Rails.root.join('config/routes/fazer_ai.rb'))
end
```

### Issue: Redis key errors

**Symptom:** `NameError: uninitialized constant Redis::Alfred::KANBAN_BOARD_ROUND_ROBIN_AGENTS`

**Solution:**
Ensure patch 001 was applied:

```bash
grep KANBAN_BOARD_ROUND_ROBIN_AGENTS lib/redis/redis_keys.rb
```

If missing, apply manually or re-run patches.

### Issue: Event type errors

**Symptom:** `NameError: uninitialized constant Events::Types::KANBAN_BOARD_UPDATED`

**Solution:**
Ensure patch 002 was applied:

```bash
grep KANBAN_BOARD_UPDATED lib/events/types.rb
```

### Issue: Frontend not loading

**Solution:**
```bash
# Rebuild frontend
pnpm build

# Or in development
pnpm dev
```

Check browser console for errors.

### Issue: Database migration errors

**Solution:**
```bash
# Check migration status
bundle exec rails db:migrate:status | grep kanban

# If failed, rollback and retry
bundle exec rails db:rollback STEP=1
bundle exec rails db:migrate
```

## Verifying Patches

After applying patches, verify they're correct:

```bash
# Check Redis keys
cat lib/redis/redis_keys.rb | grep -A 2 "Kanban Keys"

# Should show:
# ## Kanban Keys
# # Array storing the ordered ids for agent round robin assignment in Kanban boards
# KANBAN_BOARD_ROUND_ROBIN_AGENTS = 'KANBAN_BOARD_ROUND_ROBIN_AGENTS:%<board_id>d'.freeze

# Check Event types
cat lib/events/types.rb | grep -A 8 "kanban events"

# Should show:
# # kanban events
# KANBAN_BOARD_CREATED = 'kanban.board.created'
# KANBAN_BOARD_UPDATED = 'kanban.board.updated'
# KANBAN_BOARD_DELETED = 'kanban.board.deleted'
# KANBAN_TASK_CREATED = 'kanban.task.created'
# KANBAN_TASK_UPDATED = 'kanban.task.updated'
# KANBAN_TASK_DELETED = 'kanban.task.deleted'
# KANBAN_TASK_MOVED = 'kanban.task.moved'
```

## Rolling Back

If you need to remove Kanban:

```bash
# 1. Rollback migrations
bundle exec rails db:rollback STEP=6  # Number of Kanban migrations

# 2. Remove fazer_ai directory
rm -rf fazer_ai/

# 3. Revert patches
git checkout lib/redis/redis_keys.rb lib/events/types.rb

# 4. Remove patch system
rm -rf .kanban-patches/

# 5. Rebuild frontend
pnpm build
```

## Automated Installation Script

For convenience, here's a script that does it all:

```bash
#!/bin/bash
# install-kanban.sh

set -e

KANBAN_REPO="$1"  # Path to Kanban-enabled Chatwoot repo

if [ -z "$KANBAN_REPO" ]; then
  echo "Usage: $0 /path/to/kanban-chatwoot"
  exit 1
fi

echo "Installing Kanban from $KANBAN_REPO..."

# Copy fazer_ai
echo "Copying fazer_ai directory..."
cp -r "$KANBAN_REPO/fazer_ai" ./fazer_ai

# Copy patch system
echo "Copying patch system..."
cp -r "$KANBAN_REPO/.kanban-patches" ./.kanban-patches

# Apply patches
echo "Applying patches..."
.kanban-patches/scripts/apply-patches.sh

# Copy and run migrations
echo "Running migrations..."
cp -r fazer_ai/db/migrate/* db/migrate/
bundle exec rails db:migrate

# Install frontend deps
echo "Installing frontend dependencies..."
pnpm install

echo "✓ Kanban installation complete!"
echo "Start your server and visit /app/accounts/1/kanban"
```

Save this as `install-kanban.sh`, make it executable, and run:

```bash
chmod +x install-kanban.sh
./install-kanban.sh /path/to/your/kanban-enabled-chatwoot
```

## Next Steps

After successful installation:

1. **Configure Permissions:** Set up Kanban permissions in Settings > Account Settings
2. **Create Boards:** Start creating your Kanban boards
3. **Integrate Webhooks:** Set up n8n or other integrations if needed
4. **Set Up Automation:** Enable the GitHub Actions workflow for auto-updates

## Support

If you encounter issues not covered here:

1. Check the main [README.md](../README.md)
2. Review [CHANGES.md](./CHANGES.md) for details on what was modified
3. Check the patch files in `.kanban-patches/patches/`
