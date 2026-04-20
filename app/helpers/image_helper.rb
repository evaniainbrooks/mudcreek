module ImageHelper
  IMGPROXY_PRESETS = {
    card:           { width: 800,  height: 400, resizing_type: "fit",  format: "webp" },
    carousel_slide: { width: 1200, height: 480, resizing_type: "fit",  format: "webp", quality: 90 },
    carousel_thumb: { width: 152,  height: 152, resizing_type: "fill", format: "webp", quality: 85 },
    poster:         { width: 800,  height: 600, resizing_type: "fit",  format: "webp" },
    hero:           { width: 1920, height: 800, resizing_type: "fit",  format: "webp", quality: 90 },
    column:         { width: 600,  height: 800, resizing_type: "fit",  format: "webp" },
    logo:           { width: 96,   height: 96,  resizing_type: "fit",  format: "webp" }
  }.freeze

  # Returns a URL string for an attachment, optionally via imgproxy.
  def optimized_image_url(attachment, preset: :card)
    if imgproxy_enabled?
      Imgproxy.url_for(attachment, **IMGPROXY_PRESETS.fetch(preset))
    else
      url_for(attachment)
    end
  end

  # Returns an absolute URL suitable for OG/Twitter meta tags. Routes through
  # imgproxy when configured so crawlers never hit Active Storage directly.
  def absolute_optimized_image_url(attachment, preset: :card)
    url = optimized_image_url(attachment, preset:)
    url.start_with?("http") ? url : "#{request.base_url}#{url}"
  end

  # Returns an inline style string for a CSS background-image container.
  # height is in pixels. CSS properties (size/position/repeat) are always the same.
  def background_image_style(attachment, preset: :card, height: 200)
    url = optimized_image_url(attachment, preset:)
    "height: #{height}px; background-image: url('#{url}'); background-size: contain; background-position: center; background-repeat: no-repeat"
  end

  # Renders an image tag using imgproxy when configured, falling back to the
  # standard Active Storage URL when IMGPROXY_URL is not set (e.g. development).
  def optimized_image_tag(attachment, preset: :card, **html_options)
    if imgproxy_enabled?
      url = Imgproxy.url_for(attachment, **IMGPROXY_PRESETS.fetch(preset))
      image_tag url, **html_options
    else
      image_tag attachment, **html_options
    end
  end

  private

  def imgproxy_enabled?
    Imgproxy.config.endpoint.present?
  end
end
