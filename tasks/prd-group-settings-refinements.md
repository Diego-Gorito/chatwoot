# PRD: Group Settings Refinements & Cleanup

## Introduction

Refine and extend the existing WhatsApp group conversation feature in three areas:
1. **"You" badge & inbox_contact_id removal** — Add a visual "You" tag next to the self-member in group member lists, and remove the `inbox_contact_id` concept entirely (replacing it with phone_number matching for @mention exclusion).
2. **Group admin settings** — Let admins toggle announcement mode, locked mode, join approval, and leave a group directly from the GroupContactInfo sidebar. Persist group settings and invite code in `contact.additional_attributes`.
3. **Fix broken inline editing** — Restore the ability to edit group name and description from GroupContactInfo (likely broken by phone_number format mismatch in `isInboxAdmin`).

## Goals

- Allow agents to visually identify themselves ("You") in the group member list
- Remove the `inbox_contact_id` pattern from provider_config, jbuilder, InboxContact settings page, and all frontend consumers
- Admin agents can toggle group settings (announcement, locked, join approval) from the sidebar
- Admin agents can leave a group (auto-resolves the conversation)
- Persist group settings and invite code in `contact.additional_attributes` during sync and webhook events
- Fix the broken inline edit for group name/description

## User Stories

### US-041: Backend — ensure group_type is correctly set on existing contacts and conversations
**Description:** As a developer, I need the group message handler to enforce `group_type: :group` on both the contact and conversation records even when they already exist, because some groups render as individual contacts in the frontend (ContactInfo instead of GroupContactInfo, no sender name/avatar on messages).

**Root Cause:** When a group message arrives, `GroupConversationHandler#find_or_create_group_contact` calls `ContactInboxWithContactBuilder`, which may find an existing `contact_inbox` by `source_id` and return it immediately — skipping `create_contact` (the only place `group_type: :group` is set). Similarly, `find_or_create_group_conversation` returns an existing open/pending conversation without checking its `group_type`. This means contacts and conversations created before the `group_type` feature (or through a non-group path) remain `group_type: :individual`, causing the frontend to render them as individual chats.

**Acceptance Criteria:**
- [ ] `GroupConversationHandler#update_group_contact_info` now also ensures `contact.group_type = :group` if it is not already (adds `group_type: :group` to the update_params)
- [ ] `GroupConversationHandler#find_or_create_group_conversation` updates the existing conversation's `group_type` to `:group` if it is currently `:individual` before returning it
- [ ] Existing group conversations that were incorrectly typed as `individual` are corrected upon the next incoming group message
- [ ] Frontend renders GroupContactInfo (not ContactInfo) for these corrected conversations
- [ ] Group message bubbles show sender name and avatar after the fix
- [ ] `bundle exec rspec spec/` passes (no regressions)
- [ ] Typecheck passes

### US-029: i18n — add keys for "You" badge and group settings (en + pt-BR)
**Description:** As a developer, I need i18n keys for the new UI features so no bare strings appear.

