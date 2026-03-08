# frozen_string_literal: true

# Ensure core models pick up fazer_ai associations without impacting OSS license boundaries.
Rails.application.config.to_prepare do
  Account.include(FazerAi::Concerns::Account)
  AccountUser.include(FazerAi::Concerns::AccountUser)
  Inbox.include(FazerAi::Concerns::Inbox)
  User.include(FazerAi::Concerns::User)
  Conversation.include(FazerAi::Concerns::Conversation)
  Conversations::EventDataPresenter.prepend(FazerAi::Conversations::EventDataPresenter)
  AsyncDispatcher.prepend(FazerAi::AsyncDispatcher)
  AutomationRule.prepend(FazerAi::AutomationRule)

  # Extend Webhook ALLOWED_WEBHOOK_EVENTS to include Kanban events
  Webhook.class_eval do
    remove_const(:ALLOWED_WEBHOOK_EVENTS) if const_defined?(:ALLOWED_WEBHOOK_EVENTS, false)

    KANBAN_EVENTS = %w[
      kanban_task_created
      kanban_task_updated
      kanban_task_completed
      kanban_task_cancelled
      kanban_task_deleted
      kanban_task_overdue
    ].freeze

    ALLOWED_WEBHOOK_EVENTS = (%w[conversation_status_changed conversation_updated conversation_created contact_created
                                   contact_updated message_created message_incoming message_outgoing message_updated
                                   webwidget_triggered inbox_created inbox_updated conversation_typing_on
                                   conversation_typing_off provider_event_received] + KANBAN_EVENTS).freeze
  end
end
