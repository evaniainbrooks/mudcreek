module UsersHelper
  def render_users_table(users:, q:)
    table = ::TableComponent.new(rows: @users, ransack_query: @q)
    table.with_column("Email", sort_attr: :email_address) { mail_to(it.email_address) }
    table.with_column("Created At", sort_attr: :created_at, html_class: "text-muted") { it.created_at.to_fs(:long) }
    render(table)
  end
end
