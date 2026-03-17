module Admin::LotsHelper
  LOT_STATE_BADGE_CLASS = {
    "submitted" => "text-bg-secondary",
    "received"  => "text-bg-info",
    "auctioned" => "text-bg-primary",
    "settled"   => "text-bg-warning",
    "paid"      => "text-bg-success"
  }.freeze

  def lot_state_badge_class(lot)
    LOT_STATE_BADGE_CLASS.fetch(lot.state.to_s, "text-bg-secondary")
  end

  def render_lots_table(lots:, users: nil)
    table = ::TableComponent.new(rows: lots)
    table.with_column("Name") do |lot|
      link_to lot.name, admin_lot_path(lot), class: "fw-semibold text-decoration-none"
    end
    table.with_column("Number") { |lot| lot_number_badge(lot, link: true) }
    table.with_value_column("Owner") { it.owner }
    table.with_column("State") do |lot|
      tag.span(lot.state.to_s.humanize, class: "badge #{lot_state_badge_class(lot)}")
    end
    table.with_column("Commission") do |lot|
      lot.commission_rate ? "#{lot.commission_rate}%" : tag.span("—", class: "text-muted")
    end
    table.with_column("Listings") do |lot|
      tag.span(lot.listings.size, class: "badge text-bg-secondary")
    end
    table.with_column("Settlement", html_class: "text-center") do |lot|
      lot.settlement ? tag.i("", class: "bi bi-check-circle-fill text-success") : tag.span("—", class: "text-muted")
    end
    table.with_column("Actions", html_class: "text-end") do |lot|
      button_to(admin_lot_path(lot), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Delete lot \"#{lot.name}\"? Listings will be unassigned." } }) do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
