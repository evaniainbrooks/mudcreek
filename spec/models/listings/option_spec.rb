require "rails_helper"

RSpec.describe Listings::Option, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:listing) { create(:listing) }

  describe "validations" do
    it "requires name" do
      option = Listings::Option.new(listing: listing, name: "")
      expect(option).not_to be_valid
      expect(option.errors[:name]).to be_present
    end
  end

  describe "position auto-assignment" do
    it "assigns position on create" do
      option = Listings::Option.create!(listing: listing, name: "Size")
      expect(option.position).to be_present
    end

    it "assigns incrementing positions" do
      first  = Listings::Option.create!(listing: listing, name: "Size")
      second = Listings::Option.create!(listing: listing, name: "Colour")
      expect(second.position).to be > first.position
    end
  end
end
