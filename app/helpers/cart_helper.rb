module CartHelper
  def cart_badge(count)
    content_tag(
      :span,
      count,
      class: "position-absolute top-0 start-50 translate-middle badge rounded-pill bg-danger p-1",
      style: "min-width: 1.25rem; line-height: 1rem; font-size: 0.65rem",
    )
  end
end
