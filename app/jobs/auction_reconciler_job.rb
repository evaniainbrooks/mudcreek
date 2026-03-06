class AuctionReconcilerJob < ApplicationJob
  queue_as :default

  def perform(auction)
    Current.tenant = auction.tenant

    ended_listings = auction.auction_listings
      .joins(:listing)
      .where("auction_listings.ends_at <= ?", Time.current)
      .where(listings: { state: "on_sale" })
      .includes(:current_bid, :listing)

    ended_listings.each do |al|
      new_state = reserve_met?(al) ? :sold : :cancelled
      al.listing.update!(state: new_state)
      fresh = fresh_auction_listing(al, auction)
      broadcast_listing_card(fresh, auction)
      broadcast_bid_panel(fresh, auction)
    end

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

  def fresh_auction_listing(auction_listing, auction)
    fresh = auction.auction_listings
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
      .find(auction_listing.id)

    fresh.listing = Listing
      .with_attached_images
      .with_attached_videos
      .includes(:categories, lot: { listing_placeholder_attachment: :blob })
      .find(auction_listing.listing_id)

    fresh
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
