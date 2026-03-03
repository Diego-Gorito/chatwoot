# PRD: Group Members Restructure

## Introduction

Restructure how group membership is stored and managed in Chatwoot. Today, group members are tracked through `ConversationGroupMember`, which links contacts to **conversations** rather than to the group contact itself. This design has major downsides:

1. **Inbox/provider coupling:** A group contact is tied to a specific inbox/contact_inbox, so each inbox has its own group representation.
2. **Conversation-level duplication:** Every time group members need to be updated (add/remove/role change), the system must find all open/pending conversations for the group and update each one.
3. **Fragile lookups:** Controllers like `GroupMembersController` and `GroupSettingsController` must always query for open/pending conversations to find the "current" members, creating race conditions and stale data.

The new design introduces a `GroupMember` table that directly relates a **group contact** (`group_type=group`) to **individual contacts** (`group_type=individual`). This is the single source of truth for group membership; conversations no longer store members. All API endpoints, backend services, and frontend stores will be updated accordingly.

## Goals

- Create a `GroupMember` model that links group contacts to individual contacts (replacing `ConversationGroupMember`)
- Remove `ConversationGroupMember` table and all references
- Update `GroupConversationHandler` concern to operate on `GroupMember` instead of `ConversationGroupMember`
- Update all baileys handlers (`GroupParticipantsUpdate`, `GroupsUpdate`, `MessagesUpsert`, etc.) to use the new model
- Update all API controllers (`GroupMembersController`, `GroupSettingsController`, etc.) to query `GroupMember` instead of `ConversationGroupMember`
- Update the frontend `groupMembers` store and API client to work seamlessly with the restructured backend
- Keep the same frontend API interface (endpoints remain under `contacts/:group_id/group_members`)
- Remove conversation-level member data; the group contact is the single source of truth
- No data migration — the provider sync will repopulate `GroupMember` data

## User Stories

### US-050: Create GroupMember model and migration
**Description:** As a developer, I need a new `group_members` table to store the relationship between a group contact and individual contacts.

**Acceptance Criteria:**
- [ ] Create migration for `group_members` table with columns: `group_contact_id` (bigint, not null, foreign key to contacts), `contact_id` (bigint, not null, foreign key to contacts), `role` (integer, default 0/member, not null), `is_active` (boolean, default true, not null), timestamps
- [ ] Add unique index on `(group_contact_id, contact_id)`
- [ ] Add index on `(group_contact_id, is_active)`
- [ ] Add index on `contact_id`
- [ ] Add index on `group_contact_id`
- [ ] Create `GroupMember` model with: `belongs_to :group_contact, class_name: 'Contact'`, `belongs_to :contact`, `enum role: { member: 0, admin: 1 }`, `validates :group_contact_id, uniqueness: { scope: :contact_id }`, scopes `active` and `inactive`
- [ ] Add `has_many :group_memberships, class_name: 'GroupMember', foreign_key: :group_contact_id, dependent: :destroy_async` to `Contact` model (for group contacts)
- [ ] Add `has_many :group_member_contacts, through: :group_memberships, source: :contact` to `Contact` model (for group contacts)
- [ ] Add `has_many :group_participations, class_name: 'GroupMember', dependent: :destroy_async` to `Contact` model (for individual contacts — shows which groups they belong to)
- [ ] Migration runs successfully
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes (no regressions)

### US-051: Remove ConversationGroupMember model and migration
**Description:** As a developer, I need to remove the old `ConversationGroupMember` model and drop the `conversation_group_members` table since membership is now stored in `group_members`.

**Acceptance Criteria:**
- [ ] Create migration to drop `conversation_group_members` table
- [ ] Remove `app/models/conversation_group_member.rb`
- [ ] Remove `has_many :group_members, class_name: 'ConversationGroupMember'` and `has_many :group_contacts, through: :group_members` from `Conversation` model
- [ ] Remove `has_many :conversation_group_memberships, class_name: 'ConversationGroupMember'` and `has_many :group_conversations, through: :conversation_group_memberships` from `Contact` model
- [ ] Remove or update the old migration file `20260205010032_create_conversation_group_members.rb` (keep file but add drop in new migration)
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-052: Update GroupConversationHandler concern to use GroupMember
**Description:** As a developer, I need the shared concern `GroupConversationHandler` to create/update/remove `GroupMember` records instead of `ConversationGroupMember` records.

