class Admin::AuctionListingsController < Admin::BaseController
  def create
    authorize(AuctionListing)
    auction = Auction.find(params[:auction_id])
    listings = Listing.sale.where(id: Array(params[:listing_ids]).map(&:to_i))

    AddListingsToAuctionService.call(
      auction: auction,
      listings: listings,
      starting_bid: params[:starting_bid],
      listing_state: params[:listing_state].presence
    )

    auction_link = view_context.link_to(auction.name, admin_auction_path(auction))
    redirect_to admin_listings_path, notice: t(".notice", auction_link: auction_link).html_safe
  end
end
