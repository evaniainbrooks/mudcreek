module Admin::ScheduleEventPassesHelper
  def schedule_event_passes_table(passes, user: nil)
    t = TableComponent.new(rows: passes)
    t.with_column("Member") { |p| p.user&.email_address } unless user
    t.with_column("Credits remaining") { |p| p.credits_remaining }
    t.with_column("Expires") { |p| p.expires_at&.strftime("%b %-d, %Y") || "—" }
    t.with_column("Issued") { |p| p.created_at.strftime("%b %-d, %Y") }
    t.with_column("", html_class: "text-end") do |p|
      button_to admin_schedule_event_pass_path(p), method: :delete,
        class: "btn btn-outline-danger btn-sm",
        form: { data: { turbo_confirm: "Remove this pass?" } } do
        content_tag(:i, "", class: "bi bi-trash")
      end
    end
    render(t)
  end
end
