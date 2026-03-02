class CartTotalsComponent < ViewComponent::Base
  def initialize(summary:, discount_code: nil, delivery_method: nil)
    @summary         = summary
    @discount_code   = discount_code
    @delivery_method = delivery_method
  end
end
