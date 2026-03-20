class BidBroadcastService
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

  def self.call(data)
    new(data).call
  end

  def initialize(data)
    @data = data
  end

  def call
    return unless @data["state"] == "placed"

    auction_listing = fetch_auction_listing
    return unless auction_listing

    auction = auction_listing.auction
    Current.tenant = auction.tenant

    extend_if_needed(auction_listing, auction)

    broadcast_listing_card(auction_listing, auction)
    broadcast_bid_panel(auction_listing, auction)
  end

  private

  def fetch_auction_listing
    auction_listing = AuctionListing
      .select(FRESH_LISTING_SELECT)
      .includes(auction: :tenant)
      .find_by(id: @data["auction_listing_id"])

    return nil unless auction_listing

    auction_listing.listing = Listing
      .with_attached_images
      .with_attached_videos
      .includes(:categories, lot: { listing_placeholder_attachment: :blob })
      .find(auction_listing.listing_id)

    auction_listing
  end

  # If the bid landed within the extension window, push ends_at out
  # and keep the in-memory object in sync so the broadcast reflects the new time.
  def extend_if_needed(auction_listing, auction)
    extension = auction.bidding_extension.to_i
    return if extension.zero?

    rows_updated = AuctionListing
      .where(id: auction_listing.id)
      .where("ends_at IS NOT NULL AND NOW() >= ends_at - (? * interval '1 second')", extension)
      .update_all(
        "ends_at = ends_at + (#{extension} * interval '1 second'), " \
        "extension_count = extension_count + 1"
      )

    if rows_updated > 0
      auction_listing.ends_at += extension.seconds
      auction_listing.extension_count += 1
    end
  end

  def broadcast_listing_card(auction_listing, auction)
    html = renderer(auction.tenant).render(
      partial: "auctions/listing_card",
      locals: { auction_listing:, auction:, registration: nil, proxy_bids_by_listing_id: nil }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      auction,
      target: ActionView::RecordIdentifier.dom_id(auction_listing),
      html:
    )
  end

  def broadcast_bid_panel(auction_listing, auction)
    html = renderer(auction.tenant).render(
      partial: "auction_listings/bid_panel",
      locals: { auction_listing:, auction:, registration: nil, bidder_token: bidder_token_for(auction_listing.highest_bidder_id), proxy_bid: nil }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      auction_listing,
      target: ActionView::RecordIdentifier.dom_id(auction_listing, :bid_panel),
      html:
    )
  end

  def bidder_token_for(user_id)
    return nil unless user_id
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base[0, 32], "bid:#{user_id}")
  end

  def renderer(tenant)
    host = tenant&.custom_domain.presence
    return ApplicationController.renderer unless host

    ApplicationController.renderer.new("HTTP_HOST" => host)
  end
end
