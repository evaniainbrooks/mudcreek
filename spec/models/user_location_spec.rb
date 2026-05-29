require "rails_helper"

RSpec.describe UserLocation, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:location) }
  end

  describe "validations" do
    it "prevents the same user from being linked to a location twice" do
      ul   = create(:user_location)
      dupe = build(:user_location, user: ul.user, location: ul.location)
      expect(dupe).not_to be_valid
      expect(dupe.errors[:user_id]).to be_present
    end

    it "allows the same user at a different location" do
      ul    = create(:user_location)
      other = build(:user_location, user: ul.user)
      expect(other).to be_valid
    end

    it "allows a different user at the same location" do
      ul    = create(:user_location)
      other = build(:user_location, location: ul.location)
      expect(other).to be_valid
    end
  end
end
