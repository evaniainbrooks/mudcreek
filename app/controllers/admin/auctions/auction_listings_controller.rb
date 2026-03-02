class Admin::Auctions::AuctionListingsController < Admin::BaseController
  before_action :set_auction
  before_action :set_auction_listing, only: %i[destroy update]

  def destroy
    authorize(@auction_listing)
    @auction_listing.destroy!
    redirect_to admin_auction_path(@auction), notice: "Listing removed from auction."
  end

  def update
    authorize(@auction_listing)
    if @auction_listing.update(auction_listing_params)
      redirect_to admin_auction_path(@auction), notice: "Bid details updated."
    else
      redirect_to admin_auction_path(@auction), alert: @auction_listing.errors.full_messages.to_sentence
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
    @auction_listing = @auction.auction_listings.find(params[:id])
  end

  def auction_listing_params
    params.require(:auction_listing).permit(:starting_bid, :bid_increment, :reserve_price)
  end
end
