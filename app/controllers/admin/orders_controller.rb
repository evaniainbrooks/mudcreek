class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [:show, :update]

  def index
    authorize(Order)
    @filter_total = Order.count
    @q = Order.ransack(params[:q])
    scope = @q.result.includes(:user, :order_items)
    scope = scope.order(Arel.sql("COALESCE(orders.square_created_at, orders.created_at) DESC"), id: :desc) unless @q.sorts.any?
    @filter_count = scope.count
    @pagy, @orders = pagy(scope)

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
      redirect_to admin_order_path(@order), notice: t(".notice")
    else
      render :show, status: :unprocessable_content
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
