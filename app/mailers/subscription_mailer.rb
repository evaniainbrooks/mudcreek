class SubscriptionMailer < ApplicationMailer
  def invoice_generated(invoice)
    @invoice = invoice
    @user = invoice.user
    @subscription = invoice.subscription
    @plan = @subscription.subscription_plan

    mail(
      to: @user.email_address,
      subject: "Your subscription invoice — #{@plan.name}"
    )
  end
end
