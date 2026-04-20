module Subscriptions
  class AdvanceService
    def initialize(subscription)
      @subscription = subscription
    end

    def call
      case @subscription.subscription_plan.subscription_type
      when "month_to_month"
        @subscription.update!(renews_at: @subscription.renews_at + 1.month, status: :active)
      when "monthly"
        @subscription.update!(status: :active)
      when "annual"
        @subscription.update!(renews_at: @subscription.renews_at + 1.year,   status: :active)
      when "semi_annual"
        @subscription.update!(renews_at: @subscription.renews_at + 6.months, status: :active)
      when "one_time"
        @subscription.update!(renews_at: 100.years.from_now.to_date, status: :active)
      end
    end
  end
end