**Acceptance Criteria:**
- [ ] `add_group_member` now operates on `GroupMember` using `group_contact` (the group's contact) instead of `conversation`. Signature changes to accept `group_contact` instead of `conversation`.
- [ ] `remove_group_member` now operates on `GroupMember` using `group_contact`.
- [ ] `update_group_member_role` now operates on `GroupMember` using `group_contact`.
- [ ] `sync_group_members` now operates on `GroupMember` using `group_contact`. It receives participant contacts and syncs against `group_contact.group_memberships` instead of `conversation.group_members`.
- [ ] All callers of these methods (baileys handlers, baileys service) are updated to pass the group contact instead of conversation.
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-053: Update WhatsappBaileysService sync_group to use GroupMember
**Description:** As a developer, I need the `sync_group` method and its helper `sync_group_members` in `WhatsappBaileysService` to write to `GroupMember` instead of `ConversationGroupMember`.

**Acceptance Criteria:**
- [ ] `sync_group` now receives the group contact (or fetches it from the conversation) and passes it to `sync_group_members`
- [ ] `sync_group_members` in `WhatsappBaileysService` creates/updates `GroupMember` records by `group_contact` + `contact` instead of `conversation` + `contact`
- [ ] Deactivated members are marked `is_active: false` on the `GroupMember` record
- [ ] Roles (admin/member) are correctly persisted on `GroupMember`
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-054: Update GroupParticipantsUpdate handler
**Description:** As a developer, I need the `GroupParticipantsUpdate` baileys handler to add/remove/promote/demote members via `GroupMember` instead of `ConversationGroupMember`.

**Acceptance Criteria:**
- [ ] `process_group_participants_update` resolves the group contact from the group JID
- [ ] `apply_participant_action` calls `add_group_member(group_contact, contact)`, `remove_group_member(group_contact, contact)`, etc. using the updated `GroupConversationHandler` methods
- [ ] Activity messages are still created on the conversation
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-055: Update GroupsUpdate handler to use GroupMember
**Description:** As a developer, I need the `GroupsUpdate` baileys handler to use the new `GroupMember` model when relevant (e.g., group sync operations triggered by update events).

**Acceptance Criteria:**
- [ ] Any member-related operations in group update events use `GroupMember`
- [ ] Settings updates still persist in `contact.additional_attributes` (no change to this part)
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-056: Update MessagesUpsert handler for group member operations
**Description:** As a developer, I need the `MessagesUpsert` handler to use `GroupMember` when adding senders as group members on incoming group messages.

**Acceptance Criteria:**
- [ ] When a message arrives from a group, the sender is added/confirmed as a `GroupMember` of the group contact (not the conversation)
- [ ] The `GroupContactMessageHandler` concern is updated to use the new `add_group_member(group_contact, contact)` signature
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-057: Update GroupMembersController to query GroupMember
**Description:** As a developer, I need `Api::V1::Accounts::Contacts::GroupMembersController` to query `GroupMember` instead of `ConversationGroupMember`.

**Acceptance Criteria:**
- [ ] `index` action queries `GroupMember.active.where(group_contact: @contact).includes(:contact)` instead of searching through conversations
- [ ] `create` action creates `GroupMember` records after calling the provider
- [ ] `update` action (role change) updates the `GroupMember` record
- [ ] `destroy` action sets `is_active: false` on the `GroupMember` record
- [ ] The channel/provider is still resolved from the group contact's contact_inbox/inbox (find the first inbox with an active contact_inbox for this group contact)
- [ ] API response format stays the same (the jbuilder view is updated to read from `GroupMember` but returns the same JSON structure)
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-058: Update GroupSettingsController to not depend on conversations
**Description:** As a developer, I need `Api::V1::Accounts::Contacts::GroupSettingsController` to find the channel/inbox from the group contact's contact_inbox instead of querying for open/pending conversations.

**Acceptance Criteria:**
- [ ] `channel` helper finds inbox through `@contact.contact_inboxes` (or the specific contact_inbox for this group) instead of searching conversations
- [ ] `leave` action resolves all open/pending conversations for the group and resolves them
- [ ] `update` and `toggle_join_approval` work without depending on conversation lookup
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-059: Update Conversation model — remove group_members association
**Description:** As a developer, I need to remove the `group_members` and `group_contacts` associations from the `Conversation` model since membership is now stored at the contact level.

**Acceptance Criteria:**
- [ ] Remove `has_many :group_members, class_name: 'ConversationGroupMember', dependent: :destroy_async` from `Conversation`
- [ ] Remove `has_many :group_contacts, through: :group_members, source: :contact` from `Conversation`
- [ ] Any code that accessed `conversation.group_members` or `conversation.group_contacts` is updated to use `conversation.contact.group_memberships` (where `conversation.contact` is the group contact)
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-060: Update group_members jbuilder views
**Description:** As a developer, I need to update the jbuilder views to render `GroupMember` records instead of `ConversationGroupMember`.

**Acceptance Criteria:**
- [ ] `app/views/api/v1/accounts/contacts/group_members/index.json.jbuilder` renders `GroupMember` records
- [ ] The response still includes `id`, `role`, `is_active`, and nested `contact` object with `id`, `name`, `phone_number`, `identifier`, `thumbnail`
- [ ] Remove `conversation_id` from the response (no longer relevant)
- [ ] `app/views/api/v1/accounts/contacts/sync_group.json.jbuilder` renders `GroupMember` records
- [ ] `bundle exec rubocop -a` passes

### US-061: Update sync_group action on conversations controller
**Description:** As a developer, I need the `sync_group` action in `ConversationsController` to use the new `GroupMember` model.

**Acceptance Criteria:**
- [ ] `sync_group` calls `conversation.inbox.channel.sync_group(conversation)` which internally writes to `GroupMember`
- [ ] The response still returns updated contact and group members data
- [ ] Also update/add the sync_group on the contacts controller (contacts/:id/sync_group) to work with `GroupMember`
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-062: Update frontend groupMembers store — remove conversation_id dependency
**Description:** As a developer, I need to ensure the frontend `groupMembers` Vuex store and API client work correctly after the backend removes `conversation_id` from the response.

**Acceptance Criteria:**
- [ ] `GroupMembersAPI` endpoints remain the same (no URL changes needed)
- [ ] `groupMembers` store mutations and getters work without `conversation_id` in the payload
- [ ] `GroupContactInfo.vue` renders members correctly from the updated response
- [ ] `TagGroupMembers.vue` (mention dropdown) works correctly
- [ ] Editor mention integration works correctly for group conversations
- [ ] No TypeScript/lint errors

### US-063: Update GroupContactMessageHandler concern
**Description:** As a developer, I need the `GroupContactMessageHandler` concern (used by baileys handlers for incoming group messages) to use `GroupMember` for member operations.

**Acceptance Criteria:**
- [ ] The concern's method for adding the sender as a group member calls `add_group_member(group_contact, sender_contact)` (using the group contact, not the conversation)
- [ ] Any method that looked up members via conversation now looks up via group contact
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

### US-064: Helper method to find channel from group contact
**Description:** As a developer, I need a reliable way to find the channel/inbox for a group contact without depending on conversations, since multiple controllers need this.

**Acceptance Criteria:**
- [ ] Add a method (e.g., `channel_for_group_contact` or on the Contact model) that finds the inbox/channel through `contact_inboxes` for a group contact
- [ ] Use this helper in `GroupMembersController`, `GroupSettingsController`, and any other controller that needs to send commands to the provider
- [ ] The helper handles the case where the group contact has multiple contact_inboxes (selects the appropriate one for the current inbox context)
- [ ] `bundle exec rubocop -a` passes
- [ ] `bundle exec rspec` passes

## Functional Requirements

- FR-1: Create `group_members` table with columns: `group_contact_id`, `contact_id`, `role`, `is_active`, timestamps
- FR-2: `GroupMember` model validates uniqueness of `(group_contact_id, contact_id)` and has scopes `active`/`inactive`
- FR-3: `Contact` model gains `has_many :group_memberships` (for group contacts → individual members) and `has_many :group_participations` (for individual contacts → groups they belong to)
- FR-4: Drop `conversation_group_members` table and remove `ConversationGroupMember` model
- FR-5: Remove all `group_members`/`group_contacts` associations from `Conversation` model
- FR-6: `GroupConversationHandler` methods (`add_group_member`, `remove_group_member`, `update_group_member_role`, `sync_group_members`) operate on `GroupMember` via the group contact
- FR-7: All baileys handlers (`GroupParticipantsUpdate`, `GroupsUpdate`, `MessagesUpsert`, `GroupContactMessageHandler`) use `GroupMember` for member CRUD
- FR-8: `WhatsappBaileysService#sync_group` writes to `GroupMember` instead of `ConversationGroupMember`
- FR-9: `GroupMembersController#index` queries `GroupMember.active.where(group_contact: @contact)` directly
- FR-10: `GroupMembersController#create/update/destroy` operate on `GroupMember` records
- FR-11: `GroupSettingsController` finds the channel through `contact_inboxes` instead of open/pending conversations
- FR-12: API response format for group members remains the same (minus `conversation_id` field)
- FR-13: Frontend `groupMembers` store continues to index by group contact ID and works without `conversation_id`
- FR-14: `sync_group` action on both conversations and contacts controllers works with `GroupMember`

## Non-Goals

- No data migration from `conversation_group_members` to `group_members` (provider sync repopulates)
- No changes to how group settings/metadata are stored (`contact.additional_attributes` stays as-is)
- No changes to the `group_type` enum on Contact or Conversation
- No changes to group creation flow (`resources :groups, only: [:create]`)
- No new API endpoints — existing endpoints maintain the same paths
- No changes to non-WhatsApp channels (only baileys has group support currently)
- No changes to the `TagGroupMembers` mention component behavior (only data source change)

## Technical Considerations

- **No data migration needed:** Since we start from zero, the provider sync (`sync_group`) will repopulate `GroupMember` records when triggered. Groups will show empty members until a sync occurs or a message arrives.
- **Channel resolution:** Controllers currently find the channel by querying for an open/pending conversation's inbox. With the new model, they must resolve the channel through `@contact.contact_inboxes.first.inbox.channel` or similar. This is cleaner but needs to handle the case of multiple contact_inboxes.
- **Lock scope:** `GroupConversationHandler` uses `with_contact_lock` on the group JID. This stays the same since the lock is on the contact identifier, not the conversation.
- **Conversation references:** Some code creates activity messages on conversations. These still need the conversation object, which is found via `contact_inbox.conversations.where(status: [:open, :pending])`.
- **Index design:** The unique index on `(group_contact_id, contact_id)` ensures no duplicate memberships. The index on `(group_contact_id, is_active)` optimizes the most common query (active members of a group).
- **Foreign keys:** Both `group_contact_id` and `contact_id` reference `contacts.id`. No additional validation for `group_type` at the database level (just convention).

## Success Metrics

- Group member operations no longer depend on conversation state
- Adding/removing/promoting/demoting a member touches exactly 1 `GroupMember` record (not N conversation records)
- All existing group features (sync, mention, settings, invite, join requests) continue working as before
- `ConversationGroupMember` table and model are fully removed
- No performance regression on group member lookups

## Open Questions

- Should we add a validation on `GroupMember` to ensure `group_contact` has `group_type: :group`? (Model-level validation vs. convention)
- Should we add a `Contact#group?` convenience method for checking `group_type_group?` to improve readability?
- When there are multiple `contact_inboxes` for a group contact, which one should be used to resolve the channel? (First one? Most recent? Based on context?)
