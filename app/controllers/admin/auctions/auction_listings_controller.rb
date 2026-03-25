class Admin::Auctions::AuctionListingsController < Admin::BaseController
  before_action :set_auction
  before_action :set_auction_listing, only: %i[destroy update]

  def destroy
    authorize(@auction_listing)
    listing = @auction_listing.listing
    @auction_listing.destroy!
    redirect_to admin_auction_path(@auction),
      notice: ActionController::Base.helpers.link_to(listing.name, admin_listing_path(listing)) + " removed from auction."
  end

  def update
    authorize(@auction_listing)
    @auction_listing.update(auction_listing_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_auction_path(@auction), notice: "Bid details updated." }
    end
  end

  def reorder
    authorize(AuctionListing)
    auction_listing = @auction.auction_listings.find(params[:id])
    auction_listing.insert_at(params[:position].to_i)
    head :ok
  end

  private

  def set_auction
    @auction = Auction.find_by!(hashid: params[:auction_hashid])
  end

  def set_auction_listing
    @auction_listing = @auction.auction_listings.find_by!(hashid: params[:id])
  end

  def auction_listing_params
    params.require(:auction_listing).permit(:starting_bid, :reserve_price, :listing_state)
  end
end
