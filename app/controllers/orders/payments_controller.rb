class Orders::PaymentsController < ApplicationController
  def create
    @order = Current.user.orders.find_by!(number: params[:order_number])

    unless @order.pending?
      redirect_to order_path(@order), alert: "This order has already been processed."
      return
    end

    result = SquareClient.client.payments.create_payment(body: {
      source_id:       params[:source_id],
      idempotency_key: "order-#{@order.number}",
      amount_money:    { amount: @order.total_cents, currency: "CAD" },
      location_id:     SquareClient.location_id,
      reference_id:    @order.number,
      note:            "Order #{@order.number}"
    })

    if result.success?
      @order.update!(status: "paid", square_payment_id: result.data.payment.id)
      redirect_to order_path(@order), notice: "Payment successful! Your order is confirmed."
    else
      error = result.errors&.first&.detail || "Payment failed. Please try again."
      redirect_to order_path(@order), alert: error
    end
  end
end
