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

  # Explicitly require and include webhook concern
  require_dependency Rails.root.join('fazer_ai/app/models/concerns/fazer_ai/webhook')
  Webhook.include(FazerAi::Webhook)
end
