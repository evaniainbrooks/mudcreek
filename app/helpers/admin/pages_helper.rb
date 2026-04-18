module Admin::PagesHelper
  def render_pages_table(pages)
    table = TableComponent.new(rows: pages)

    table.with_column("Title") do |p|
      safe_join([
        link_to(p.title, edit_admin_page_path(p)),
        p.parent ? content_tag(:small, " ↳ #{p.parent.title}", class: "text-muted ms-1") : ""
      ])
    end
    table.with_column("Slug") { |p| content_tag(:code, p.slug) }
    table.with_value_column("Published") { it.published }
table.with_value_column("Position") { it.position }
    table.with_column("Actions", html_class: "text-end") do |p|
      safe_join([
        link_to("Edit", edit_admin_page_path(p), class: "btn btn-sm btn-outline-secondary"),
        link_to("+ Child", new_admin_page_path(parent_id: p.id), class: "btn btn-sm btn-outline-secondary ms-1"),
        link_to("Delete", admin_page_path(p),
          data: { turbo_method: :delete, turbo_confirm: "Delete \"#{p.title}\"?" },
          class: "btn btn-sm btn-outline-danger ms-1")
      ])
    end

    render(table)
  end
end
