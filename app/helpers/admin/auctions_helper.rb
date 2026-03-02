module Admin::AuctionsHelper
  def render_auctions_table(auctions:)
    table = ::TableComponent.new(rows: auctions, tbody_id: "admin-auctions-tbody")
    table.with_column("Name") { |a| link_to(a.name, admin_auction_path(a)) }
    table.with_value_column("Starts At") { it.starts_at }
    table.with_value_column("Ends At") { it.ends_at }
    table.with_column("Published", html_class: "text-center") { |a| a.published? ? tag.span("Yes", class: "badge text-bg-success") : tag.span("No", class: "badge text-bg-secondary") }
    table.with_column("Reconciled", html_class: "text-center") { |a| a.reconciled? ? tag.span("Yes", class: "badge text-bg-info") : tag.span("No", class: "badge text-bg-secondary") }
    table.with_column("Listings", html_class: "text-center") { |a| a.listings.size }
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

  def render_auction_listings_table(auction_listings:, auction:)
    table = ::TableComponent.new(
      rows: auction_listings,
      tbody_data: { controller: "sortable", sortable_url_value: reorder_admin_auction_auction_listings_path(auction) }
    )
    table.with_column("", html_class: "text-center pe-0") { tag.span("", class: "bi bi-grip-vertical text-muted sortable-handle", style: "cursor: grab; font-size: 1.1rem") }
    table.with_column("Name") { |al| link_to(al.listing.name, admin_listing_path(al.listing)) }
    table.with_column("State") { |al| listing_state_badge(al.listing) }
    table.with_column("Actions", html_class: "text-end") do |al|
      button_to("Remove", admin_auction_auction_listing_path(auction, al),
        method: :delete,
        class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Remove this listing from the auction?" } })
    end
    render(table)
  end
end
