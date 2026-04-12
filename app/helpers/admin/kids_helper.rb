module Admin::KidsHelper
  def render_kids_table(kids)
    table = TableComponent.new(rows: kids)
    table.with_column("Name") { |k| link_to k.name, admin_user_path(k.user), class: "fw-medium text-decoration-none" }
    table.with_value_column("User") { it.user }
    table.with_column("Birthdate") { |k| k.birthdate.strftime("%b %-d, %Y") }
    table.with_column("Age") { |k| "#{((Date.current - k.birthdate) / 365.25).floor}y" }
    render(table)
  end
end
