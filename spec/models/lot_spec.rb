require "rails_helper"

RSpec.describe Lot, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:owner).class_name("User") }
    it { is_expected.to have_many(:listings).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "destroying a lot" do
    it "nullifies the lot_id on associated listings rather than deleting them" do
      lot     = create(:lot)
      listing = create(:listing, lot: lot)

      lot.destroy

      expect(listing.reload.lot_id).to be_nil
    end
  end
end
