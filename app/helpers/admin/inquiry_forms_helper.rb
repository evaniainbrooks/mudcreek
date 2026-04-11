module Admin::InquiryFormsHelper
  def render_inquiry_forms_table(inquiry_forms)
    table = TableComponent.new(rows: inquiry_forms)

    table.with_column("Name") { |f| link_to f.name, edit_admin_inquiry_form_path(f) }
    table.with_column("Slug") { |f| content_tag(:code, f.slug) }
    table.with_value_column("Recipient") { it.notification_recipient.email_address }
    table.with_value_column("Published") { it.published }
    table.with_column("Actions", html_class: "text-end") do |f|
      safe_join([
        link_to("Edit", edit_admin_inquiry_form_path(f), class: "btn btn-sm btn-outline-secondary"),
        link_to("Delete", admin_inquiry_form_path(f),
          data: { turbo_method: :delete, turbo_confirm: "Delete \"#{f.name}\"?" },
          class: "btn btn-sm btn-outline-danger ms-1")
      ])
    end

    render(table)
  end
end
