class ProcessPaymentJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(order_id, source_id)
    order = Order.unscoped.find(order_id)
    return unless order.pending?

    response = SquareClient.client.payments.create(
      source_id:       source_id,
      idempotency_key: "order-#{order.number}",
      amount_money:    { amount: order.total_cents, currency: "CAD" },
      location_id:     SquareClient.location_id,
      reference_id:    order.number,
      note:            "Order #{order.number}"
    )

    order.update!(status: "paid", square_payment_id: response.payment.id)

    Turbo::StreamsChannel.broadcast_action_to(
      "order_payment_#{order.id}",
      action: "redirect",
      target: order_path(order)
    )
  rescue Square::Errors::ResponseError => e
    error = JSON.parse(e.message).dig("errors", 0, "detail") rescue "Payment failed. Please try again."

    Turbo::StreamsChannel.broadcast_replace_to(
      "order_payment_#{order.id}",
      target: "payment-card",
      partial: "orders/payment_error",
      locals: { order: order, error: error }
    )
  end
end
