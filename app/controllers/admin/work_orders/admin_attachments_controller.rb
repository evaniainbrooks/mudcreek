class Admin::WorkOrders::AdminAttachmentsController < Admin::BaseController
  before_action :set_work_order

  def create
    @work_order.admin_attachments.attach(params[:files])
    redirect_to admin_work_order_path(@work_order), notice: t(".notice")
  end

  def destroy
    attachment = ActiveStorage::Attachment.find_by!(
      record: @work_order, name: "admin_attachments", id: params[:id]
    )
    attachment.purge_later
    redirect_to admin_work_order_path(@work_order), notice: t(".notice", filename: attachment.filename)
  end

  private

  def set_work_order
    @work_order = WorkOrder.find_by!(number: params[:work_order_number])
    authorize(@work_order, :update?)
  end
end
