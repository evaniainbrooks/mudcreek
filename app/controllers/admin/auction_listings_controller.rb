class Admin::AuctionListingsController < Admin::BaseController
  def create
    authorize(AuctionListing)
    auction = Auction.find(params[:auction_id])
    listing_ids = Listing.sale.where(id: Array(params[:listing_ids]).map(&:to_i)).pluck(:id)

    listing_ids.each do |listing_id|
      AuctionListing.create!(auction: auction, listing_id: listing_id)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      next
    end

    redirect_to admin_listings_path, notice: "Listings added to auction."
  end
end
