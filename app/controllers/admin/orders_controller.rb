class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [:show, :update]

  def index
    authorize(Order)
    @q = Order.ransack(params[:q])
    scope = @q.result.includes(:user, :order_items).order(created_at: :desc, id: :desc)
    @pagy, @orders = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append("admin-orders-tbody", partial: "admin/orders/order_row", collection: @orders, as: :order),
            turbo_stream.replace("sentinel", partial: "admin/orders/sentinel", locals: { pagy: @pagy, q: params[:q] })
          ]
        else
          render :index, formats: [:html]
        end
      end
    end
  end

  def show
  end

  def update
    if @order.update(order_params)
      redirect_to admin_order_path(@order), notice: "Order updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.includes(:user, :order_items).find_by!(number: params[:number])
    authorize(@order)
  end

  def order_params
    params.require(:order).permit(:status, :street_address, :city, :province, :postal_code, :country, :admin_notes)
  end
end
