# Kanban Integration Changes

This document lists all changes made to vanilla Chatwoot to integrate Kanban functionality from Fazer AI.

## Core Infrastructure Changes

### 1. Redis Keys (`lib/redis/redis_keys.rb`)

**Added:**
```ruby
## Kanban Keys
# Array storing the ordered ids for agent round robin assignment in Kanban boards
KANBAN_BOARD_ROUND_ROBIN_AGENTS = 'KANBAN_BOARD_ROUND_ROBIN_AGENTS:%<board_id>d'.freeze
```

**Why:** The Kanban board model uses round-robin agent assignment and needs a Redis key to store the queue.

**Used by:** `FazerAi::Kanban::BoardRoundRobinService`

---

### 2. Event Types (`lib/events/types.rb`)

**Added:**
```ruby
# kanban events
KANBAN_BOARD_CREATED = 'kanban.board.created'
KANBAN_BOARD_UPDATED = 'kanban.board.updated'
KANBAN_BOARD_DELETED = 'kanban.board.deleted'
KANBAN_TASK_CREATED = 'kanban.task.created'
KANBAN_TASK_UPDATED = 'kanban.task.updated'
KANBAN_TASK_DELETED = 'kanban.task.deleted'
KANBAN_TASK_MOVED = 'kanban.task.moved'
```

**Why:** Kanban models dispatch events for ActionCable broadcasts and webhook integrations.

**Used by:**
- `FazerAi::Kanban::Board#dispatch_update_event`
- `FazerAi::ActionCableListener`
- Webhook integrations (n8n, etc.)

---

## Fazer AI Directory Structure

All Kanban code lives in the `fazer_ai/` directory and doesn't modify core Chatwoot files except for the two changes above.

```
fazer_ai/
├── app/
│   ├── models/fazer_ai/kanban/
│   │   ├── board.rb
│   │   ├── board_step.rb
│   │   ├── board_agent.rb
│   │   ├── board_inbox.rb
│   │   └── task.rb
│   ├── controllers/api/v1/accounts/kanban/
│   │   ├── boards_controller.rb
│   │   ├── board_steps_controller.rb
│   │   ├── board_agents_controller.rb
│   │   ├── board_inboxes_controller.rb
│   │   ├── board_conversations_controller.rb
│   │   └── audit_events_controller.rb
│   ├── services/fazer_ai/kanban/
│   │   └── board_round_robin_service.rb
│   ├── policies/fazer_ai/kanban/
│   │   └── ...
│   ├── listeners/fazer_ai/
│   │   └── action_cable_listener.rb
│   └── javascript/
│       ├── kanban/      # Kanban v1 (legacy)
│       └── kanban2/     # Kanban v2 (current)
├── db/migrate/
│   └── [kanban migration files]
├── config/
│   └── routes/
│       └── fazer_ai.rb
└── spec/
    └── [kanban specs]
```

---

## Database Tables

Kanban uses the following tables (created by migrations in `fazer_ai/db/migrate/`):

- `kanban_boards` - Board definitions
- `kanban_board_steps` - Columns/stages in a board
- `kanban_board_agents` - Agent assignments to boards
- `kanban_board_inboxes` - Inbox associations to boards
- `kanban_tasks` - Individual tasks
- `kanban_account_user_preferences` - User preferences for Kanban

---

## Routes

Kanban routes are defined in `fazer_ai/config/routes/fazer_ai.rb` and mounted in the main routes file:

```ruby
namespace :kanban do
  resources :boards do
    # ... board routes
  end
  resources :tasks do
    # ... task routes
  end
end
```

---

## Frontend Integration

### Kanban v1 (Legacy)
- Path: `fazer_ai/app/javascript/kanban/`
- Used by: Existing Kanban implementation
- Status: Maintained for compatibility

### Kanban v2 (Current)
- Path: `fazer_ai/app/javascript/kanban2/`
- Features:
  - Premium rounded UI design
  - Full feature parity with v1
  - Vue 3 Composition API
  - Vuex state management
  - Drag & drop with vuedraggable
  - Filter & sort capabilities
  - Modal-based task creation/editing

---

## Minimum Required Patches

To integrate Kanban into a fresh Chatwoot installation, you need:

1. **Redis key constant** (Patch 001)
2. **Event type constants** (Patch 002)
3. **Fazer AI directory** (full copy)
4. **Database migrations** (run migrations from `fazer_ai/db/migrate/`)

---

## Compatibility Notes

### Chatwoot Version Compatibility

| Chatwoot Version | Kanban Compatible | Notes |
|-----------------|-------------------|-------|
| v3.0.x - v3.2.x | ✅ Yes | Tested and working |
| v3.3.x+         | ⚠️ Unknown | Test patches before deploying |
| v4.0.x+         | ⚠️ Unknown | May require patch updates |

### Breaking Changes to Watch

When updating Chatwoot, check for changes in:
- `lib/redis/redis_keys.rb` structure
- `lib/events/types.rb` structure
- ActionCable architecture
- Vuex store patterns
- Vue Router configuration

---

## Testing After Merge

After merging a new Chatwoot version:

1. **Backend Tests:**
   ```bash
   bundle exec rspec fazer_ai/spec/
   ```

2. **Frontend Tests:**
   ```bash
   pnpm test fazer_ai/app/javascript/kanban2/
   ```

3. **Manual Testing:**
   - Create a Kanban board
   - Add tasks
   - Drag & drop tasks
   - Delete board
   - Check for errors in console/logs

---

## Rollback Plan

If patches fail or cause issues:

1. **Revert patches:**
   ```bash
   git revert <commit-hash>
   ```

2. **Or reset to previous version:**
   ```bash
   git reset --hard <previous-commit>
   ```

3. **Keep Fazer AI directory** - it doesn't conflict with core Chatwoot
