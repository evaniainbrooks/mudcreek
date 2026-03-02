module Admin::AuctionsHelper
  def render_auctions_table(auctions:)
    table = ::TableComponent.new(rows: auctions, tbody_id: "admin-auctions-tbody")
    table.with_column("Name") { |a| link_to(a.name, admin_auction_path(a)) }
    table.with_value_column("Starts At") { it.starts_at }
    table.with_value_column("Ends At") { it.ends_at }
    table.with_column("Published", html_class: "text-center") { |a| a.published? ? tag.span("Yes", class: "badge text-bg-success") : tag.span("No", class: "badge text-bg-secondary") }
    table.with_column("Reconciled", html_class: "text-center") { |a| a.reconciled? ? tag.span("Yes", class: "badge text-bg-info") : tag.span("No", class: "badge text-bg-secondary") }
    table.with_column("Listings", html_class: "text-center") { |a| a.listings.size }
    table.with_column("Lots") do |a|
      lots = a.listings.filter_map(&:lot).uniq(&:id).sort_by(&:number)
      lots.any? ? safe_join(lots.map { |l| lot_number_badge(l) }, " ") : tag.span("—", class: "text-muted")
    end
    table.with_column("Location") do |a|
      a.address ? a.address.city.presence || a.address.street_address.presence || "—" : tag.span("—", class: "text-muted")
    end
    table.with_column("Actions", html_class: "text-end") do |auction|
      content_tag(:div, class: "btn-group") do
        safe_join([
          link_to("Edit", edit_admin_auction_path(auction), class: "btn btn-sm btn-outline-primary"),
          content_tag(:button, content_tag(:span, "Toggle dropdown", class: "visually-hidden"),
            type: "button",
            class: "btn btn-sm btn-outline-primary dropdown-toggle dropdown-toggle-split",
            data: { bs_toggle: "dropdown" },
            aria: { expanded: "false" }),
          content_tag(:ul, class: "dropdown-menu dropdown-menu-end") do
            content_tag(:li) do
              link_to("Delete", admin_auction_path(auction),
                class: "dropdown-item text-danger",
                data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this auction?" })
            end
          end
        ])
      end
    end
    render(table)
  end

  def render_auction_registrations_table(registrations:)
    table = ::TableComponent.new(rows: registrations)
    table.with_column("User") { |r| link_to r.user.name, admin_user_path(r.user) }
    table.with_column("Email") { |r| r.user.email_address }
    table.with_column("State", html_class: "text-center") { |r| auction_registration_state_badge(r) }
    table.with_value_column("Registered") { it.created_at }
    render(table)
  end

  def auction_registration_state_badge(registration)
    case registration.state
    when "pending"  then tag.span("Pending",  class: "badge text-bg-secondary")
    when "approved" then tag.span("Approved", class: "badge text-bg-success")
    when "rejected" then tag.span("Rejected", class: "badge text-bg-danger")
    end
  end

  def render_auction_listings_table(auction_listings:, auction:)
    table = ::TableComponent.new(
      rows: auction_listings,
      tbody_id: "auction-listings-tbody",
      tbody_data: { controller: "sortable", sortable_url_value: reorder_admin_auction_auction_listings_path(auction) }
    )
    table.with_column("", html_class: "text-center pe-0") { tag.span("", class: "bi bi-grip-vertical text-muted sortable-handle", style: "cursor: grab; font-size: 1.1rem") }
    table.with_column("Name") { |al| link_to(al.listing.name, admin_listing_path(al.listing)) }
    table.with_column("State") { |al| listing_state_badge(al.listing) }
    table.with_column("Starting Bid") { |al| auction_listing_money_input("starting_bid", al) }
    table.with_column("Bid Increment") { |al| auction_listing_money_input("bid_increment", al) }
    table.with_column("Reserve") { |al| auction_listing_money_input("reserve_price", al) }
    table.with_column("Actions", html_class: "text-end") do |al|
      safe_join([
        form_with(url: admin_auction_auction_listing_path(auction, al), method: :patch,
          id: "al-form-#{al.id}", class: "d-inline") { |f| f.button("Save", class: "btn btn-sm btn-outline-success me-1") },
        button_to("Remove", admin_auction_auction_listing_path(auction, al),
          method: :delete,
          class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Remove this listing from the auction?" } })
      ])
    end
    render(table)
  end

  private

  def auction_listing_money_input(field, al)
    cents = al.send(:"#{field}_cents")
    value = cents ? "%.2f" % (cents / 100.0) : nil
    symbol = Money::Currency.new(Money.default_currency).symbol
    content_tag(:div, class: "input-group input-group-sm", style: "width: 120px") do
      safe_join([
        content_tag(:span, symbol, class: "input-group-text"),
        number_field_tag("auction_listing[#{field}]", value,
          form: "al-form-#{al.id}",
          class: "form-control form-control-sm",
          step: "0.01",
          min: "0",
          placeholder: "—")
      ])
    end
  end
end
