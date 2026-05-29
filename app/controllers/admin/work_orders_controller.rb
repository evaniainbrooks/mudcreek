class Admin::WorkOrdersController < Admin::BaseController
  before_action :set_work_order, only: [ :show, :edit, :update, :send_estimate, :advance_state, :estimate ]

  def index
    authorize(WorkOrder)
    @filter_total = WorkOrder.count
    @q = WorkOrder.ransack(params[:q])
    scope = @q.result.includes(:user).order(created_at: :desc, id: :desc)
    @filter_count = scope.count
    @pagy, @work_orders = pagy(:keyset, scope)

    respond_to do |format|
      format.html
      format.turbo_stream do
        if params[:page].present?
          render turbo_stream: [
            turbo_stream.append("admin-work-orders-tbody", partial: "admin/work_orders/work_order_row", collection: @work_orders, as: :work_order),
            turbo_stream.replace("sentinel", partial: "admin/work_orders/sentinel", locals: { pagy: @pagy, q: params[:q] })
          ]
        else
          render :index, formats: [ :html ]
        end
      end
    end
  end

  def show
  end

  def new
    authorize(WorkOrder)
    @work_order = WorkOrder.new
    @work_order.build_address
  end

  def create
    authorize(WorkOrder)
    @work_order = WorkOrder.new(work_order_params)

    if @work_order.save
      redirect_to admin_work_order_path(@work_order), notice: t(".notice")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @work_order.build_address if @work_order.address.nil?
  end

  def update
    if @work_order.update(work_order_params)
      redirect_to admin_work_order_path(@work_order), notice: t(".notice")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def send_estimate
    result = WorkOrders::SendEstimateService.call(work_order: @work_order)

    unless result.success?
      return redirect_to admin_work_order_path(@work_order), alert: result.error
    end

    sign_result = WorkOrders::SendSignatureRequestService.call(work_order: @work_order)

    if sign_result.success?
      redirect_to admin_work_order_path(@work_order), notice: t(".notice")
    else
      redirect_to admin_work_order_path(@work_order), alert: sign_result.error
    end
  end

  def advance_state
    new_state = params[:state].presence_in(WorkOrder.states.keys)
    return redirect_to admin_work_order_path(@work_order), alert: t(".invalid_state") unless new_state

    AdvanceWorkOrderStateJob.perform_later(@work_order.id, new_state)
    redirect_to admin_work_order_path(@work_order), notice: t(".notice", state: new_state.humanize)
  end

  def estimate
    render "work_orders/estimate", layout: false
  end

  private

  def set_work_order
    @work_order = WorkOrder.includes(:work_order_items, :work_order_milestones, :address, :user)
      .find_by!(number: params[:number])
    authorize(@work_order)
  end

  def work_order_params
    params.expect(work_order: [
      :title, :description, :client_name, :client_email, :client_phone, :user_id, :admin_notes,
      address_attributes: [ :id, :street_address, :city, :province, :postal_code, :country, :_destroy ],
      work_order_items_attributes: [ [ :id, :name, :description, :quantity, :unit_price, :position, :_destroy ] ],
      work_order_milestones_attributes: [ [ :id, :name, :percentage, :trigger_state, :position, :_destroy ] ]
    ])
  end
end
