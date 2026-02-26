module ListingsHelper
  def render_listings_table(listings:, q:)
    table = ::TableComponent.new(rows: listings, ransack_query: q)
    table.with_column("Name", sort_attr: :name) { link_to(it.name, admin_listing_path(it)) }
    table.with_value_column("Price", sort_attr: :price_cents) { it.price }
    table.with_value_column("Acquisition Price", sort_attr: :acquisition_price_cents) { it.acquisition_price }
    table.with_value_column("Quantity", sort_attr: :quantity) { it.quantity }
    table.with_value_column("Owner") { it.owner }
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
