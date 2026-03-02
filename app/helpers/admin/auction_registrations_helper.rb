module Admin::AuctionRegistrationsHelper
  def render_auction_registrations_index_table(registrations:, q:)
    table = ::TableComponent.new(rows: registrations, tbody_id: "admin-auction-registrations-tbody", ransack_query: q)
    add_auction_registration_columns(table)
    render(table)
  end

  def auction_registration_columns
    add_auction_registration_columns(::TableComponent.new(rows: [])).columns
  end

  private

  def add_auction_registration_columns(table)
    table.with_column("Auction") { |r| link_to(r.auction.name, admin_auction_path(r.auction)) }
    table.with_value_column("User") { it.user }
    table.with_column("State", html_class: "text-center") { |r| auction_registration_state_badge(r) }
    table.with_value_column("Registered", sort_attr: :created_at) { it.created_at }
    table.with_value_column("Updated", sort_attr: :updated_at) { it.updated_at }
  end
end
