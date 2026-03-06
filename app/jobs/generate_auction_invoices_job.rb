class GenerateAuctionInvoicesJob < ApplicationJob
  queue_as :default

  def perform(auction)
    Current.tenant = auction.tenant

    sold_listings = auction.auction_listings
      .joins(:listing)
      .where(listings: { state: "sold" })
      .includes(:listing, bids: { auction_registration: :user })

    # Group won listings by winning bidder
    wins_by_user = Hash.new { |h, k| h[k] = [] }

    sold_listings.each do |al|
      winning_bid = al.bids
        .select { |b| b.state == "placed" }
        .max_by { |b| [ b.amount_cents, -b.created_at.to_i ] }
      next unless winning_bid

      user = winning_bid.auction_registration.user
      wins_by_user[user] << { listing: al.listing, amount_cents: winning_bid.amount_cents }
    end

    wins_by_user.each do |user, items|
      # Skip if an invoice already exists for this user/auction (idempotency)
      next if Invoice.exists?(user: user, auction: auction)

      invoice = Invoice.create!(
        user: user,
        auction: auction,
        total_cents: items.sum { |i| i[:amount_cents] }
      )

      items.each do |item|
        invoice.invoice_items.create!(
          listing: item[:listing],
          name: item[:listing].name,
          amount_cents: item[:amount_cents]
        )
      end

      InvoiceMailer.invoice_generated(invoice).deliver_later
    end
  end
end
