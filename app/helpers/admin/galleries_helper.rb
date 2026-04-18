module Admin::GalleriesHelper
  def render_galleries_table(galleries)
    table = TableComponent.new(rows: galleries)

    table.with_column("Name") do |g|
      link_to g.name, edit_admin_gallery_path(g), class: "fw-semibold text-decoration-none text-body"
    end
    table.with_column("Description") do |g|
      content_tag(:span, g.description.to_plain_text.truncate(120), class: "text-muted") if g.description.present?
    end
    table.with_column("Listing") do |g|
      if g.listing
        link_to g.listing.name, admin_listing_path(g.listing), class: "text-decoration-none"
      else
        content_tag(:span, "—", class: "text-muted")
      end
    end
    table.with_column("Media", html_class: "text-center") do |g|
      count = g.photos.size + g.videos.size + g.documents.size
      content_tag(:span, count, class: "badge bg-secondary")
    end
    table.with_column("", html_class: "text-end") do |g|
      link_to admin_gallery_path(g), class: "btn btn-sm btn-outline-danger",
              data: { turbo_method: :delete, turbo_confirm: "Delete '#{g.name}'?" } do
        content_tag(:i, "", class: "bi bi-trash")
      end
    end

    render(table)
  end
end
