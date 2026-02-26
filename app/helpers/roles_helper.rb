module RolesHelper
  def render_roles_table(roles:)
    table = ::TableComponent.new(rows: roles)
    table.with_column("Name") { |role| link_to role.name, admin_role_permissions_path(role) }
    table.with_value_column("Description") { it.description }
    table.with_value_column("Permissions") { it.permissions.size }
    table.with_value_column("Users") { it.users.size }
    table.with_column("Actions", html_class: "text-end") do |role|
      button_to admin_role_path(role), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Delete role \"#{role.name}\"?" } } do
          content_tag(:i, "", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
