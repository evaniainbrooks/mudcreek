module Admin::LocationsHelper
  def render_locations_table(locations:)
    table = ::TableComponent.new(rows: locations)
    table.with_column("Name") { |l| link_to l.name, admin_location_path(l), class: "fw-medium text-decoration-none" }
    table.with_column("Address") { |l| l.address&.to_fs(:long).presence || content_tag(:span, "—", class: "text-muted") }
    table.with_column("Check-ins") { |l| l.check_ins.count }
    table.with_value_column("Published") { |l| l.published }
    render(table)
  end
end
