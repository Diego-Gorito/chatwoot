# frozen_string_literal: true

class FazerAi::ReconcileSubscriptionService
  def perform
    return unless ChatwootApp.fazer_ai?

    # Kanban is now a standard feature without subscription limits
    # No reconciliation needed
  end
end