**Acceptance Criteria:**
- [ ] Add `GROUP.INFO.YOU_BADGE` with value `"You"` (en) / `"Você"` (pt-BR)
- [ ] Add `GROUP.SETTINGS.SECTION_TITLE` — "Group Settings" / "Configurações do Grupo"
- [ ] Add `GROUP.SETTINGS.ANNOUNCEMENT_MODE` — "Announcement Mode" / "Modo Anúncio"
- [ ] Add `GROUP.SETTINGS.ANNOUNCEMENT_MODE_DESC` — "Only admins can send messages" / "Apenas admins podem enviar mensagens"
- [ ] Add `GROUP.SETTINGS.LOCKED_MODE` — "Edit Restricted" / "Edição Restrita"
- [ ] Add `GROUP.SETTINGS.LOCKED_MODE_DESC` — "Only admins can edit group info" / "Apenas admins podem editar informações do grupo"
- [ ] Add `GROUP.SETTINGS.JOIN_APPROVAL` — "Admin Approval to Join" / "Aprovação do Admin para Entrar"
- [ ] Add `GROUP.SETTINGS.JOIN_APPROVAL_DESC` — "New members need admin approval" / "Novos membros precisam de aprovação do admin"
- [ ] Add `GROUP.SETTINGS.LEAVE_GROUP` — "Leave Group" / "Sair do Grupo"
- [ ] Add `GROUP.SETTINGS.LEAVE_CONFIRM` — "Are you sure you want to leave this group? The conversation will be resolved." / "Tem certeza que deseja sair deste grupo? A conversa será resolvida."
- [ ] Add `GROUP.SETTINGS.LEAVE_SUCCESS` — "You have left the group." / "Você saiu do grupo."
- [ ] Add `GROUP.SETTINGS.LEAVE_ERROR` — "Failed to leave group." / "Falha ao sair do grupo."
- [ ] Add `GROUP.SETTINGS.UPDATE_SUCCESS` — "Group setting updated." / "Configuração do grupo atualizada."
- [ ] Add `GROUP.SETTINGS.UPDATE_ERROR` — "Failed to update group setting." / "Falha ao atualizar configuração do grupo."
- [ ] Remove `INBOX_MGMT.TABS.INBOX_CONTACT` and `INBOX_MGMT.SETTINGS_POPUP.INBOX_CONTACT.*` from en/inboxMgmt.json
- [ ] Typecheck passes

### US-030: Backend — fix Baileys API route/method mismatches
**Description:** As a developer, I need the WhatsappBaileysService methods to match the actual Baileys REST API endpoints documented in ROUTES_SUMMARY.md.

**Acceptance Criteria:**
- [ ] `update_group_participants`: HTTP method changed from PATCH to POST; body sends singular `participant` key; iterates `Array(participants)` making one POST per participant
- [ ] `group_invite_code`: response dig changed from `dig('data', 'code')` to `dig('data', 'inviteCode')`
- [ ] `revoke_group_invite`: response dig changed from `dig('data', 'code')` to `dig('data', 'inviteCode')`
- [ ] `group_join_requests`: route changed from `group-join-requests` to `group-request-participants-list`
- [ ] `handle_group_join_requests`: route changed from `group-join-requests-handle` to `group-request-participants-update`
- [ ] `on_whatsapp`: response parsing changed from `response.parsed_response&.first` to `response.parsed_response&.dig('data')&.first`; spec stubs updated to wrap response in `{ data: [...] }`
- [ ] `bundle exec rspec spec/services/whatsapp/providers/whatsapp_baileys_service_spec.rb` passes
- [ ] `bundle exec rubocop app/services/whatsapp/providers/whatsapp_baileys_service.rb` passes
- [ ] Typecheck passes

### US-031: Backend — add group_leave, group_setting_update, group_join_approval_mode service methods
**Description:** As a developer, I need new methods in WhatsappBaileysService to call the Baileys API for leaving groups and managing group settings.

**Acceptance Criteria:**
- [ ] `group_leave(group_jid)` added: `POST /connections/{phone}/group-leave` with body `{ jid: group_jid }`
- [ ] `group_setting_update(group_jid, setting)` added: `POST /connections/{phone}/group-setting-update` with body `{ jid: group_jid, setting: setting }` (setting is one of: announcement, not_announcement, locked, unlocked)
- [ ] `group_join_approval_mode(group_jid, mode)` added: `POST /connections/{phone}/group-join-approval-mode` with body `{ jid: group_jid, mode: mode }` (mode is 'on' or 'off')
- [ ] All three methods raise `ProviderUnavailableError` on non-2xx responses
- [ ] All three methods added to `with_error_handling` list
- [ ] Delegates added in `Channel::Whatsapp` for the three new methods
- [ ] `bundle exec rspec spec/services/whatsapp/providers/whatsapp_baileys_service_spec.rb` passes
- [ ] Typecheck passes

### US-032: Backend — persist group settings, invite code, and profile picture during sync
**Description:** As a developer, I need `sync_group` and the `groups_update` webhook handler to persist group settings, invite code, and group profile picture in `contact.additional_attributes` and avatar, so the frontend can read them without extra API calls.

