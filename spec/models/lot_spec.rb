require "rails_helper"

RSpec.describe Lot, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:owner).class_name("User") }
    it { is_expected.to have_many(:listings).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "destroying a lot" do
    it "destroys associated listings", :skip_n_plus_one do
      lot     = create(:lot)
      listing = create(:listing, lot: lot, owner: nil)

      lot.destroy

      expect { listing.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
