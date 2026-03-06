module Admin::ListingsHelper
  def render_listing_offers_table(offers)
    table = ::TableComponent.new(rows: offers)
    table.with_value_column("Buyer") { it.user }
    table.with_value_column("Amount", html_class: "text-end") { it.amount }
    table.with_column("State") { |o| offer_state_badge(o) }
    table.with_value_column("Message") { it.message.presence }
    table.with_value_column("Submitted") { it.created_at }
    table.with_column("", html_class: "text-end") { |o| link_to("View", admin_offer_path(o), class: "btn btn-sm btn-outline-primary") }
    render(table)
  end
end
