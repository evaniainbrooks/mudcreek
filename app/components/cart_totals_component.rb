class CartTotalsComponent < ViewComponent::Base
  def initialize(summary:, discount_code: nil, delivery_method: nil, requires_delivery: false, address_saved: false, guest_info_saved: nil)
    @summary           = summary
    @discount_code     = discount_code
    @delivery_method   = delivery_method
    @requires_delivery = requires_delivery
    @address_saved     = address_saved
    @guest_info_saved  = guest_info_saved
  end
end
