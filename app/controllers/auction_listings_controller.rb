class AuctionListingsController < ApplicationController
  allow_unauthenticated_access

  def show
    @auction = Auction.where(published: true).find_by!(hashid: params[:auction_hashid])

    @auction_listing = @auction.auction_listings
      .select(<<~SQL.squish)
        auction_listings.*,
        COALESCE(
          (SELECT COUNT(*) FROM bids WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'),
          0
        ) as bids_count
      SQL
      .find_by!(hashid: params[:hashid])

    @next_auction_listing = @auction.auction_listings
      .where("position > ?", @auction_listing.position)
      .order(position: :asc)
      .first

    @registration = AuctionRegistration.find_by(auction: @auction, user: Current.user) if Current.user

    highest_bidder_id = @auction_listing.bids
      .where(state: "placed")
      .order(amount_cents: :desc, created_at: :desc)
      .joins(auction_registration: :user)
      .pick("users.id")

    @highest_bidder_token = highest_bidder_id &&
      OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base[0, 32], "bid:#{highest_bidder_id}")

    @listing = Listing.where(published: true)
      .with_rich_text_description
      .with_attached_images
      .with_attached_videos
      .with_attached_documents
      .includes(:categories, lot: { listing_placeholder_attachment: :blob })
      .find(@auction_listing.listing_id)
  end
end
