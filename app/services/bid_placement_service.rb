class BidPlacementService
  AuctionEnded = Class.new(StandardError)

  def self.call(listing:, user:, amount:)
    raise AuctionEnded if Time.current >= listing.ends_at

    bid = listing.bids.create!(
      user: user,
      amount: amount
    )

    extend_if_needed(listing)

    bid
  end

  def self.extend_if_needed(listing)
    Listing.where(id: listing.id)
      .where("NOW() >= ends_at - interval '2 minutes'")
      .update_all(<<~SQL)
        ends_at = ends_at + interval '5 minutes',
        extension_count = extension_count + 1
      SQL
  end
end
