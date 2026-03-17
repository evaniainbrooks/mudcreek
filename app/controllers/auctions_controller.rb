class AuctionsController < ApplicationController
  allow_unauthenticated_access

  def index
    @state           = params[:state].presence_in(%w[live upcoming ended])
    @search          = params[:search].presence
    @category_hashid = params[:category_id].presence
    @categories      = Listings::Category.order(:name)

    base = Auction.where(published: true)
    @filter_total = base.count
    scope = base.with_attached_poster.includes(:address)

    scope = scope.where("auctions.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(@search)}%") if @search

    if @category_hashid
      category = Listings::Category.find_by(hashid: @category_hashid)
      scope = scope.where(id: Auction.joins(listings: :categories).where(listings_categories: { id: category.id }).select(:id)) if category
    end

    scope = case @state
    when "live"     then scope.where("starts_at <= NOW() AND ends_at > NOW()")
    when "upcoming" then scope.where("starts_at > NOW()")
    when "ended"    then scope.where("ends_at < NOW()")
    else scope
    end

    @registrations_by_auction_id = if Current.user
      AuctionRegistration.where(auction: scope, user: Current.user).index_by(&:auction_id)
    else
      {}
    end

    @auctions = scope.order(Arel.sql(<<~SQL.squish))
      CASE
        WHEN starts_at <= NOW() AND ends_at > NOW() THEN 0
        WHEN starts_at > NOW() THEN 1
        ELSE 2
      END,
      starts_at ASC
    SQL
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
    @categories      = Listings::Category
      .joins(category_assignments: { listing: :auction_listings })
      .where(auction_listings: { auction_id: @auction.id })
      .distinct
      .order(:name)

    @auction_listing_count = @auction.auction_listings.count

    scope = @auction.auction_listings.joins(:listing)
    scope = scope.where("listings.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(@search)}%") if @search
    case @filter
    when "my_listings"
      scope = scope.where(listings: { state: "sold" }).where(<<~SQL.squish, Current.user.id)
        (
          SELECT auction_registrations.user_id FROM bids
          JOIN auction_registrations ON auction_registrations.id = bids.auction_registration_id
          WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'
          ORDER BY bids.amount_cents DESC, bids.created_at DESC
          LIMIT 1
        ) = ?
      SQL
    when "my_bids"
      scope = scope.where(<<~SQL.squish, Current.user.id)
        EXISTS (
          SELECT 1 FROM bids
          JOIN auction_registrations ON auction_registrations.id = bids.auction_registration_id
          WHERE bids.auction_listing_id = auction_listings.id
            AND bids.state = 'placed'
            AND auction_registrations.user_id = ?
        )
      SQL
    when "watchlist"
      scope = scope.where(
        listing_id: WatchlistItem.where(user: Current.user).select(:listing_id)
      )
    else
      scope = scope.where(listings: { state: @listing_state }) if @listing_state
    end
    if @category_hashid
      category = Listings::Category.find_by(hashid: @category_hashid)
      scope = scope.where(listing_id: Listing.joins(:categories).where(listings_categories: { id: category.id }).select(:id)) if category
    end

    @auction_listings = scope
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
      .order(:position).to_a
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
    @filter_count = @auction_listings.size

    @registration = AuctionRegistration.find_by(auction: @auction, user: Current.user) if Current.user
  end
end
