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
  kanban_events = %w[
    kanban_task_created
    kanban_task_updated
    kanban_task_completed
    kanban_task_cancelled
    kanban_task_deleted
    kanban_task_overdue
  ].freeze

  # Save original events, remove constant, then set new one with Kanban events added
  original_events = Webhook::ALLOWED_WEBHOOK_EVENTS.dup
  Webhook.class_eval do
    silence_warnings do
      remove_const(:ALLOWED_WEBHOOK_EVENTS)
      const_set(:ALLOWED_WEBHOOK_EVENTS, (original_events + kanban_events).freeze)
    end
  end
end
