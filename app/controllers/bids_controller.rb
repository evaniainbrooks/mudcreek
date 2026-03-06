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
      broadcast_listing_card
      broadcast_bid_panel
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

  def fresh_auction_listing
    @fresh_auction_listing ||= begin
      fresh = @auction.auction_listings
        .select(<<~SQL.squish)
          auction_listings.*,
          COALESCE(
            (SELECT COUNT(*) FROM bids WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'),
            0
          ) as bids_count,
          (
            SELECT auction_registrations.user_id FROM bids
            JOIN auction_registrations ON auction_registrations.id = bids.auction_registration_id
            WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'
            ORDER BY bids.amount_cents DESC, bids.created_at DESC
            LIMIT 1
          ) as highest_bidder_id
        SQL
        .find(@auction_listing.id)

      fresh.listing = Listing
        .with_attached_images
        .with_attached_videos
        .includes(:categories, lot: { listing_placeholder_attachment: :blob })
        .find(@auction_listing.listing_id)

      fresh
    end
  end

  def broadcast_bid_panel
    bidder_token = OpenSSL::HMAC.hexdigest(
      "SHA256", Rails.application.secret_key_base[0, 32], "bid:#{Current.user.id}"
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      @auction_listing,
      target: ActionView::RecordIdentifier.dom_id(fresh_auction_listing, :bid_panel),
      partial: "auction_listings/bid_panel",
      locals: { auction_listing: fresh_auction_listing, auction: @auction, registration: nil, bidder_token: }
    )
  end

  def broadcast_listing_card
    Turbo::StreamsChannel.broadcast_replace_to(
      @auction,
      target: ActionView::RecordIdentifier.dom_id(fresh_auction_listing),
      partial: "auctions/listing_card",
      locals: { auction_listing: fresh_auction_listing, auction: @auction, registration: nil }
    )
  end
end
