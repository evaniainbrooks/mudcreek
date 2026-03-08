class ChargeInvoiceJob < ApplicationJob
  queue_as :default

  def perform(invoice_id)
    invoice = Invoice.unscoped.find(invoice_id)
    Current.tenant = invoice.tenant
    return if invoice.paid?

    card_id = invoice.user.default_square_card_id
    return unless card_id.present?

    response = SquareClient.client.payments.create(
      source_id: card_id,
      idempotency_key: "invoice-#{invoice.id}-#{invoice.number}",
      amount_money: { amount: invoice.total_cents, currency: "CAD" },
      location_id: SquareClient.location_id,
      reference_id: invoice.number,
      note: "Invoice #{invoice.number}"
    )
    invoice.update!(status: :paid, square_payment_id: response.payment.id, charge_error: nil)

  rescue Square::Errors::ResponseError => e
    detail = (JSON.parse(e.message) rescue {}).dig("errors", 0, "detail") || "Payment failed."
    invoice.update_columns(charge_error: detail)
    InvoiceMailer.invoice_generated(invoice).deliver_later

  rescue => e
    invoice.update_columns(charge_error: e.message)
    raise
  end
end
