require 'rails_helper'

RSpec.describe ConversationGroupMember do
  describe 'associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
  end

  describe 'validations' do
    it 'prevents duplicate contact in same conversation' do
      existing_member = create(:conversation_group_member)

      duplicate_member = build(
        :conversation_group_member,
        conversation: existing_member.conversation,
        contact: existing_member.contact
      )

      expect(duplicate_member).not_to be_valid
      expect(duplicate_member.errors[:conversation_id]).to include('has already been taken')
    end

    it 'allows same contact in different conversations' do
      existing_member = create(:conversation_group_member)
      new_conversation = create(:conversation, account: existing_member.conversation.account)

      new_member = build(
        :conversation_group_member,
        conversation: new_conversation,
        contact: existing_member.contact
      )

      expect(new_member).to be_valid
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active members' do
        active_member = create(:conversation_group_member, is_active: true)
        create(:conversation_group_member, :inactive)

        expect(described_class.active).to eq([active_member])
      end
    end

    describe '.inactive' do
      it 'returns only inactive members' do
        create(:conversation_group_member, is_active: true)
        inactive_member = create(:conversation_group_member, :inactive)

        expect(described_class.inactive).to eq([inactive_member])
      end
    end
  end

  describe 'default values' do
    it 'defaults to member role' do
      member = create(:conversation_group_member)

      expect(member.role).to eq('member')
    end

    it 'defaults to active status' do
      member = create(:conversation_group_member)

      expect(member.is_active).to be(true)
    end
  end
end
