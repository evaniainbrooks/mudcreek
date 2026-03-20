class ProxyBidsController < ApplicationController
  before_action :require_authentication

  def create
    @auction = Auction.find_by!(hashid: params[:auction_hashid])
    @auction_listing = @auction.auction_listings.find_by!(hashid: params[:auction_listing_hashid])
    fallback = auction_path(@auction)

    registration = AuctionRegistration.find_or_create_by!(
      auction: @auction, user: Current.user
    )

    max_cents = (params[:max_bid].to_f * 100).round

    proxy_bid = @auction_listing.proxy_bids.find_or_initialize_by(
      auction_registration: registration
    )

    if proxy_bid.persisted? && max_cents <= proxy_bid.max_bid_cents
      flash.now[:alert] = "New max must be higher than your current proxy bid."
      return respond_with_flash_or_redirect(fallback)
    end

    proxy_bid.max_bid_cents = max_cents

    if proxy_bid.save
      ProxyBiddingService.resolve(@auction_listing)
      flash.now[:notice] = "Proxy bid set to #{helpers.humanized_money_with_symbol(proxy_bid.max_bid)}."
    else
      flash.now[:alert] = proxy_bid.errors.full_messages.join(", ")
    end

    respond_with_flash_or_redirect(fallback)
  end

  private

  def respond_with_flash_or_redirect(fallback)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash") }
      format.html { redirect_back_or_to fallback }
    end
  end
end