**Acceptance Criteria:**
- [ ] `update_group_contact_info` in whatsapp_baileys_service.rb now also persists `announce`, `restrict`, `joinApprovalMode`, `memberAddMode` from group_metadata response into `contact.additional_attributes`
- [ ] `sync_group` calls `group_invite_code` and persists the result as `invite_code` in `contact.additional_attributes`
- [ ] `sync_group` calls `get_profile_pic(group_contact.identifier)` to fetch the group profile picture URL and enqueues `Avatar::AvatarFromUrlJob` to attach it to the group contact (same pattern as `try_update_participant_avatar` for individual contacts)
- [ ] `groups_update.rb` `process_group_settings_changes` now persists setting values (boolean) into `contact.additional_attributes` alongside creating activity messages
- [ ] `groups_update.rb` `process_single_group_update` persists `inviteCode` value into `contact.additional_attributes['invite_code']` when present
- [ ] `bundle exec rspec spec/services/whatsapp/providers/whatsapp_baileys_service_spec.rb` passes
- [ ] Typecheck passes

### US-033: Backend — GroupSettingsController with leave, update, toggle_join_approval
**Description:** As an agent, I need API endpoints to leave a group, toggle group settings, and toggle join approval mode.

**Acceptance Criteria:**
- [ ] New controller `Api::V1::Accounts::Contacts::GroupSettingsController` at `app/controllers/api/v1/accounts/contacts/group_settings_controller.rb`
- [ ] `POST .../group_settings/leave` action: calls `channel.group_leave(@contact.identifier)`, then resolves the conversation (sets status to :resolved). Returns 200. Returns 422 on ProviderUnavailableError.
- [ ] `PATCH .../group_settings` action: accepts `{ setting: 'announcement|not_announcement|locked|unlocked' }`, calls `channel.group_setting_update`. Updates `contact.additional_attributes` accordingly. Returns 200. Returns 422 on error.
- [ ] `POST .../group_settings/toggle_join_approval` action: accepts `{ mode: 'on|off' }`, calls `channel.group_join_approval_mode`. Updates `contact.additional_attributes['joinApprovalMode']`. Returns 200. Returns 422 on error.
- [ ] Routes added in config/routes.rb under the contacts scope: `resource :group_settings, only: [:update] do; post :leave, on: :member; post :toggle_join_approval, on: :member; end`
- [ ] `bundle exec rubocop` passes for the new controller
- [ ] Typecheck passes

### US-034: Backend — remove inbox_contact_id from provider_config and jbuilder
**Description:** As a developer, I need to remove the `inbox_contact_id` concept from the backend: the `link_inbox_contact` method, the jbuilder serialization, and the call in `sync_group`.

**Acceptance Criteria:**
- [ ] `link_inbox_contact` private method removed from `whatsapp_baileys_service.rb`
- [ ] Call to `link_inbox_contact(inbox, participant_contacts)` removed from `sync_group` method
- [ ] `json.inbox_contact_id` line removed from `app/views/api/v1/models/_inbox.json.jbuilder`
- [ ] No remaining references to `inbox_contact_id` in Ruby backend code (except possible migration cleanup — not needed)
- [ ] `bundle exec rspec` passes (any specs referencing inbox_contact_id are updated or removed)
- [ ] Typecheck passes

### US-035: Frontend — refactor TagGroupMembers to use phone_number matching
**Description:** As a developer, I need to replace `excludeContactId` prop with `excludePhoneNumber` in TagGroupMembers so it no longer depends on `inbox_contact_id`.

**Acceptance Criteria:**
- [ ] `TagGroupMembers.vue`: prop renamed from `excludeContactId` (Number|String) to `excludePhoneNumber` (String)
- [ ] Filter at line ~43 changed from `member.contact?.id !== props.excludeContactId` to `member.contact?.phone_number !== props.excludePhoneNumber`
- [ ] `Editor.vue`: prop renamed from `inboxContactId` to `inboxPhoneNumber`; passes it to TagGroupMembers as `exclude-phone-number`
- [ ] `ReplyBox.vue`: computed `inboxContactId` renamed to `inboxPhoneNumber`, returns `this.inbox?.phone_number` instead of `this.inbox?.inbox_contact_id`
- [ ] @mention self-exclusion still works: the inbox's own phone is excluded from the mentions dropdown
- [ ] Typecheck passes

