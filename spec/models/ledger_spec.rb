require "rails_helper"

RSpec.describe Ledger, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "defaults" do
    it "is shared by default" do
      expect(Ledger.new(name: "Test").shared).to be true
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:location).optional }
    it { is_expected.to have_many(:entries).class_name("Ledger::Entry").dependent(:destroy) }
  end

  describe "#tax_rate" do
    it "returns the location tax rate when a location is assigned" do
      location = create(:location, tax_rate: 0.13)
      ledger   = create(:ledger, location: location)
      expect(ledger.tax_rate).to eq(0.13)
    end

    it "falls back to SALES_TAX_RATE when no location is assigned" do
      ledger = create(:ledger, location: nil)
      expect(ledger.tax_rate).to eq(SALES_TAX_RATE)
    end
  end

  describe ".ordered" do
    it "orders by name" do
      c = create(:ledger, name: "Canteen")
      a = create(:ledger, name: "Admin")
      b = create(:ledger, name: "Bar")
      expect(Ledger.ordered.to_a).to eq([a, b, c])
    end
  end
end
