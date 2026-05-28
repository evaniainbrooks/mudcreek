module Admin::ScheduleEventSessionsHelper
  def registrations_table(registrations)
    t = TableComponent.new(rows: registrations)
    t.with_column("Member") { |r| r.user&.email_address }
    t.with_column("Pass used") { |r| r.schedule_event_pass ? "#{r.schedule_event_pass.credits_remaining} credits remaining" : "—" }
    t.with_column("Registered at") { |r| r.created_at.strftime("%b %-d, %Y %-I:%M %p") }
    render(t)
  end
end