### US-036: Frontend — remove InboxContact.vue and settings tab
**Description:** As a developer, I need to remove the InboxContact component and its tab in inbox settings since `inbox_contact_id` is being removed.

**Acceptance Criteria:**
- [ ] `app/javascript/dashboard/routes/dashboard/settings/inbox/components/InboxContact.vue` file deleted
- [ ] `Settings.vue`: import of InboxContact removed, component registration removed, tab entry `{ key: 'inbox-contact', ... }` removed from visibleToAllChannelTabs for Baileys/Zapi channels, template `<InboxContact :inbox="inbox" />` block removed
- [ ] i18n keys `INBOX_MGMT.TABS.INBOX_CONTACT` and `INBOX_MGMT.SETTINGS_POPUP.INBOX_CONTACT.*` removed from inboxMgmt.json (the removal was done in US-029 i18n step)
- [ ] No remaining imports or references to InboxContact in the frontend
- [ ] Typecheck passes

### US-037: Frontend — add "You" badge in GroupContactInfo member list
**Description:** As an agent, I want to see a "You" badge next to my own contact in the group member list so I can identify myself.

**Acceptance Criteria:**
- [ ] In the member list loop in `GroupContactInfo.vue`, a new badge is displayed next to a member when `member.contact?.phone_number === inboxPhone` (the `inboxPhone` computed already exists)
- [ ] Badge styled similarly to the Admin badge: `px-1.5 py-0.5 text-xs font-medium rounded` with distinct color (e.g. `bg-n-blue-3 text-n-blue-11`)
- [ ] Badge text uses i18n key `GROUP.INFO.YOU_BADGE`
- [ ] Badge appears alongside Admin badge when the inbox contact is also an admin (both badges shown)
- [ ] Tailwind only, no custom CSS
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-038: Frontend — fix inline edit for group name and description
**Description:** As an admin agent, I want inline editing of group name and description to work again in the GroupContactInfo sidebar.

**Acceptance Criteria:**
- [ ] The `isInboxAdmin` computed in `GroupContactInfo.vue` normalizes phone numbers before comparison (strip `+` prefix from both sides) to handle format mismatches between `inbox.phone_number` (e.g. `+5511...`) and `member.contact.phone_number` (e.g. `+5511...` or `5511...`)
- [ ] Clicking the group name activates the inline edit input when user is admin
- [ ] Clicking the description activates the inline edit textarea when user is admin
- [ ] Saving name calls `updateGroupMetadata` with `subject` param and updates the contact name locally
- [ ] Saving description calls `updateGroupMetadata` with `description` param and updates `contact.additional_attributes.description` locally
- [ ] Non-admin users see name and description as read-only text
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-039: Frontend — group settings section UI with toggles
**Description:** As an admin agent, I want to see and toggle group settings (announcement mode, locked mode, join approval) from the GroupContactInfo sidebar.

**Acceptance Criteria:**
- [ ] New "Group Settings" section added in GroupContactInfo below the join requests section, visible only to inbox admins
- [ ] Section shows three toggle switches reading from `contact.additional_attributes`: `announce` (boolean), `restrict` (boolean), `joinApprovalMode` (boolean)
- [ ] Each toggle displays its label and a short description from i18n (`GROUP.SETTINGS.ANNOUNCEMENT_MODE`, etc.)
- [ ] Toggling announcement calls API `PATCH .../group_settings` with `setting: 'announcement'`/`'not_announcement'`
- [ ] Toggling locked calls API with `setting: 'locked'`/`'unlocked'`
- [ ] Toggling join approval calls API `POST .../group_settings/toggle_join_approval` with `mode: 'on'`/`'off'`
- [ ] On success: update `contact.additional_attributes` locally and show success alert
- [ ] On error: revert toggle and show error alert
- [ ] Tailwind only, <script setup> and Composition API
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

### US-040: Frontend — leave group UI with confirmation and auto-resolve
**Description:** As an agent, I want a "Leave Group" button in the GroupContactInfo sidebar that leaves the WhatsApp group and resolves the conversation.

