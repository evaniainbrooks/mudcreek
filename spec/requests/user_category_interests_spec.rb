require "rails_helper"

RSpec.describe "UserCategoryInterests", type: :request do
  before do
    host! "example.com"
    Current.tenant = Tenant.create!(key: "test", name: "Test", default: true)
  end

  let(:category) { create(:listings_category) }

  # ─────────────────────────────────────────────────────────────────────────────
  # Order paid (admin action)
  # ─────────────────────────────────────────────────────────────────────────────
  describe "PATCH /admin/orders/:number — order paid" do
    let(:role) do
      Role.create!(name: "order_manager", description: "Manage orders").tap do |r|
        r.permissions.create!(resource: "Order", action: "index")
        r.permissions.create!(resource: "Order", action: "show")
        r.permissions.create!(resource: "Order", action: "update")
      end
    end

    let(:admin)   { create(:user, role: role) }
    let(:buyer)   { create(:user) }
    let(:listing) { create(:listing) }
    let!(:order)  { create(:order, user: buyer) }

    before do
      listing.categories << category
      order.order_items.create!(listing: listing, name: listing.name, price_cents: listing.price_cents)
      post session_path, params: { email_address: admin.email_address, password: "password" }
    end

    it "records a category interest for the buyer when the order is marked paid" do
      expect {
        patch admin_order_path(order), params: { order: { status: "paid" } }
      }.to change(UserCategoryInterest, :count).by(1)

      interest = UserCategoryInterest.last
      expect(interest.user).to eq(buyer)
      expect(interest.category).to eq(category)
    end

    it "does not record interest when status changes to something other than paid" do
      expect {
        patch admin_order_path(order), params: { order: { status: "cancelled" } }
      }.not_to change(UserCategoryInterest, :count)
    end

    it "skips order items without a listing" do
      order.order_items.first.update_columns(listing_id: nil)

      expect {
        patch admin_order_path(order), params: { order: { status: "paid" } }
      }.not_to change(UserCategoryInterest, :count)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Offer created (public action)
  # ─────────────────────────────────────────────────────────────────────────────
  describe "POST /listings/:listing_hashid/offers — offer submitted" do
    let(:user)    { create(:user) }
    let(:listing) { create(:listing, pricing_type: :negotiable) }

    before do
      listing.categories << category
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

    it "records a category interest when an offer is submitted" do
      expect {
        post listing_offers_path(listing), params: { offer: { amount: "50.00" } }
      }.to change(UserCategoryInterest, :count).by(1)

      interest = UserCategoryInterest.last
      expect(interest.user).to eq(user)
      expect(interest.category).to eq(category)
    end

    it "does not create a duplicate interest on a second offer for the same listing" do
      post listing_offers_path(listing), params: { offer: { amount: "50.00" } }

      expect {
        post listing_offers_path(listing), params: { offer: { amount: "75.00" } }
      }.not_to change(UserCategoryInterest, :count)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Auction reconciled (admin action)
  # ─────────────────────────────────────────────────────────────────────────────
  describe "PATCH /admin/auctions/:hashid — auction reconciled" do
    let(:role) do
      Role.create!(name: "auction_manager", description: "Manage auctions").tap do |r|
        r.permissions.create!(resource: "Auction", action: "index")
        r.permissions.create!(resource: "Auction", action: "show")
        r.permissions.create!(resource: "Auction", action: "update")
      end
    end

    let(:admin)           { create(:user, role: role) }
    let(:bidder)          { create(:user) }
    let(:auction)         { create(:auction, starts_at: 2.hours.ago, ends_at: 1.hour.from_now) }
    let(:listing)         { create(:listing) }
    let(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }
    let(:registration)    { AuctionRegistration.create!(auction: auction, user: bidder, state: :approved) }
    let(:schedule)        { create(:bid_increment_schedule, auction: auction) }

    before do
      listing.categories << category
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 0, increment_cents: 500)
      schedule.tiers.reset
      Bid.create!(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
      post session_path, params: { email_address: admin.email_address, password: "password" }
    end

    it "records a category interest for each bidder when the auction is reconciled" do
      expect {
        patch admin_auction_path(auction), params: { auction: { reconciled: true } }
      }.to change(UserCategoryInterest, :count).by(1)

      interest = UserCategoryInterest.last
      expect(interest.user).to eq(bidder)
      expect(interest.category).to eq(category)
    end

    it "does not record interest when other attributes change" do
      expect {
        patch admin_auction_path(auction), params: { auction: { name: "Updated Name" } }
      }.not_to change(UserCategoryInterest, :count)
    end

    it "is idempotent — reconciling again does not create duplicate interests" do
      patch admin_auction_path(auction), params: { auction: { reconciled: true } }

      auction.update_column(:reconciled, false)

      expect {
        patch admin_auction_path(auction), params: { auction: { reconciled: true } }
      }.not_to change(UserCategoryInterest, :count)
    end
  end
end
