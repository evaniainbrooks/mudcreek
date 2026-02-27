module UsersHelper
  def render_users_table(users:, q:)
    table = ::TableComponent.new(rows: @users, ransack_query: @q)
    table.with_value_column("Name") { "#{it.first_name} #{it.last_name}" }
    table.with_column("Email", sort_attr: :email_address) { mail_to(it.email_address) }
    table.with_value_column("Role") { it.role }
    table.with_value_column("Created At", sort_attr: :created_at) { it.created_at }
    render(table)
  end
end
