# frozen_string_literal: true

# Dispatches Kanban events to external webhooks (n8n, Zapier, etc.)
# Similar to WebhookListener but for Kanban-specific events
class FazerAi::KanbanWebhookListener < BaseListener
  def kanban_task_created(event)
    task = event.data[:task]
    return unless task&.account&.kanban_feature_enabled?

    payload = build_payload(task, 'kanban_task_created')
    deliver_webhooks(payload, task.account)
  end

  def kanban_task_updated(event)
    task = event.data[:task]
    return unless task&.account&.kanban_feature_enabled?

    changed_attributes = event.data[:changed_attributes]
    payload = build_payload(task, 'kanban_task_updated', changed_attributes)
    deliver_webhooks(payload, task.account)
  end

  def kanban_task_completed(event)
    task = event.data[:task]
    return unless task&.account&.kanban_feature_enabled?

    changed_attributes = event.data[:changed_attributes]
    payload = build_payload(task, 'kanban_task_completed', changed_attributes)
    deliver_webhooks(payload, task.account)
  end

  def kanban_task_cancelled(event)
    task = event.data[:task]
    return unless task&.account&.kanban_feature_enabled?

    changed_attributes = event.data[:changed_attributes]
    payload = build_payload(task, 'kanban_task_cancelled', changed_attributes)
    deliver_webhooks(payload, task.account)
  end

  def kanban_task_deleted(event)
    task_data = event.data[:task]
    # task_data is a hash (snapshot) since the record was destroyed
    account_id = task_data.is_a?(Hash) ? task_data[:account_id] : task_data.account_id
    account = Account.find_by(id: account_id)
    return unless account&.kanban_feature_enabled?

    payload = if task_data.is_a?(Hash)
                task_data.merge(event: 'kanban_task_deleted', account: account.webhook_data)
              else
                build_payload(task_data, 'kanban_task_deleted')
              end

    deliver_webhooks(payload, account)
  end

  private

  def build_payload(task, event_name, changed_attributes = nil)
    payload = task.push_event_data.merge(
      event: event_name,
      account: task.account.webhook_data
    )
    payload[:changed_attributes] = changed_attributes if changed_attributes.present?
    payload
  end

  def deliver_webhooks(payload, account)
    account.webhooks.account_type.each do |webhook|
      next unless webhook.subscriptions.include?(payload[:event])

      WebhookJob.perform_later(webhook.url, payload)
    end
  end
end
