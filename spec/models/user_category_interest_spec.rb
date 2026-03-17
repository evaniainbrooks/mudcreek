require "rails_helper"

RSpec.describe UserCategoryInterest, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user)     { create(:user) }
  let(:listing)  { create(:listing) }
  let(:category) { create(:listings_category) }

  before { listing.categories << category }

  describe ".record_for" do
    it "creates an interest row for each category on the listing" do
      expect {
        UserCategoryInterest.record_for(user: user, listing: listing)
      }.to change(UserCategoryInterest, :count).by(1)

      interest = UserCategoryInterest.last
      expect(interest.user).to eq(user)
      expect(interest.category).to eq(category)
    end

    it "creates one row per category when a listing has multiple categories" do
      other = create(:listings_category)
      listing.categories << other

      expect {
        UserCategoryInterest.record_for(user: user, listing: listing)
      }.to change(UserCategoryInterest, :count).by(2)
    end

    it "is idempotent — duplicate calls do not raise or create extra rows" do
      UserCategoryInterest.record_for(user: user, listing: listing)

      expect {
        UserCategoryInterest.record_for(user: user, listing: listing)
      }.not_to change(UserCategoryInterest, :count)
    end

    it "does nothing when the listing has no categories" do
      listing.categories.clear

      expect {
        UserCategoryInterest.record_for(user: user, listing: listing)
      }.not_to change(UserCategoryInterest, :count)
    end

    it "records interests for different users independently" do
      other_user = create(:user)
      UserCategoryInterest.record_for(user: user, listing: listing)

      expect {
        UserCategoryInterest.record_for(user: other_user, listing: listing)
      }.to change(UserCategoryInterest, :count).by(1)
    end
  end

  describe "User#interested_categories" do
    it "returns the categories the user has expressed interest in" do
      UserCategoryInterest.record_for(user: user, listing: listing)
      expect(user.interested_categories).to include(category)
    end
  end

  describe "Listings::Category#interested_users" do
    it "returns users who have expressed interest in the category" do
      UserCategoryInterest.record_for(user: user, listing: listing)
      expect(category.interested_users).to include(user)
    end
  end
end

RSpec.describe "Category interest recording", type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:category) { create(:listings_category) }

  describe "on Order paid" do
    let(:user)    { create(:user) }
    let(:listing) { create(:listing) }
    let(:order)   { create(:order, user: user) }

    before { listing.categories << category }

    it "records interest for each listing's categories when the order is paid" do
      order.order_items.create!(listing: listing, name: listing.name, price_cents: listing.price_cents)

      expect {
        order.update!(status: :paid)
      }.to change(UserCategoryInterest, :count).by(1)
    end

    it "does not record interest when status changes to something other than paid" do
      order.order_items.create!(listing: listing, name: listing.name, price_cents: listing.price_cents)

      expect {
        order.update!(status: :cancelled)
      }.not_to change(UserCategoryInterest, :count)
    end

    it "skips order items without a listing" do
      order.order_items.create!(listing: nil, name: "Shipping", price_cents: 500)

      expect {
        order.update!(status: :paid)
      }.not_to change(UserCategoryInterest, :count)
    end
  end

  describe "on Offer created" do
    let(:user)    { create(:user) }
    let(:listing) { create(:listing) }

    before { listing.categories << category }

    it "records interest when an offer is submitted" do
      expect {
        Offer.create!(user: user, listing: listing, amount_cents: 500)
      }.to change(UserCategoryInterest, :count).by(1)
    end

    it "does not duplicate interest on a second offer for the same listing" do
      Offer.create!(user: user, listing: listing, amount_cents: 500)

      expect {
        Offer.create!(user: user, listing: listing, amount_cents: 600)
      }.not_to change(UserCategoryInterest, :count)
    end
  end

  describe "on Auction reconciled" do
    # Auction starts in the past and ends in the future so bids are valid at setup time.
    let(:auction)         { create(:auction, starts_at: 2.hours.ago, ends_at: 1.hour.from_now) }
    let(:listing)         { create(:listing) }
    let(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }
    let(:bidder)          { create(:user) }
    let(:registration)    { AuctionRegistration.create!(auction: auction, user: bidder, state: :approved) }
    let(:schedule)        { create(:bid_increment_schedule, auction: auction) }

    before do
      listing.categories << category
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 0, increment_cents: 500)
      schedule.tiers.reset
      Bid.create!(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
    end

    it "records interest for each bidder when the auction is reconciled" do
      expect {
        auction.update!(reconciled: true)
      }.to change(UserCategoryInterest, :count).by(1)

      interest = UserCategoryInterest.last
      expect(interest.user).to eq(bidder)
      expect(interest.category).to eq(category)
    end

    it "does not record interest when other attributes change" do
      expect {
        auction.update!(name: "New Name")
      }.not_to change(UserCategoryInterest, :count)
    end

    it "records interest for multiple bidders" do
      other_bidder  = create(:user)
      other_reg     = AuctionRegistration.create!(auction: auction, user: other_bidder, state: :approved)
      other_listing = create(:listing)
      other_listing.categories << category
      other_al = create(:auction_listing, auction: auction, listing: other_listing, starting_bid_cents: 1000)
      Bid.create!(auction_registration: other_reg, auction_listing: other_al, amount_cents: 1000)

      expect {
        auction.update!(reconciled: true)
      }.to change(UserCategoryInterest, :count).by(2)
    end

    it "is idempotent if reconciled is set again" do
      auction.update!(reconciled: true)

      expect {
        auction.update_column(:reconciled, false)
        auction.update!(reconciled: true)
      }.not_to change(UserCategoryInterest, :count)
    end
  end
end
