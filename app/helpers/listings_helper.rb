module ListingsHelper
  BADGE_COLORS = %w[text-bg-primary text-bg-success text-bg-danger text-bg-warning text-bg-info text-bg-secondary text-bg-dark].freeze

  def set_listing_meta_tags(listing)
    description = listing.description.to_plain_text.truncate(200)
    og_image =
      if listing.images.attached?
        absolute_url_for(listing.images.first)
      elsif listing.lot&.listing_placeholder&.attached?
        absolute_url_for(listing.lot.listing_placeholder)
      elsif Current.tenant.listing_placeholder.attached?
        absolute_url_for(Current.tenant.listing_placeholder)
      end
    set_meta_tags title: listing.name,
      description: description,
      og: { title: listing.name, description: description, image: og_image },
      twitter: {
        card: (og_image ? "summary_large_image" : "summary"),
        title: listing.name, description: description, image: og_image
      }
  end

  def rental_booking_events_json(bookings)
    bookings.map { |b|
      { title: b.cart_item.user.email_address, start: b.start_at.iso8601, end: b.end_at.iso8601 }
    }.to_json
  end

  def public_listing_back_button(listing)
    if (auction = listing.auction_listing&.auction)
      link_to(admin_auction_path(auction), class: "btn btn-outline-secondary") do
        content_tag(:i, "", class: "bi bi-arrow-left me-1") + "Back to Auction"
      end
    else
      link_to(admin_listings_path, class: "btn btn-outline-secondary") do
        content_tag(:i, "", class: "bi bi-arrow-left me-1") + "Back to Listings"
      end
    end
  end

  def public_listing_path(listing)
    if listing.auction_listing
      auction_auction_listing_path(listing.auction_listing.auction, listing.auction_listing)
    else
      listing_path(listing)
    end
  end

  def badge_color_for(str)
    BADGE_COLORS[str.bytes.sum % BADGE_COLORS.size]
  end

  def lot_number_badge(lot, link: false)
    label = lot.number.presence || lot.name
    color = badge_color_for(lot.number.presence || lot.name)
    popover_content = lot_popover_content(lot)
    badge = content_tag(:span, label,
      class: "badge #{color}",
      style: "cursor: pointer; font-family: monospace; font-size: 0.75em; border: 2px solid rgba(0,0,0,0.25); letter-spacing: 0.05em;",
      data: {
        bs_toggle: "popover",
        bs_trigger: "hover focus",
        bs_html: "true",
        bs_content: popover_content
      })
    link ? link_to(badge, admin_lot_path(lot)) : badge
  end

  def listing_pricing_type_badge(listing, extra_css: nil)
    css = listing.firm? ? "text-bg-secondary" : "text-bg-success"
    content_tag(:span, listing.pricing_type.humanize, class: ["badge", css, extra_css].compact.join(" "))
  end

  def listing_type_badge(listing, extra_css: nil)
    css = listing.rental? ? "text-bg-info" : "text-bg-warning"
    content_tag(:span, listing.listing_type.humanize, class: ["badge", css, extra_css].compact.join(" "))
  end

  def listing_state_badge(listing, extra_css: nil)
    css = if listing.sold?       then "text-bg-danger"
    elsif listing.on_sale? then "text-bg-success"
    else "text-bg-secondary"
    end
    content_tag(:span, listing.state.humanize, class: ["badge", css, extra_css].compact.join(" "))
  end

  def listing_categories_badges(listing, css: nil)
    safe_join(listing.categories.map { |cat|
      content_tag(:span, class: "badge #{css || badge_color_for(cat.name)} me-1") do
        content_tag(:i, "", class: "bi bi-tag-fill me-1") + cat.name
      end
    })
  end

  def render_listings_table(listings:, q:)
    table = ::TableComponent.new(
      rows: listings,
      ransack_query: q,
      tbody_id: "admin-listings-tbody",
      tbody_data: { controller: "sortable", sortable_url_value: reorder_admin_listings_path }
    )
    add_listing_columns(table)
    render(table)
  end

  # Returns the column definitions shared between the full table and the row partial.
  def listing_columns
    add_listing_columns(::TableComponent.new(rows: [])).columns
  end

  private

  def lot_popover_content(lot)
    lines = []
    lines << content_tag(:div, lot.name, class: "fw-semibold")
    if lot.owner
      lines << content_tag(:div, lot.owner.name)
    end
    if (addr = lot.address)
      parts = [ addr.street_address, [ addr.city, addr.province ].compact_blank.join(", "), addr.postal_code, addr.country ].compact_blank
      lines << content_tag(:div, parts.join(" · "), class: "text-muted small mt-1") if parts.any?
    end
    safe_join(lines)
  end

  def add_listing_columns(table)
    table.with_column("", html_class: "text-center pe-0") { |l| l.auction_listing || l.rental? ? "".html_safe : tag.input(type: "checkbox", class: "form-check-input", value: l.id, data: { "bulk-select-target": "checkbox", action: "change->bulk-select#toggle" }) }
    table.with_column("", html_class: "text-center pe-0") { tag.span("", class: "bi bi-grip-vertical text-muted sortable-handle", style: "cursor: grab; font-size: 1.1rem") }
    table.with_column("Lot") { |l| l.lot ? lot_number_badge(l.lot) : "—" }
    table.with_column("Name", sort_attr: :name) { link_to(it.name, admin_listing_path(it)) }
    table.with_column("Type", sort_attr: :listing_type) { |l| listing_type_badge(l) }
    table.with_value_column("Price", sort_attr: :price_cents) { it.price }
    table.with_column("Pricing", sort_attr: :pricing_type) { |l| listing_pricing_type_badge(l) }
    table.with_column("State", sort_attr: :state) { |l| listing_state_badge(l) }
    table.with_value_column("Owner") { it.owner }
    table.with_column("Categories") { |l| listing_categories_badges(l) }
    table.with_value_column("Published", sort_attr: :published) { it.published }
    table.with_value_column("Created At", sort_attr: :created_at) { it.created_at }
    table.with_column("Actions", html_class: "text-end") do |listing|
      content_tag(:div, class: "btn-group") do
        safe_join([
          link_to("Edit", edit_admin_listing_path(listing), class: "btn btn-sm btn-outline-primary"),
          content_tag(:button, content_tag(:span, "Toggle dropdown", class: "visually-hidden"),
            type: "button",
            class: "btn btn-sm btn-outline-primary dropdown-toggle dropdown-toggle-split",
            data: { bs_toggle: "dropdown" },
            aria: { expanded: "false" }),
          content_tag(:ul, class: "dropdown-menu dropdown-menu-end") do
            content_tag(:li) do
              link_to("Delete", admin_listing_path(listing),
                class: "dropdown-item text-danger",
                data: { turbo_method: :delete, turbo_confirm: "Are you sure you want to delete this listing?" })
            end
          end
        ])
      end
    end
  end
end
