class BidButtonComponent < ViewComponent::Base
  def initialize(auction_listing:, auction:, registration: nil, bidder_token: nil, button_class: "btn btn-primary")
    @auction_listing = auction_listing
    @auction = auction
    @bidder_token = bidder_token
    @button_class = button_class
  end
end
