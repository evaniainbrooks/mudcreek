module UsersHelper
  def render_birthdays_table(entries:)
    today = Date.current
    table = ::TableComponent.new(rows: entries)
    table.with_column("Type") do |entry|
      if entry[:type] == :user
        content_tag(:span, "User", class: "badge text-bg-primary")
      else
        content_tag(:span, "Kid", class: "badge text-bg-secondary")
      end
    end
    table.with_column("Name") do |entry|
      record = entry[:record]
      path = entry[:type] == :user ? admin_user_path(record) : admin_user_path(record.user)
      link_to(record.name, path, class: "text-decoration-none fw-medium")
    end
    table.with_column("Parent") do |entry|
      if entry[:type] == :kid
        link_to(entry[:record].user.name, admin_user_path(entry[:record].user), class: "text-decoration-none text-muted")
      else
        content_tag(:span, "—", class: "text-muted")
      end
    end
    table.with_value_column("Birthdate") { |entry| entry[:record].birthdate }
    table.with_column("Turns") do |entry|
      entry[:next_birthday].year - entry[:record].birthdate.year
    end
    table.with_column("Days Until") do |entry|
      days_until = (entry[:next_birthday] - today).to_i
      if days_until == 0
        content_tag(:span, "Today!", class: "badge text-bg-success")
      else
        pluralize(days_until, "day")
      end
    end
    render(table)
  end

  def render_users_table(users:, q:)
    table = ::TableComponent.new(rows: users, ransack_query: q)
    table.with_column("Name") { |u| link_to(u.name, admin_user_path(u)) }
    table.with_column("Email", sort_attr: :email_address) do |u|
      if u.disabled?
        safe_join([
          mail_to(u.disabled_email_address),
          content_tag(:i, "",
            class: "bi bi-slash-circle text-danger ms-1",
            data: { bs_toggle: "tooltip", bs_title: "This user has been disabled" })
        ])
      else
        mail_to(u.email_address)
      end
    end
    table.with_value_column("Role") { it.role }
    table.with_value_column("Created At", sort_attr: :created_at) { it.created_at }
    table.with_column("", html_class: "text-end") do |u|
      display_email = u.disabled? ? u.disabled_email_address : u.email_address
      content_tag(:div, class: "d-flex gap-1 justify-content-end") do
        buttons = []
        unless u.activated? || u.disabled?
          buttons << button_to(
            "Resend Activation",
            resend_activation_admin_user_path(u),
            method: :post,
            class: "btn btn-sm btn-outline-secondary",
            data: { turbo_confirm: "Resend activation email to #{display_email}?" }
          )
        end
        if u.disabled?
          buttons << button_to(
            "Enable",
            admin_user_disablement_path(u),
            method: :delete,
            class: "btn btn-sm btn-outline-success",
            data: { turbo_confirm: "Re-enable #{display_email}?" }
          )
        else
          buttons << button_to(
            "Disable",
            admin_user_disablement_path(u),
            method: :post,
            class: "btn btn-sm btn-outline-danger",
            data: { turbo_confirm: "Disable #{display_email}? They will be signed out immediately." }
          )
        end
        safe_join(buttons)
      end
    end
    render(table)
  end
end
