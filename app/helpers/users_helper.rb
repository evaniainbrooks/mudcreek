module UsersHelper
  def render_users_table(users:, q:)
    table = ::TableComponent.new(rows: users, ransack_query: q)
    table.with_column("Name") { |u| link_to(u.name, admin_user_path(u)) }
    table.with_column("Email", sort_attr: :email_address) { mail_to(it.email_address) }
    table.with_value_column("Role") { it.role }
    table.with_value_column("Created At", sort_attr: :created_at) { it.created_at }
    table.with_column("", html_class: "text-end") do |u|
      unless u.activated?
        button_to(
          "Resend Activation",
          resend_activation_admin_user_path(u),
          method: :post,
          class: "btn btn-sm btn-outline-secondary d-inline",
          data: { turbo_confirm: "Resend activation email to #{u.email_address}?" }
        )
      end
    end
    render(table)
  end
end
