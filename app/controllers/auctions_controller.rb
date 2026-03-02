class AuctionsController < ApplicationController
  allow_unauthenticated_access

  def show
    @auction = Auction
      .where(published: true)
      .with_attached_poster
      .with_rich_text_description
      .includes(:address)
      .find_by!(hashid: params[:hashid])

    @auction_listings = @auction.auction_listings.order(:position).to_a
    listing_ids = @auction_listings.map(&:listing_id)
    listings_by_id = Listing
      .where(id: listing_ids)
      .with_attached_images
      .with_attached_videos
      .with_rich_text_description
      .includes(:rental_rate_plans, :categories, lot: :listing_placeholder_attachment)
      .index_by(&:id)
    @auction_listings.each { |al| al.listing = listings_by_id[al.listing_id] }
    @auction_listings.select!(&:listing)
  end
end
