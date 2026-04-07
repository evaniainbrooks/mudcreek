module ApplicationHelper
  FLASH_CLASS_MAP = {
    "notice"  => "success",
    "alert"   => "danger",
    "warning" => "warning",
    "info"    => "info"
  }.freeze

  DOCUMENT_ICON_MAP = {
    "application/pdf"                                                             => "bi-file-pdf",
    "application/msword"                                                          => "bi-file-word",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"     => "bi-file-word",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"           => "bi-file-excel"
  }.freeze

  def inline_edit_cell(record, field, value, url:, scope:)
    errors = record.errors[field]
    in_edit = errors.any?

    display = tag.span(value.presence || "—",
      class: "inline-editable",
      hidden: in_edit,
      data: {
        "inline-edit-target" => "display",
        action: "click->inline-edit#edit",
        value: value.to_s
      })

    form = tag.div(hidden: !in_edit, data: { "inline-edit-target" => "form" }) do
      form_with(url: url, method: :patch, scope: scope) do |f|
        safe_join([
          (tag.div(errors.to_sentence, class: "text-danger small mb-1") if errors.any?),
          tag.div(class: "input-group input-group-sm") do
            f.text_field(field, value: value,
              class: "form-control form-control-sm #{"is-invalid" if errors.any?}",
              data: {
                "inline-edit-target" => "input",
                action: "keydown->inline-edit#keydown"
              }) +
            f.button(type: "submit", class: "btn btn-outline-primary") do
              tag.i("", class: "bi bi-check-lg")
            end
          end
        ].compact)
      end
    end

    tag.div(id: "#{dom_id(record)}_#{field}", data: { controller: "inline-edit" }) do
      display + form
    end
  end

  def registration_status(registration)
    return "unauthenticated" unless Current.user
    registration&.state || "none"
  end

  def user_bid_token(user_or_id)
    id = user_or_id.respond_to?(:id) ? user_or_id.id : user_or_id
    return nil unless id
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base[0, 32], "bid:#{id}")
  end

  def categories_exist?
    @categories_exist ||= Listings::Category.exists?
  end

  def browse_tabs(active:)
    has_auctions   = Current.tenant.features.auctions?
    has_categories = categories_exist?
    tabs = []
    tabs << { key: :auctions,   label: "Auctions",   icon: "bi-hammer", path: auctions_path }   if has_auctions
    tabs << { key: :listings,   label: "Listings",   icon: "bi-tag",    path: listings_path }   if has_auctions || has_categories
    tabs << { key: :categories, label: "Categories", icon: "bi-grid",   path: categories_path } if has_categories
    return if tabs.empty?
    content_tag(:ul, class: "nav nav-tabs px-4 pt-3 flex-nowrap overflow-x-auto overflow-y-hidden") do
      safe_join(tabs.map do |tab|
        content_tag(:li, class: "nav-item") do
          link_to tab[:path], class: "nav-link #{"active" if tab[:key] == active}" do
            content_tag(:i, "", class: "bi #{tab[:icon]} me-1 d-none d-sm-inline") + content_tag(:span, tab[:label])
          end
        end
      end)
    end
  end

  def google_maps_api_key
    Rails.application.credentials.dig(:google_maps, :api_key)
  end

  def google_maps_configured?
    google_maps_api_key.present?
  end

  def google_maps_embed_url(address)
    query = address.geocoded? ? "#{address.latitude},#{address.longitude}" : ERB::Util.url_encode(address.to_geocode_string)
    key = google_maps_api_key
    if key.present?
      "https://www.google.com/maps/embed/v1/place?key=#{key}&q=#{query}&zoom=15"
    else
      "https://maps.google.com/maps?q=#{query}&output=embed"
    end
  end

  def oauth_provider_configured?(provider)
    key = case provider
    when :google   then Rails.application.credentials.dig(:oauth, :google, :client_id)
    when :facebook then Rails.application.credentials.dig(:oauth, :facebook, :app_id)
    when :apple    then Rails.application.credentials.dig(:oauth, :apple, :client_id)
    end
    key.present?
  end

  def bootstrap_flash_class(type)
    FLASH_CLASS_MAP.fetch(type.to_s, "secondary")
  end

  def document_icon_class(content_type)
    DOCUMENT_ICON_MAP.fetch(content_type.to_s, "bi-file-earmark")
  end

  def absolute_url_for(attachment)
    url = url_for(attachment)
    url.start_with?("http") ? url : "#{request.base_url}#{url}"
  end

  # Injects a <style> tag overriding Bootstrap CSS variables for the current tenant's theme.
  # Returns nil if the tenant has no custom colors set.
  def tenant_theme_tag(tenant)
    css = tenant_theme_css(tenant)
    return if css.blank?
    content_tag(:style, css.html_safe)
  end

  private

  def tenant_theme_css(tenant)
    rules = []

    root_vars = {}
    root_vars["--bs-primary"]         = tenant.primary_color    if tenant.primary_color.present?
    root_vars["--bs-primary-rgb"]     = hex_to_rgb_string(tenant.primary_color) if tenant.primary_color.present?
    root_vars["--bs-secondary"]       = tenant.secondary_color  if tenant.secondary_color.present?
    root_vars["--bs-secondary-rgb"]   = hex_to_rgb_string(tenant.secondary_color) if tenant.secondary_color.present?
    root_vars["--bs-body-bg"]         = tenant.background_color if tenant.background_color.present?
    root_vars["--bs-body-bg-rgb"]     = hex_to_rgb_string(tenant.background_color) if tenant.background_color.present?
    root_vars["--bs-body-color"]      = tenant.text_color       if tenant.text_color.present?
    root_vars["--bs-body-color-rgb"]  = hex_to_rgb_string(tenant.text_color) if tenant.text_color.present?
    root_vars["--bs-link-color"]      = tenant.link_color       if tenant.link_color.present?
    root_vars["--bs-link-color-rgb"]  = hex_to_rgb_string(tenant.link_color) if tenant.link_color.present?
    root_vars["--bs-link-hover-color"] = shade_hex(tenant.link_color, 20) if tenant.link_color.present?

    if root_vars.any?
      vars_css = root_vars.map { |k, v| "  #{k}: #{v};" }.join("\n")
      rules << ":root {\n#{vars_css}\n}"
    end

    if tenant.primary_color.present?
      c   = tenant.primary_color
      rgb = hex_to_rgb_string(c)
      h15 = shade_hex(c, 15)
      h20 = shade_hex(c, 20)
      h25 = shade_hex(c, 25)
      rules << ".btn-primary {\n" \
               "  --bs-btn-bg: #{c};\n" \
               "  --bs-btn-border-color: #{c};\n" \
               "  --bs-btn-hover-bg: #{h15};\n" \
               "  --bs-btn-hover-border-color: #{h20};\n" \
               "  --bs-btn-active-bg: #{h20};\n" \
               "  --bs-btn-active-border-color: #{h25};\n" \
               "  --bs-btn-disabled-bg: #{c};\n" \
               "  --bs-btn-disabled-border-color: #{c};\n" \
               "  --bs-btn-focus-shadow-rgb: #{rgb};\n" \
               "}"
      rules << ".btn-outline-primary {\n" \
               "  --bs-btn-color: #{c};\n" \
               "  --bs-btn-border-color: #{c};\n" \
               "  --bs-btn-hover-bg: #{c};\n" \
               "  --bs-btn-hover-border-color: #{c};\n" \
               "  --bs-btn-active-bg: #{c};\n" \
               "  --bs-btn-active-border-color: #{c};\n" \
               "}"
      rules << ".text-primary { color: #{c} !important; }"
      rules << ".bg-primary { background-color: #{c} !important; }"
      rules << ".border-primary { border-color: #{c} !important; }"
    end

    if tenant.secondary_color.present?
      c   = tenant.secondary_color
      rgb = hex_to_rgb_string(c)
      h15 = shade_hex(c, 15)
      h20 = shade_hex(c, 20)
      h25 = shade_hex(c, 25)
      rules << ".btn-secondary {\n" \
               "  --bs-btn-bg: #{c};\n" \
               "  --bs-btn-border-color: #{c};\n" \
               "  --bs-btn-hover-bg: #{h15};\n" \
               "  --bs-btn-hover-border-color: #{h20};\n" \
               "  --bs-btn-active-bg: #{h20};\n" \
               "  --bs-btn-active-border-color: #{h25};\n" \
               "  --bs-btn-disabled-bg: #{c};\n" \
               "  --bs-btn-disabled-border-color: #{c};\n" \
               "  --bs-btn-focus-shadow-rgb: #{rgb};\n" \
               "}"
      rules << ".btn-outline-secondary {\n" \
               "  --bs-btn-color: #{c};\n" \
               "  --bs-btn-border-color: #{c};\n" \
               "  --bs-btn-hover-bg: #{c};\n" \
               "  --bs-btn-hover-border-color: #{c};\n" \
               "  --bs-btn-active-bg: #{c};\n" \
               "  --bs-btn-active-border-color: #{c};\n" \
               "}"
      rules << ".text-secondary { color: #{c} !important; }"
      rules << ".bg-secondary { background-color: #{c} !important; }"
      rules << ".border-secondary { border-color: #{c} !important; }"
      rules << "thead.thead-secondary { --bs-table-bg: #{c}; --bs-table-border-color: #{h15}; }"
    end

    if tenant.tertiary_color.present?
      c = tenant.tertiary_color
      rules << ".text-tertiary { color: #{c} !important; }"
      rules << ".bg-tertiary { background-color: #{c} !important; }"
    end

    if tenant.footer_color.present?
      rules << "footer.bg-body-tertiary { background-color: #{tenant.footer_color} !important; }"
    end

    if tenant.container_color.present?
      rules << ":root { --app-card-bg: #{tenant.container_color}; }"
    end

    if tenant.card_color.present?
      rules << ".card { --bs-card-bg: #{tenant.card_color}; }"
    end

    # Navbar gradient — uses tenant secondary + primary with darkened stops
    sec = tenant.secondary_color.presence || "#6B3A2A"
    pri = tenant.primary_color.presence   || "#355E3B"
    ter = tenant.tertiary_color.presence  || "#C8A84B"
    sec_dark = shade_hex(sec, 35)
    pri_dark  = shade_hex(pri, 20)
    rules << ".navbar {\n" \
             "  background: linear-gradient(135deg, #{sec_dark} 0%, #{sec} 50%, #{pri_dark} 100%) !important;\n" \
             "  border-bottom-color: #{ter} !important;\n" \
             "  --bs-navbar-hover-color: #{ter};\n" \
             "  --bs-navbar-active-color: #{ter};\n" \
             "  --bs-navbar-brand-hover-color: #{ter};\n" \
             "  --bs-nav-link-hover-color: #{ter};\n" \
             "}"

    rules.join("\n")
  end

  def hex_to_rgb_string(hex)
    r, g, b = parse_hex(hex)
    "#{r}, #{g}, #{b}"
  end

  def shade_hex(hex, percent)
    r, g, b = parse_hex(hex)
    factor = 1.0 - (percent / 100.0)
    r = (r * factor).round.clamp(0, 255)
    g = (g * factor).round.clamp(0, 255)
    b = (b * factor).round.clamp(0, 255)
    "#%02x%02x%02x" % [r, g, b]
  end

  def parse_hex(hex)
    h = hex.delete_prefix("#")
    # Expand shorthand (#abc -> #aabbcc)
    h = h.chars.flat_map { |c| [c, c] }.join if h.length == 3
    [h[0, 2].to_i(16), h[2, 2].to_i(16), h[4, 2].to_i(16)]
  end
end
