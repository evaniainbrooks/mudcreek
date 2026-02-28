module Admin::DiscountCodesHelper
  def render_discount_codes_table(discount_codes:)
    table = ::TableComponent.new(rows: discount_codes)
    table.with_column("Key") { |dc| tag.span(dc.key, class: "font-monospace fw-semibold") }
    table.with_column("Type") do |dc|
      css = dc.fixed? ? "text-bg-secondary" : "text-bg-primary"
      content_tag(:span, dc.discount_type.humanize, class: "badge #{css}")
    end
    table.with_column("Amount") do |dc|
      if dc.fixed?
        humanized_money_with_symbol(dc.amount, no_cents_if_whole: false)
      else
        "#{dc.amount_cents / 100}%"
      end
    end
    table.with_column("Start") { |dc| dc.start_at ? dc.start_at.to_fs(:short) : tag.span("—", class: "text-muted") }
    table.with_column("End")   { |dc| dc.end_at   ? dc.end_at.to_fs(:short)   : tag.span("—", class: "text-muted") }
    table.with_column("Actions", html_class: "text-end") do |dc|
      button_to(admin_discount_code_path(dc), method: :delete, class: "btn btn-sm btn-outline-danger",
        form: { data: { turbo_confirm: "Delete discount code \"#{dc.key}\"?" } }) do
        tag.i("", class: "bi bi-trash3") + " Delete"
      end
    end
    render(table)
  end
end
