class Admin::WorkOrders::ClientAttachmentsController < Admin::BaseController
  before_action :set_work_order

  def destroy
    attachment = ActiveStorage::Attachment.find_by!(
      record: @work_order, name: "client_attachments", id: params[:id]
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
