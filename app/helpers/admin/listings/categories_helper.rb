module Admin::Listings::CategoriesHelper
  def render_listings_categories_table(categories:)
    table = ::TableComponent.new(rows: categories)
    table.with_column("Name") { |cat| inline_edit_cell(cat, :name, cat.name, url: admin_listings_category_path(cat), scope: :listings_category) }
    table.with_value_column("Assignments") { it.category_assignments.size }
    table.with_column("Actions", html_class: "text-end") do |category|
      if category.category_assignments.none?
        button_to admin_listings_category_path(category), method: :delete, class: "btn btn-sm btn-outline-danger",
          form: { data: { turbo_confirm: "Delete category \"#{category.name}\"?" } } do
            content_tag(:i, "", class: "bi bi-trash3") + " Delete"
        end
      else
        content_tag(:span, "In use", class: "text-muted small fst-italic")
      end
    end
    render(table)
  end
end
