require "rails_helper"

RSpec.describe BidIncrementTier, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:schedule) { create(:bid_increment_schedule) }

  describe "associations" do
    it { is_expected.to belong_to(:bid_increment_schedule) }
  end

  describe "validations" do
    describe "min_amount_cents" do
      it "is valid at zero" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 0)

        expect(tier).to be_valid
      end

      it "is valid for a positive value" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 10_000)

        expect(tier).to be_valid
      end

      it "is invalid when absent" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: nil)

        expect(tier).not_to be_valid
        expect(tier.errors[:min_amount_cents]).to be_present
      end

      it "is invalid when negative" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: -1)

        expect(tier).not_to be_valid
        expect(tier.errors[:min_amount_cents]).to be_present
      end

      it "is invalid when non-integer" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, min_amount_cents: 1.5)

        expect(tier).not_to be_valid
        expect(tier.errors[:min_amount_cents]).to be_present
      end
    end

    describe "increment_cents" do
      it "is valid for a positive value" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, increment_cents: 500)

        expect(tier).to be_valid
      end

      it "is invalid when absent" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, increment_cents: nil)

        expect(tier).not_to be_valid
        expect(tier.errors[:increment_cents]).to be_present
      end

      it "is invalid at zero" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, increment_cents: 0)

        expect(tier).not_to be_valid
        expect(tier.errors[:increment_cents]).to be_present
      end

      it "is invalid when negative" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, increment_cents: -100)

        expect(tier).not_to be_valid
        expect(tier.errors[:increment_cents]).to be_present
      end

      it "is invalid when non-integer" do
        tier = build(:bid_increment_tier, bid_increment_schedule: schedule, increment_cents: 5.5)

        expect(tier).not_to be_valid
        expect(tier.errors[:increment_cents]).to be_present
      end
    end
  end
end
