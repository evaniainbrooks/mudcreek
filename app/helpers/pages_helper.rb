module PagesHelper
  def set_page_meta_tags(page)
    meta_title = page.meta_title.presence || page.title
    meta_desc  = page.meta_description.presence
    og_image   = page.hero_image.attached? ? absolute_url_for(page.hero_image) : nil
    set_meta_tags title: meta_title,
      description: meta_desc,
      og: { title: meta_title, description: meta_desc, image: og_image },
      twitter: {
        card: (og_image ? "summary_large_image" : "summary"),
        title: meta_title, description: meta_desc, image: og_image
      }
  end

  # Returns the Bootstrap column class for the body column based on which sidebar images are present.
  def page_body_col_class(page)
    left  = page.left_column_image.attached?
    right = page.right_column_image.attached?
    (left && right) ? "col-4" : "col-8"
  end
end
