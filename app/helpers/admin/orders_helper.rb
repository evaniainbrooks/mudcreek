module Admin::OrdersHelper
  def render_orders_table(orders:, q:)
    table = ::TableComponent.new(rows: orders, ransack_query: q, tbody_id: "admin-orders-tbody")
    table.with_column("Order", sort_attr: :number) { |o| link_to(o.number, admin_order_path(o), class: "fw-semibold") }
    table.with_value_column("Buyer") { it.user }
    table.with_column("Items", html_class: "text-center") { |o| o.order_items.size }
    table.with_column("Status", sort_attr: :status) { |o| order_status_badge(o) }
    table.with_value_column("Total", sort_attr: :total_cents) { it.total }
    table.with_value_column("Date", sort_attr: :created_at) { it.created_at }
    render(table)
  end
end
