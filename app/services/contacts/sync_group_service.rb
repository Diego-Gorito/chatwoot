class Contacts::SyncGroupService
  pattr_initialize [:contact!]

  def perform
    validate_group_contact!
    @channel = find_baileys_channel!

    group_metadata = @channel.provider_service.group_metadata(contact.identifier)
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.metadata_unavailable') if group_metadata.blank?

    update_contact_from_metadata(group_metadata)
    sync_group_participants(group_metadata)

    contact.reload
    dispatch_group_synced_event
    contact
  end

  private

  def validate_group_contact!
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.not_a_group') if contact.group_type_individual?
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_identifier') if contact.identifier.blank?
  end

  def find_baileys_channel!
    @contact_inbox = contact.contact_inboxes.find do |ci|
      ci.inbox.channel_type == 'Channel::Whatsapp' && ci.inbox.channel&.provider == 'baileys'
    end
    raise ActionController::BadRequest, I18n.t('contacts.sync_group.no_supported_inbox') if @contact_inbox.blank?

    @contact_inbox.inbox.channel
  end

  def inbox
    @contact_inbox.inbox
  end

  def update_contact_from_metadata(group_metadata)
    update_params = {
      name: (group_metadata[:subject] if name_changed?(group_metadata)),
      additional_attributes: (updated_additional_attributes(group_metadata) if additional_attributes_changed?(group_metadata))
    }.compact

    contact.update!(update_params) if update_params.present?
  end

  def name_changed?(group_metadata)
    group_metadata[:subject].present? && contact.name != group_metadata[:subject]
  end

  def updated_additional_attributes(group_metadata)
    (contact.additional_attributes || {}).merge(
      'description' => group_metadata[:desc].presence,
      'owner' => group_metadata[:owner],
      'owner_pn' => group_metadata[:ownerPn].presence
    )
  end

  def additional_attributes_changed?(group_metadata)
    updated_additional_attributes(group_metadata) != contact.additional_attributes
  end

  def dispatch_group_synced_event
    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONTACT_GROUP_SYNCED,
      Time.zone.now,
      contact: contact
    )
  end

  def sync_group_participants(group_metadata)
    return if group_metadata[:participants].blank?

    conversations = @contact_inbox.conversations.where(status: :open)
    return if conversations.blank?

    participants = group_metadata[:participants]

    conversations.find_each do |conversation|
      sync_participants_for_conversation(conversation, participants)
    end
  end

  def sync_participants_for_conversation(conversation, participants)
    new_contact_ids = participants.filter_map do |participant|
      participant_contact = find_or_create_participant_contact(participant)
      next if participant_contact.blank?

      role = participant[:admin].in?(%w[admin superadmin]) ? :admin : :member
      member = ConversationGroupMember.find_or_initialize_by(conversation: conversation, contact: participant_contact)
      member.assign_attributes(role: role, is_active: true)
      member.save! if member.changed?
      participant_contact.id
    end

    conversation.group_members.active.where.not(contact_id: new_contact_ids).find_each do |member|
      member.update!(is_active: false)
    end
  end

  def find_or_create_participant_contact(participant)
    lid = extract_lid_from_participant(participant)
    phone = extract_phone_from_participant(participant)
    identifier = lid ? "#{lid}@lid" : nil
    source_id = lid || phone

    return nil if source_id.blank?

    consolidate_contact(phone, lid, identifier)

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: {
        name: phone,
        phone_number: ("+#{phone}" if phone),
        identifier: identifier
      }
    ).perform

    update_contact_whatsapp_info(contact_inbox.contact, phone, identifier)
  end

  def consolidate_contact(phone, lid, identifier)
    return unless phone || lid

    Whatsapp::ContactInboxConsolidationService.new(
      inbox: inbox, phone: phone, lid: lid, identifier: identifier
    ).perform
  end

  def update_contact_whatsapp_info(participant_contact, phone, identifier)
    update_params = {
      phone_number: ("+#{phone}" if phone && participant_contact.phone_number.blank?),
      identifier: (identifier if identifier && participant_contact.identifier.blank?)
    }.compact

    participant_contact.update!(update_params) if update_params.present?
    participant_contact
  end

  def extract_lid_from_participant(participant)
    return nil if participant[:id].blank?

    jid_part, jid_suffix = participant[:id].split('@')
    jid_part if jid_suffix == 'lid' && jid_part.match?(/^\d+$/)
  end

  def extract_phone_from_participant(participant)
    return nil if participant[:phoneNumber].blank?

    phone = participant[:phoneNumber].split('@').first
    phone if phone.match?(/^\d+$/)
  end
end
