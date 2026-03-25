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
      listing.variants.includes(option_values: :option).each do |variant|
        create_variant_listing(listing, variant)
      end
    else
      return unless create_listing(listing)
      listing.update_column(:state, @listing_state) if @listing_state.present?
    end
  end

  def create_variant_listing(listing, variant)
    ordered_ovs = variant.option_values.sort_by { |ov| ov.option.position }
    variant_label = ordered_ovs.map(&:value).join("/")

    new_listing = listing.dup
    new_listing.name = "#{listing.name} (#{variant_label})"
    new_listing.quantity = variant.quantity
    new_listing.sku = variant.sku
    new_listing.price_cents = variant.effective_price_cents
    new_listing.description = listing.description.body if listing.description.present?

    listing.properties.order(:position).each_with_index do |prop, idx|
      new_listing.properties.build(name: prop.name, value: prop.value, icon: prop.icon, position: idx + 1)
    end

    base_position = listing.properties.size
    ordered_ovs.each_with_index do |ov, idx|
      new_listing.properties.build(name: ov.option.name, value: ov.value, position: base_position + idx + 1)
    end

    new_listing.save!

    AuctionListing.create!(
      auction: @auction,
      listing: new_listing,
      starting_bid_cents: compute_starting_bid(variant.effective_price_cents)
    )

    new_listing.update_column(:state, @listing_state) if @listing_state.present?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # skip duplicate or invalid variant listing
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
