require "rails_helper"

RSpec.describe Listings::OptionValue, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing) { create(:listing) }
  let(:option)  { Listings::Option.create!(listing: listing, name: "Size") }

  describe "validations" do
    it "requires a value" do
      value = Listings::OptionValue.new(option: option, value: "")
      expect(value).not_to be_valid
      expect(value.errors[:value]).to be_present
    end
  end

  describe "position auto-assignment" do
    it "assigns a position on create" do
      value = Listings::OptionValue.create!(option: option, value: "Small")
      expect(value.position).to be_present
    end

    it "assigns incrementing positions" do
      first  = Listings::OptionValue.create!(option: option, value: "Small")
      second = Listings::OptionValue.create!(option: option, value: "Large")
      expect(second.position).to be > first.position
    end
  end
end
