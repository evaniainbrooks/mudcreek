class GenerateSubscriptionInvoicesJob < ApplicationJob
  queue_as :default

  def perform
    Tenant.find_each do |tenant|
      Current.tenant = tenant

      Subscription.due.includes(:user, :subscription_plan).find_each do |subscription|
        next if Invoice.where(subscription: subscription, status: :unpaid).exists?

        plan = subscription.subscription_plan
        invoice = Invoice.create!(
          user: subscription.user,
          subscription: subscription,
          total_cents: plan.amount_cents
        )

        invoice.invoice_items.create!(
          name: plan.name,
          amount_cents: plan.amount_cents
        )

        if subscription.user.default_square_card_id.present?
          ChargeInvoiceJob.perform_later(invoice.id)
        else
          SubscriptionMailer.invoice_generated(invoice).deliver_later
        end
      end
    ensure
      Current.tenant = nil
    end
  end
end
