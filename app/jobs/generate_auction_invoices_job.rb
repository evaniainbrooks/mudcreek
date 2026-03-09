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

    # Pre-fetch existing invoice user_ids for idempotency check (avoids N+1)
    existing_user_ids = Invoice.where(auction: auction).pluck(:user_id).to_set

    wins_by_user.each do |user, items|
      next if existing_user_ids.include?(user.id)

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

      if user.default_square_card_id.present?
        ChargeInvoiceJob.perform_later(invoice.id)
      else
        # Reload with associations to avoid N+1 in the mailer view
        invoice_with_assocs = Invoice.includes(:user, :auction, invoice_items: :listing).find(invoice.id)
        InvoiceMailer.invoice_generated(invoice_with_assocs).deliver_later
      end
    end
  end
end
