module Admin::AuctionRegistrationsHelper
  def render_auction_registrations_index_table(registrations:, q:)
    table = ::TableComponent.new(rows: registrations, tbody_id: "admin-auction-registrations-tbody", ransack_query: q)
    table.with_column("Auction") { |r| link_to(r.auction.name, admin_auction_path(r.auction)) }
    table.with_column("User") { |r| link_to(r.user.name, admin_user_path(r.user)) }
    table.with_column("Email") { |r| r.user.email_address }
    table.with_column("State", html_class: "text-center") { |r| auction_registration_state_badge(r) }
    table.with_value_column("Registered", sort_attr: :created_at) { it.created_at }
    render(table)
  end
end
