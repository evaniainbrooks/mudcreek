class AdvanceWorkOrderStateJob < ApplicationJob
  queue_as :default

  def perform(work_order_id, new_state)
    work_order = WorkOrder.unscoped.find(work_order_id)
    Current.tenant = work_order.tenant

    attrs = { state: new_state }
    attrs[:completed_at] = Time.current if new_state.to_s == "completed"

    work_order.update!(attrs)

    work_order.work_order_milestones
      .where(trigger_state: new_state.to_s, invoice_generated: false)
      .each { |m| WorkOrders::GenerateMilestoneInvoiceService.call(milestone: m) }
  end
end
