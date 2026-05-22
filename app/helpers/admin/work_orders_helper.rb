module Admin::WorkOrdersHelper
  STATE_BADGE = {
    "draft"          => "text-bg-secondary",
    "estimate_sent"  => "text-bg-info",
    "contracted"     => "text-bg-primary",
    "in_progress"    => "text-bg-warning",
    "completed"      => "text-bg-success",
    "cancelled"      => "text-bg-danger"
  }.freeze

  def work_order_state_badge(work_order)
    css = STATE_BADGE.fetch(work_order.state, "text-bg-secondary")
    content_tag(:span, work_order.state.humanize, class: "badge #{css}")
  end
end
