class ProcessWorkOrderContractJob < ApplicationJob
  queue_as :default

  def perform(work_order_id)
    work_order = WorkOrder.unscoped.find(work_order_id)
    Current.tenant = work_order.tenant

    WorkOrders::ComputeMilestoneAmountsService.call(work_order:)

    work_order.update!(state: :contracted, contracted_at: Time.current)

    work_order.work_order_milestones
      .where(trigger_state: "contracted", invoice_generated: false)
      .each { |m| WorkOrders::GenerateMilestoneInvoiceService.call(milestone: m) }

    WorkOrderMailer.contract_signed(work_order).deliver_later
  end
end
