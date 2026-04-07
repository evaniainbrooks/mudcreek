module LocationsHelper
  # Returns a hash of inline style strings for the fullscreen showroom view.
  def location_showroom_styles(location)
    accent  = Current.tenant.primary_color.presence || "#4f8ef7"
    accent2 = Current.tenant.secondary_color.presence || accent
    {
      bg: "background: #000;",
      top_bar: "padding: 0.5rem 2rem; display: grid; grid-template-columns: 1fr auto 1fr; " \
               "align-items: center; font-size: clamp(1.5rem, 3vw, 2.5rem); " \
               "color: rgba(255,255,255,0.6)",
      clock:   "color: #fff; font-weight: 600; letter-spacing: 0.05em; text-shadow: 0 0 12px #{accent}",
      center:  "flex: 1; display: flex; flex-direction: column; align-items: center; " \
               "justify-content: center; gap: 2rem; text-align: center; " \
               "padding: 0 1rem; margin-top: -3rem; overflow: hidden; min-height: 0",
      title:   "font-size: clamp(2rem, 5vw, 4rem); font-weight: bold; margin: 0; " \
               "text-shadow: 0 0 30px #{accent}, 0 0 60px #{accent}80, 0 2px 16px rgba(0,0,0,0.9)",
      msg:     "background: rgba(0,0,0,0.55); backdrop-filter: blur(2px); " \
               "border-radius: 1rem; padding: 1.25rem 1.5rem; " \
               "font-size: clamp(1rem, 2vw, 1.75rem); color: #fff; " \
               "text-align: left; justify-self: end; max-width: 30vw; " \
               "border-left: 3px solid #{accent}",
      qr_box:  "background: #fff; padding: 1rem; border-radius: 0.5rem; " \
               "display: inline-block; line-height: 0; " \
               "box-shadow: 0 4px 32px rgba(0,0,0,0.8), 0 0 0 4px #{accent}, 0 0 40px #{accent}80",
      events:  "background: rgba(0,0,0,0.55); backdrop-filter: blur(2px); " \
               "border-radius: 1rem; padding: 1.25rem 1.5rem; " \
               "font-size: clamp(0.85rem, 1.5vw, 1.25rem); color: #fff; " \
               "text-align: left; justify-self: start; max-width: 30vw; " \
               "border-left: 3px solid #{accent2}; " \
               "overflow: hidden; max-height: 50vh",
      prompt:  "font-size: clamp(1.25rem, 2.5vw, 2rem); color: #fff; font-weight: 500; " \
               "letter-spacing: 0.02em; margin: 0; padding: 0.75rem 2rem 2.5rem; " \
               "text-align: center; flex-shrink: 0; " \
               "text-shadow: 0 0 20px #{accent}, 0 2px 10px rgba(0,0,0,0.9); " \
               "animation: showroom-pulse 1.6s ease-in-out infinite"
    }
  end

  def render_check_ins_by_user_table(user_stats)
    table = TableComponent.new(rows: user_stats)
    table.with_column("User") do |stat|
      if stat[:user]
        safe_join([
          link_to(stat[:user].name, admin_user_path(stat[:user]), class: "text-decoration-none"),
          content_tag(:small, stat[:user].email_address, class: "text-muted d-block")
        ])
      elsif stat[:guest_name]
        safe_join([
          stat[:guest_name],
          content_tag(:small, "Guest", class: "text-muted d-block")
        ])
      else
        content_tag(:span, "Deleted user", class: "text-muted")
      end
    end
    table.with_column("Total", html_class: "text-center") { |stat| stat[:count] }
    table.with_column("Last Check-in") { |stat| stat[:last_at]&.strftime("%b %-d, %Y %H:%M") || "—" }
    render table
  end
end
