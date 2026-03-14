module Admin::Listings::DeliveryMethodSetsHelper
  def render_delivery_method_sets_table(delivery_method_sets:)
    table = ::TableComponent.new(rows: delivery_method_sets)
    table.with_column("Name") { |s| inline_edit_cell(s, :name, s.name, url: admin_listings_delivery_method_set_path(s), scope: :listings_delivery_method_set) }
    table.with_column("Methods") do |s|
      count = s.deliveries.size
      link_to(admin_listings_delivery_method_set_path(s), class: "btn btn-sm btn-outline-secondary") do
        tag.i("", class: "bi bi-truck me-1") + "View #{count} #{"Method".pluralize(count)}"
      end
    end
    table.with_column("Actions", html_class: "text-end") do |s|
      count = s.deliveries.size
      button_to admin_listings_delivery_method_set_path(s), method: :delete,
          class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Delete \"#{s.name}\"? This will remove the set but not the delivery methods themselves." } } do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end

  def render_deliveries_table(deliveries:, delivery_method_set:)
    table = ::TableComponent.new(rows: deliveries)
    table.with_column("Name") { |d| d.delivery_method.name }
    table.with_column("Price") { |d| d.delivery_method.price_cents.zero? ? tag.span("Free", class: "badge text-bg-success") : humanized_money_with_symbol(d.delivery_method.price) }
    table.with_column("Address required") { |d| d.delivery_method.address_required? ? tag.span("Required", class: "badge text-bg-info") : tag.span("Not required", class: "badge text-bg-secondary") }
    table.with_column("Actions", html_class: "text-end") do |d|
      button_to admin_listings_delivery_method_set_delivery_method_path(delivery_method_set, d), method: :delete,
          class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Remove \"#{d.delivery_method.name}\" from this set?" } } do
        tag.i("", class: "bi bi-trash3") + " Remove"
      end
    end
    render(table)
  end
end
