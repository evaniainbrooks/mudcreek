module PermissionsHelper
  def render_permissions_table(role:, permissions:)
    table = ::TableComponent.new(rows: permissions)
    table.with_value_column("Resource") { it.resource }
    table.with_value_column("Action") { it.action }
    table.with_column("", html_class: "text-end") do |permission|
      button_to admin_role_permission_path(role, permission), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Remove this permission?" } } do
          content_tag(:i, "", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
