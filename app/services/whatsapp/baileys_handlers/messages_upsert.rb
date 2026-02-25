module Whatsapp::BaileysHandlers::MessagesUpsert
  include Whatsapp::BaileysHandlers::Helpers
  include Whatsapp::BaileysHandlers::Concerns::GroupContactMessageHandler
  include Whatsapp::BaileysHandlers::Concerns::IndividualContactMessageHandler
  include Whatsapp::BaileysHandlers::Concerns::GroupEventHelper
  include BaileysHelper

  MEMBERSHIP_REQUEST_STUB = 'GROUP_MEMBERSHIP_JOIN_APPROVAL_REQUEST_NON_ADMIN_ADD'.freeze
  ICON_CHANGE_STUB = 'GROUP_CHANGE_ICON'.freeze

  private

  def process_messages_upsert
    messages = processed_params[:data][:messages]
    messages.each do |message|
      @message = nil
      @contact_inbox = nil
      @contact = nil
      @raw_message = message

      next handle_message if incoming?

      # NOTE: Shared lock with Whatsapp::SendOnWhatsappService
      # Avoids race conditions when sending messages.
      with_baileys_channel_lock_on_outgoing_message(inbox.channel.id) { handle_message }
    end
  end

  def handle_message
    @lock_acquired = false

    return handle_message_stub if message_stub?

    return if ignore_message?
    return if find_message_by_source_id(raw_message_id)

    return handle_individual_contact_message if %w[lid user].include?(jid_type)
    return handle_group_contact_message if jid_type == 'group'
  end

  def message_stub?
    @raw_message[:messageStubType].present?
  end

  def handle_message_stub
    return unless jid_type == 'group'

    @lock_acquired = acquire_message_processing_lock
    return unless @lock_acquired

    case @raw_message[:messageStubType]
    when MEMBERSHIP_REQUEST_STUB
      handle_membership_request_stub
    when ICON_CHANGE_STUB
      handle_icon_change_stub
    end
  ensure
    clear_message_source_id_from_redis if @lock_acquired
  end

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
