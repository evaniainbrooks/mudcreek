class ProcessPaymentJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :default

  def perform(transaction_id, source_id, customer_id = nil)
    transaction = Transaction.unscoped.find(transaction_id)
    return unless transaction.pending?

    transaction.with_lock do
      return unless transaction.pending?

      order = transaction.order

      begin
        payment_params = {
          source_id:       source_id,
          idempotency_key: transaction.uuid,
          amount_money:    { amount: transaction.amount_cents, currency: "CAD" },
          location_id:     SquareClient.location_id,
          reference_id:    order.number,
          note:            "Order #{order.number}"
        }
        payment_params[:customer_id] = customer_id if customer_id.present?

        response = SquareClient.client.payments.create(**payment_params)

        payment = response.payment

        transaction.update!(
          state:           :succeeded,
          square_payment_id: payment.id,
          raw_response:    response.to_h
        )

        order.with_lock { order.update!(status: :paid) if order.pending? }

        broadcast_success(order)

      rescue Square::Errors::ResponseError => e
        transaction.update!(state: :failed, error_message: extract_error(e))

        broadcast_error(order, e)
      end
    end
  end

  private

  def broadcast_success(order)
    return unless order

    Turbo::StreamsChannel.broadcast_action_to(
      "order_payment_#{order.id}",
      action: "redirect",
      target: order_path(order)
    )
  end

  def broadcast_error(order, error)
    return unless order

    Turbo::StreamsChannel.broadcast_replace_to(
      "order_payment_#{order.id}",
      target: "payment-card",
      partial: "orders/payment_error",
      locals: { order:, error: extract_error(error) }
    )
  end

  def extract_error(error)
    parsed = JSON.parse(error.message) rescue {}
    parsed.dig("errors", 0, "detail") || "Payment failed. Please try again."
  end
end
