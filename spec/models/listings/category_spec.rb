require "rails_helper"

RSpec.describe Listings::Category, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to have_many(:category_assignments).dependent(:destroy) }
    it { is_expected.to have_many(:listings).through(:category_assignments) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "rejects duplicate names within the same tenant (case-sensitive uniqueness)" do
      create(:listings_category, name: "Canoes")
      duplicate = build(:listings_category, name: "Canoes")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it "allows the same name across different tenants" do
      create(:listings_category, name: "Canoes")

      Current.tenant = create(:tenant)
      other = build(:listings_category, name: "Canoes")

      expect(other).to be_valid
    ensure
      Current.tenant = nil
    end
  end
end
