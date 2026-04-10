require "rails_helper"

RSpec.describe CheckIn, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:location) { create(:location) }

  describe "validations" do
    it "requires guest_name when no user is set" do
      check_in = CheckIn.new(location: location, user: nil, guest_name: "")
      expect(check_in).not_to be_valid
      expect(check_in.errors[:guest_name]).to be_present
    end

    it "does not require guest_name when a user is set" do
      check_in = CheckIn.new(location: location, user: create(:user), guest_name: nil)
      expect(check_in).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:location) }
    it { is_expected.to belong_to(:user).optional }
  end
end
