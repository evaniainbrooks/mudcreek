require "rails_helper"

RSpec.describe DeliveryMethod, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "rejects duplicate names within the same tenant (case-insensitive)" do
      create(:delivery_method, name: "Standard Shipping")
      duplicate = build(:delivery_method, name: "standard shipping")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "rejects a negative price" do
      method = build(:delivery_method, price_cents: -1)

      expect(method).not_to be_valid
      expect(method.errors[:price_cents]).to be_present
    end

    it "accepts a zero price (free delivery)" do
      method = build(:delivery_method, price_cents: 0)

      expect(method).to be_valid
    end

    it "accepts a positive price" do
      method = build(:delivery_method, price_cents: 1500)

      expect(method).to be_valid
    end
  end

  describe "monetization" do
    it "exposes price as a Money object" do
      method = build(:delivery_method, price_cents: 999)

      expect(method.price).to eq(Money.new(999, "CAD"))
    end
  end
end
