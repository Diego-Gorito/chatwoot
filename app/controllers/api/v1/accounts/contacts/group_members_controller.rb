class Api::V1::Accounts::Contacts::GroupMembersController < Api::V1::Accounts::Contacts::BaseController
  def index
    @group_members = ConversationGroupMember.active
                                            .where(conversation: @contact.conversations)
                                            .includes(:contact, :conversation)
  end
end
