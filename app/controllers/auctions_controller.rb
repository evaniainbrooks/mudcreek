class AuctionsController < ApplicationController
  include AuctionFeatureGated
  allow_unauthenticated_access

  def index
    @state           = params[:state].presence_in(%w[live upcoming ended])
    @search          = params[:search].presence
    @category_hashid = params[:category_id].presence
    @categories      = Listings::Category.order(:name)

    base = Auction.where(published: true)
    @filter_total = base.count
    scope = base.with_attached_poster.includes(:address, :auction_listings)

    scope = scope.search_name(@search) if @search

    if @category_hashid
      category = Listings::Category.find_by(hashid: @category_hashid)
      scope = scope.by_category(category) if category
    end

    scope = scope.public_send(@state) if @state

    @registrations_by_auction_id = if Current.user
      AuctionRegistration.where(auction: scope, user: Current.user).index_by(&:auction_id)
    else
      {}
    end

    @auctions = scope.by_status_order
    @filter_count = @auctions.size
  end

  def show
    @auction = Auction
      .where(published: true)
      .with_attached_poster
      .with_attached_terms_and_conditions
      .with_rich_text_description
      .includes(:address)
      .find_by!(hashid: params[:hashid])

    @search          = params[:search].presence
    @listing_state   = params[:state].presence_in(%w[on_sale sold cancelled])
    @filter          = params[:filter].presence_in(%w[my_listings my_bids watchlist]) if Current.user
    @category_hashid = params[:category_id].presence
    @lot_hashid      = params[:lot_id].presence
    @categories      = Listings::Category
      .joins(category_assignments: { listing: :auction_listings })
      .where(auction_listings: { auction_id: @auction.id })
      .distinct
      .order(:name)

    @auction_listing_count = @auction.auction_listings.count

    scope = @auction.auction_listings.joins(:listing)
    scope = scope.search_listing_name(@search) if @search

    case @filter
    when "my_listings" then scope = scope.won_by(Current.user)
    when "my_bids"     then scope = scope.bid_on_by(Current.user)
    when "watchlist"   then scope = scope.on_watchlist_of(Current.user)
    else
      scope = scope.where(listings: { state: @listing_state }) if @listing_state
    end

    if @category_hashid
      category = Listings::Category.find_by(hashid: @category_hashid)
      scope = scope.by_category(category) if category
    end

    if @lot_hashid
      lot = Lot.find_by(hashid: @lot_hashid)
      scope = scope.where(listing_id: lot.listing_ids) if lot
    end

    @auction_listings = scope.with_bid_stats.order(:position).to_a
    listing_ids = @auction_listings.map(&:listing_id)
    listings_by_id = Listing
      .where(id: listing_ids)
      .with_attached_images
      .with_attached_videos
      .with_rich_text_description
      .includes(:rental_rate_plans, :categories, lot: [ :owner, :address, :listing_placeholder_attachment ])
      .index_by(&:id)
    @auction_listings.each { |al| al.listing = listings_by_id[al.listing_id] }
    @auction_listings.select!(&:listing)
    @filter_count = @auction_listings.size

    @registration = AuctionRegistration.find_by(auction: @auction, user: Current.user) if Current.user

    @proxy_bids_by_listing_id = if Current.user && @registration
      ProxyBid.where(
        auction_listing_id: @auction_listings.map(&:id),
        auction_registration: @registration
      ).index_by(&:auction_listing_id)
    else
      {}
    end
  end
end
