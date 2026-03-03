module Admin::AuctionsHelper
  def render_auctions_table(auctions:)
    table = ::TableComponent.new(rows: auctions, tbody_id: "admin-auctions-tbody")
    table.with_column("Name") { |a| link_to(a.name, admin_auction_path(a)) }
    table.with_value_column("Starts At") { it.starts_at }
    table.with_value_column("Ends At") { it.ends_at }
    table.with_column("Extension") do |a|
      a.bidding_extension.positive? ? tag.span("#{a.bidding_extension}s") : tag.span("—", class: "text-muted")
    end
    table.with_column("Published", html_class: "text-center") { |a| a.published? ? tag.span("Yes", class: "badge text-bg-success") : tag.span("No", class: "badge text-bg-danger") }
    table.with_column("Reconciled", html_class: "text-center") { |a| a.reconciled? ? tag.span("Yes", class: "badge text-bg-success") : tag.span("No", class: "badge text-bg-danger") }
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
    table.with_value_column("User") { it.user }
    table.with_column("State", html_class: "text-center") { auction_registration_state_badge(it) }
    table.with_value_column("Registered") { it.created_at }
    table.with_value_column("Updated", sort_attr: :updated_at) { it.updated_at }
    render(table)
  end

  def auction_registration_state_badge(registration)
    case registration.state
    when "pending"  then tag.span("Pending",  class: "badge text-bg-warning")
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
    table.with_column("End Offset") do |al|
      stagger = auction.end_time_stagger_interval
      next tag.span("—", class: "text-muted") unless stagger.positive?
      seconds = (al.position - 1) * stagger
      tag.span("#{seconds}s", class: seconds.zero? ? "text-muted" : nil)
    end
    table.with_column("Starting Bid") { |al| auction_listing_money_inline_cell("starting_bid", al, auction) }
    table.with_column("Bid Increment") { |al| auction_listing_money_inline_cell("bid_increment", al, auction) }
    table.with_column("Reserve") { |al| auction_listing_money_inline_cell("reserve_price", al, auction) }
    table.with_column("Actions", html_class: "text-end") do |al|
      button_to("Remove", admin_auction_auction_listing_path(auction, al),
        method: :delete,
        class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Remove this listing from the auction?" } })
    end
    render(table)
  end

  private

  def auction_listing_money_inline_cell(field, al, auction)
    cents = al.send(:"#{field}_cents")
    value = cents ? "%.2f" % (cents / 100.0) : nil
    symbol = Money::Currency.new(Money.default_currency).symbol
    errors = al.errors[field]
    in_edit = errors.any?

    display = tag.span(value ? "#{symbol}#{value}" : "—",
      class: "inline-editable",
      hidden: in_edit,
      data: {
        "inline-edit-target" => "display",
        action: "click->inline-edit#edit",
        value: value.to_s
      })

    form = tag.div(hidden: !in_edit, data: { "inline-edit-target" => "form" }) do
      form_with(url: admin_auction_auction_listing_path(auction, al), method: :patch, scope: :auction_listing) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          tag.div(class: "input-group input-group-sm", style: "width: 130px") do
            tag.span(symbol, class: "input-group-text") +
            f.number_field(field, value: value,
              class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
              step: "0.01",
              min: "0",
              placeholder: "—",
              data: {
                "inline-edit-target" => "input",
                action: "keydown->inline-edit#keydown"
              }) +
            f.button(type: "submit", class: "btn btn-outline-primary") do
              tag.i("", class: "bi bi-check-lg")
            end
          end
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(al)}_#{field}", data: { controller: "inline-edit" }) do
      display + form
    end
  end
end
