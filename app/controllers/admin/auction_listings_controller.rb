class Admin::AuctionListingsController < Admin::BaseController
  def create
    authorize(AuctionListing)
    auction = Auction.find(params[:auction_id])
    listings = Listing.sale.where(id: Array(params[:listing_ids]).map(&:to_i))

    new_state = params[:listing_state].presence

    listings.each do |listing|
      starting_bid_cents = compute_starting_bid(listing.price_cents)

      AuctionListing.create!(
        auction: auction,
        listing_id: listing.id,
        starting_bid_cents: starting_bid_cents
      )
      listing.update_column(:state, new_state) if new_state.present?
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      next
    end

    auction_link = view_context.link_to(auction.name, admin_auction_path(auction))
    redirect_to admin_listings_path, notice: "Listings added to #{auction_link}.".html_safe
  end

  private

  def compute_starting_bid(price_cents)
    case params[:starting_bid]
    when "50"     then (price_cents * 0.5).ceil
    when "10"     then (price_cents * 0.1).ceil
    when "dollar" then 100
    else price_cents
    end
  end
end
