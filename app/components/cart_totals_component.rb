class CartTotalsComponent < ViewComponent::Base
  def initialize(summary:, discount_code: nil, delivery_method: nil, requires_delivery: false)
    @summary           = summary
    @discount_code     = discount_code
    @delivery_method   = delivery_method
    @requires_delivery = requires_delivery
  end
end
