class AuctionReconcilerJob < ApplicationJob
  queue_as :default

  FRESH_LISTING_SELECT = <<~SQL.squish
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

  def perform(auction)
    Current.tenant = auction.tenant

    # Preload documents_attachments so the documents_content_type validation
    # on listing.update! doesn't issue a query per listing.
    ended_listings = auction.auction_listings
      .joins(:listing)
      .where("auction_listings.ends_at <= ?", Time.current)
      .where(listings: { state: "on_sale" })
      .includes(:current_bid, listing: [ :tenant, :rich_text_description, { documents_attachments: :blob }, { watchlist_items: :user } ])

    ended_listings.each do |al|
      new_state = reserve_met?(al) ? :sold : :cancelled
      al.listing.update!(state: new_state)
    end

    broadcast_ended_listings(ended_listings, auction)

    next_end_time = auction.auction_listings
      .joins(:listing)
      .where("auction_listings.ends_at > ?", Time.current)
      .where(listings: { state: "on_sale" })
      .minimum("auction_listings.ends_at")

    if next_end_time
      AuctionReconcilerJob.set(wait_until: next_end_time).perform_later(auction)
    else
      auction.update!(reconciled: true)
      GenerateAuctionInvoicesJob.perform_later(auction)
    end
  end

  private

  def reserve_met?(auction_listing)
    bid = auction_listing.current_bid
    return false unless bid
    return true unless auction_listing.reserve_price_cents.present?

    bid.amount_cents >= auction_listing.reserve_price_cents
  end

  # Batch-load fresh auction listing data for all ended listings, then broadcast.
  # Avoids N+1 from calling fresh_auction_listing + Listing.find per listing.
  def broadcast_ended_listings(ended_listings, auction)
    return if ended_listings.empty?

    ids = ended_listings.map(&:id)

    # Single query for all fresh auction listing rows (with subquery virtual attrs)
    fresh_records = auction.auction_listings
      .select(FRESH_LISTING_SELECT)
      .where(id: ids)
      .to_a

    # Preload current_bid for all fresh records in one query
    ActiveRecord::Associations::Preloader.new(
      records: fresh_records, associations: [:current_bid]
    ).call

    # Batch-load listings with all associations needed by the listing card partial
    listing_ids = fresh_records.map(&:listing_id)
    listings_by_id = Listing
      .with_attached_images
      .with_attached_videos
      .with_rich_text_description
      .includes(:categories, lot: { listing_placeholder_attachment: :blob })
      .where(id: listing_ids)
      .index_by(&:id)

    fresh_records.each do |fresh|
      fresh.listing = listings_by_id[fresh.listing_id]
      broadcast_listing_card(fresh, auction)
      broadcast_bid_panel(fresh, auction)
    end
  end

  def broadcast_listing_card(auction_listing, auction)
    Turbo::StreamsChannel.broadcast_replace_to(
      auction,
      target: ActionView::RecordIdentifier.dom_id(auction_listing),
      partial: "auctions/listing_card",
      locals: { auction_listing:, auction:, registration: nil }
    )
  end

  def broadcast_bid_panel(auction_listing, auction)
    Turbo::StreamsChannel.broadcast_replace_to(
      auction_listing,
      target: ActionView::RecordIdentifier.dom_id(auction_listing, :bid_panel),
      partial: "auction_listings/bid_panel",
      locals: { auction_listing:, auction:, registration: nil, bidder_token: nil }
    )
  end
end
