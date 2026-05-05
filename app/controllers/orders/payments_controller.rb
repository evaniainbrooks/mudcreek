class Orders::PaymentsController < ApplicationController
  def create
    @order = Current.user.orders.find_by!(number: params[:order_number])

    unless @order.pending?
      redirect_to order_path(@order), alert: t(".alert")
      return
    end

    transaction = nil

    Order.transaction do
      @order.lock!

      raise "Already paid" unless @order.pending?

      transaction = @order.transactions.create!(amount_cents: @order.total_cents, state: :pending)
    end

    ProcessPaymentJob.perform_later(transaction.id, params[:source_id], Current.user.square_customer_id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("payment-card",
          partial: "orders/payment_processing")
      end
      format.html { redirect_to order_path(@order) }
    end
  end
end
