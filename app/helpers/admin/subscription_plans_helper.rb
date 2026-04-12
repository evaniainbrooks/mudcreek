module Admin::SubscriptionPlansHelper
  def render_subscription_plans_table(subscription_plans)
    table = TableComponent.new(rows: subscription_plans)

    table.with_column("Name") { |p| link_to p.name, admin_subscription_plan_path(p) }
    table.with_value_column("Kind") { it.kind.humanize }
    table.with_value_column("Amount") { humanized_money_with_symbol(it.amount) }
    table.with_value_column("Subscriptions") { it.subscriptions.size }
    table.with_column("Actions", html_class: "text-end") do |p|
      link_to "Delete", admin_subscription_plan_path(p),
        data: { turbo_method: :delete, turbo_confirm: "Delete \"#{p.name}\"?" },
        class: "btn btn-sm btn-outline-danger"
    end

    render(table)
  end
end
