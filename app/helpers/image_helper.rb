module ImageHelper
  IMGPROXY_PRESETS = {
    card:           { width: 800,  height: 400, resizing_type: "fill", format: "webp" },
    carousel_slide: { width: 1200, height: 480, resizing_type: "fill", format: "webp" },
    carousel_thumb: { width: 152,  height: 152, resizing_type: "fill", format: "webp" },
    poster:         { width: 800,  height: 600, resizing_type: "fit",  format: "webp" }
  }.freeze

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
