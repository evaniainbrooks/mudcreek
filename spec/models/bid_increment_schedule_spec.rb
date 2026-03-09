require "rails_helper"

RSpec.describe BidIncrementSchedule, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:auction).optional }
    it { is_expected.to have_many(:tiers).class_name("BidIncrementTier").dependent(:destroy) }
  end

  describe "tiers ordering" do
    it "returns tiers ordered by min_amount_cents ascending" do
      schedule = create(:bid_increment_schedule)
      t3 = create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 50_000, increment_cents: 5_000)
      t1 = create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents:      0, increment_cents:   500)
      t2 = create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 10_000, increment_cents: 1_000)

      expect(schedule.tiers.to_a).to eq([t1, t2, t3])
    end
  end

  describe "#increment_for" do
    subject(:schedule) { create(:bid_increment_schedule) }

    before do
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents:      0, increment_cents:   500)
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 10_000, increment_cents: 1_000)
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 25_000, increment_cents: 2_500)
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 50_000, increment_cents: 5_000)
      schedule.tiers.reset
    end

    it "returns the increment for a bid exactly at a tier boundary" do
      expect(schedule.increment_for(0)).to eq(500)
    end

    it "returns the increment for a bid within the first tier" do
      expect(schedule.increment_for(9_999)).to eq(500)
    end

    it "returns the higher increment when crossing into the next tier" do
      expect(schedule.increment_for(10_000)).to eq(1_000)
    end

    it "returns the increment for a bid mid-tier" do
      expect(schedule.increment_for(15_000)).to eq(1_000)
    end

    it "returns the increment for the highest tier" do
      expect(schedule.increment_for(50_000)).to eq(5_000)
    end

    it "returns the highest increment for amounts above all tier boundaries" do
      expect(schedule.increment_for(999_999)).to eq(5_000)
    end

    it "returns 0 when there are no tiers" do
      empty_schedule = create(:bid_increment_schedule)

      expect(empty_schedule.increment_for(10_000)).to eq(0)
    end
  end

  describe "tenant default scope" do
    it "is a tenant default when auction_id is nil" do
      schedule = create(:bid_increment_schedule, auction_id: nil)

      expect(Current.tenant.default_bid_increment_schedule).to eq(schedule)
    end

    it "is not returned as tenant default when linked to an auction" do
      auction  = create(:auction)
      create(:bid_increment_schedule, auction: auction)

      expect(Current.tenant.default_bid_increment_schedule).to be_nil
    end
  end

  describe "dependent destroy" do
    it "destroys associated tiers when the schedule is destroyed" do
      schedule = create(:bid_increment_schedule)
      create(:bid_increment_tier, bid_increment_schedule: schedule)
      create(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 10_000, increment_cents: 1_000)

      expect { schedule.destroy }.to change(BidIncrementTier, :count).by(-2)
    end
  end
end
