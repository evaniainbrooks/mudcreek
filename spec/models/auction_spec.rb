require "rails_helper"

RSpec.describe Auction, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  def build_auction(attrs = {})
    Auction.new({ name: "Spring Auction", starts_at: 1.hour.from_now, ends_at: 2.hours.from_now }.merge(attrs))
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "rejects a negative buyers_premium_rate" do
      expect(build_auction(buyers_premium_rate: -1)).not_to be_valid
    end

    it "rejects a negative bidding_extension" do
      expect(build_auction(bidding_extension: -1)).not_to be_valid
    end

    it "rejects a non-integer end_time_stagger_interval" do
      expect(build_auction(end_time_stagger_interval: 1.5)).not_to be_valid
    end

    it "rejects a stagger interval between 1 and 29 seconds" do
      auction = build_auction(end_time_stagger_interval: 10)
      expect(auction).not_to be_valid
      expect(auction.errors[:end_time_stagger_interval]).to be_present
    end

    it "accepts a stagger interval of 0 (disabled)" do
      expect(build_auction(end_time_stagger_interval: 0)).to be_valid
    end

    it "accepts a stagger interval of 30 or more" do
      expect(build_auction(end_time_stagger_interval: 30)).to be_valid
    end
  end

  describe "ends_at_after_starts_at" do
    it "rejects ends_at before starts_at" do
      auction = build_auction(starts_at: 2.hours.from_now, ends_at: 1.hour.from_now)
      expect(auction).not_to be_valid
      expect(auction.errors[:ends_at]).to be_present
    end

    it "rejects ends_at equal to starts_at" do
      t = 1.hour.from_now
      auction = build_auction(starts_at: t, ends_at: t)
      expect(auction).not_to be_valid
    end

    it "accepts ends_at after starts_at" do
      expect(build_auction).to be_valid
    end
  end

  describe "stagger_interval_immutable_after_start" do
    it "rejects changing the stagger interval after the auction has started" do
      auction = create(:auction, starts_at: 2.hours.ago, ends_at: 1.hour.from_now,
                       end_time_stagger_interval: 0)
      auction.end_time_stagger_interval = 60
      expect(auction).not_to be_valid
      expect(auction.errors[:end_time_stagger_interval]).to be_present
    end

    it "allows changing the stagger interval before the auction starts" do
      auction = create(:auction, starts_at: 2.hours.from_now, ends_at: 4.hours.from_now,
                       end_time_stagger_interval: 0)
      auction.end_time_stagger_interval = 60
      expect(auction).to be_valid
    end
  end

  describe "#started?" do
    it "returns true when starts_at is in the past" do
      auction = build_auction(starts_at: 1.minute.ago)
      expect(auction.started?).to be true
    end

    it "returns false when starts_at is in the future" do
      auction = build_auction(starts_at: 1.minute.from_now)
      expect(auction.started?).to be false
    end
  end

  describe "#ended?" do
    it "returns true when ends_at is in the past" do
      auction = build_auction(ends_at: 1.minute.ago)
      expect(auction.ended?).to be true
    end

    it "returns false when ends_at is in the future" do
      auction = build_auction(ends_at: 1.minute.from_now)
      expect(auction.ended?).to be false
    end
  end
end
