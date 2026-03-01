require "rails_helper"

RSpec.describe Listings::RentalRatePlan, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing) { create(:listing, listing_type: :rental) }

  describe "associations" do
    it { is_expected.to belong_to(:listing) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:duration_minutes) }
    it { is_expected.to validate_presence_of(:price_cents) }

    it "rejects a zero duration" do
      plan = build(:listings_rental_rate_plan, listing: listing, duration_minutes: 0)

      expect(plan).not_to be_valid
      expect(plan.errors[:duration_minutes]).to be_present
    end

    it "rejects a negative duration" do
      plan = build(:listings_rental_rate_plan, listing: listing, duration_minutes: -60)

      expect(plan).not_to be_valid
      expect(plan.errors[:duration_minutes]).to be_present
    end

    it "accepts a positive duration" do
      plan = build(:listings_rental_rate_plan, listing: listing, duration_minutes: 60)

      expect(plan).to be_valid
    end

    it "rejects a negative price" do
      plan = build(:listings_rental_rate_plan, listing: listing, price_cents: -1)

      expect(plan).not_to be_valid
      expect(plan.errors[:price_cents]).to be_present
    end

    it "accepts a zero price" do
      plan = build(:listings_rental_rate_plan, listing: listing, price_cents: 0)

      expect(plan).to be_valid
    end

    it "accepts a positive price" do
      plan = build(:listings_rental_rate_plan, listing: listing, price_cents: 1500)

      expect(plan).to be_valid
    end
  end

  describe "monetization" do
    it "exposes price as a Money object" do
      plan = build(:listings_rental_rate_plan, listing: listing, price_cents: 2500)

      expect(plan.price).to eq(Money.new(2500, "CAD"))
    end
  end
end
