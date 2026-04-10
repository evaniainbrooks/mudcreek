require "rails_helper"

RSpec.describe Listings::Property, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }

    it "is invalid when neither listing nor property_set is present" do
      property = Listings::Property.new(name: "Colour", value: "Red")
      expect(property).not_to be_valid
      expect(property.errors[:base]).to be_present
    end

    it "is valid when assigned to a listing" do
      property = Listings::Property.new(name: "Colour", value: "Red", listing: create(:listing))
      expect(property).to be_valid
    end

    it "is valid when assigned to a property_set" do
      property = build(:listings_property)
      expect(property).to be_valid
    end
  end
end
