module LocationsHelper
  # Returns a hash of inline style strings for the fullscreen showroom view.
  def location_showroom_styles(location)
    accent = Current.tenant.primary_color.presence || "#4f8ef7"
    {
      bg: if location.background.attached? && !location.background.video?
            "background-image: url(#{url_for(location.background)}); background-size: cover; background-position: center;"
          else
            "background: #000;"
          end,
      top_bar: "padding: 1.5rem 2rem; display: grid; grid-template-columns: 1fr auto 1fr; " \
               "align-items: center; font-size: clamp(1.5rem, 3vw, 2.5rem); " \
               "color: rgba(255,255,255,0.6)",
      center:  "flex: 1; display: flex; flex-direction: column; align-items: center; " \
               "justify-content: center; gap: 2rem; text-align: center; " \
               "padding: 0 1rem; margin-top: -3rem",
      msg:     "background: rgba(0,0,0,0.55); backdrop-filter: blur(2px); " \
               "border-radius: 1rem; padding: 1.25rem 1.5rem; " \
               "font-size: clamp(1rem, 2vw, 1.75rem); color: #fff; " \
               "text-align: left; justify-self: end; max-width: 30vw",
      qr_box:  "background: #fff; padding: 1rem; border-radius: 0.5rem; " \
               "display: inline-block; line-height: 0; " \
               "box-shadow: 0 4px 32px rgba(0,0,0,0.8), 0 0 0 4px #{accent}",
      events:  "background: rgba(0,0,0,0.55); backdrop-filter: blur(2px); " \
               "border-radius: 1rem; padding: 1.25rem 1.5rem; " \
               "font-size: clamp(0.85rem, 1.5vw, 1.25rem); color: #fff; " \
               "text-align: left; justify-self: start; max-width: 30vw",
      prompt:  "font-size: clamp(1.25rem, 2.5vw, 2rem); color: #fff; font-weight: 500; " \
               "letter-spacing: 0.02em; margin: 0; text-shadow: 0 2px 10px rgba(0,0,0,0.9)"
    }
  end
end
