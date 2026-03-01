module OrdersHelper
  ORDER_STATUS_COLORS = {
    "pending"   => "warning",
    "paid"      => "success",
    "cancelled" => "danger"
  }.freeze

  def order_status_badge(order)
    color = ORDER_STATUS_COLORS.fetch(order.status, "secondary")
    content_tag(:span, order.status.capitalize, class: "badge text-bg-#{color}")
  end
end
