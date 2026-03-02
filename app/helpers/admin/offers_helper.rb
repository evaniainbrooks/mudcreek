module Admin::OffersHelper
  STATE_BADGE = {
    "pending"  => "text-bg-warning",
    "accepted" => "text-bg-success",
    "declined" => "text-bg-secondary"
  }.freeze

  def offer_state_badge(offer)
    css = STATE_BADGE.fetch(offer.state, "text-bg-secondary")
    content_tag(:span, offer.state.humanize, class: "badge #{css}")
  end

  def render_offers_table(offers:, q:)
    table = ::TableComponent.new(rows: offers, ransack_query: q)
    table.with_column("Listing") { |o| link_to(o.listing.name, admin_listing_path(o.listing)) }
    table.with_value_column("Buyer") { it.user }
    table.with_value_column("Amount", sort_attr: :amount_cents) { it.amount }
    table.with_column("State", sort_attr: :state) { |o| offer_state_badge(o) }
    table.with_value_column("Message") { it.message.presence }
    table.with_value_column("Submitted", sort_attr: :created_at) { it.created_at }
    table.with_column("", html_class: "text-end") { |o| link_to("View", admin_offer_path(o), class: "btn btn-sm btn-outline-primary") }
    render(table)
  end
end
