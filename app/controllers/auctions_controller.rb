class AuctionsController < ApplicationController
  allow_unauthenticated_access

  def show
    @auction = Auction
      .where(published: true)
      .with_attached_poster
      .with_attached_cover_photo
      .with_rich_text_description
      .includes(:address)
      .find_by!(hashid: params[:hashid])

    listing_ids = @auction.auction_listings.order(:position).pluck(:listing_id)
    listings_by_id = Listing
      .where(id: listing_ids)
      .with_attached_images
      .with_attached_videos
      .with_rich_text_description
      .includes(:rental_rate_plans, :categories, lot: :listing_placeholder_attachment)
      .index_by(&:id)
    @listings = listing_ids.filter_map { listings_by_id[_1] }
  end
end
