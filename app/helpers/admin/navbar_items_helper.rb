module Admin::NavbarItemsHelper
  def navbar_items_table(navbar_items)
    t = TableComponent.new(
      rows: navbar_items,
      row_data: ->(item) { { id: item.id } },
      tbody_data: { controller: "sortable", sortable_url_value: reorder_admin_navbar_items_path }
    )
    t.with_column("", html_class: "pe-0") do
      content_tag(:span, "", class: "bi bi-grip-vertical text-muted sortable-handle", style: "cursor: grab")
    end
    t.with_column("Icon") do |item|
      content_tag(:i, "", class: "bi #{item.icon} fs-5") if item.icon.present?
    end
    t.with_column("Title", html_class: "fw-semibold") { |item| item.title }
    t.with_column("Path", html_class: "text-muted small font-monospace") { |item| item.path }
    t.with_column("", html_class: "text-end") do |item|
      content_tag(:div, class: "d-flex gap-1 justify-content-end") do
        safe_join([
          link_to(content_tag(:i, "", class: "bi bi-pencil"), edit_admin_navbar_item_path(item), class: "btn btn-sm btn-outline-secondary"),
          link_to(content_tag(:i, "", class: "bi bi-trash"), admin_navbar_item_path(item), class: "btn btn-sm btn-outline-danger",
            data: { turbo_method: :delete, turbo_confirm: "Delete '#{item.title}'?" })
        ])
      end
    end
    render(t)
  end
end
