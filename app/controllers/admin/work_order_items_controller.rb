class Admin::WorkOrderItemsController < Admin::BaseController
  before_action :set_work_order

  def create
    authorize(WorkOrderItem)
    @item = @work_order.work_order_items.new(item_params)

    if @item.save
      render turbo_stream: turbo_stream.append(
        "work-order-items",
        partial: "admin/work_orders/item_fields",
        locals: { item: @item, work_order: @work_order }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "work-order-item-errors",
        partial: "admin/work_orders/item_errors",
        locals: { item: @item }
      ), status: :unprocessable_content
    end
  end

  def update
    @item = @work_order.work_order_items.find(params[:id])
    authorize(@item)

    if @item.update(item_params)
      head :ok
    else
      render turbo_stream: turbo_stream.replace(
        "work-order-item-#{@item.id}-errors",
        partial: "admin/work_orders/item_errors",
        locals: { item: @item }
      ), status: :unprocessable_content
    end
  end

  def destroy
    @item = @work_order.work_order_items.find(params[:id])
    authorize(@item)
    @item.destroy!
    head :ok
  end

  private

  def set_work_order
    @work_order = WorkOrder.find_by!(number: params[:work_order_number])
  end

  def item_params
    params.expect(work_order_item: [ :name, :description, :quantity, :unit_price, :position ])
  end
end
