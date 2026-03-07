module Admin::InvoicesHelper
  def render_invoices_table(invoices:, q:)
    table = ::TableComponent.new(rows: invoices, ransack_query: q, tbody_id: "admin-invoices-tbody")
    add_invoice_columns(table)
    render(table)
  end

  def invoice_columns
    add_invoice_columns(::TableComponent.new(rows: [])).columns
  end

  private

  def add_invoice_columns(table)
    table.with_column("Invoice", sort_attr: :number) { |inv| link_to inv.number, admin_invoice_path(inv) }
    table.with_value_column("User") { it.user }
    table.with_column("For") do |inv|
      if inv.auction
        content_tag(:div, class: "lh-sm") do
          safe_join([
            inv.auction.name,
            content_tag(:small, "Auction", class: "text-muted d-block")
          ])
        end
      elsif inv.offer
        content_tag(:div, class: "lh-sm") do
          safe_join([
            inv.offer.listing.name,
            content_tag(:small, "Offer", class: "text-muted d-block")
          ])
        end
      end
    end
    table.with_column("Status", sort_attr: :status) { |inv| invoice_status_badge(inv) }
    table.with_value_column("Total", sort_attr: :total_cents) { it.total }
    table.with_value_column("Issued", sort_attr: :created_at) { it.created_at }
  end
end
