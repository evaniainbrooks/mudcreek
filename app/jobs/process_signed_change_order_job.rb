class ProcessSignedChangeOrderJob < ApplicationJob
  queue_as :default

  def perform(change_order_id)
    change_order = ChangeOrder.unscoped.find(change_order_id)
    Current.tenant = change_order.work_order.tenant

    change_order.update!(status: :signed, signed_at: Time.current)

    WorkOrders::GenerateChangeOrderInvoiceService.call(change_order: change_order)

    WorkOrderMailer.change_order_signed(change_order).deliver_later
  end
end
