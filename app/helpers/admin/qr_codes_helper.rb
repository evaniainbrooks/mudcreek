module Admin::QrCodesHelper
  def qr_scans_table(recent_scans)
    t = TableComponent.new(rows: recent_scans)
    t.with_column("Time")       { |s| s.created_at.strftime("%b %-d, %Y %H:%M") }
    t.with_column("IP Address") { |s| s.ip_address || "—" }
    t.with_column("User Agent", html_class: "text-truncate") { |s| s.user_agent || "—" }
    render(t)
  end
end
