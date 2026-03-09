# frozen_string_literal: true

class EnableKanbanForExistingAccounts < ActiveRecord::Migration[7.0]
  def up
    # Enable kanban feature for all existing accounts
    Account.find_each do |account|
      next if account.feature_kanban?

      account.enable_features!('kanban')
    end
  end

  def down
    # Optionally disable kanban for accounts if rolling back
    # Leave empty if you want to preserve the enabled state
  end
end
