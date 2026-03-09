require "rails_helper"

RSpec.describe "Auction bidding and invoice generation", type: :system do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  before { driven_by :rack_test }

  let(:bidder) { create(:user) }
  let(:owner)  { create(:user) }

  let(:auction) do
    create(:auction,
      starts_at:    2.hours.ago,
      ends_at:      1.hour.from_now,
      auto_approve: true,
      published:    true)
  end

  # Listing 1: has a high reserve price — bidder's bid won't meet it → cancelled
  let(:listing1) { create(:listing, state: :on_sale, published: true, owner: owner) }
  # Listing 2: no reserve price — bidder wins it
  let(:listing2) { create(:listing, state: :on_sale, published: true, owner: owner) }

  # ends_at is auto-set to auction.ends_at via initialize_end_time
  let!(:auction_listing1) do
    create(:auction_listing, auction: auction, listing: listing1,
      starting_bid_cents: 1_000, bid_increment_cents: 500,
      reserve_price_cents: 10_000)
  end
  let!(:auction_listing2) do
    create(:auction_listing, auction: auction, listing: listing2,
      starting_bid_cents: 2_000, bid_increment_cents: 500)
  end

  before { ActionMailer::Base.deliveries.clear }

  it "registers, bids on 2 listings, wins 1 (reserve not met on the other), receives an invoice" do
    # --- Register for the auction (auto-approved) ---
    sign_in_as(bidder)
    page.driver.post(auction_auction_registrations_path(auction))

    registration = AuctionRegistration.find_by!(user: bidder, auction: auction)
    expect(registration).to be_approved

    # --- Bid on listing 1 (will not meet reserve) ---
    page.driver.post(
      auction_auction_listing_bids_path(auction, auction_listing1),
      { amount_cents: 1_000 }
    )

    # --- Bid on listing 2 (no reserve — will win) ---
    page.driver.post(
      auction_auction_listing_bids_path(auction, auction_listing2),
      { amount_cents: 2_000 }
    )

    expect(Bid.placed.count).to eq(2)

    # --- Travel past the auction end time and reconcile ---
    travel_to(2.hours.from_now) do
      perform_enqueued_jobs do
        AuctionReconcilerJob.new.perform(auction)
      end
    end

    # Listing 1: reserve not met → cancelled; listing 2: sold
    expect(listing1.reload.state).to eq("cancelled")
    expect(listing2.reload.state).to eq("sold")
    expect(auction.reload).to be_reconciled

    # Invoice covers only listing 2 (the won listing)
    invoice = Invoice.find_by!(user: bidder, auction: auction)
    expect(invoice.total_cents).to eq(2_000)
    expect(invoice.invoice_items.count).to eq(1)
    expect(invoice.invoice_items.first.listing).to eq(listing2)

    # Bidder received an invoice email
    expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(bidder.email_address)

    # Visit the invoice page to verify it renders correctly
    visit invoice_path(invoice)
    expect(page).to have_text(listing2.name)
  end
end
