module Admin::WorkOrdersHelper
  STATE_BADGE = {
    "draft"          => "text-bg-secondary",
    "estimate_sent"  => "text-bg-info",
    "contracted"     => "text-bg-primary",
    "in_progress"    => "text-bg-warning",
    "completed"      => "text-bg-success",
    "cancelled"      => "text-bg-danger"
  }.freeze

  CHANGE_ORDER_STATUS_BADGE = {
    "draft"          => "text-bg-secondary",
    "signature_sent" => "text-bg-info",
    "signed"         => "text-bg-success"
  }.freeze

  def change_order_status_badge(change_order)
    css = CHANGE_ORDER_STATUS_BADGE.fetch(change_order.status, "text-bg-secondary")
    content_tag(:span, change_order.status.humanize, class: "badge #{css}")
  end

  def change_orders_table(change_orders, work_order:)
    t = TableComponent.new(rows: change_orders)
    t.with_column("Number") { |co| link_to co.number, admin_work_order_change_order_path(work_order, co), class: "fw-semibold text-decoration-none" }
    t.with_column("Description") { |co| content_tag(:span, co.description, class: "text-truncate d-inline-block", style: "max-width:260px") }
    t.with_value_column("Amount") { |co| co.amount }
    t.with_column("Status") { |co| change_order_status_badge(co) }
    render(t)
  end

  def work_order_state_badge(work_order)
    css = STATE_BADGE.fetch(work_order.state, "text-bg-secondary")
    content_tag(:span, work_order.state.humanize, class: "badge #{css}")
  end

  def work_orders_table(work_orders, ransack_query: nil)
    t = TableComponent.new(rows: work_orders, ransack_query:, tbody_id: "admin-work-orders-tbody")
    t.with_column("Number") { |wo| link_to wo.number, admin_work_order_path(wo), class: "fw-semibold text-decoration-none" }
    t.with_column("Title", sort_attr: "title") { |wo| wo.title }
    t.with_column("Client") do |wo|
      if wo.user
        link_to wo.user.email_address, admin_user_path(wo.user)
      elsif wo.client_email.present?
        mail_to wo.client_email, wo.client_display_name
      else
        content_tag(:span, wo.client_display_name)
      end
    end
    t.with_value_column("Total") { |wo| wo.total }
    t.with_column("State") { |wo| work_order_state_badge(wo) }
    t.with_value_column("Created", sort_attr: "created_at") { |wo| wo.created_at }
    t.with_column("", html_class: "text-end") do |wo|
      link_to content_tag(:i, "", class: "bi bi-eye"), admin_work_order_path(wo), class: "btn btn-sm btn-outline-secondary"
    end
    render(t)
  end

  def work_order_items_table(items, total:)
    t = TableComponent.new(rows: items)
    t.with_column("Description") { |item| item.name }
    t.with_column("Qty", html_class: "text-center") { |item| item.quantity }
    t.with_value_column("Unit Price", html_class: "text-end") { |item| item.unit_price }
    t.with_value_column("Total", html_class: "text-end") { |item| item.line_total }
    t.with_footer_row do
      safe_join([
        content_tag(:td, "Total", colspan: 3),
        content_tag(:td, humanized_money_with_symbol(total), class: "text-end")
      ])
    end
    render(t)
  end

  def work_order_milestones_table(milestones)
    t = TableComponent.new(rows: milestones)
    t.with_column("Name") { |m| m.name }
    t.with_column("Trigger") { |m| m.trigger_state.humanize }
    t.with_column("%", html_class: "text-end") { |m| "#{m.percentage}%" }
    t.with_column("Amount", html_class: "text-end") do |m|
      if m.amount_cents > 0
        humanized_money_with_symbol(m.amount)
      else
        content_tag(:span, "Calculated at signing", class: "text-muted fst-italic")
      end
    end
    t.with_column("Invoice") do |m|
      if m.invoice_generated?
        invoice = m.invoices.first
        if invoice
          link_to invoice.number, admin_invoice_path(invoice), class: "badge text-bg-success text-decoration-none"
        else
          content_tag(:span, "Generated", class: "badge text-bg-success")
        end
      else
        content_tag(:span, "Pending", class: "badge text-bg-secondary")
      end
    end
    render(t)
  end
end
