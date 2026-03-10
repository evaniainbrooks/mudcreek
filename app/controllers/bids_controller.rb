class BidsController < ApplicationController
  before_action :require_authentication

  def create
    @auction = Auction.find_by!(hashid: params[:auction_hashid])
    @auction_listing = @auction.auction_listings.find_by!(hashid: params[:auction_listing_hashid])

    submitted_amount = params[:amount_cents].to_i
    current_bid = @auction_listing.current_bid

    fallback = auction_path(@auction)

    if current_bid && current_bid.amount_cents >= submitted_amount
      flash.now[:alert] = "Another bid was placed while you were viewing the page. Please try again."
      return respond_with_flash_or_redirect(fallback)
    end

    registration = AuctionRegistration.find_or_create_by!(
      auction: @auction,
      user: Current.user
    )

    bid = @auction_listing.bids.build(
      auction_registration: registration,
      amount_cents: submitted_amount
    )

    if bid.save
      flash.now[:notice] = "Bid of #{helpers.humanized_money_with_symbol(bid.amount)} placed successfully."
      respond_with_flash_or_redirect(fallback)
    else
      flash.now[:alert] = bid.errors.full_messages.join(", ")
      respond_with_flash_or_redirect(fallback)
    end
  end

  private

  def respond_with_flash_or_redirect(fallback)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
      end
      format.html { redirect_back_or_to fallback }
    end
  end
end
