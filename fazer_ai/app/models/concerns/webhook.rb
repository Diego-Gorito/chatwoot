# frozen_string_literal: true

module FazerAi::Webhook
  extend ActiveSupport::Concern

  KANBAN_WEBHOOK_EVENTS = %w[
    kanban_task_created
    kanban_task_updated
    kanban_task_completed
    kanban_task_cancelled
    kanban_task_deleted
    kanban_task_overdue
  ].freeze

  included do
    # Extend ALLOWED_WEBHOOK_EVENTS to include Kanban events
    const_set(:ALLOWED_WEBHOOK_EVENTS, (const_get(:ALLOWED_WEBHOOK_EVENTS) + KANBAN_WEBHOOK_EVENTS).freeze)
  end
end
