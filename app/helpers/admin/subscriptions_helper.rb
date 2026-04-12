module Admin::SubscriptionsHelper
  STATUS_BADGE = {
    "active"    => "success",
    "lapsed"    => "warning",
    "cancelled" => "secondary"
  }.freeze

  def render_subscriptions_table(subscriptions)
    table = TableComponent.new(rows: subscriptions)

    table.with_column("User") { |s| link_to s.user.name, admin_subscription_path(s) }
    table.with_value_column("Plan") { it.subscription_plan.name }
    table.with_value_column("Renews") { it.renews_at }
    table.with_column("Status") { |s| subscription_status_badge(s) }

    render(table)
  end

  def subscription_status_badge(subscription)
    variant = STATUS_BADGE.fetch(subscription.status, "secondary")
    content_tag(:span, subscription.status.humanize, class: "badge bg-#{variant}")
  end
end
