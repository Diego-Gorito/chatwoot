module Whatsapp::BaileysHandlers::Concerns::GroupStubMessageHandler
  MEMBERSHIP_REQUEST_STUB = 'GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD'.freeze
  ICON_CHANGE_STUB = 'GROUP_CHANGE_ICON'.freeze

  private

  def handle_membership_request_stub
    stub_params = @raw_message[:messageStubParameters]
    return if stub_params.blank?

    action = parse_membership_request_action(stub_params)
    return unless action

    group_jid = @raw_message[:key][:remoteJid]
    contact_name = resolve_membership_request_contact_name(stub_params)

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_by_jid(group_jid)
      conversation = find_or_create_group_conversation(group_contact_inbox)
      create_group_activity(conversation, action, contact_name: contact_name)
    end
  end

  def handle_icon_change_stub
    group_jid = @raw_message[:key][:remoteJid]
    participant_jid = @raw_message[:key][:participant]

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_by_jid(group_jid)
      conversation = find_or_create_group_conversation(group_contact_inbox)
      author_name = resolve_author_name(participant_jid)
      create_group_activity(conversation, 'icon_changed', author_name: author_name)
    end
  end

  def parse_membership_request_action(stub_params)
    if stub_params.include?('created')
      'membership_request_created'
    elsif stub_params.include?('revoked')
      'membership_request_revoked'
    end
  end

  def resolve_membership_request_contact_name(stub_params)
    participant_data = JSON.parse(stub_params.first)
    lid = extract_jid_user(participant_data['lid'])
    phone = extract_jid_user(participant_data['pn'])

    find_contact_display_name(lid, phone) || format_fallback_name(lid, phone)
  rescue JSON::ParserError
    extract_jid_user(@raw_message[:key][:participant])
  end

  def extract_jid_user(jid)
    jid&.split('@')&.first
  end

  def find_contact_display_name(lid, phone)
    source_id = lid || phone
    return unless source_id

    contact = inbox.contact_inboxes.find_by(source_id: source_id)&.contact
    return unless contact

    contact.name.presence || contact.phone_number
  end

  def format_fallback_name(lid, phone)
    phone ? "+#{phone}" : lid
  end
end
