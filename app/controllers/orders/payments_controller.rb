class Orders::PaymentsController < ApplicationController
  def create
    @order = Current.user.orders.find_by!(number: params[:order_number])

    unless @order.pending?
      redirect_to order_path(@order), alert: "This order has already been processed."
      return
    end

    response = SquareClient.client.payments.create(
      source_id:       params[:source_id],
      idempotency_key: "order-#{@order.number}",
      amount_money:    { amount: @order.total_cents, currency: "CAD" },
      location_id:     SquareClient.location_id,
      reference_id:    @order.number,
      note:            "Order #{@order.number}"
    )

    @order.update!(status: "paid", square_payment_id: response.payment.id)
    redirect_to order_path(@order), notice: "Payment successful! Your order is confirmed."
  rescue Square::Errors::ResponseError => e
    error = JSON.parse(e.message).dig("errors", 0, "detail") rescue nil
    redirect_to order_path(@order), alert: error || "Payment failed. Please try again."
  end
end
