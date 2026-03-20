class ProxyBiddingService
  def self.resolve(auction_listing)
    new(auction_listing).resolve
  end

  def initialize(auction_listing)
    @listing = auction_listing
  end

  def resolve
    return unless @listing.active?

    proxy_bids = @listing.proxy_bids
      .joins(:auction_registration)
      .where(auction_registrations: { state: "approved" })
      .order(max_bid_cents: :desc, created_at: :asc)

    return if proxy_bids.empty?

    winner    = proxy_bids.first
    runner_up = proxy_bids.second

    current = @listing.bids.where(state: "placed").order(amount_cents: :desc, created_at: :desc).first

    runner_up_max      = runner_up&.max_bid_cents || 0
    manual_challenge   = (current && current.auction_registration_id != winner.auction_registration_id) ?
                           current.amount_cents : 0
    challenge = [ runner_up_max, manual_challenge ].max

    target = if challenge.zero?
      @listing.starting_bid_cents
    else
      inc = increment_for(challenge)
      [ challenge + inc, winner.max_bid_cents ].min
    end

    return if current&.auction_registration_id == winner.auction_registration_id &&
              current.amount_cents == target

    bid = @listing.bids.build(
      auction_registration: winner.auction_registration,
      amount_cents: target
    )
    bid.proxy_placed = true
    bid.save!
  end

  private

  def increment_for(amount_cents)
    schedule = @listing.auction.effective_bid_increment_schedule
    schedule&.increment_for(amount_cents) || 0
  end
end
