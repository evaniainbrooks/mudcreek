module Admin::SchedulesHelper
  def schedule_events_table(events, location, schedule, pagy)
    return if events.empty?

    t = TableComponent.new(rows: events)

    t.with_column("Summary") do |e|
      link_to(e.summary.presence || content_tag(:em, "No title", class: "text-muted"),
              edit_admin_location_schedule_schedule_event_path(location, schedule, e))
    end

    t.with_column("Starts") do |e|
      next unless e.starts_at
      e.all_day? ? e.starts_at.utc.to_date.strftime("%b %-d, %Y")
                 : e.starts_at.in_time_zone.strftime("%b %-d, %Y %-I:%M %p")
    end

    t.with_column("Ends") do |e|
      next unless e.ends_at
      e.all_day? ? e.ends_at.utc.to_date.strftime("%b %-d, %Y")
                 : e.ends_at.in_time_zone.strftime("%b %-d, %Y %-I:%M %p")
    end

    t.with_column("All Day", html_class: "text-center") do |e|
      content_tag(:i, "", class: "bi bi-check-lg text-success") if e.all_day?
    end

    t.with_column("Recurrence") do |e|
      content_tag(:code, e.rrule, class: "small") if e.rrule.present?
    end

    t.with_column("Bookable", html_class: "text-center") do |e|
      content_tag(:i, "", class: "bi bi-check-lg text-success") if e.bookable?
    end

    t.with_column("", html_class: "text-end") do |e|
      button_to admin_location_schedule_schedule_event_path(location, schedule, e),
                method: :delete, class: "btn btn-outline-danger btn-sm",
                form: { data: { turbo_confirm: "Delete this event?" } } do
        content_tag(:i, "", class: "bi bi-trash")
      end
    end

    render(t).then do |table_html|
      if pagy&.next
        next_link = link_to(admin_location_schedule_path(location, schedule, page: pagy.next),
                            class: "btn btn-outline-secondary btn-sm") do
          safe_join(["Next ", content_tag(:i, "", class: "bi bi-chevron-right")])
        end
        table_html + content_tag(:div, next_link, class: "card-footer d-flex justify-content-end")
      else
        table_html
      end
    end
  end
end
