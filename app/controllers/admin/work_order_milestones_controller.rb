class Admin::WorkOrderMilestonesController < Admin::BaseController
  before_action :set_work_order

  def create
    authorize(WorkOrderMilestone)
    @milestone = @work_order.work_order_milestones.new(milestone_params)

    if @milestone.save
      render turbo_stream: turbo_stream.append(
        "work-order-milestones",
        partial: "admin/work_orders/milestone_fields",
        locals: { milestone: @milestone, work_order: @work_order }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "work-order-milestone-errors",
        partial: "admin/work_orders/milestone_errors",
        locals: { milestone: @milestone }
      ), status: :unprocessable_content
    end
  end

  def update
    @milestone = @work_order.work_order_milestones.find(params[:id])
    authorize(@milestone)

    if @milestone.update(milestone_params)
      head :ok
    else
      render turbo_stream: turbo_stream.replace(
        "work-order-milestone-#{@milestone.id}-errors",
        partial: "admin/work_orders/milestone_errors",
        locals: { milestone: @milestone }
      ), status: :unprocessable_content
    end
  end

  def destroy
    @milestone = @work_order.work_order_milestones.find(params[:id])
    authorize(@milestone)
    @milestone.destroy!
    head :ok
  end

  private

  def set_work_order
    @work_order = WorkOrder.find_by!(number: params[:work_order_number])
  end

  def milestone_params
    params.expect(work_order_milestone: [ :name, :percentage, :trigger_state, :position ])
  end
end
