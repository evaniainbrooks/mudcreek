require "rails_helper"

RSpec.describe SubscriptionUser, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  describe "associations" do
    it { is_expected.to belong_to(:subscription) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it "prevents adding the same user to a subscription twice" do
      su   = create(:subscription_user)
      dupe = build(:subscription_user, subscription: su.subscription, user: su.user)
      expect(dupe).not_to be_valid
      expect(dupe.errors[:user_id]).to be_present
    end

    it "allows the same user on a different subscription" do
      su    = create(:subscription_user)
      other = build(:subscription_user, user: su.user)
      expect(other).to be_valid
    end
  end
end
