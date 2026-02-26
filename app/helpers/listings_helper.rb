module ListingsHelper
  def render_listings_table(listings:, q:)
    table = ::TableComponent.new(rows: listings, ransack_query: q)
    table.with_column("Name", sort_attr: :name) { link_to(it.name, admin_listing_path(it)) }
    table.with_value_column("Price", sort_attr: :price_cents) { it.price }
    table.with_value_column("Owner") { it.owner }
    table.with_value_column("Published", sort_attr: :published) { it.published }
    table.with_value_column("Created At", sort_attr: :created_at) { it.created_at }
    table.with_column("Actions", html_class: "text-end") do |listing|
      safe_join([
        link_to("Edit", edit_admin_listing_path(listing), class: "btn btn-sm btn-outline-primary me-1"),
        button_to("Delete", admin_listing_path(listing), method: :delete, class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Are you sure you want to delete this listing?" } })
      ])
    end
    render(table)
  end
end
