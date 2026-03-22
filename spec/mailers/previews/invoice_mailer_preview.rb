class InvoiceMailerPreview < ActionMailer::Preview
  def invoice_generated
    Current.tenant = Tenant.find_by(default: true) || Tenant.first!
    invoice = Invoice.includes(:user, :auction).first!
    InvoiceMailer.invoice_generated(invoice)
  end
end
