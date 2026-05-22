class WorkOrderMailer < ApplicationMailer
  def estimate_email(work_order)
    @work_order = work_order

    attachments["estimate-#{work_order.number}.pdf"] = {
      mime_type: "application/pdf",
      content:   work_order.estimate_pdf.download
    } if work_order.estimate_pdf.attached?

    mail(
      to:      work_order.client_contact_email,
      subject: "Estimate #{work_order.number} — #{work_order.title}"
    )
  end

  def contract_signed(work_order)
    @work_order = work_order

    mail(
      to:      Current.tenant.email_address,
      subject: "Work order #{work_order.number} has been signed"
    )
  end

  def milestone_invoice(invoice)
    @invoice    = invoice
    @work_order = invoice.work_order
    @milestone  = invoice.work_order_milestone

    mail(
      to:      @work_order.client_contact_email,
      subject: "Invoice #{invoice.number} — #{@work_order.title}"
    )
  end
end