**Acceptance Criteria:**
- [ ] "Leave Group" button at the bottom of GroupContactInfo, always visible (not admin-only), styled as a destructive action (red/ruby color)
- [ ] Clicking shows a confirmation dialog with the text from `GROUP.SETTINGS.LEAVE_CONFIRM`
- [ ] Confirming calls `POST .../group_settings/leave` API
- [ ] On success: shows success alert, conversation is resolved (status updates reactively via existing store), navigates to conversation list
- [ ] On error: shows error alert
- [ ] Tailwind only, <script setup> and Composition API
- [ ] Typecheck passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-0: `group_type: :group` must be enforced on both contact and conversation records whenever a group message is processed, even if the records already exist as `individual`
- FR-1: The system must display a "You"/"Você" badge next to the inbox's own contact in the group member list
- FR-2: The system must identify the self-member by comparing `inbox.phone_number` against `member.contact.phone_number` (with normalization)
- FR-3: The @mention dropdown must exclude the inbox's own contact using phone_number matching instead of `inbox_contact_id`
- FR-4: The InboxContact settings page/tab must be removed entirely
- FR-5: The `inbox_contact_id` field must be removed from provider_config serialization and backend logic
- FR-6: `POST .../group_settings/leave` must leave the WhatsApp group and resolve the conversation
- FR-7: `PATCH .../group_settings` must toggle announcement/locked mode on the WhatsApp group
- FR-8: `POST .../group_settings/toggle_join_approval` must toggle join approval mode on/off
- FR-9: Group settings (announce, restrict, joinApprovalMode, memberAddMode) must be persisted in `contact.additional_attributes` during sync and webhook events
- FR-10: Invite code must be persisted in `contact.additional_attributes['invite_code']` during sync and webhook events
- FR-10b: Group profile picture must be fetched via `get_profile_pic(group_jid)` and attached to the group contact during sync (using the same `profile-picture-url` Baileys route used for individual contacts)
- FR-11: WhatsappBaileysService API calls must match the documented Baileys REST API (ROUTES_SUMMARY.md)
- FR-12: Inline editing of group name and description must work for admin users

## Non-Goals (Out of Scope)

- `group_member_add_mode` API endpoint — not exposed in UI, only persisted from API/webhook
- `group_toggle_ephemeral` (disappearing messages) — not implemented
- Group profile picture **upload** via UI — uses existing contact avatar update flow (unchanged)
- Revoke invite button in the settings section — already handled in the invite link section (US-022)
- Migration to clean up existing `inbox_contact_id` values in provider_config JSON — they are harmless

## Technical Considerations

- `ContactInboxWithContactBuilder` returns early when `source_id` matches an existing `contact_inbox` (line 17–18). It never reaches `create_contact` where `group_type` is assigned. The fix must be in `GroupConversationHandler`, not in the builder (which is shared across all channel types).
- `find_or_create_group_conversation` queries `group_contact_inbox.conversations.where(status: %i[open pending]).last` — if that conversation has `group_type: individual`, it's returned as-is. The fix adds a `group_type` check-and-update before returning.
- Phone number normalization: `inbox.phone_number` may include `+` prefix while `member.contact.phone_number` may not. Always strip `+` for comparison.
- The `groups_update.rb` webhook handler's `TRACKED_SETTINGS` array already includes the setting keys. The change is to persist values in addition to creating activity messages.
- `sync_group` calling `group_invite_code` and `get_profile_pic` adds two extra HTTP calls during sync. This is acceptable since sync is an infrequent manual or scheduled operation.
- The `get_profile_pic` method already exists and accepts any JID (individual `phone@s.whatsapp.net` or group `id@g.us`). For groups, pass `group_contact.identifier` directly (no JID construction needed).
- `group_leave` should trigger conversation resolution server-side, not rely on frontend to call toggle_status separately.

## Success Metrics

- Admin agents can manage group settings without leaving Chatwoot
- Self-member is clearly identifiable in the member list
- No references to `inbox_contact_id` remain in the codebase (except harmless JSON values in existing DB records)
- All existing specs continue to pass after the changes
- Group conversations that were incorrectly typed as `individual` self-correct upon the next incoming message
