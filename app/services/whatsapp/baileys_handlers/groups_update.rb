module Whatsapp::BaileysHandlers::GroupsUpdate
  include Whatsapp::BaileysHandlers::Helpers
  include Whatsapp::BaileysHandlers::Concerns::GroupContactMessageHandler

  TRACKED_SETTINGS = %w[restrict announce memberAddMode joinApprovalMode].freeze

  private

  def process_groups_update
    updates = processed_params[:data]
    return if updates.blank?

    updates.each { |update| process_single_group_update(update) }
  end

  def process_single_group_update(update)
    group_jid = update[:id]
    return if group_jid.blank?

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_for_update(group_jid)
      conversation = find_or_create_conversation_for_update(group_contact_inbox)
      author_name = resolve_author_name(update[:author])

      update_group_subject(group_contact_inbox, update[:subject], conversation, author_name) if update.key?(:subject)
      update_group_description(conversation, update, author_name) if update.key?(:desc)
      create_group_activity(conversation, 'invite_link_reset', author_name: author_name) if update.key?(:inviteCode)
      process_group_settings_changes(conversation, update, author_name)
    end
  end

  def find_or_create_group_contact_inbox_for_update(group_jid)
    source_id = group_jid.split('@').first

    ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: {
        name: source_id,
        identifier: group_jid,
        group_type: :group
      }
    ).perform
  end

  def find_or_create_conversation_for_update(group_contact_inbox)
    conversation = group_contact_inbox.conversations.where(status: :open).last
    return conversation if conversation.present?

    ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: group_contact_inbox.contact_id,
      contact_inbox_id: group_contact_inbox.id,
      conversation_type: :group
    )
  end

  def update_group_subject(group_contact_inbox, subject, conversation, author_name)
    return if subject.blank?

    contact = group_contact_inbox.contact
    contact.update!(name: subject)

    create_group_activity(conversation, 'subject_changed', author_name: author_name, value: subject)
  end

  def update_group_description(conversation, update, author_name)
    desc = update[:desc]

    if desc.present?
      create_group_activity(conversation, 'description_changed', author_name: author_name)
    else
      create_group_activity(conversation, 'description_removed', author_name: author_name)
    end
  end

  def process_group_settings_changes(conversation, update, author_name)
    TRACKED_SETTINGS.each do |setting|
      next unless update.key?(setting.to_sym)

      value = update[setting.to_sym]
      setting_key = setting.underscore
      i18n_key = value ? "#{setting_key}_enabled" : "#{setting_key}_disabled"

      create_group_activity(conversation, i18n_key, author_name: author_name)
    end
  end

  def create_group_activity(conversation, action, **params)
    locale = inbox.account.locale || I18n.default_locale

    content = I18n.with_locale(locale) { I18n.t("conversations.activity.groups_update.#{action}", **params) }

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    )
  end

  def resolve_author_name(author_jid)
    return author_jid if author_jid.blank?

    lid = author_jid.split('@').first
    contact_inbox = inbox.contact_inboxes.find_by(source_id: lid)
    resolved_contact = contact_inbox&.contact

    resolved_contact&.name.presence || resolved_contact&.phone_number || lid
  end
end
