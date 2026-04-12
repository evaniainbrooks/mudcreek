module Subscriptions
  class AdvanceService
    def initialize(subscription)
      @subscription = subscription
    end

    def call
      case @subscription.subscription_plan.kind
      when "month_to_month"
        @subscription.update!(renews_at: @subscription.renews_at + 1.month, status: :active)
      end
    end
  end
end
