module QrCodesHelper
  def render_qr_codes_table(qr_codes:)
    table = ::TableComponent.new(rows: qr_codes)
    table.with_column("Name") { |qr| link_to(qr.name, admin_qr_code_path(qr)) }
    table.with_column("Slug") { |qr| content_tag(:code, qr.slug) }
    table.with_column("Destination") { |qr| content_tag(:span, qr.destination_url, class: "text-truncate d-inline-block", style: "max-width:200px") }
    table.with_column("Status") do |qr|
      if qr.live?
        content_tag(:span, "Live", class: "badge bg-success")
      elsif qr.expires_at&.past?
        content_tag(:span, "Expired", class: "badge bg-secondary")
      else
        content_tag(:span, "Inactive", class: "badge bg-warning text-dark")
      end
    end
    table.with_value_column("Owner") { |qr| qr.owner }
    table.with_value_column("Scans") { |qr| qr.scan_count }
    table.with_value_column("Last Scanned") { |qr| qr.last_scanned_at }
    table.with_column("", html_class: "text-end") do |qr|
      unless qr.location_qr_code?
        link_to("Delete", admin_qr_code_path(qr),
          data: { turbo_method: :delete, turbo_confirm: "Delete \"#{qr.name}\"?" },
          class: "btn btn-sm btn-outline-danger")
      end
    end
    render(table)
  end
end
