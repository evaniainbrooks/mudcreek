require "rails_helper"

RSpec.describe AuctionListing, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction)         { create(:auction, starts_at: 1.hour.ago, ends_at: 1.day.from_now) }
  let(:listing)         { create(:listing) }
  let(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 5000) }

  describe "associations" do
    it { is_expected.to belong_to(:auction) }
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to have_many(:bids).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:starting_bid_cents) }

    it "rejects a negative starting bid" do
      al = build(:auction_listing, starting_bid_cents: -1)
      expect(al).not_to be_valid
      expect(al.errors[:starting_bid_cents]).to be_present
    end

    it "accepts a zero starting bid" do
      al = build(:auction_listing, starting_bid_cents: 0)
      expect(al).to be_valid
    end

    it "rejects a duplicate listing" do
      auction_listing
      duplicate = build(:auction_listing, listing: listing)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:listing_id]).to be_present
    end
  end

  describe "#active?" do
    it "returns true when listing is on_sale, ends_at is in the future and auction has started" do
      expect(auction_listing.active?).to be true
    end

    it "returns false when the listing is not on_sale" do
      listing.update_column(:state, "sold")
      expect(auction_listing.active?).to be false
    end

    it "returns false when ends_at is in the past" do
      auction_listing.update_column(:ends_at, 1.minute.ago)
      expect(auction_listing.active?).to be false
    end

    it "returns false when ends_at is nil" do
      auction_listing.update_column(:ends_at, nil)
      expect(auction_listing.active?).to be false
    end

    it "returns false when the auction has not started yet" do
      auction.update_columns(starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
      auction_listing.update_column(:ends_at, 2.hours.from_now)
      expect(auction_listing.active?).to be false
    end

    it "returns true when auction starts_at is nil" do
      auction.update_column(:starts_at, nil)
      expect(auction_listing.active?).to be true
    end
  end

  describe "#next_bid_amount" do
    context "with no current bid" do
      it "returns the starting bid as a Money object" do
        expect(auction_listing.next_bid_amount.cents).to eq(5000)
      end
    end

    context "with a current bid and an increment schedule" do
      let(:schedule) { create(:bid_increment_schedule, auction: auction) }

      before do
        create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 0, increment_cents: 500)
        schedule.tiers.reset
        registration = AuctionRegistration.create!(auction: auction, user: create(:user), state: :approved)
        Bid.create!(
          auction_registration: registration,
          auction_listing: auction_listing,
          amount_cents: 5000,
          state: :placed
        )
        auction_listing.reload
      end

      it "returns current bid amount plus the increment" do
        expect(auction_listing.next_bid_amount.cents).to eq(5500)
      end
    end
  end
end
