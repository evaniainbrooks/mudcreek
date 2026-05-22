module WorkOrdersHelper
  def work_order_state_badge(work_order)
    Admin::WorkOrdersHelper::STATE_BADGE
    css = Admin::WorkOrdersHelper::STATE_BADGE.fetch(work_order.state, "text-bg-secondary")
    content_tag(:span, work_order.state.humanize, class: "badge #{css}")
  end
end
