module Admin::LocationsHelper
  def render_locations_table(locations:)
    table = ::TableComponent.new(rows: locations)
    table.with_column("Name") { |l| link_to l.name, admin_location_path(l), class: "fw-medium text-decoration-none" }
    table.with_column("Address") { |l| l.address&.to_fs(:long).presence || content_tag(:span, "—", class: "text-muted") }
    table.with_column("Check-ins") { |l| l.check_ins.count }
    table.with_value_column("Published") { |l| l.published }
    render(table)
  end

  def location_member_table(members, location)
    t = TableComponent.new(rows: members)
    t.with_column("Name")  { |u| u.name }
    t.with_column("Email") { |u| u.email_address }
    t.with_column("", html_class: "text-end") do |u|
      user_location = UserLocation.find_by!(location: location, user: u)
      button_to admin_location_location_user_path(location, user_location),
        method: :delete, class: "btn btn-outline-danger btn-sm",
        form: { data: { turbo_confirm: "Remove #{u.name} from this location?" } } do
        content_tag(:i, "", class: "bi bi-x")
      end
    end
    render(t)
  end

  def location_announcement_table(announcements, location)
    t = TableComponent.new(rows: announcements)
    t.with_column("Subject") { |a| a.subject }
    t.with_column("Sent") do |a|
      a.sent_at ? a.sent_at.strftime("%b %-d") : content_tag(:span, "Pending", class: "badge bg-warning text-dark")
    end
    t.with_column("", html_class: "text-end") do |a|
      link_to "View", admin_location_location_announcement_path(location, a), class: "btn btn-outline-secondary btn-sm"
    end
    render(t)
  end

  def location_schedules_table(schedules, location)
    t = TableComponent.new(rows: schedules)
    t.with_column("Name") do |s|
      link_to(s.name.presence || content_tag(:span, "Untitled", class: "text-muted"), admin_location_schedule_path(location, s))
    end
    t.with_column("Source") { |s| s.source_url.presence || content_tag(:span, "Uploaded file", class: "text-muted fst-italic") }
    t.with_value_column("Last synced") { |s| s.last_synced_at }
    t.with_column("Events") { |s| s.schedule_events.count }
    t.with_column("", html_class: "text-end") do |s|
      button_to admin_location_schedule_path(location, s), method: :delete, class: "btn btn-outline-danger btn-sm",
        form: { data: { turbo_confirm: "Delete \"#{s.name}\"?" } } do
        content_tag(:i, "", class: "bi bi-trash")
      end
    end
    render(t)
  end
end
