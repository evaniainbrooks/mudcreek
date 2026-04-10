require "rails_helper"

RSpec.describe Location, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "rejects a negative tax rate" do
      location = build(:location, tax_rate: -0.01)
      expect(location).not_to be_valid
      expect(location.errors[:tax_rate]).to be_present
    end

    it "rejects a tax rate >= 1" do
      location = build(:location, tax_rate: 1.0)
      expect(location).not_to be_valid
    end

    it "accepts a tax rate of 0" do
      expect(build(:location, tax_rate: 0)).to be_valid
    end
  end

  describe "only one default per tenant" do
    it "allows the first default location" do
      location = build(:location, default: true)
      expect(location).to be_valid
    end

    it "rejects a second default location" do
      create(:location, default: true)
      second = build(:location, default: true)
      expect(second).not_to be_valid
      expect(second.errors[:base]).to be_present
    end

    it "allows updating the existing default location without error" do
      location = create(:location, default: true)
      location.name = "Updated"
      expect(location).to be_valid
    end
  end

  describe "#tax_rate_percent" do
    it "returns tax_rate as a percentage" do
      location = build(:location, tax_rate: 0.13)
      expect(location.tax_rate_percent).to eq(13.0)
    end
  end

  describe "#tax_rate_percent=" do
    it "converts a percentage string to a decimal tax_rate" do
      location = build(:location)
      location.tax_rate_percent = "13"
      expect(location.tax_rate).to eq(BigDecimal("0.13"))
    end
  end

  describe ".ordered" do
    it "orders by name" do
      c = create(:location, name: "Central")
      a = create(:location, name: "Airport")
      expect(Location.ordered.to_a).to eq([a, c])
    end
  end
end
