require "rails_helper"

RSpec.describe ProxyBid, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:auction)      { create(:auction, starts_at: 1.hour.ago, ends_at: 1.day.from_now) }
  let(:listing)      { create(:listing) }
  let!(:schedule) do
    s = BidIncrementSchedule.create!(auction_id: nil)
    s.tiers.create!(min_amount_cents: 0, increment_cents: 500)
    s
  end
  let!(:auction_listing) { create(:auction_listing, auction: auction, listing: listing, starting_bid_cents: 1000) }
  let(:bidder)       { create(:user) }
  let(:registration) { AuctionRegistration.create!(auction: auction, user: bidder, state: :approved) }

  def valid_proxy_bid(attrs = {})
    ProxyBid.new({ auction_listing: auction_listing, auction_registration: registration, max_bid_cents: 1000 }.merge(attrs))
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(valid_proxy_bid).to be_valid
    end

    it "requires max_bid_cents" do
      proxy = valid_proxy_bid(max_bid_cents: nil)
      expect(proxy).not_to be_valid
      expect(proxy.errors[:max_bid_cents]).to be_present
    end

    it "rejects zero max_bid_cents" do
      proxy = valid_proxy_bid(max_bid_cents: 0)
      expect(proxy).not_to be_valid
      expect(proxy.errors[:max_bid_cents]).to be_present
    end

    it "rejects negative max_bid_cents" do
      proxy = valid_proxy_bid(max_bid_cents: -100)
      expect(proxy).not_to be_valid
      expect(proxy.errors[:max_bid_cents]).to be_present
    end

    it "rejects max below the listing minimum" do
      proxy = valid_proxy_bid(max_bid_cents: 999)
      expect(proxy).not_to be_valid
      expect(proxy.errors[:max_bid]).to be_present
    end

    it "rejects a bid from a pending registration" do
      pending_reg = AuctionRegistration.create!(auction: auction, user: create(:user), state: :pending)
      proxy = valid_proxy_bid(auction_registration: pending_reg)
      expect(proxy).not_to be_valid
      expect(proxy.errors[:auction_registration]).to be_present
    end

    it "enforces uniqueness per listing and registration" do
      valid_proxy_bid.save!
      duplicate = valid_proxy_bid
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "associations" do
    it "belongs to an auction_listing" do
      proxy = valid_proxy_bid
      proxy.save!
      expect(proxy.auction_listing).to eq(auction_listing)
    end

    it "belongs to an auction_registration" do
      proxy = valid_proxy_bid
      proxy.save!
      expect(proxy.auction_registration).to eq(registration)
    end
  end
end
