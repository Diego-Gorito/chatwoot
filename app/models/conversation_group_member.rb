# == Schema Information
#
# Table name: conversation_group_members
#
#  id              :bigint           not null, primary key
#  is_active       :boolean          default(TRUE), not null
#  role            :integer          default("member"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  contact_id      :bigint           not null
#  conversation_id :bigint           not null
#
# Indexes
#
#  idx_on_conversation_id_contact_id_4eee54a959         (conversation_id,contact_id) UNIQUE
#  idx_on_conversation_id_is_active_7d6f2cc76a          (conversation_id,is_active)
#  index_conversation_group_members_on_contact_id       (contact_id)
#  index_conversation_group_members_on_conversation_id  (conversation_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#

class ConversationGroupMember < ApplicationRecord
  belongs_to :conversation
  belongs_to :contact

  enum role: { member: 0, admin: 1 }

  validates :conversation_id, uniqueness: { scope: :contact_id }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
end
