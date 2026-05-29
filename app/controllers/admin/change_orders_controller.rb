class Admin::ChangeOrdersController < Admin::BaseController
  before_action :set_work_order
  before_action :set_change_order, only: [ :show, :send_for_signature ]

  def new
    authorize(ChangeOrder)
    @change_order = @work_order.change_orders.new
  end

  def create
    authorize(ChangeOrder)
    @change_order = @work_order.change_orders.new(change_order_params)

    if @change_order.save
      render turbo_stream: [
        turbo_stream.update(
          "change-orders-section",
          partial: "admin/change_orders/table",
          locals: { change_orders: @work_order.change_orders.reload, work_order: @work_order }
        ),
        turbo_stream.action(:close_modal, "new-change-order-modal")
      ]
    else
      render turbo_stream: turbo_stream.replace(
        "new-change-order-form-errors",
        partial: "admin/change_orders/form_errors",
        locals: { change_order: @change_order }
      ), status: :unprocessable_content
    end
  end

  def show
  end

  def send_for_signature
    result = WorkOrders::SendChangeOrderService.call(change_order: @change_order)

    if result.success?
      redirect_to admin_work_order_change_order_path(@work_order, @change_order), notice: t(".notice")
    else
      redirect_to admin_work_order_change_order_path(@work_order, @change_order), alert: result.error
    end
  end

  private

  def set_work_order
    @work_order = WorkOrder.find_by!(number: params[:work_order_number])
    authorize(@work_order, :show?)
  end

  def set_change_order
    @change_order = @work_order.change_orders.find_by!(number: params[:number])
    authorize(@change_order)
  end

  def change_order_params
    params.expect(change_order: [ :description, :amount, :tax_exempt ])
  end
end
