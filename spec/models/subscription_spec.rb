require "rails_helper"

RSpec.describe Subscription, type: :model do
  before { Current.tenant = create(:tenant) }
  after  { Current.tenant = nil }

  let(:user) { create(:user) }
  let(:plan) { create(:subscription_plan) }

  describe "validations" do
    it "requires renews_at" do
      sub = Subscription.new(subscription_plan: plan, renews_at: nil)
      expect(sub).not_to be_valid
      expect(sub.errors[:renews_at]).to be_present
    end
  end

  describe ".due" do
    it "includes active subscriptions with renews_at on or before today" do
      due_sub = create(:subscription, user: user, subscription_plan: plan, renews_at: Date.yesterday)
      expect(Subscription.due).to include(due_sub)
    end

    it "excludes subscriptions with renews_at in the future" do
      future_sub = create(:subscription, user: user, subscription_plan: plan, renews_at: Date.tomorrow)
      expect(Subscription.due).not_to include(future_sub)
    end

    it "excludes lapsed subscriptions" do
      lapsed = create(:subscription, user: user, subscription_plan: plan, renews_at: Date.yesterday, status: :lapsed)
      expect(Subscription.due).not_to include(lapsed)
    end

    it "excludes cancelled subscriptions" do
      cancelled = create(:subscription, user: user, subscription_plan: plan, renews_at: Date.yesterday, status: :cancelled)
      expect(Subscription.due).not_to include(cancelled)
    end
  end
end
