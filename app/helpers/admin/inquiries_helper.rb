module Admin::InquiriesHelper
  def render_inquiries_table(inquiries:, q:)
    table = ::TableComponent.new(rows: inquiries, ransack_query: q, tbody_id: "admin-inquiries-tbody")
    add_inquiry_columns(table)
    render(table)
  end

  def inquiry_columns
    add_inquiry_columns(::TableComponent.new(rows: [])).columns
  end

  private

  def add_inquiry_columns(table)
    table.with_column("Form") { |i| link_to i.inquiry_form.name, admin_inquiry_form_path(i.inquiry_form) }
    table.with_column("Name", sort_attr: :name) { |i| link_to i.name, admin_inquiry_path(i) }
    table.with_value_column("Email") { it.email }
    table.with_value_column("Phone") { it.phone.presence }
    table.with_value_column("Submitted", sort_attr: :created_at) { it.created_at }
  end
end
