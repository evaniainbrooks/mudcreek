class Orders::PaymentsController < ApplicationController
  def create
    @order = Current.user.orders.find_by!(number: params[:order_number])

    unless @order.pending?
      redirect_to order_path(@order), alert: "This order has already been processed."
      return
    end

    ProcessPaymentJob.perform_later(@order.id, params[:source_id])

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("payment-card",
          partial: "orders/payment_processing")
      end
      format.html { redirect_to order_path(@order) }
    end
  end
end
