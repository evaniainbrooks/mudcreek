require "rails_helper"

RSpec.describe Kid, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:birthdate) }
  end

  describe "associations" do
    it "belongs to a user" do
      kid = create(:kid)
      expect(kid.user).to be_a(User)
    end
  end
end
