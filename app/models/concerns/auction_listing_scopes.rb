module AuctionListingScopes
  extend ActiveSupport::Concern

  included do
    scope :search_listing_name, ->(query) {
      joins(:listing).where("listings.name ILIKE ?", "%#{sanitize_sql_like(query)}%")
    }

    # Lots won by a user: listing sold and user is the highest placed bidder
    scope :won_by, ->(user) {
      joins(:listing)
        .where(listings: { state: "sold" })
        .where(<<~SQL.squish, user.id)
          (
            SELECT auction_registrations.user_id FROM bids
            JOIN auction_registrations ON auction_registrations.id = bids.auction_registration_id
            WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'
            ORDER BY bids.amount_cents DESC, bids.created_at DESC
            LIMIT 1
          ) = ?
        SQL
    }

    # Lots the user has placed at least one bid on
    scope :bid_on_by, ->(user) {
      where(<<~SQL.squish, user.id)
        EXISTS (
          SELECT 1 FROM bids
          JOIN auction_registrations ON auction_registrations.id = bids.auction_registration_id
          WHERE bids.auction_listing_id = auction_listings.id
            AND bids.state = 'placed'
            AND auction_registrations.user_id = ?
        )
      SQL
    }

    scope :on_watchlist_of, ->(user) {
      where(listing_id: WatchlistItem.where(user: user).select(:listing_id))
    }

    scope :by_category, ->(category) {
      where(listing_id: Listing.joins(:categories).where(listings_categories: { id: category.id }).select(:id))
    }

    # Appends per-row bids_count and highest_bidder_id virtual columns
    scope :with_bid_stats, -> {
      select(Arel.sql(<<~SQL.squish))
        auction_listings.*,
        COALESCE(
          (SELECT COUNT(*) FROM bids
           WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'),
          0
        ) AS bids_count,
        (
          SELECT auction_registrations.user_id FROM bids
          JOIN auction_registrations ON auction_registrations.id = bids.auction_registration_id
          WHERE bids.auction_listing_id = auction_listings.id AND bids.state = 'placed'
          ORDER BY bids.amount_cents DESC, bids.created_at DESC
          LIMIT 1
        ) AS highest_bidder_id
      SQL
    }
  end
end
