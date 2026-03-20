class Admin::BidsController < Admin::BaseController
  before_action :set_bid

  def update
    state = params[:state].presence_in(Bid.states.keys)
    return redirect_to admin_listing_path(@bid.auction_listing.listing), alert: "Invalid state." unless state

    @bid.update!(state: state)
    ProxyBiddingService.resolve(@bid.auction_listing)
    redirect_to admin_listing_path(@bid.auction_listing.listing), notice: "Bid marked as #{state}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_listing_path(@bid.auction_listing.listing), alert: e.message
  end

  private

  def set_bid
    @bid = Bid.find(params[:id])
    authorize(@bid)
  end
end
