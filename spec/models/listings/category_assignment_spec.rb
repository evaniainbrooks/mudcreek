require "rails_helper"

RSpec.describe Listings::CategoryAssignment, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it "rejects assigning the same category to a listing twice" do
      listing  = create(:listing)
      category = create(:listings_category)
      Listings::CategoryAssignment.create!(listing: listing, category: category)
      duplicate = Listings::CategoryAssignment.new(listing: listing, category: category)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:listings_category_id]).to be_present
    end

    it "allows the same category on different listings" do
      category = create(:listings_category)
      Listings::CategoryAssignment.create!(listing: create(:listing), category: category)
      second   = Listings::CategoryAssignment.new(listing: create(:listing), category: category)
      expect(second).to be_valid
    end
  end
end
