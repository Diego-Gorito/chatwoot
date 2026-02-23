json.payload do
  json.partial! 'api/v1/models/contact', formats: [:json], resource: @contact, with_contact_inboxes: true

  json.group_members do
    group_conversation = @contact.conversations.where(conversation_type: :group, status: %i[open pending]).order(created_at: :desc).first
    members = ConversationGroupMember.active.where(conversation: group_conversation).includes(:contact) if group_conversation
    json.array!(members || []) do |member|
      json.id member.id
      json.role member.role
      json.is_active member.is_active
      json.contact do
        json.id member.contact.id
        json.name member.contact.name
        json.phone_number member.contact.phone_number
        json.identifier member.contact.identifier
      end
    end
  end
end
