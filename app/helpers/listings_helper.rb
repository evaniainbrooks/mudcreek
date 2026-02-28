module ListingsHelper
  BADGE_COLORS = %w[text-bg-primary text-bg-success text-bg-danger text-bg-warning text-bg-info text-bg-secondary text-bg-dark].freeze

  def badge_color_for(str)
    BADGE_COLORS[str.bytes.sum % BADGE_COLORS.size]
  end

  def render_listings_table(listings:, q:)
    table = ::TableComponent.new(
      rows: listings,
      ransack_query: q,
      tbody_id: "admin-listings-tbody",
      tbody_data: { controller: "sortable", sortable_url_value: reorder_admin_listings_path }
    )
    table.with_column("", html_class: "text-center pe-0") { tag.span("", class: "bi bi-grip-vertical text-muted sortable-handle", style: "cursor: grab; font-size: 1.1rem") }
    table.with_column("Lot") { |l| l.lot ? content_tag(:span, l.lot.number, class: "badge #{badge_color_for(l.lot.name)}") : "—" }
    table.with_column("Name", sort_attr: :name) { link_to(it.name, admin_listing_path(it)) }
    table.with_value_column("Price", sort_attr: :price_cents) { it.price }
    table.with_column("Pricing", sort_attr: :pricing_type) do |listing|
      css = listing.firm? ? "text-bg-secondary" : "text-bg-success"
      content_tag(:span, listing.pricing_type.humanize, class: "badge #{css}")
    end
    table.with_value_column("Acquisition Price", sort_attr: :acquisition_price_cents) { it.acquisition_price }
    table.with_value_column("Owner") { it.owner }
    table.with_column("Categories") do |listing|
      safe_join(listing.categories.map { |cat| content_tag(:span, cat.name, class: "badge #{badge_color_for(cat.name)} me-1") })
    end
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
    render(table)
  end
end
