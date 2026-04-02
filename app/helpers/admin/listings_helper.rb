module Admin::ListingsHelper
  def render_acquisitions_table(listing, acquisitions)
    table = ::TableComponent.new(rows: acquisitions)
    table.with_value_column("Date") { it.acquired_on }
    table.with_value_column("Qty") { it.quantity }
    table.with_value_column("Unit Price") { it.unit_price_cents ? it.unit_price : nil }
    table.with_value_column("Notes") { it.notes.presence }
    table.with_column("", html_class: "text-end") do |acq|
      button_to admin_listing_acquisition_path(listing, acq), method: :delete,
        class: "btn btn-outline-danger btn-sm",
        form: { data: { turbo_confirm: "Remove this acquisition? The listing quantity will be decremented." } } do
        content_tag(:i, "", class: "bi bi-trash")
      end
    end
    render(table)
  end

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
