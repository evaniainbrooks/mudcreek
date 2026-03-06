class InvoiceMailer < ApplicationMailer
  def invoice_generated(invoice)
    @invoice = invoice
    @user = invoice.user
    @auction = invoice.auction

    mail(
      to: @user.email_address,
      subject: "Your invoice for #{@auction.name}"
    )
  end
end
