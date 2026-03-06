module InvoicesHelper
  def invoice_status_badge(invoice)
    if invoice.paid?
      content_tag(:span, "Paid", class: "badge text-bg-success")
    else
      content_tag(:span, "Unpaid", class: "badge text-bg-warning text-dark")
    end
  end
end
