# frozen_string_literal: true

# Extends Webhook model to support Kanban events
module FazerAiWebhook
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
    # Override ALLOWED_WEBHOOK_EVENTS to include Kanban events
    remove_const(:ALLOWED_WEBHOOK_EVENTS) if const_defined?(:ALLOWED_WEBHOOK_EVENTS, false)

    const_set(
      :ALLOWED_WEBHOOK_EVENTS,
      (%w[conversation_status_changed conversation_updated conversation_created contact_created contact_updated
          message_created message_incoming message_outgoing message_updated webwidget_triggered
          inbox_created inbox_updated conversation_typing_on conversation_typing_off provider_event_received] +
       KANBAN_WEBHOOK_EVENTS).freeze
    )
  end
end
