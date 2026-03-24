class AddListingsToAuctionService
  def self.call(auction:, listings:, starting_bid:, listing_state: nil)
    new(auction: auction, listings: listings, starting_bid: starting_bid, listing_state: listing_state).call
  end

  def initialize(auction:, listings:, starting_bid:, listing_state: nil)
    @auction = auction
    @listings = listings
    @starting_bid = starting_bid
    @listing_state = listing_state
  end

  def call
    @listings.each { |listing| add_listing(listing) }
  end

  private

  def add_listing(listing)
    if listing.has_variants?
      listing.variants.each { |variant| create_variant_listing(listing, variant) }
      listing.update_column(:state, @listing_state) if @listing_state.present?
    else
      return unless create_listing(listing)
      listing.update_column(:state, @listing_state) if @listing_state.present?
    end
  end

  def create_variant_listing(listing, variant)
    AuctionListing.create!(
      auction: @auction,
      listing: listing,
      variant: variant,
      starting_bid_cents: compute_starting_bid(variant.effective_price_cents)
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # skip duplicate or invalid variant
  end

  def create_listing(listing)
    AuctionListing.create!(
      auction: @auction,
      listing: listing,
      starting_bid_cents: compute_starting_bid(listing.price_cents)
    )
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    false
  end

  def compute_starting_bid(price_cents)
    case @starting_bid
    when "50"     then (price_cents * 0.5).ceil
    when "10"     then (price_cents * 0.1).ceil
    when "dollar" then 100
    else               price_cents
    end
  end
end
