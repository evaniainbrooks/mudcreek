module Admin::Listings::PropertySetsHelper
  def render_property_sets_table(property_sets:)
    table = ::TableComponent.new(rows: property_sets)
    table.with_column("Name") { |ps| inline_edit_cell(ps, :name, ps.name, url: admin_listings_property_set_path(ps), scope: :listings_property_set) }
    table.with_column("Properties") do |ps|
      count = ps.properties.size
      link_to(admin_listings_property_set_path(ps), class: "btn btn-sm btn-outline-secondary") do
        tag.i("", class: "bi bi-list-columns me-1") + "View #{count} #{"Property".pluralize(count)}"
      end
    end
    table.with_column("Actions", html_class: "text-end") do |ps|
      count = ps.properties.size
      button_to admin_listings_property_set_path(ps), method: :delete,
          class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Delete \"#{ps.name}\"? This will also remove all #{count} #{"property".pluralize(count)}." } } do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end

  def render_properties_table(properties:, property_set:)
    table = ::TableComponent.new(
      rows: properties,
      tbody_data: {
        controller: "sortable",
        sortable_url_value: reorder_admin_listings_property_sets_path
      }
    )
    table.with_column("", html_class: "text-center pe-0") { tag.span("", class: "bi bi-grip-vertical text-muted sortable-handle", style: "cursor: grab; font-size: 1.1rem") }
    table.with_column("Icon") do |p|
      safe_join([
        inline_edit_cell(p, :icon, p.icon, url: admin_listings_property_set_property_path(property_set, p), scope: :listings_property),
        (tag.i("", class: "bi #{p.icon} ms-2 text-muted") if p.icon.present?)
      ].compact)
    end
    table.with_column("Name") { |p| inline_edit_cell(p, :name, p.name, url: admin_listings_property_set_property_path(property_set, p), scope: :listings_property) }
    table.with_column("Example Value") { |p| inline_edit_cell(p, :value, p.value, url: admin_listings_property_set_property_path(property_set, p), scope: :listings_property) }
    table.with_column("Actions", html_class: "text-end") do |p|
      button_to admin_listings_property_set_property_path(property_set, p), method: :delete,
          class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Remove \"#{p.name}\"?" } } do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
