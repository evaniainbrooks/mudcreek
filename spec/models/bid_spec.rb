require "rails_helper"

RSpec.describe Bid, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction)      { create(:auction, starts_at: 1.hour.ago, ends_at: 1.day.from_now) }
  let(:listing)      { create(:listing) }
  let(:schedule)     { create(:bid_increment_schedule, auction: auction) }
  let(:auction_listing) do
    create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000)
  end
  let(:bidder)       { create(:user) }
  let(:registration) do
    AuctionRegistration.create!(auction: auction, user: bidder, state: :approved)
  end

  before do
    create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 0, increment_cents: 500)
    schedule.tiers.reset
    auction_listing
  end

  describe "associations" do
    it { is_expected.to belong_to(:auction_registration) }
    it { is_expected.to belong_to(:auction_listing) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount_cents) }

    it "rejects a zero amount" do
      bid = build(:bid, auction_registration: registration, auction_listing: auction_listing, amount_cents: 0)
      expect(bid).not_to be_valid
      expect(bid.errors[:amount_cents]).to be_present
    end
  end

  describe "custom validations on create" do
    describe "registration_must_be_approved" do
      it "rejects a bid from a pending registration" do
        pending_reg = AuctionRegistration.create!(auction: auction, user: create(:user), state: :pending)
        bid = Bid.new(auction_registration: pending_reg, auction_listing: auction_listing, amount_cents: 1000)
        expect(bid).not_to be_valid
        expect(bid.errors[:auction_registration]).to be_present
      end

      it "accepts a bid from an approved registration" do
        bid = Bid.new(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
        expect(bid).to be_valid
      end
    end

    describe "listing_must_be_biddable" do
      it "rejects a bid when the auction listing is not active" do
        listing.update_column(:state, "sold")
        bid = Bid.new(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
        expect(bid).not_to be_valid
        expect(bid.errors[:base]).to include("bidding is not currently open for this listing")
      end
    end

    describe "listing_must_have_bid_configuration" do
      it "rejects a bid when there is no bid increment schedule" do
        schedule.destroy!
        Current.tenant.update_column(:default_bid_increment_schedule_id, nil) if Current.tenant.respond_to?(:default_bid_increment_schedule_id)
        auction.reload
        bid = Bid.new(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
        expect(bid).not_to be_valid
        expect(bid.errors[:base]).to include("this listing does not have a bid increment configured")
      end
    end

    describe "cannot_outbid_yourself" do
      it "rejects a second bid from the current highest bidder" do
        Bid.create!(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
        auction_listing.reload
        next_amount = auction_listing.next_bid_amount.cents
        second = Bid.new(auction_registration: registration, auction_listing: auction_listing, amount_cents: next_amount)
        expect(second).not_to be_valid
        expect(second.errors[:base]).to include("you are already the highest bidder")
      end
    end

    describe "amount_must_equal_next_bid_amount" do
      it "rejects an amount that does not match the expected next bid" do
        bid = Bid.new(auction_registration: registration, auction_listing: auction_listing, amount_cents: 999)
        expect(bid).not_to be_valid
        expect(bid.errors[:amount]).to be_present
      end

      it "accepts the exact next bid amount" do
        bid = Bid.new(auction_registration: registration, auction_listing: auction_listing, amount_cents: 1000)
        expect(bid).to be_valid
      end
    end
  end
end
